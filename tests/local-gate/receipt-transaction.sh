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
        --file tests/e2e/tui-render-replay.test.ts \
        --output "$root/tests/local-gate/fixtures/known-timeout.log" \
        --exit-code 1
)
printf '%s\n' "$known" | jq -e \
    '.status == "quarantined" and .failure_count == 1 and
     .signatures == ["tmux-session-exit-timeout"]' >/dev/null \
    || fail "known runtime timeout was not classified"

# The quarantine carries no assertion-shaped signature. An assertion that
# fails on this surface is read as a defect and blocks, which is what let the
# Ctrl-X encoding bug hide behind a tolerated signature until it was fixed.
set +e
assertion_output=$(
    python3 "$root/scripts/classify-quarantine.py" \
        --manifest "$root/gate/macos-arm64-quarantine.json" \
        --file tests/e2e/tui-render-replay.test.ts \
        --output "$root/tests/local-gate/fixtures/known-assertion.log" \
        --exit-code 1 2>&1
)
assertion_status=$?
set -e
[ "$assertion_status" -ne 0 ] || fail "assertion failure was quarantined"
printf '%s\n' "$assertion_output" | grep -F 'undeclared failure signature' \
    >/dev/null || fail "assertion refusal was not explained"

set +e
unknown_output=$(
    python3 "$root/scripts/classify-quarantine.py" \
        --manifest "$root/gate/macos-arm64-quarantine.json" \
        --file tests/e2e/tui-render-replay.test.ts \
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
        --file tests/e2e/tui-render-replay.test.ts \
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
        --file tests/e2e/tui-render-replay.test.ts \
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
mkdir -p "$fx_worktree/.github/workflows" "$fx_worktree/src" \
    "$fx_worktree/scripts" "$fx_worktree/tests/e2e" \
    "$fx_worktree/tests/e2e/render-lab" "$fx_worktree/tests/fxnk"
printf 'name: Full CI\non:\n  push:\n    branches-ignore:\n      - main\n' \
    >"$fx_worktree/.github/workflows/full-ci.yml"
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
blob=$(git -C "$fx_worktree" hash-object tests/e2e/quarantined.test.ts)

git clone --quiet --bare "$fx_worktree" "$upstream_repo"
git -C "$fx_worktree" checkout --quiet -b carry/hosted-full-ci
printf 'name: Full CI\non:\n  workflow_dispatch:\n  push:\n    branches:\n      - integration\n' \
    >"$fx_worktree/.github/workflows/full-ci.yml"
git -C "$fx_worktree" add .github/workflows/full-ci.yml
git -C "$fx_worktree" commit --quiet -m 'restrict hosted full CI'
git -C "$fx_worktree" checkout --quiet -b integration
printf 'candidate\n' >"$fx_worktree/candidate.txt"
git -C "$fx_worktree" add candidate.txt
git -C "$fx_worktree" commit --quiet -m candidate
sha=$(git -C "$fx_worktree" rev-parse HEAD)
git clone --quiet --bare "$fx_worktree" "$fork_repo"
git --git-dir="$fork_repo" update-ref refs/heads/integration "$sha"
git -C "$fx_worktree" remote add origin "$upstream_repo"
git -C "$fx_worktree" remote add fork "$fork_repo"
git -C "$fx_worktree" fetch --quiet origin main
pinned_upstream_sha=$(git -C "$fx_worktree" rev-parse refs/remotes/origin/main)
future_upstream_sha=$(
    GIT_AUTHOR_NAME=fxnk-test \
    GIT_AUTHOR_EMAIL=fxnk@example.invalid \
    GIT_COMMITTER_NAME=fxnk-test \
    GIT_COMMITTER_EMAIL=fxnk@example.invalid \
    git --git-dir="$upstream_repo" commit-tree \
        "$(git --git-dir="$upstream_repo" rev-parse 'main^{tree}')" \
        -p "$pinned_upstream_sha" <<'EOF'
future upstream
EOF
)
git --git-dir="$upstream_repo" update-ref refs/heads/main "$future_upstream_sha"
git -C "$fx_worktree" fetch --quiet origin main

jq -n --arg blob "$blob" \
    '{schema:1,platform:{os:"Darwin",arch:"arm64"},entries:[{
      file:"tests/e2e/quarantined.test.ts",test_name_pattern:"fixture",
      required_blobs:[{path:"tests/e2e/quarantined.test.ts",oid:$blob}],
      allowed_signatures:[{id:"fixture",kind:"runtime",regex:"fixture"}]
    }]}' >"$manifest"

gate_env=(
    MAINTAIN_UPSTREAM_SHA="$pinned_upstream_sha"
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

set +e
missing_record_pin_output=$(
    FXNK_LOCAL_GATE_TESTING=1 \
    FXNK_LOCAL_GATE_UNAME_S=Darwin \
    FXNK_LOCAL_GATE_UNAME_M=arm64 \
    FXNK_LOCAL_GATE_MANIFEST="$manifest" \
    FXNK_LOCAL_GATE_ZIG_BIN="$root/tests/local-gate/fixtures/fake-zig.sh" \
    FXNK_LOCAL_GATE_BUN_BIN="$root/tests/local-gate/fixtures/fake-bun.sh" \
    FXNK_TEST_FAKE_FX="$root/tests/local-gate/fixtures/fake-fx.sh" \
    FXNK_TEST_FAKE_BUN_QUARANTINE=1 \
    FXNK_STATE_DIR="$state_dir" \
    "$root/scripts/local-gate.sh" --worktree "$fx_worktree" --record 2>&1
)
missing_record_pin_status=$?
set -e
[ "$missing_record_pin_status" -ne 0 ] \
    || fail "recorded gate accepted no pinned upstream target"
printf '%s\n' "$missing_record_pin_output" | grep -F \
    'MAINTAIN_UPSTREAM_SHA is required with --record' >/dev/null \
    || fail "recorded gate did not explain its missing upstream pin"

env "${gate_env[@]}" "$root/scripts/local-gate.sh" \
    --worktree "$fx_worktree" --record >/dev/null
receipt="$state_dir/local-gates/$sha.json"
[ -f "$receipt" ] || fail "recorded gate did not write the exact-SHA receipt"
[ "$(stat -f '%Lp' "$receipt")" = 600 ] \
    || fail "recorded gate receipt is not mode 0600"
jq -e --arg sha "$sha" --arg upstream_sha "$pinned_upstream_sha" \
    '.authority == "test" and .fx_sha == $sha and
     .upstream.sha == $upstream_sha and
     .outcomes.hosted_ci_composition == "pass" and
     .outcomes.direct_write_audit == "pass" and
     .outcomes.fresh_binary == "pass" and
     .outcomes.quarantine[0].status == "quarantined" and
     .outcomes.quarantine[0].failure_count == 1 and
     .outcomes.quarantine[0].signatures == ["fixture"] and
     (.outcomes.quarantine[0].blob | test("^[0-9a-f]{40}$"))' \
    "$receipt" >/dev/null || fail "recorded gate receipt has the wrong proof"

git -C "$fx_worktree" checkout --quiet -b future-integration "$future_upstream_sha"
git -C "$fx_worktree" merge --quiet --no-edit carry/hosted-full-ci
# The real reconciliation path resets origin/main to the pin. The local gate
# must still reject the later upstream commit retained only in that ref's log.
git -C "$fx_worktree" update-ref refs/remotes/origin/main "$pinned_upstream_sha"
set +e
future_base_output=$(env "${gate_env[@]}" "$root/scripts/local-gate.sh" \
    --worktree "$fx_worktree" 2>&1)
future_base_status=$?
set -e
[ "$future_base_status" -ne 0 ] \
    || fail "gate accepted a candidate based on later upstream"
printf '%s\n' "$future_base_output" | grep -F \
    "not pinned target $pinned_upstream_sha" >/dev/null \
    || fail "later-upstream refusal did not explain the pinned target"
git -C "$fx_worktree" checkout --quiet integration

git -C "$fx_worktree" checkout --quiet -b integration-workflow-mismatch
printf '\n# integration-only mutation\n' \
    >>"$fx_worktree/.github/workflows/full-ci.yml"
git -C "$fx_worktree" add .github/workflows/full-ci.yml
git -C "$fx_worktree" commit --quiet -m 'mutate integration workflow'
set +e
workflow_output=$(env "${gate_env[@]}" "$root/scripts/local-gate.sh" \
    --worktree "$fx_worktree" 2>&1)
workflow_status=$?
set -e
[ "$workflow_status" -ne 0 ] \
    || fail "Integration-only workflow mutation did not block the gate"
printf '%s\n' "$workflow_output" | grep -F \
    'changes the hosted Full CI workflow' >/dev/null \
    || fail "Integration-only workflow refusal was not explained"
git -C "$fx_worktree" checkout --quiet integration

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

set +e
missing_ship_pin_output=$(
    FXNK_LOCAL_GATE_TESTING=1 FXNK_LOCAL_GATE_MANIFEST="$manifest" \
    FXNK_STATE_DIR="$state_dir" \
        "$root/scripts/ship-gate.sh" \
        --worktree "$fx_worktree" --branch integration --sha "$sha" 2>&1
)
missing_ship_pin_status=$?
set -e
[ "$missing_ship_pin_status" -ne 0 ] \
    || fail "ship gate accepted no pinned upstream target"
printf '%s\n' "$missing_ship_pin_output" | grep -F \
    'MAINTAIN_UPSTREAM_SHA is required' >/dev/null \
    || fail "ship gate did not explain its missing upstream pin"

MAINTAIN_UPSTREAM_SHA="$pinned_upstream_sha" \
FXNK_LOCAL_GATE_TESTING=1 FXNK_LOCAL_GATE_MANIFEST="$manifest" FXNK_STATE_DIR="$state_dir" \
    "$root/scripts/ship-gate.sh" \
    --worktree "$fx_worktree" --branch integration --sha "$sha" \
    | grep -Fx "SHIP $sha" >/dev/null \
    || fail "ship gate rejected the exact local proof"

set +e
mismatched_ship_pin_output=$(
    MAINTAIN_UPSTREAM_SHA="$future_upstream_sha" \
    FXNK_LOCAL_GATE_TESTING=1 FXNK_LOCAL_GATE_MANIFEST="$manifest" \
    FXNK_STATE_DIR="$state_dir" \
        "$root/scripts/ship-gate.sh" \
        --worktree "$fx_worktree" --branch integration --sha "$sha" 2>&1
)
mismatched_ship_pin_status=$?
set -e
[ "$mismatched_ship_pin_status" -ne 0 ] \
    || fail "ship gate accepted a receipt for a different upstream target"
printf '%s\n' "$mismatched_ship_pin_output" | grep -F \
    "expected pinned target $future_upstream_sha" >/dev/null \
    || fail "ship gate did not explain the mismatched upstream pin"

invalid_receipt="$test_root/invalid-receipt.json"
jq '.contract_digest = "0000000000000000000000000000000000000000000000000000000000000000"' \
    "$receipt" >"$invalid_receipt"
chmod 0600 "$invalid_receipt"
mv "$invalid_receipt" "$receipt"
set +e
invalid_output=$(
    MAINTAIN_UPSTREAM_SHA="$pinned_upstream_sha" \
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
