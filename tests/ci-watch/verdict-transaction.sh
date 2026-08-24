#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
fixtures="$root/tests/ci-watch/fixtures"

fail() {
    printf 'ci-watch-transaction: %s\n' "$*" >&2
    exit 1
}

test_root=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-ci-watch-test.XXXXXX")
cleanup() {
    local status=$?
    trap - EXIT
    rm -rf -- "$test_root"
    exit "$status"
}
trap cleanup EXIT

sha=1111111111111111111111111111111111111111
tip_date=2026-08-24T12:00:00Z
# Two hours after the tip, so the trigger grace window has closed.
now=$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' 2026-08-24T14:00:00Z '+%s')

runs="$test_root/runs.json"
jobs="$test_root/jobs.json"
log="$test_root/failed.log"
calls="$test_root/gh-calls.txt"
notified="$test_root/notified.txt"

run_watch() {
    local state_dir="$1" at="${2:-$now}"
    env \
        FXNK_CI_WATCH_GH_BIN="$fixtures/fake-gh.sh" \
        FXNK_CI_WATCH_NOTIFIER_BIN="$fixtures/fake-notifier.sh" \
        FXNK_CI_WATCH_NOW="$at" \
        FXNK_TEST_GH_TIP="$sha" \
        FXNK_TEST_GH_TIP_DATE="$tip_date" \
        FXNK_TEST_GH_RUNS="$runs" \
        FXNK_TEST_GH_JOBS="$jobs" \
        FXNK_TEST_GH_LOG="$log" \
        FXNK_TEST_GH_CALLS="$calls" \
        FXNK_TEST_NOTIFY_FILE="$notified" \
        "$root/scripts/ci-watch.sh" --once --state-dir "$state_dir"
}

# Most scenarios assert silence, which is only meaningful once the daily
# heartbeat clock has already been started.
seed_quiet() {
    local state_dir="$1"
    mkdir -p "$state_dir/full-ci"
    jq -n --arg at "$(date -u -r "$now" '+%Y-%m-%dT%H:%M:%SZ')" \
        '{schema:1,updated_at:$at,stale_notified_at:null,last_message_at:$at,
          open:[]}' >"$state_dir/full-ci/pending.json"
}

write_run() {
    jq -n --arg sha "$sha" --arg status "$1" --arg conclusion "$2" \
        '[{databaseId:9001,headSha:$sha,status:$status,
           conclusion:(if $conclusion == "" then null else $conclusion end),
           createdAt:"2026-08-24T12:05:00Z",
           url:"https://github.com/possibilities/fx/actions/runs/9001"}]' >"$runs"
}

# --- a green verdict is recorded and stays quiet -----------------------------
state="$test_root/green"
seed_quiet "$state"
write_run completed success
: >"$notified"
run_watch "$state" >/dev/null
receipt="$state/full-ci/$sha.json"
[ -f "$receipt" ] || fail "green verdict was not recorded"
[ "$(stat -f '%Lp' "$receipt")" = 600 ] || fail "verdict receipt is not mode 0600"
jq -e '.status == "green" and .classification == "green" and .notified_at == null' \
    "$receipt" >/dev/null || fail "green verdict recorded the wrong proof"
jq -e '.open == []' "$state/full-ci/pending.json" >/dev/null \
    || fail "green verdict left an open obligation"
[ ! -s "$notified" ] || fail "green verdict notified the human"

# --- a real test failure escalates exactly once ------------------------------
state="$test_root/failed"
write_run completed failure
jq -n '{jobs:[{name:"E2E (ReleaseSafe, macos-aarch64, shard 1/4)",
               conclusion:"failure",
               steps:[{name:"Run deterministic E2E shard",conclusion:"failure"}]}]}' >"$jobs"
printf '(fail) tui: direct-write audit > classifies the real repository [1076.89ms]\n' >"$log"
: >"$notified"
: >"$calls"
run_watch "$state" >/dev/null
receipt="$state/full-ci/$sha.json"
jq -e '.status == "failed" and .classification == "real_failure" and
       .notified_at != null and (.failing_tests | length) == 1 and
       (.failing_jobs[0].failed_step == "Run deterministic E2E shard")' \
    "$receipt" >/dev/null || fail "real failure recorded the wrong proof"
jq -e '.open[0].kind == "real_failure" and .open[0].fx_sha == "'"$sha"'"' \
    "$state/full-ci/pending.json" >/dev/null \
    || fail "real failure left no obligation for the next cycle"
[ "$(wc -l <"$notified")" -eq 1 ] || fail "real failure did not notify exactly once"
grep -F 'Fx Maintenance' "$notified" >/dev/null || fail "notification lost its title"
grep -F 'fxnk.maintain' "$notified" >/dev/null || fail "notification lost its group"
grep -Fv -- '--failed' "$calls" | grep -F 'run rerun' >/dev/null \
    && fail "real failure was rerun instead of escalated"
run_watch "$state" >/dev/null
[ "$(wc -l <"$notified")" -eq 1 ] || fail "unchanged real failure notified twice"

# --- a setup failure is retried once, then escalated -------------------------
state="$test_root/infra"
seed_quiet "$state"
write_run completed failure
jq -n '{jobs:[{name:"E2E (ReleaseSafe, linux-x86_64, shard 2/4)",
               conclusion:"failure",
               steps:[{name:"Install E2E system dependencies",conclusion:"failure"}]}]}' >"$jobs"
: >"$log"
: >"$notified"
: >"$calls"
run_watch "$state" >/dev/null
receipt="$state/full-ci/$sha.json"
jq -e '.status == "pending" and .classification == "rerun" and .reruns == 1' \
    "$receipt" >/dev/null || fail "setup failure was not retried mechanically"
grep -F 'run rerun 9001' "$calls" >/dev/null || fail "no rerun was requested"
[ ! -s "$notified" ] || fail "first setup failure notified the human"
run_watch "$state" >/dev/null
jq -e '.status == "failed" and .classification == "infrastructure" and .reruns == 1' \
    "$receipt" >/dev/null || fail "repeated setup failure was not escalated"
[ "$(wc -l <"$notified")" -eq 1 ] || fail "repeated setup failure did not notify"

# --- a published tip with no run at all is a broken trigger ------------------
state="$test_root/absent"
printf '[]\n' >"$runs"
: >"$notified"
run_watch "$state" >/dev/null
jq -e '.status == "no_run" and .classification == "absent" and .notified_at != null' \
    "$state/full-ci/$sha.json" >/dev/null || fail "missing run was not escalated"
jq -e '.open[0].kind == "absent"' "$state/full-ci/pending.json" >/dev/null \
    || fail "missing run left no obligation"

# --- a tip pushed moments ago is simply waiting ------------------------------
state="$test_root/fresh"
seed_quiet "$state"
printf '[]\n' >"$runs"
: >"$notified"
tip_date_saved=$tip_date
tip_date=$(date -u -r $((now - 60)) '+%Y-%m-%dT%H:%M:%SZ')
run_watch "$state" >/dev/null
tip_date=$tip_date_saved
jq -e '.status == "pending" and .classification == "awaiting_start"' \
    "$state/full-ci/$sha.json" >/dev/null || fail "a just-pushed tip was escalated"
[ ! -s "$notified" ] || fail "a just-pushed tip notified the human"

# --- an unverified tip eventually becomes overdue ----------------------------
state="$test_root/overdue"
seed_quiet "$state"
write_run in_progress ""
: >"$notified"
run_watch "$state" >/dev/null
jq -e '.status == "pending" and .classification == "running"' \
    "$state/full-ci/$sha.json" >/dev/null || fail "a running suite was misclassified"
[ ! -s "$notified" ] || fail "a running suite notified the human"

run_watch "$state" $((now + 5 * 24 * 60 * 60)) >/dev/null
[ "$(wc -l <"$notified")" -eq 1 ] || fail "an overdue verdict did not reach the human"
grep -F 'pause Integration pushes' "$notified" >/dev/null \
    || fail "overdue notification does not say what to do"
jq -e '.open[0].kind == "overdue" and .stale_notified_at != null' \
    "$state/full-ci/pending.json" >/dev/null \
    || fail "overdue verdict left no obligation"

# --- a quiet watcher still proves it is alive once a day --------------------
state="$test_root/heartbeat"
write_run completed success
: >"$notified"
run_watch "$state" >/dev/null
[ "$(wc -l <"$notified")" -eq 1 ] || fail "a fresh watcher did not announce itself"
grep -F 'Full CI watch alive' "$notified" >/dev/null \
    || fail "the heartbeat does not say the watcher is alive"
run_watch "$state" >/dev/null
[ "$(wc -l <"$notified")" -eq 1 ] || fail "the heartbeat repeated within a day"
run_watch "$state" $((now + 25 * 60 * 60)) >/dev/null
[ "$(wc -l <"$notified")" -eq 2 ] || fail "the heartbeat did not repeat after a day"
jq -e '.last_message_at != null' "$state/full-ci/pending.json" >/dev/null \
    || fail "the heartbeat clock was not recorded"

printf 'ci watch verdict transaction validation passed.\n'
