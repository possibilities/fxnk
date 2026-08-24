#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)

fail() {
    printf 'local-gate-transaction: %s\n' "$*" >&2
    exit 1
}

known=$(
    python3 "$root/scripts/classify-quarantine.py" \
        --manifest "$root/gate/macos-arm64-quarantine.json" \
        --file tests/e2e/tui-subagent-manager.test.ts \
        --output "$root/tests/local-gate/fixtures/known-assertion.log" \
        --exit-code 1
)
printf '%s\n' "$known" | jq -e \
    '.status == "quarantined" and .failure_count == 1 and
     .signatures == ["ctrl-x-child-row-race"]' >/dev/null \
    || fail "known assertion was not classified"

set +e
unknown_output=$(
    python3 "$root/scripts/classify-quarantine.py" \
        --manifest "$root/gate/macos-arm64-quarantine.json" \
        --file tests/e2e/tui-subagent-manager.test.ts \
        --output "$root/tests/local-gate/fixtures/unknown-mixed.log" \
        --exit-code 1 2>&1
)
unknown_status=$?
set -e
[ "$unknown_status" -ne 0 ] || fail "unknown mixed assertion was quarantined"
printf '%s\n' "$unknown_output" | grep -F 'undeclared assertion' >/dev/null \
    || fail "unknown assertion refusal was not explained"

set +e
trailing_output=$(
    python3 "$root/scripts/classify-quarantine.py" \
        --manifest "$root/gate/macos-arm64-quarantine.json" \
        --file tests/e2e/tui-subagent-manager.test.ts \
        --output "$root/tests/local-gate/fixtures/trailing-error.log" \
        --exit-code 1 2>&1
)
trailing_status=$?
set -e
[ "$trailing_status" -ne 0 ] || fail "trailing TypeError was quarantined"
printf '%s\n' "$trailing_output" | grep -F \
    'undeclared diagnostic outside a failure block' >/dev/null \
    || fail "trailing diagnostic refusal was not explained"

set +e
crash_output=$(
    python3 "$root/scripts/classify-quarantine.py" \
        --manifest "$root/gate/macos-arm64-quarantine.json" \
        --file tests/e2e/tui-subagent-manager.test.ts \
        --output "$root/tests/local-gate/fixtures/trailing-crash.log" \
        --exit-code 139 2>&1
)
crash_status=$?
set -e
[ "$crash_status" -ne 0 ] || fail "trailing process crash was quarantined"
printf '%s\n' "$crash_output" | grep -F \
    'undeclared diagnostic outside a failure block' >/dev/null \
    || fail "trailing process crash refusal was not explained"

test_root=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-local-gate-test.XXXXXX")
cleanup_test() {
    local status=$?
    trap - EXIT
    find "$test_root" -depth -delete
    exit "$status"
}
trap cleanup_test EXIT

fx_worktree="$test_root/fx"
upstream_repo="$test_root/upstream.git"
fork_repo="$test_root/fork.git"
state_dir="$test_root/state"
manifest="$test_root/quarantine.json"
mkdir -p "$fx_worktree/src" "$fx_worktree/scripts" "$fx_worktree/tests/e2e" \
    "$fx_worktree/tests/e2e/render-lab" "$fx_worktree/tests/fxnk"
printf 'fixture\n' >"$fx_worktree/tests/e2e/render-lab/audit-direct-writes.ts"
printf 'pub fn main() void {}\n' >"$fx_worktree/tests/fxnk/runner.zig"
printf 'test {}\n' >"$fx_worktree/src/main.zig"
printf 'pub fn build() void {}\n' >"$fx_worktree/build.zig"
printf 'fixture\n' >"$fx_worktree/tests/e2e/quarantined.test.ts"
printf 'zig-out/\ntests/e2e/node_modules/\n' >"$fx_worktree/.gitignore"
printf '#!/bin/bash\nexit 0\n' >"$fx_worktree/scripts/check-public-surface.sh"
chmod +x "$fx_worktree/scripts/check-public-surface.sh"
git -C "$fx_worktree" init --quiet -b main
git -C "$fx_worktree" config user.name fxnk-test
git -C "$fx_worktree" config user.email fxnk@example.invalid
git -C "$fx_worktree" add .
git -C "$fx_worktree" commit --quiet -m fixture
sha=$(git -C "$fx_worktree" rev-parse HEAD)
blob=$(git -C "$fx_worktree" hash-object tests/e2e/quarantined.test.ts)

git clone --quiet --bare "$fx_worktree" "$upstream_repo"
git clone --quiet --bare "$fx_worktree" "$fork_repo"
git --git-dir="$fork_repo" update-ref refs/heads/integration "$sha"
git -C "$fx_worktree" remote add origin "$upstream_repo"
git -C "$fx_worktree" remote add fork "$fork_repo"
git -C "$fx_worktree" fetch --quiet origin main

jq -n --arg blob "$blob" \
    '{schema:1,platform:{os:"Darwin",arch:"arm64"},entries:[{
      file:"tests/e2e/quarantined.test.ts",test_name_pattern:"fixture",
      required_blobs:[{path:"tests/e2e/quarantined.test.ts",oid:$blob}],
      allowed_signatures:[{id:"fixture",kind:"runtime",regex:"fixture"}]
    }]}' >"$manifest"

gate_env=(
    FXNK_LOCAL_GATE_TESTING=1
    FXNK_LOCAL_GATE_UNAME_S=Darwin
    FXNK_LOCAL_GATE_UNAME_M=arm64
    FXNK_LOCAL_GATE_MANIFEST="$manifest"
    FXNK_LOCAL_GATE_ZIG_BIN="$root/tests/local-gate/fixtures/fake-zig.sh"
    FXNK_LOCAL_GATE_BUN_BIN="$root/tests/local-gate/fixtures/fake-bun.sh"
    FXNK_TEST_FAKE_FX="$root/tests/local-gate/fixtures/fake-fx.sh"
    FXNK_TEST_FAKE_BUN_QUARANTINE=1
    FXNK_STATE_DIR="$state_dir"
)
env "${gate_env[@]}" "$root/scripts/local-gate.sh" \
    --worktree "$fx_worktree" --record >/dev/null
receipt="$state_dir/local-gates/$sha.json"
[ -f "$receipt" ] || fail "recorded gate did not write the exact-SHA receipt"
[ "$(stat -f '%Lp' "$receipt")" = 600 ] \
    || fail "recorded gate receipt is not mode 0600"
jq -e --arg sha "$sha" \
    '.authority == "test" and .fx_sha == $sha and
     .outcomes.direct_write_audit == "pass" and
     .outcomes.quarantine[0].status == "quarantined" and
     .outcomes.quarantine[0].failure_count == 1 and
     .outcomes.quarantine[0].signatures == ["fixture"] and
     (.outcomes.quarantine[0].blob | test("^[0-9a-f]{40}$"))' \
    "$receipt" >/dev/null || fail "recorded gate receipt has the wrong proof"

set +e
audit_output=$(
    FXNK_TEST_FAKE_BUN_AUDIT_FAIL=1 \
    env "${gate_env[@]}" "$root/scripts/local-gate.sh" \
        --worktree "$fx_worktree" 2>&1
)
audit_status=$?
set -e
[ "$audit_status" -ne 0 ] || fail "unclassified direct write did not block the gate"
printf '%s\n' "$audit_output" | grep -F 'direct-write-audit exited' >/dev/null \
    || fail "direct-write audit refusal was not explained"

before=$(shasum -a 256 "$receipt" | awk '{print $1}')
count_file="$test_root/mv-count"
set +e
failure_output=$(
    PATH="$root/tests/fixtures/fail-bin:$PATH" \
    FXNK_TEST_MV_COUNT_FILE="$count_file" \
    FXNK_TEST_MV_FAIL_AT=1 \
    env "${gate_env[@]}" "$root/scripts/local-gate.sh" \
        --worktree "$fx_worktree" --record 2>&1
)
failure_status=$?
set -e
[ "$failure_status" -ne 0 ] || fail "injected receipt move did not fail"
printf '%s\n' "$failure_output" | grep -F \
    'could not atomically record the local gate receipt' >/dev/null \
    || fail "receipt move failure was not explained"
after=$(shasum -a 256 "$receipt" | awk '{print $1}')
[ "$before" = "$after" ] || fail "failed receipt replacement changed prior proof"

FXNK_LOCAL_GATE_TESTING=1 FXNK_LOCAL_GATE_MANIFEST="$manifest" FXNK_STATE_DIR="$state_dir" \
    "$root/scripts/ship-gate.sh" \
    --worktree "$fx_worktree" --branch integration --sha "$sha" \
    | grep -Fx "SHIP $sha" >/dev/null \
    || fail "ship gate rejected the exact local proof"

invalid_receipt="$test_root/invalid-receipt.json"
jq '.contract_digest = "0000000000000000000000000000000000000000000000000000000000000000"' \
    "$receipt" >"$invalid_receipt"
chmod 0600 "$invalid_receipt"
mv "$invalid_receipt" "$receipt"
set +e
invalid_output=$(
    FXNK_LOCAL_GATE_TESTING=1 FXNK_LOCAL_GATE_MANIFEST="$manifest" FXNK_STATE_DIR="$state_dir" \
        "$root/scripts/ship-gate.sh" \
        --worktree "$fx_worktree" --branch integration --sha "$sha" 2>&1
)
invalid_status=$?
set -e
[ "$invalid_status" -ne 0 ] || fail "ship gate accepted a stale contract digest"
printf '%s\n' "$invalid_output" | grep -F \
    'does not prove the current gate contract' >/dev/null \
    || fail "stale contract refusal was not explained"

printf 'local gate receipt transaction validation passed.\n'
