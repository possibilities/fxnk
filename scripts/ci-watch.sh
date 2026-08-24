#!/bin/bash

# Watch the fork's hosted Full CI and drive every published Integration SHA to
# a recorded verdict. Full CI gates nothing, so this script never blocks and
# never publishes; it observes, retries what is mechanically retryable, and
# escalates to the human when a verdict is bad or overdue.

set -euo pipefail

# The declared subject. These match MAINTAIN.md; nothing else here decides them.
repo=possibilities/fx
branch=integration
workflow=full-ci.yml

# A push that never produced a run within this window is a broken trigger.
trigger_grace_seconds=900
# The published tip may sit unverified this long before the human hears about it.
max_unverified_seconds=$((3 * 24 * 60 * 60))
# Re-escalate an unchanged overdue verdict at most this often.
stale_repeat_seconds=$((24 * 60 * 60))
# Mechanical reruns before a run's failure becomes the human's problem.
max_auto_reruns=1
# Silence is indistinguishable from a dead watcher, so say something this often
# even when there is nothing wrong.
heartbeat_seconds=$((24 * 60 * 60))

die() {
    printf 'fxnk ci watch: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/ci-watch.sh [--once | --declare] [--state-dir PATH]\n'
}

mode=once
state_dir_override=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --once)
            mode=once
            shift
            ;;
        --declare)
            mode=declare
            shift
            ;;
        --state-dir)
            [ "$#" -ge 2 ] || die "--state-dir requires a path"
            state_dir_override=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 64
            ;;
    esac
done

if [ "$mode" = declare ]; then
    jq -n \
        --arg repo "$repo" \
        --arg branch "$branch" \
        --arg workflow "$workflow" \
        --argjson trigger_grace_seconds "$trigger_grace_seconds" \
        --argjson max_unverified_seconds "$max_unverified_seconds" \
        --argjson max_auto_reruns "$max_auto_reruns" \
        '{repo:$repo,branch:$branch,workflow:$workflow,
          trigger_grace_seconds:$trigger_grace_seconds,
          max_unverified_seconds:$max_unverified_seconds,
          max_auto_reruns:$max_auto_reruns}'
    exit 0
fi

for required in jq date; do
    command -v "$required" >/dev/null 2>&1 || die "$required is required"
done
gh_bin="${FXNK_CI_WATCH_GH_BIN:-$(command -v gh || true)}"
[ -n "$gh_bin" ] && [ -x "$gh_bin" ] || die "gh is required"
notifier_bin="${FXNK_CI_WATCH_NOTIFIER_BIN:-$(command -v terminal-notifier || true)}"

now="${FXNK_CI_WATCH_NOW:-$(date +%s)}"
case "$now" in
    ''|*[!0-9]*) die "FXNK_CI_WATCH_NOW must be epoch seconds" ;;
esac

state_dir="${state_dir_override:-${FXNK_STATE_DIR:-$HOME/.local/state/fxnk}}"
verdict_dir="$state_dir/full-ci"
pending_file="$verdict_dir/pending.json"
mkdir -p "$verdict_dir"
chmod 0700 "$state_dir" "$verdict_dir"

scratch=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-ci-watch.XXXXXX")
cleanup() {
    local status=$?
    trap - EXIT
    rm -rf -- "$scratch"
    exit "$status"
}
trap cleanup EXIT

iso_now=$(date -u -r "$now" '+%Y-%m-%dT%H:%M:%SZ')

epoch_of() {
    # GitHub timestamps are RFC 3339 in UTC.
    date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" '+%s' 2>/dev/null || printf '0'
}

write_atomic() {
    local destination="$1" source="$2" pending
    pending=$(mktemp "$(dirname "$destination")/.$(basename "$destination").XXXXXX")
    cat "$source" >"$pending"
    chmod 0600 "$pending"
    mv "$pending" "$destination" \
        || die "could not atomically record $destination"
}

sent_message=false

notify() {
    local message="$1" url="$2"
    [ -n "$notifier_bin" ] || return 0
    sent_message=true
    if [ -n "$url" ]; then
        "$notifier_bin" -title 'Fx Maintenance' -group fxnk.maintain \
            -message "$message" -open "$url" -ignoreDnD >/dev/null 2>&1 || true
    else
        "$notifier_bin" -title 'Fx Maintenance' -group fxnk.maintain \
            -message "$message" -ignoreDnD >/dev/null 2>&1 || true
    fi
}

# ---------------------------------------------------------------------------
# The published tip and its newest run.

tip=$("$gh_bin" api "repos/$repo/git/ref/heads/$branch" --jq '.object.sha' 2>/dev/null) \
    || die "could not read the published $branch ref"
printf '%s' "$tip" | grep -Eq '^[0-9a-f]{40}$' \
    || die "published $branch ref is not a commit SHA"

tip_committed_at=$(
    "$gh_bin" api "repos/$repo/commits/$tip" --jq '.commit.committer.date' 2>/dev/null
) || die "could not read the published tip commit"
tip_epoch=$(epoch_of "$tip_committed_at")

runs_file="$scratch/runs.json"
"$gh_bin" run list --repo "$repo" --workflow "$workflow" --limit 50 \
    --json databaseId,headSha,status,conclusion,createdAt,url \
    >"$runs_file" 2>/dev/null || die "could not list $workflow runs"

run=$(jq -c --arg sha "$tip" \
    '[.[] | select(.headSha == $sha)] | sort_by(.createdAt) | last // empty' \
    "$runs_file")

receipt="$verdict_dir/$tip.json"
prior='{}'
[ -f "$receipt" ] && prior=$(cat "$receipt")
prior_reruns=$(printf '%s' "$prior" | jq -r '.reruns // 0')
prior_first_seen=$(printf '%s' "$prior" | jq -r '.first_seen_at // empty')
prior_notified=$(printf '%s' "$prior" | jq -r '.notified_at // empty')
prior_notified_classification=$(
    printf '%s' "$prior" | jq -r '.notified_classification // empty'
)
[ -n "$prior_first_seen" ] || prior_first_seen=$iso_now

status=
classification=
conclusion=null
run_id=null
run_url=
failing_jobs='[]'
failing_tests='[]'
reruns=$prior_reruns
detail=

if [ -z "$run" ]; then
    conclusion=null
    if [ $((now - tip_epoch)) -gt "$trigger_grace_seconds" ]; then
        status=no_run
        classification=absent
        detail="no $workflow run exists for the published tip"
    else
        status=pending
        classification=awaiting_start
        detail='waiting for the run to appear'
    fi
else
    run_id=$(printf '%s' "$run" | jq -r '.databaseId')
    run_url=$(printf '%s' "$run" | jq -r '.url')
    run_status=$(printf '%s' "$run" | jq -r '.status')
    run_conclusion=$(printf '%s' "$run" | jq -r '.conclusion // ""')
    conclusion=$(printf '%s' "$run" | jq '.conclusion')

    if [ "$run_status" != completed ]; then
        status=pending
        classification=running
        detail="run $run_id is $run_status"
    else
        case "$run_conclusion" in
            success)
                status=green
                classification=green
                detail='every declared job passed'
                ;;
            cancelled)
                # cancel-in-progress fired, but this SHA is still the published
                # tip, so nothing newer replaced its verdict — it is simply
                # missing, and restarting it is mechanical.
                status=no_verdict
                classification=cancelled
                detail="run $run_id was cancelled and left the tip unverified"
                if [ "$reruns" -lt "$max_auto_reruns" ]; then
                    if "$gh_bin" run rerun "$run_id" --repo "$repo" >/dev/null 2>&1; then
                        reruns=$((reruns + 1))
                        status=pending
                        classification=rerun
                        detail="restarted cancelled run $run_id for the current tip"
                    fi
                fi
                ;;
            *)
                jobs_file="$scratch/jobs.json"
                "$gh_bin" run view "$run_id" --repo "$repo" --json jobs \
                    >"$jobs_file" 2>/dev/null || printf '{"jobs":[]}' >"$jobs_file"
                failing_jobs=$(jq -c '[.jobs[]? | select(.conclusion != "success")
                    | {name, conclusion,
                       failed_step: ([.steps[]? | select(.conclusion != "success")
                                      | .name] | first // "")}]' "$jobs_file")

                # Classify from the step that failed. Setup and dependency steps
                # are the runner's problem and are worth one mechanical retry;
                # anything else — including anything unrecognized — is ours.
                infrastructure=$(jq -r '
                    def setupish:
                        test("^(Set up job|Setup |Install |Restore |Post |Checkout|actions/)";
                             "i");
                    if ((. | length) == 0) then "false"
                    elif all(.[]; (.failed_step | setupish) or .conclusion == "cancelled")
                    then "true" else "false" end' <<<"$failing_jobs")

                log_file="$scratch/failed.log"
                "$gh_bin" run view "$run_id" --repo "$repo" --log-failed \
                    >"$log_file" 2>/dev/null || : >"$log_file"
                # An empty log is normal for an infrastructure failure, and a
                # grep that matches nothing must not poison the pipeline.
                failing_tests=$(
                    { grep -m 200 -Eo '\(fail\) [^[]+' "$log_file" || true; } \
                        | sed 's/^(fail) //; s/[[:space:]]*$//' | sort -u \
                        | jq -R . | jq -sc '.[0:20]'
                )

                if [ "$infrastructure" = true ] && [ "$reruns" -lt "$max_auto_reruns" ]; then
                    if "$gh_bin" run rerun "$run_id" --repo "$repo" --failed \
                        >/dev/null 2>&1; then
                        reruns=$((reruns + 1))
                        status=pending
                        classification=rerun
                        detail="retried infrastructure failure in run $run_id"
                    else
                        status=failed
                        classification=infrastructure
                        detail="run $run_id failed in setup and could not be retried"
                    fi
                elif [ "$infrastructure" = true ]; then
                    status=failed
                    classification=infrastructure
                    detail="run $run_id failed in setup again after $reruns retry"
                else
                    status=failed
                    classification=real_failure
                    detail="run $run_id has failing tests"
                fi
                ;;
        esac
    fi
fi

# ---------------------------------------------------------------------------
# Escalate at most once per SHA, and record what was sent.

notified_at=$prior_notified
notified_classification=$prior_notified_classification
if [ "$status" = failed ] || [ "$status" = no_run ]; then
    if [ "$prior_notified_classification" != "$classification" ]; then
        summary=$(printf '%s' "$failing_tests" | jq -r 'if length == 0 then "" else .[0] end')
        message="Full CI ${classification//_/ } on ${tip:0:12}"
        [ -n "$summary" ] && message="$message — $summary"
        notify "$message" "$run_url"
        notified_at=$iso_now
        notified_classification=$classification
    fi
fi

jq -n \
    --arg sha "$tip" \
    --arg workflow "$workflow" \
    --arg status "$status" \
    --arg classification "$classification" \
    --arg detail "$detail" \
    --arg url "$run_url" \
    --arg first_seen "$prior_first_seen" \
    --arg recorded_at "$iso_now" \
    --arg notified_at "$notified_at" \
    --arg notified_classification "$notified_classification" \
    --argjson run_id "$run_id" \
    --argjson conclusion "$conclusion" \
    --argjson failing_jobs "$failing_jobs" \
    --argjson failing_tests "$failing_tests" \
    --argjson reruns "$reruns" \
    '{schema:1,fx_sha:$sha,workflow:$workflow,
      run:{id:$run_id,url:$url},
      status:$status,classification:$classification,detail:$detail,
      conclusion:$conclusion,
      failing_jobs:$failing_jobs,failing_tests:$failing_tests,
      reruns:$reruns,
      first_seen_at:$first_seen,recorded_at:$recorded_at,
      notified_at:(if $notified_at == "" then null else $notified_at end),
      notified_classification:(if $notified_classification == "" then null
                               else $notified_classification end)}' \
    >"$scratch/receipt.json"
write_atomic "$receipt" "$scratch/receipt.json"

# ---------------------------------------------------------------------------
# The overdue backstop. Serialization means a busy week can cancel every run;
# that is accepted, but it must never be silent.

prior_pending='{}'
[ -f "$pending_file" ] && prior_pending=$(cat "$pending_file")
stale_notified=$(printf '%s' "$prior_pending" | jq -r '.stale_notified_at // empty')
last_message=$(printf '%s' "$prior_pending" | jq -r '.last_message_at // empty')

last_green=$(
    jq -sr '[.[] | select(.status == "green")] | sort_by(.recorded_at) | last // empty
            | .recorded_at // ""' "$verdict_dir"/*.json 2>/dev/null || printf ''
)
unverified_since=${last_green:-}
if [ -n "$unverified_since" ]; then
    unverified_epoch=$(epoch_of "$unverified_since")
else
    unverified_epoch=$(epoch_of "$prior_first_seen")
fi
unverified_seconds=$((now - unverified_epoch))

stale=false
if [ "$status" != green ] && [ "$unverified_seconds" -gt "$max_unverified_seconds" ]; then
    stale=true
fi

stale_notified_at=$stale_notified
if [ "$stale" = true ]; then
    send=true
    if [ -n "$stale_notified" ]; then
        last_epoch=$(epoch_of "$stale_notified")
        [ $((now - last_epoch)) -ge "$stale_repeat_seconds" ] || send=false
    fi
    if [ "$send" = true ]; then
        notify \
            "Full CI has not been green for $((unverified_seconds / 86400))d — pause Integration pushes to let a suite finish" \
            "https://github.com/$repo/actions/workflows/$workflow"
        stale_notified_at=$iso_now
    fi
fi

# A quiet day still gets one line, so a watcher that has silently died is
# visible as absence rather than mistaken for good news.
if [ "$sent_message" = false ]; then
    last_message_epoch=0
    [ -n "$last_message" ] && last_message_epoch=$(epoch_of "$last_message")
    if [ $((now - last_message_epoch)) -ge "$heartbeat_seconds" ]; then
        heartbeat="Full CI watch alive — ${tip:0:12} is $status"
        [ -n "$last_green" ] && heartbeat="$heartbeat, last green $last_green"
        notify "$heartbeat" "$run_url"
    fi
fi
last_message_at=$last_message
[ "$sent_message" = true ] && last_message_at=$iso_now

open_kind=
case "$status" in
    failed) open_kind=$classification ;;
    no_run) open_kind=absent ;;
esac
if [ "$stale" = true ] && [ -z "$open_kind" ]; then
    open_kind=overdue
fi

if [ -n "$open_kind" ]; then
    jq -n \
        --arg updated_at "$iso_now" \
        --arg sha "$tip" \
        --arg kind "$open_kind" \
        --arg detail "$detail" \
        --arg url "$run_url" \
        --arg since "$prior_first_seen" \
        --arg stale_notified_at "$stale_notified_at" \
        --arg last_message_at "$last_message_at" \
        '{schema:1,updated_at:$updated_at,
          stale_notified_at:(if $stale_notified_at == "" then null
                             else $stale_notified_at end),
          last_message_at:(if $last_message_at == "" then null
                           else $last_message_at end),
          open:[{fx_sha:$sha,kind:$kind,detail:$detail,run_url:$url,since:$since}]}' \
        >"$scratch/pending.json"
else
    jq -n \
        --arg updated_at "$iso_now" \
        --arg stale_notified_at "$stale_notified_at" \
        --arg last_message_at "$last_message_at" \
        '{schema:1,updated_at:$updated_at,
          stale_notified_at:(if $stale_notified_at == "" then null
                             else $stale_notified_at end),
          last_message_at:(if $last_message_at == "" then null
                           else $last_message_at end),
          open:[]}' \
        >"$scratch/pending.json"
fi
write_atomic "$pending_file" "$scratch/pending.json"

printf 'CI-WATCH %s %s %s\n' "${tip:0:12}" "$status" "$classification"
