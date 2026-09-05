#!/bin/bash

# Watch the fork's hosted Full CI and drive every published Integration SHA to
# a recorded verdict. Full CI gates nothing, so this script never blocks and
# never publishes; it observes, retries what is mechanically retryable, and
# escalates to the human when a verdict is bad, missing, or overdue.
#
# Two rules shape everything below. A verdict is only as good as its evidence,
# so anything this cannot classify escalates rather than guessing. And silence
# must never pass for health, so an unverified tip stays on the books and a
# quiet watcher still says it is alive.

set -euo pipefail

# The declared subject. These match MAINTAIN.md; nothing else here decides them.
repo=possibilities/fx
branch=integration
workflow=full-ci.yml
# Jobs that only restate other jobs' conclusions. They carry no evidence of
# their own, and counting them makes every failure look like a test failure,
# because the aggregate step fails whatever the real cause was.
aggregate_job_prefix='Full suite'

# A push that never produced a run within this window is a broken trigger.
trigger_grace_seconds=900
# The published branch may go this long without a green verdict before the
# human hears about it.
max_unverified_seconds=$((3 * 24 * 60 * 60))
# Re-escalate an unchanged overdue verdict at most this often.
stale_repeat_seconds=$((24 * 60 * 60))
# Repeat an escalation for one SHA at most this often, however much its
# classification moves around.
renotify_seconds=$((6 * 60 * 60))
# Mechanical reruns before a run's failure becomes the human's problem.
max_auto_reruns=1
# Silence is indistinguishable from a dead watcher, so say something this often
# even when there is nothing wrong.
heartbeat_seconds=$((24 * 60 * 60))
# A poll that died without releasing its lock must not wedge the watcher.
lock_stale_seconds=1800
# An obligation nobody revisited in this long describes a tip that is gone.
carry_seconds=$((30 * 24 * 60 * 60))

die() {
    printf 'fxnk ci watch: %s\n' "$*" >&2
    exit 1
}

warn() {
    printf 'fxnk ci watch: %s\n' "$*" >&2
}

usage() {
    printf 'Usage: scripts/ci-watch.sh [--once | --declare] [--state-dir PATH]\n'
}

mode=once
state_dir_override=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --once) mode=once; shift ;;
        --declare) mode=declare; shift ;;
        --state-dir)
            [ "$#" -ge 2 ] || die "--state-dir requires a path"
            state_dir_override=$2
            shift 2
            ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 64 ;;
    esac
done

for required in jq date; do
    command -v "$required" >/dev/null 2>&1 || die "$required is required"
done

if [ "$mode" = declare ]; then
    jq -n \
        --arg repo "$repo" \
        --arg branch "$branch" \
        --arg workflow "$workflow" \
        --argjson trigger_grace_seconds "$trigger_grace_seconds" \
        --argjson max_unverified_seconds "$max_unverified_seconds" \
        --argjson max_auto_reruns "$max_auto_reruns" \
        --argjson heartbeat_seconds "$heartbeat_seconds" \
        '{repo:$repo,branch:$branch,workflow:$workflow,
          trigger_grace_seconds:$trigger_grace_seconds,
          max_unverified_seconds:$max_unverified_seconds,
          max_auto_reruns:$max_auto_reruns,
          heartbeat_seconds:$heartbeat_seconds}'
    exit 0
fi

gh_bin="${FXNK_CI_WATCH_GH_BIN:-$(command -v gh || true)}"
[ -n "$gh_bin" ] && [ -x "$gh_bin" ] || die "gh is required"
# An explicitly empty override means "no notifier", which must stay
# distinguishable from "not overridden".
notifier_bin="${FXNK_CI_WATCH_NOTIFIER_BIN-$(command -v terminal-notifier || true)}"

now="${FXNK_CI_WATCH_NOW:-$(date +%s)}"
case "$now" in
    ''|*[!0-9]*) die "FXNK_CI_WATCH_NOW must be epoch seconds" ;;
esac

state_dir="${state_dir_override:-${FXNK_STATE_DIR:-$HOME/.local/state/fxnk}}"
verdict_dir="$state_dir/full-ci"
pending_file="$verdict_dir/pending.json"
lock_dir="$verdict_dir/.lock"
mkdir -p "$verdict_dir"
chmod 0700 "$state_dir" "$verdict_dir"

iso_now=$(date -u -r "$now" '+%Y-%m-%dT%H:%M:%SZ')

# One poll at a time. A poll makes several network round trips, so launchd can
# start the next before this one finishes; overlap would double-spend the rerun
# budget and lose whichever file the loser wrote.
if ! mkdir "$lock_dir" 2>/dev/null; then
    lock_epoch=$(stat -f '%m' "$lock_dir" 2>/dev/null || stat -c '%Y' "$lock_dir" 2>/dev/null || printf '0')
    if [ "$((now - lock_epoch))" -lt "$lock_stale_seconds" ]; then
        printf 'CI-WATCH busy\n'
        exit 0
    fi
    warn "breaking a stale poll lock"
    rm -rf -- "$lock_dir"
    mkdir "$lock_dir" 2>/dev/null || die "could not take the poll lock"
fi

scratch=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-ci-watch.XXXXXX")
pending_write=
cleanup() {
    local status=$?
    trap - EXIT
    if [ -n "$pending_write" ] && [ -e "$pending_write" ]; then
        rm -f -- "$pending_write"
    fi
    rm -rf -- "$scratch" "$lock_dir"
    exit "$status"
}
trap cleanup EXIT

# GitHub timestamps are RFC 3339. Print epoch seconds, or nothing when the
# stamp cannot be read: an unreadable time is unknown, and no caller may turn
# unknown into an escalation.
epoch_of() {
    local stamp="$1" normalized
    [ -n "$stamp" ] || return 0
    normalized=${stamp/+00:00/Z}
    date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$normalized" '+%s' 2>/dev/null || true
}

# A hand-edited, truncated, or half-written state file costs one poll's
# history, never every future poll.
read_json() {
    local file="$1" text
    [ -f "$file" ] || { printf '{}'; return 0; }
    text=$(cat "$file" 2>/dev/null) || { printf '{}'; return 0; }
    if printf '%s' "$text" | jq -e 'type == "object"' >/dev/null 2>&1; then
        printf '%s' "$text"
    else
        warn "ignoring unreadable state file: $file"
        printf '{}'
    fi
}

write_atomic() {
    local destination="$1" source="$2"
    pending_write=$(mktemp "$(dirname "$destination")/.$(basename "$destination").XXXXXX")
    cat "$source" >"$pending_write"
    chmod 0600 "$pending_write"
    mv "$pending_write" "$destination" \
        || die "could not atomically record $destination"
    pending_write=
}

# Report whether the human was actually reached. Recording a notification that
# never left would silently spend the escalation for that SHA.
sent_message=false
notify() {
    local message="$1" url="$2"
    if [ -z "$notifier_bin" ]; then
        warn "no notifier available; not delivered: $message"
        return 1
    fi
    if [ -n "$url" ]; then
        "$notifier_bin" -title 'Fx Maintenance' -group fxnk.maintain \
            -message "$message" -open "$url" -ignoreDnD >/dev/null 2>&1 \
            || { warn "notifier failed; not delivered: $message"; return 1; }
    else
        "$notifier_bin" -title 'Fx Maintenance' -group fxnk.maintain \
            -message "$message" -ignoreDnD >/dev/null 2>&1 \
            || { warn "notifier failed; not delivered: $message"; return 1; }
    fi
    sent_message=true
    return 0
}

# --- the published tip and its newest run ------------------------------------

tip=$("$gh_bin" api "repos/$repo/git/ref/heads/$branch" --jq '.object.sha' 2>/dev/null) \
    || die "could not read the published $branch ref"
printf '%s' "$tip" | grep -Eq '^[0-9a-f]{40}$' \
    || die "published $branch ref is not a commit SHA"

tip_committed_at=$(
    "$gh_bin" api "repos/$repo/commits/$tip" --jq '.commit.committer.date' 2>/dev/null
) || die "could not read the published tip commit"
tip_epoch=$(epoch_of "$tip_committed_at")

runs_file="$scratch/runs.json"
"$gh_bin" run list --repo "$repo" --workflow "$workflow" --limit 100 \
    --json databaseId,headSha,status,conclusion,createdAt,url \
    >"$runs_file" 2>/dev/null || die "could not list $workflow runs"
jq -e 'type == "array"' "$runs_file" >/dev/null 2>&1 \
    || die "could not parse the $workflow run list"

run=$(jq -c --arg sha "$tip" \
    '[.[] | select(.headSha == $sha)] | sort_by(.createdAt) | last // empty' \
    "$runs_file")

receipt="$verdict_dir/$tip.json"
prior=$(read_json "$receipt")
prior_reruns=$(printf '%s' "$prior" | jq -r '(.reruns | numbers) // 0')
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

request_rerun() {
    local target="$1" scope="$2"
    [ "$reruns" -lt "$max_auto_reruns" ] || return 1
    if [ "$scope" = failed ]; then
        "$gh_bin" run rerun "$target" --repo "$repo" --failed >/dev/null 2>&1 || return 1
    else
        "$gh_bin" run rerun "$target" --repo "$repo" >/dev/null 2>&1 || return 1
    fi
    reruns=$((reruns + 1))
    return 0
}

if [ -z "$run" ]; then
    if [ -z "$tip_epoch" ]; then
        # An unreadable commit time is not evidence that the trigger is broken.
        status=pending
        classification=awaiting_start
        detail='waiting for the run to appear; the tip commit time is unreadable'
    elif [ $((now - tip_epoch)) -gt "$trigger_grace_seconds" ]; then
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
                if request_rerun "$run_id" all; then
                    status=pending
                    classification=rerun
                    detail="restarted cancelled run $run_id for the current tip"
                else
                    status=no_verdict
                    classification=cancelled
                    detail="run $run_id was cancelled and left the tip unverified"
                fi
                ;;
            failure|timed_out)
                jobs_file="$scratch/jobs.json"
                jobs_read=true
                "$gh_bin" run view "$run_id" --repo "$repo" --json jobs \
                    >"$jobs_file" 2>/dev/null || jobs_read=false
                if [ "$jobs_read" = true ]; then
                    jq -e '.jobs | type == "array"' "$jobs_file" >/dev/null 2>&1 \
                        || jobs_read=false
                fi

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
                named_failures=$(printf '%s' "$failing_tests" | jq -r 'length')

                if [ "$jobs_read" = false ]; then
                    # No job evidence at all. Say that, rather than inventing a
                    # cause; a transient API error must not read as a red build.
                    status=failed
                    classification=unclassified
                    detail="run $run_id failed and its jobs could not be read"
                else
                    failing_jobs=$(jq -c '[.jobs[]? | select(.conclusion != "success")
                        | {name, conclusion,
                           failed_step: ([.steps[]? | select(.conclusion != "success")
                                          | .name] | first // "")}]' "$jobs_file")
                    # Aggregate jobs restate other jobs' results, so they are
                    # evidence of nothing and would mask every real cause.
                    leaf_jobs=$(printf '%s' "$failing_jobs" | jq -c \
                        --arg prefix "$aggregate_job_prefix" \
                        '[.[] | select(.name | startswith($prefix) | not)]')
                    setup_only=$(jq -r '
                        def setupish:
                            test("^(Set up job|Set up |Setup |Install |Restore |Post |Run actions/)";
                                 "i");
                        if (length == 0) then "false"
                        elif all(.[]; (.failed_step | length > 0) and
                                      (.failed_step | setupish)) then "true"
                        else "false" end' <<<"$leaf_jobs")

                    if [ "$named_failures" -gt 0 ]; then
                        # Named failing tests are the strongest evidence there
                        # is, whatever the step names happen to look like.
                        status=failed
                        classification=real_failure
                        detail="run $run_id has failing tests"
                    elif [ "$setup_only" = true ]; then
                        if request_rerun "$run_id" failed; then
                            status=pending
                            classification=rerun
                            detail="retried infrastructure failure in run $run_id"
                        else
                            status=failed
                            classification=infrastructure
                            detail="run $run_id failed in setup and was not retried again"
                        fi
                    elif [ "$run_conclusion" = timed_out ]; then
                        if request_rerun "$run_id" failed; then
                            status=pending
                            classification=rerun
                            detail="retried timed-out run $run_id"
                        else
                            status=failed
                            classification=infrastructure
                            detail="run $run_id timed out again"
                        fi
                    else
                        status=failed
                        classification=unclassified
                        detail="run $run_id failed without a recognizable cause"
                    fi
                fi
                ;;
            *)
                # skipped, neutral, startup_failure, action_required, stale.
                # None of these is a red build, and none is a verdict.
                status=no_verdict
                classification="$run_conclusion"
                detail="run $run_id ended $run_conclusion without a verdict"
                ;;
        esac
    fi
fi

# --- escalate on evidence, at most once per SHA per window -------------------

needs_human=false
case "$status" in
    failed|no_run) needs_human=true ;;
esac

notified_at=$prior_notified
notified_classification=$prior_notified_classification
if [ "$needs_human" = true ]; then
    send=false
    if [ -z "$prior_notified" ]; then
        send=true
    elif [ "$prior_notified_classification" != "$classification" ]; then
        # A changed classification is news, but a flapping one must not page
        # every five minutes.
        prior_epoch=$(epoch_of "$prior_notified")
        if [ -z "$prior_epoch" ] || [ $((now - prior_epoch)) -ge "$renotify_seconds" ]; then
            send=true
        fi
    fi
    if [ "$send" = true ]; then
        summary=$(printf '%s' "$failing_tests" | jq -r 'if length == 0 then "" else .[0] end')
        message="Full CI ${classification//_/ } on ${tip:0:12}"
        [ -n "$summary" ] && message="$message — $summary"
        if notify "$message" "$run_url"; then
            notified_at=$iso_now
            notified_classification=$classification
        fi
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

# --- the books: every unresolved SHA, not only the current tip ---------------

prior_pending=$(read_json "$pending_file")
stale_notified=$(printf '%s' "$prior_pending" | jq -r '.stale_notified_at // empty')
last_message=$(printf '%s' "$prior_pending" | jq -r '.last_message_at // empty')
prior_unverified_since=$(printf '%s' "$prior_pending" | jq -r '.unverified_since // empty')

open_file="$scratch/open.jsonl"
: >"$open_file"
last_green=
for candidate in "$verdict_dir"/*.json; do
    [ -e "$candidate" ] || continue
    [ "$candidate" = "$pending_file" ] && continue
    entry=$(read_json "$candidate")
    entry_status=$(printf '%s' "$entry" | jq -r '.status // empty')
    [ -n "$entry_status" ] || continue
    entry_recorded=$(printf '%s' "$entry" | jq -r '.recorded_at // empty')
    if [ "$entry_status" = green ]; then
        if [ -z "$last_green" ] || [[ "$entry_recorded" > "$last_green" ]]; then
            last_green=$entry_recorded
        fi
        continue
    fi
    case "$entry_status" in
        failed|no_run|no_verdict) ;;
        *) continue ;;
    esac
    entry_epoch=$(epoch_of "$entry_recorded")
    if [ -n "$entry_epoch" ] && [ $((now - entry_epoch)) -gt "$carry_seconds" ]; then
        continue
    fi
    printf '%s' "$entry" | jq -c \
        '{fx_sha,kind:.classification,detail,run_url:.run.url,
          since:.first_seen_at,recorded_at}' >>"$open_file"
done
open_list=$(jq -sc 'sort_by(.recorded_at) | reverse | .[0:20]' "$open_file")

# --- overdue: anchored to CI reality, carried across pushes ------------------

if [ "$status" = green ]; then
    unverified_since=
else
    # Anchoring to the last green we recorded is what keeps a busy week of
    # cancelled runs from resetting the clock with every new tip.
    unverified_since=$prior_unverified_since
    [ -z "$unverified_since" ] && unverified_since=$last_green
    [ -z "$unverified_since" ] && unverified_since=$iso_now
fi

stale=false
unverified_epoch=
if [ -n "$unverified_since" ]; then
    unverified_epoch=$(epoch_of "$unverified_since")
    if [ -n "$unverified_epoch" ] \
        && [ $((now - unverified_epoch)) -gt "$max_unverified_seconds" ]; then
        stale=true
    fi
fi

stale_notified_at=$stale_notified
if [ "$stale" = true ]; then
    send=true
    if [ -n "$stale_notified" ]; then
        last_epoch=$(epoch_of "$stale_notified")
        if [ -n "$last_epoch" ] && [ $((now - last_epoch)) -lt "$stale_repeat_seconds" ]; then
            send=false
        fi
    fi
    if [ "$send" = true ]; then
        days=$(( (now - unverified_epoch) / 86400 ))
        if notify \
            "Full CI has not been green for ${days}d — pause Integration pushes to let a suite finish" \
            "https://github.com/$repo/actions/workflows/$workflow"; then
            stale_notified_at=$iso_now
        fi
    fi
fi

# --- proof of life -----------------------------------------------------------
# A quiet day still gets one line, so a watcher that has silently died reads as
# absence rather than as good news.

if [ "$sent_message" = false ]; then
    last_message_epoch=
    [ -n "$last_message" ] && last_message_epoch=$(epoch_of "$last_message")
    if [ -z "$last_message_epoch" ] \
        || [ $((now - last_message_epoch)) -ge "$heartbeat_seconds" ]; then
        heartbeat="Full CI watch alive — ${tip:0:12} is $status"
        [ -n "$last_green" ] && heartbeat="$heartbeat, last green $last_green"
        notify "$heartbeat" "$run_url" || true
    fi
fi
last_message_at=$last_message
[ "$sent_message" = true ] && last_message_at=$iso_now

jq -n \
    --arg updated_at "$iso_now" \
    --arg stale_notified_at "$stale_notified_at" \
    --arg last_message_at "$last_message_at" \
    --arg unverified_since "$unverified_since" \
    --argjson open "$open_list" \
    --argjson overdue "$stale" \
    '{schema:1,updated_at:$updated_at,overdue:$overdue,
      stale_notified_at:(if $stale_notified_at == "" then null
                         else $stale_notified_at end),
      last_message_at:(if $last_message_at == "" then null
                       else $last_message_at end),
      unverified_since:(if $unverified_since == "" then null
                        else $unverified_since end),
      open:$open}' \
    >"$scratch/pending.json"
write_atomic "$pending_file" "$scratch/pending.json"

printf 'CI-WATCH %s %s %s\n' "${tip:0:12}" "$status" "$classification"
