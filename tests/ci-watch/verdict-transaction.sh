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
lock_stale_seconds=1800
# Two hours after the tip, so the trigger grace window has closed.
# GNU date first; BSD date rejects -d cleanly with nothing on stdout.
iso_of() {
    date -u -d "@$1" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -r "$1" '+%Y-%m-%dT%H:%M:%SZ'
}
now=$(date -u -d 2026-08-24T14:00:00Z '+%s' 2>/dev/null \
    || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' 2026-08-24T14:00:00Z '+%s')

runs="$test_root/runs.json"
jobs="$test_root/jobs.json"
log="$test_root/failed.log"
calls="$test_root/gh-calls.txt"
notified="$test_root/notified.txt"

run_watch() {
    local state_dir="$1" at="${2:-$now}"
    env \
        FXNK_TEST_GH_JOBS_FAIL="${jobs_fail:-0}" \
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
    jq -n --arg at "$(iso_of "$now")" \
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
[ "$(stat -c '%a' "$receipt" 2>/dev/null || stat -f '%Lp' "$receipt")" = 600 ] || fail "verdict receipt is not mode 0600"
jq -e '.status == "green" and .classification == "green" and .notified_at == null' \
    "$receipt" >/dev/null || fail "green verdict recorded the wrong proof"
jq -e '.open == [] and .overdue == false and .unverified_since == null' \
    "$state/full-ci/pending.json" >/dev/null \
    || fail "green verdict left an open obligation"
[ ! -s "$notified" ] || fail "green verdict notified the human"

# --- a real test failure is recorded for the cycle, not paged -----------------
state="$test_root/failed"
seed_quiet "$state"
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
       .notified_at == null and (.failing_tests | length) == 1 and
       (.failing_jobs[0].failed_step == "Run deterministic E2E shard")' \
    "$receipt" >/dev/null || fail "real failure recorded the wrong proof"
jq -e '.open[0].kind == "real_failure" and .open[0].fx_sha == "'"$sha"'"' \
    "$state/full-ci/pending.json" >/dev/null \
    || fail "real failure left no obligation for the next cycle"
[ ! -s "$notified" ] || fail "real failure paged the human; the verdict belongs to the ledger"
grep -Fv -- '--failed' "$calls" | grep -F 'run rerun' >/dev/null \
    && fail "real failure was rerun instead of recorded"
run_watch "$state" >/dev/null
[ ! -s "$notified" ] || fail "unchanged real failure paged the human"

# --- a setup failure is retried once, then recorded --------------------------
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
    "$receipt" >/dev/null || fail "repeated setup failure was not recorded as infrastructure"
[ ! -s "$notified" ] || fail "repeated setup failure paged the human"

# --- a published tip with no run at all is a broken trigger ------------------
state="$test_root/absent"
printf '[]\n' >"$runs"
: >"$notified"
run_watch "$state" >/dev/null
jq -e '.status == "no_run" and .classification == "absent" and .notified_at != null' \
    "$state/full-ci/$sha.json" >/dev/null || fail "missing run was not escalated"
[ "$(wc -l <"$notified")" -eq 1 ] || fail "missing run did not notify exactly once"
grep -F 'Fx Maintenance' "$notified" >/dev/null || fail "notification lost its title"
grep -F 'fxnk.maintain' "$notified" >/dev/null || fail "notification lost its group"
jq -e '.open[0].kind == "absent"' "$state/full-ci/pending.json" >/dev/null \
    || fail "missing run left no obligation"

# --- a tip pushed moments ago is simply waiting ------------------------------
state="$test_root/fresh"
seed_quiet "$state"
printf '[]\n' >"$runs"
: >"$notified"
tip_date_saved=$tip_date
tip_date=$(iso_of $((now - 60)))
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
jq -e '.overdue == true and .stale_notified_at != null' \
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

# --- an aggregate job must not mask an infrastructure failure ---------------
# full-ci.yml's "Full suite" jobs restate the matrix result, so they fail
# alongside anything. Counting them would make every failure look like a test
# failure and leave the retry path dead.
state="$test_root/aggregate"
seed_quiet "$state"
write_run completed failure
jq -n '{jobs:[
    {name:"E2E (ReleaseSafe, linux-x86_64, shard 2/4)",conclusion:"failure",
     steps:[{name:"Install E2E system dependencies",conclusion:"failure"}]},
    {name:"Full suite (linux-x86_64)",conclusion:"failure",
     steps:[{name:"Verify native and E2E matrices",conclusion:"failure"}]}]}' >"$jobs"
: >"$log"
: >"$notified"
: >"$calls"
run_watch "$state" >/dev/null
jq -e '.status == "pending" and .classification == "rerun" and .reruns == 1' \
    "$state/full-ci/$sha.json" >/dev/null \
    || fail "an aggregate job masked an infrastructure failure"
[ ! -s "$notified" ] || fail "a retryable failure escalated immediately"

# --- named failing tests outrank every step name ----------------------------
state="$test_root/named"
seed_quiet "$state"
printf '(fail) some real test > does a thing [10ms]\n' >"$log"
run_watch "$state" >/dev/null
jq -e '.status == "failed" and .classification == "real_failure" and
       (.failing_jobs | length) == 2' \
    "$state/full-ci/$sha.json" >/dev/null \
    || fail "named failing tests were not decisive"

# --- unreadable job evidence is never reported as a red build ---------------
state="$test_root/blind"
seed_quiet "$state"
: >"$log"
: >"$notified"
jobs_fail=1
run_watch "$state" >/dev/null
jobs_fail=0
jq -e '.status == "failed" and .classification == "unclassified" and
       (.detail | test("jobs could not be read"))' \
    "$state/full-ci/$sha.json" >/dev/null \
    || fail "an unreadable jobs list was reported as a test failure"
[ "$(wc -l <"$notified")" -eq 1 ] || fail "an unclassified failure did not escalate"

# --- a failure with no recognizable cause escalates, never reruns -----------
state="$test_root/unknown"
seed_quiet "$state"
jq -n '{jobs:[{name:"Native checks (ReleaseSafe, macos-aarch64)",conclusion:"failure",
               steps:[{name:"Run unit tests",conclusion:"failure"}]}]}' >"$jobs"
: >"$log"
: >"$calls"
run_watch "$state" >/dev/null
jq -e '.status == "failed" and .classification == "unclassified"' \
    "$state/full-ci/$sha.json" >/dev/null \
    || fail "an unrecognized failure was not escalated"
if grep -F 'run rerun' "$calls" >/dev/null; then
    fail "an unrecognized failure spent a rerun"
fi

# --- conclusions that are not verdicts are not red builds -------------------
for outcome in startup_failure action_required skipped neutral stale; do
    state="$test_root/outcome-$outcome"
    seed_quiet "$state"
    write_run completed "$outcome"
    : >"$notified"
    run_watch "$state" >/dev/null
    jq -e --arg outcome "$outcome" \
        '.status == "no_verdict" and .classification == $outcome' \
        "$state/full-ci/$sha.json" >/dev/null \
        || fail "$outcome was misread as a verdict"
    [ ! -s "$notified" ] || fail "$outcome paged the human as a red build"
    jq -e --arg sha "$sha" '[.open[].fx_sha] | index($sha) != null' \
        "$state/full-ci/pending.json" >/dev/null \
        || fail "$outcome left the tip unverified with nothing on the books"
done

# --- a corrupt state file costs one poll, not every poll --------------------
state="$test_root/corrupt"
seed_quiet "$state"
write_run completed success
printf '{"schema":1,"fx_sha":' >"$state/full-ci/$sha.json"
printf 'not json at all' >"$state/full-ci/pending.json"
run_watch "$state" >/dev/null 2>&1
jq -e '.status == "green"' "$state/full-ci/$sha.json" >/dev/null \
    || fail "a corrupt receipt wedged the watcher"
jq -e '.schema == 1' "$state/full-ci/pending.json" >/dev/null \
    || fail "a corrupt pending file wedged the watcher"

# --- an undelivered notification is never recorded as delivered -------------
state="$test_root/undeliverable"
seed_quiet "$state"
write_run completed failure
jq -n '{jobs:[{name:"E2E (ReleaseSafe, macos-aarch64, shard 1/4)",conclusion:"failure",
               steps:[{name:"Run deterministic E2E shard",conclusion:"failure"}]}]}' >"$jobs"
printf '(fail) a real test > fails [1ms]\n' >"$log"
env FXNK_CI_WATCH_GH_BIN="$fixtures/fake-gh.sh" \
    FXNK_CI_WATCH_NOTIFIER_BIN="" \
    FXNK_CI_WATCH_NOW="$now" \
    FXNK_TEST_GH_TIP="$sha" FXNK_TEST_GH_TIP_DATE="$tip_date" \
    FXNK_TEST_GH_RUNS="$runs" FXNK_TEST_GH_JOBS="$jobs" FXNK_TEST_GH_LOG="$log" \
    FXNK_TEST_GH_CALLS="$calls" \
    "$root/scripts/ci-watch.sh" --once --state-dir "$state" >/dev/null 2>&1
jq -e '.status == "failed" and .notified_at == null' \
    "$state/full-ci/$sha.json" >/dev/null \
    || fail "an undelivered notification was recorded as delivered"

# --- an obligation survives a newer, greener tip ----------------------------
state="$test_root/carry"
seed_quiet "$state"
failed_sha=$sha
write_run completed failure
run_watch "$state" >/dev/null
jq -e --arg sha "$failed_sha" '[.open[].fx_sha] | index($sha) != null' \
    "$state/full-ci/pending.json" >/dev/null || fail "the failure was not booked"
sha=2222222222222222222222222222222222222222
write_run completed success
run_watch "$state" >/dev/null
jq -e --arg sha "$failed_sha" '[.open[].fx_sha] | index($sha) != null' \
    "$state/full-ci/pending.json" >/dev/null \
    || fail "a newer green tip erased an unresolved obligation"
sha=$failed_sha

# --- the overdue clock survives a stream of new tips ------------------------
# The failure this guards: anchoring to the current SHA's first sighting means
# every push resets the clock, so a never-green branch is never escalated.
state="$test_root/never-green"
seed_quiet "$state"
: >"$notified"
day=0
while [ "$day" -lt 6 ]; do
    sha=$(printf '3%039d' "$day")
    write_run completed cancelled
    FXNK_TEST_GH_RERUN_FAILS=1 \
        run_watch "$state" $((now + day * 24 * 60 * 60)) >/dev/null
    day=$((day + 1))
done
sha=1111111111111111111111111111111111111111
grep -F 'has not been green' "$notified" >/dev/null \
    || fail "a branch that was never green was never escalated"
jq -e '.overdue == true and .unverified_since != null' \
    "$state/full-ci/pending.json" >/dev/null \
    || fail "the overdue clock was not carried across tips"

# --- overlapping polls never double-spend the rerun budget ------------------
state="$test_root/locked"
seed_quiet "$state"
write_run completed success
mkdir -p "$state/full-ci/.lock"
: >"$calls"
run_watch "$state" | grep -Fx 'CI-WATCH busy' >/dev/null \
    || fail "a concurrent poll did not defer to the lock holder"
[ ! -f "$state/full-ci/$sha.json" ] || fail "a deferred poll wrote a receipt"
rmdir "$state/full-ci/.lock"
run_watch "$state" >/dev/null
jq -e '.status == "green"' "$state/full-ci/$sha.json" >/dev/null \
    || fail "the watcher did not resume once the lock cleared"
# A lock left behind by a killed poll must not wedge the watcher forever.
rm -f "$state/full-ci/$sha.json"
mkdir -p "$state/full-ci/.lock"
touch -d "$(iso_of $((now - 2 * lock_stale_seconds)))" \
    "$state/full-ci/.lock"
run_watch "$state" >/dev/null 2>&1
jq -e '.status == "green"' "$state/full-ci/$sha.json" >/dev/null \
    || fail "a stale lock was not broken"

# --- a superseded obligation is marked, and only --close retires it ----------
state="$test_root/superseded"
seed_quiet "$state"
old_sha=2222222222222222222222222222222222222222
jq -n --arg sha "$old_sha" --arg at "$(iso_of $((now - 3600)))" \
    '{schema:1,fx_sha:$sha,workflow:"full-ci.yml",run:{id:8001,url:"https://example.invalid/8001"},
      status:"failed",classification:"real_failure",detail:"one deterministic failure",
      conclusion:"failure",failing_jobs:[],failing_tests:["(fail) old"],reruns:0,
      first_seen_at:$at,recorded_at:$at,notified_at:null,notified_classification:null}' \
    >"$state/full-ci/$old_sha.json"
write_run completed failure
jq -n '{jobs:[{name:"Full suite (1/4)",conclusion:"failure",
               steps:[{name:"Run deterministic E2E shard",conclusion:"failure"}]}]}' >"$jobs"
printf '(fail) tui: startup > current [1.00ms]\n' >"$log"
: >"$notified"
run_watch "$state" >/dev/null
jq -e '(.open | length) == 2 and
       (.open[] | select(.fx_sha == "'"$old_sha"'") | .superseded) == true and
       (.open[] | select(.fx_sha == "'"$sha"'") | .superseded) == false' \
    "$state/full-ci/pending.json" >/dev/null \
    || fail "a superseded obligation was not marked while the tip is red"
set +e
"$root/scripts/ci-watch.sh" --close "$old_sha" --state-dir "$state" >/dev/null 2>&1 \
    && fail "an obligation was closed without a reason"
"$root/scripts/ci-watch.sh" --close 3333333333333333333333333333333333333333 --reason x --state-dir "$state" >/dev/null 2>&1 \
    && fail "an unknown obligation was closed"
set -e
FXNK_CI_WATCH_GH_BIN="$fixtures/fake-gh.sh" FXNK_CI_WATCH_NOW="$now" \
    "$root/scripts/ci-watch.sh" --close "$old_sha" --reason "repaired in the test cycle" --state-dir "$state" \
    | grep -F "CI-WATCH closed ${old_sha:0:12}" >/dev/null || fail "--close did not report the closure"
jq -e '.closed_reason == "repaired in the test cycle" and .closed_at != null and .status == "failed"' \
    "$state/full-ci/$old_sha.json" >/dev/null || fail "--close did not record the judgment on the receipt"
jq -e '(.open | length) == 1 and .open[0].fx_sha == "'"$sha"'"' \
    "$state/full-ci/pending.json" >/dev/null || fail "--close left the obligation open"
run_watch "$state" >/dev/null
jq -e '(.open | length) == 1 and .open[0].fx_sha == "'"$sha"'"' \
    "$state/full-ci/pending.json" >/dev/null || fail "a poll reopened a closed obligation"

printf 'ci watch verdict transaction validation passed.\n'
