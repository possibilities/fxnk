#!/bin/bash
# Prove scripts/replay-carries.sh on a throwaway repository: the plan follows
# the graph, a replay merges in dependency order and is idempotent, a textual
# conflict stops with exit 2, a merge completed only through a recorded rerere
# resolution stops with exit 3 and prints what the resolution drops, continue
# commits it, and compose merges the graph's sinks into a candidate branch.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
replay="$root/scripts/replay-carries.sh"

fail() {
    printf 'replay-carries-test: %s\n' "$*" >&2
    exit 1
}

test_root=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-replay-test.XXXXXX")
cleanup() {
    local status=$?
    trap - EXIT
    rm -rf -- "$test_root"
    exit "$status"
}
trap cleanup EXIT

repo="$test_root/fx"
wt="$test_root/worktrees"
graph="$test_root/graph.tsv"
git init -q -b main "$repo"
g() { git -C "$repo" -c user.name=test -c user.email=test@example.com "$@"; }
g config rerere.enabled true
g config user.name test
g config user.email test@example.com
printf 'base\n' >"$repo/base.txt"
g add base.txt && g commit -q -m "base"
g checkout -q -b carry/hosted-full-ci
mkdir -p "$repo/.github/workflows" && printf 'hosted\n' >"$repo/.github/workflows/full-ci.yml"
g add .github && g commit -q -m "hosted"
g checkout -q -b carry/a && printf 'a\n' >"$repo/a.txt" && g add a.txt && g commit -q -m "a"
g checkout -q -b carry/b && printf 'b\n' >"$repo/b.txt" && g add b.txt && g commit -q -m "b"
g checkout -q carry/hosted-full-ci && g checkout -q -b carry/c
printf 'c edit\n' >"$repo/base.txt" && g commit -q -am "c edits base"
g checkout -q carry/hosted-full-ci && g checkout -q -b carry/twin
g checkout -q main
printf 'upstream edit\n' >"$repo/base.txt" && g commit -q -am "upstream moves base"
upstream=$(g rev-parse HEAD)
# The repository stays on main: a branch checked out here cannot get a worktree.
printf 'hosted-full-ci\tupstream\ntwin\t=hosted-full-ci\na\t-\nb\ta\nc\t-\n' >"$graph"

plan=$("$replay" plan --graph "$graph")
[ "$(printf '%s\n' "$plan" | sed -n '1p')" = "hosted-full-ci	" ] || fail "plan does not start at the base: $plan"
printf '%s\n' "$plan" | grep -Fx 'b	hosted-full-ci,a' >/dev/null || fail "plan lost b's dependency on a"
printf '%s\n' "$plan" | grep -Fx 'compose	b,c' >/dev/null || fail "plan names the wrong sinks: $plan"

# A conflict stops the replay with exit 2 and names the file.
set +e
output=$("$replay" replay --checkout "$repo" --root "$wt" --upstream "$upstream" --graph "$graph" --trailer 'Test-Trailer: yes' 2>&1)
status=$?
set -e
[ "$status" -eq 2 ] || fail "conflict did not stop the replay (exit $status): $output"
printf '%s\n' "$output" | grep -F 'CONFLICT c' | grep -F 'base.txt' >/dev/null || fail "conflict did not name base.txt: $output"
printf '%s\n' "$output" | grep -F 'merged a' >/dev/null || fail "a was not merged before the conflict: $output"
printf '%s\n' "$output" | grep -F 'merged b' >/dev/null || fail "b was not merged before the conflict: $output"
git -C "$wt/b" merge-base --is-ancestor "$(git -C "$wt/a" rev-parse HEAD)" HEAD || fail "b does not contain a"
git -C "$wt/a" merge-base --is-ancestor "$upstream" HEAD || fail "a does not contain the upstream target"
git -C "$wt/a" log -1 --format=%B | grep -Fx 'Test-Trailer: yes' >/dev/null || fail "merge message lacks the trailer"
[ "$(git -C "$wt/twin" rev-parse HEAD)" = "$(git -C "$wt/hosted-full-ci" rev-parse HEAD)" ] || fail "twin did not fast-forward to the base"

# Resolve by hand, commit, and record the resolution.
before_resolution=$(git -C "$wt/c" rev-parse HEAD)
printf 'resolved\n' >"$wt/c/base.txt"
git -C "$wt/c" add base.txt
git -C "$wt/c" -c user.name=test -c user.email=test@example.com commit -q --no-edit
output=$("$replay" replay --checkout "$repo" --root "$wt" --upstream "$upstream" --graph "$graph" 2>&1) \
    || fail "replay after the resolution failed: $output"
printf '%s\n' "$output" | grep -F 'REPLAY COMPLETE' >/dev/null || fail "replay did not complete: $output"
output=$("$replay" replay --checkout "$repo" --root "$wt" --upstream "$upstream" --graph "$graph" 2>&1)
[ "$(printf '%s\n' "$output" | grep -c '^merged')" -eq 0 ] || fail "a rerun merged again: $output"

# The same conflict again is completed only by the recorded resolution: the
# replay stops with exit 3, shows what the resolution drops, and continue
# commits it.
git -C "$wt/c" reset -q --hard "$before_resolution"
set +e
output=$("$replay" replay --checkout "$repo" --root "$wt" --upstream "$upstream" --graph "$graph" 2>&1)
status=$?
set -e
[ "$status" -eq 3 ] || fail "a recorded resolution did not stop for review (exit $status): $output"
printf '%s\n' "$output" | grep -F 'RECORDED c' >/dev/null || fail "recorded resolution was not announced: $output"
printf '%s\n' "$output" | grep -F 'REVIEW base.txt' >/dev/null || fail "review did not name base.txt: $output"
printf '%s\n' "$output" | grep -F 'merged-only: upstream edit' >/dev/null || fail "review did not show the dropped upstream line: $output"
[ -f "$(git -C "$wt/c" rev-parse --git-path MERGE_HEAD)" ] || fail "the recorded merge was committed without review"
output=$("$replay" continue --checkout "$repo" --root "$wt" --upstream "$upstream" --graph "$graph" 2>&1) \
    || fail "continue failed: $output"
printf '%s\n' "$output" | grep -F 'committed c' >/dev/null || fail "continue did not commit c: $output"
[ ! -f "$(git -C "$wt/c" rev-parse --git-path MERGE_HEAD)" ] || fail "continue left the merge open"
[ "$(cat "$wt/c/base.txt")" = resolved ] || fail "the recorded resolution was not applied"

# Compose merges the sinks onto the base and contains every carry.
output=$("$replay" compose --checkout "$repo" --root "$wt" --branch candidate/test --graph "$graph" 2>&1) \
    || fail "compose failed: $output"
candidate=$(printf '%s\n' "$output" | sed -n 's/^COMPOSED //p')
[ -n "$candidate" ] || fail "compose printed no candidate: $output"
for carry in hosted-full-ci a b c twin; do
    git -C "$wt/candidate" merge-base --is-ancestor "$(git -C "$wt/$carry" rev-parse HEAD)" "$candidate" \
        || fail "candidate does not contain carry/$carry"
done
[ "$(git -C "$wt/candidate" rev-parse --abbrev-ref HEAD)" = candidate/test ] || fail "candidate is not on its branch"
git -C "$wt/candidate" log -1 --format=%s | grep -F 'Compose carry/c into Integration' >/dev/null \
    || fail "compose subject is wrong"

# A cyclic graph is refused before any merge.
printf 'hosted-full-ci\tupstream\nx\ty\ny\tx\n' >"$test_root/cycle.tsv"
set +e
output=$("$replay" plan --graph "$test_root/cycle.tsv" 2>&1)
status=$?
set -e
[ "$status" -ne 0 ] || fail "a cyclic graph was accepted"
printf '%s\n' "$output" | grep -F 'cycle' >/dev/null || fail "the cycle was not explained: $output"

printf 'replay-carries validation passed.\n'
