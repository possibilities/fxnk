#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck disable=SC1091 # Resolved from this script's repository root.
source "$root/scripts/gate-contract.sh"

die() {
    printf 'fxnk local gate: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/local-gate.sh --worktree PATH [--record]\n'
}

fx_worktree=
record=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --worktree)
            [ "$#" -ge 2 ] || die "--worktree requires a path"
            fx_worktree=$2
            shift 2
            ;;
        --record)
            record=1
            shift
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
[ -n "$fx_worktree" ] || die "--worktree is required"

test_mode="${FXNK_LOCAL_GATE_TESTING:-0}"
case "$test_mode" in
    0|1) ;;
    *) die "FXNK_LOCAL_GATE_TESTING must be 0 or 1" ;;
esac
if [ "$test_mode" -eq 0 ]; then
    for test_override in \
        FXNK_LOCAL_GATE_UNAME_S \
        FXNK_LOCAL_GATE_UNAME_M \
        FXNK_LOCAL_GATE_MANIFEST \
        FXNK_LOCAL_GATE_ZIG_BIN \
        FXNK_LOCAL_GATE_BUN_BIN; do
        [ -z "${!test_override+x}" ] \
            || die "$test_override is available only in test mode"
    done
    authority='local'
    kernel=$(uname -s)
    machine=$(uname -m)
else
    authority='test'
    kernel="${FXNK_LOCAL_GATE_UNAME_S:-$(uname -s)}"
    machine="${FXNK_LOCAL_GATE_UNAME_M:-$(uname -m)}"
fi
[ "$kernel" = Darwin ] || die "the authoritative local gate requires macOS"
[ "$machine" = arm64 ] || die "the authoritative local gate requires macOS arm64"

for required in git jq shasum python3 tmux; do
    command -v "$required" >/dev/null 2>&1 || die "$required is required"
done
zig_bin="${FXNK_LOCAL_GATE_ZIG_BIN:-$(command -v zig || true)}"
bun_bin="${FXNK_LOCAL_GATE_BUN_BIN:-$(command -v bun || true)}"
[ -n "$zig_bin" ] && [ -x "$zig_bin" ] || die "zig is required"
[ -n "$bun_bin" ] && [ -x "$bun_bin" ] || die "bun is required"

[ "$(git -C "$fx_worktree" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] \
    || die "$fx_worktree is not a git worktree"
fx_worktree=$(cd "$fx_worktree" && pwd -P)
if [ "$test_mode" -eq 0 ]; then
    origin_url=$(git -C "$fx_worktree" remote get-url origin 2>/dev/null) \
        || die "$fx_worktree has no origin remote"
    case "$origin_url" in
        https://github.com/vercel-labs/fx | \
        https://github.com/vercel-labs/fx.git | \
        git@github.com:vercel-labs/fx.git) ;;
        *) die "$fx_worktree origin points at $origin_url" ;;
    esac
fi
fx_sha=$(git -C "$fx_worktree" rev-parse HEAD) \
    || die "could not read the Fx worktree HEAD"
worktree_subject=$fx_sha
if [ -n "$(git -C "$fx_worktree" status --porcelain)" ]; then
    worktree_subject="$fx_sha+worktree"
fi
if [ "$record" -eq 1 ] && [ "$worktree_subject" != "$fx_sha" ]; then
    die "recording requires a clean Fx worktree"
fi

verify_recordable_state() {
    local current_sha
    current_sha=$(git -C "$fx_worktree" rev-parse HEAD) \
        || die "could not re-read the Fx worktree HEAD"
    [ "$current_sha" = "$fx_sha" ] \
        || die "Fx worktree moved from $fx_sha to $current_sha during the gate"
    [ -z "$(git -C "$fx_worktree" status --porcelain)" ] \
        || die "Fx worktree changed during the recorded gate"
}

upstream_ref=refs/remotes/origin/main
git -C "$fx_worktree" rev-parse --verify --quiet "$upstream_ref^{commit}" >/dev/null \
    || die "$fx_worktree has no origin/main tracking commit"
upstream_sha=$(git -C "$fx_worktree" rev-parse "$upstream_ref")
# The candidate is not required to contain the tracked origin/main head
# (operator decision, 2026-09-03): upstream currency is recorded in the
# receipt, never gated. The hosted CI carry is measured against the merge base
# it actually sits on.
hosted_ci_base=$(git -C "$fx_worktree" merge-base "$upstream_sha" "$fx_sha")

hosted_ci_ref=refs/heads/carry/hosted-full-ci
hosted_ci_workflow=.github/workflows/full-ci.yml
hosted_ci_sha=$(git -C "$fx_worktree" rev-parse --verify \
    "$hosted_ci_ref^{commit}" 2>/dev/null) \
    || die "$fx_worktree has no carry/hosted-full-ci commit"
hosted_ci_base=$(git -C "$fx_worktree" merge-base "$hosted_ci_base" "$hosted_ci_sha")
[ "$(git -C "$fx_worktree" diff --name-only \
    "$hosted_ci_base..$hosted_ci_sha")" = "$hosted_ci_workflow" ] \
    || die "carry/hosted-full-ci changes files outside its owned workflow"
git -C "$fx_worktree" merge-base --is-ancestor "$hosted_ci_sha" "$fx_sha" \
    || die "$fx_sha does not contain carry/hosted-full-ci at $hosted_ci_sha"
hosted_ci_blob=$(git -C "$fx_worktree" rev-parse \
    "$hosted_ci_sha:$hosted_ci_workflow") \
    || die "carry/hosted-full-ci does not carry $hosted_ci_workflow"
candidate_ci_blob=$(git -C "$fx_worktree" rev-parse \
    "$fx_sha:$hosted_ci_workflow") \
    || die "$fx_sha does not carry $hosted_ci_workflow"
[ "$candidate_ci_blob" = "$hosted_ci_blob" ] \
    || die "$fx_sha changes the hosted Full CI workflow"
printf 'LOCAL-GATE %-24s pass\n' hosted-ci-composition

manifest="${FXNK_LOCAL_GATE_MANIFEST:-$root/gate/macos-arm64-quarantine.json}"
[ -f "$manifest" ] || die "quarantine manifest is missing: $manifest"
jq -e \
    --arg os "$kernel" \
    --arg arch "$machine" \
    '.schema == 1 and .platform.os == $os and .platform.arch == $arch and
     (.entries | length > 0) and
     ([.entries[].file] | unique | length) == (.entries | length) and
     all(.entries[];
         (.file | test("^tests/e2e/[A-Za-z0-9._-]+\\.test\\.ts$")) and
         (.test_name_pattern | type == "string" and length > 0) and
         (.required_blobs | length > 0) and
         all(.required_blobs[];
             (.path | test("^tests/e2e/[A-Za-z0-9._/-]+$")) and
             (.oid | test("^[0-9a-f]{40}$"))) and
         (.allowed_signatures | length > 0) and
         all(.allowed_signatures[];
             (.id | type == "string" and length > 0) and
             (.kind == "runtime" or .kind == "assertion") and
             (.regex | type == "string" and length > 0)))' \
    "$manifest" >/dev/null || die "quarantine manifest is invalid for this platform"

contract_digest=$(fxnk_gate_contract_digest "$root" "$manifest")

started_at=$(date +%s)
scratch=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-local-gate.XXXXXX")
pending_receipt=
model_catalog_server_pid=
model_catalog_url=
model_catalog_requests_file=
cleanup() {
    local status=$?
    trap - EXIT
    if [ -n "$model_catalog_server_pid" ]; then
        kill "$model_catalog_server_pid" 2>/dev/null || true
        wait "$model_catalog_server_pid" 2>/dev/null || true
    fi
    if [ -n "$pending_receipt" ] && [ -e "$pending_receipt" ]; then
        rm -f -- "$pending_receipt"
    fi
    rm -rf -- "$scratch"
    exit "$status"
}
trap cleanup EXIT
mkdir -m 0700 "$scratch/tmux"

step() {
    printf 'LOCAL-GATE %-24s' "$1"
    shift
    "$@"
    printf ' pass\n'
}

run_in_dir() (
    cd "$1"
    shift
    "$@"
)

bun_step() {
    local label="$1" expected_passes="$2" output status
    shift 2
    output="$scratch/$label.log"
    printf 'LOCAL-GATE %-24s' "$label"
    set +e
    run_in_dir "$fx_worktree/tests/e2e" "$@" >"$output" 2>&1
    status=$?
    set -e
    sed -n '1,240p' "$output"
    [ "$status" -eq 0 ] || die "$label exited $status"
    grep -Eq "^[[:space:]]*$expected_passes pass(es)?[[:space:]]*$" "$output" \
        || die "$label did not execute exactly $expected_passes tests"
    grep -Eq '^[[:space:]]*0 fail(s)?[[:space:]]*$' "$output" \
        || die "$label did not report zero failures"
    printf ' pass\n'
}

audit_step() {
    local output="$scratch/direct-write-audit.log" status
    printf 'LOCAL-GATE %-24s' direct-write-audit
    set +e
    run_in_dir "$fx_worktree" "$bun_bin" \
        tests/e2e/render-lab/audit-direct-writes.ts --repo-root "$fx_worktree" \
        >"$output" 2>&1
    status=$?
    set -e
    sed -n '1,240p' "$output"
    [ "$status" -eq 0 ] || die "direct-write-audit exited $status"
    grep -Eq 'direct-write audit passed .* frame_commit=1 .*unclassified=0$' "$output" \
        || die "direct-write-audit did not report a clean classified surface"
    printf ' pass\n'
}

canary_step() {
    local output="$scratch/fxnk-unit-canaries.log" status
    printf 'LOCAL-GATE %-24s' fxnk-unit-canaries
    set +e
    run_in_dir "$fx_worktree" \
        "$zig_bin" build test-fxnk -Doptimize=ReleaseSafe >"$output" 2>&1
    status=$?
    set -e
    sed -n '1,240p' "$output"
    [ "$status" -eq 0 ] || die "fxnk-unit-canaries exited $status"
    [ "$(grep -Fxc 'FXNK-CANARIES 100/100 passed' "$output")" -eq 1 ] \
        || die "fxnk-unit-canaries did not prove exactly 100 declared canaries"
    printf ' pass\n'
}

start_model_catalog_fixture() {
    local ready_file="$scratch/model-catalog.ready"
    local requests_file="$scratch/model-catalog.requests"
    local output="$scratch/model-catalog-server.log"
    local port= attempt=0

    "$bun_bin" "$root/tests/local-gate/fixtures/model-catalog-server.ts" \
        --ready-file "$ready_file" --requests-file "$requests_file" \
        >"$output" 2>&1 &
    model_catalog_server_pid=$!
    while [ "$attempt" -lt 50 ]; do
        attempt=$((attempt + 1))
        if [ -s "$ready_file" ]; then
            port=$(<"$ready_file")
            case "$port" in
                ''|*[!0-9]*) die "model catalog fixture returned an invalid port" ;;
            esac
            [ "$port" -gt 0 ] && [ "$port" -le 65535 ] \
                || die "model catalog fixture returned an invalid port"
            model_catalog_url="http://127.0.0.1:$port/models"
            model_catalog_requests_file="$requests_file"
            return
        fi
        if ! kill -0 "$model_catalog_server_pid" 2>/dev/null; then
            sed -n '1,120p' "$output" >&2
            die "model catalog fixture exited before readiness"
        fi
        sleep 0.1
    done
    die "model catalog fixture did not become ready"
}

stop_model_catalog_fixture() {
    [ -n "$model_catalog_server_pid" ] || return
    kill "$model_catalog_server_pid" 2>/dev/null || true
    wait "$model_catalog_server_pid" 2>/dev/null || true
    model_catalog_server_pid=
}

step format "$zig_bin" fmt --check "$fx_worktree/src/" "$fx_worktree/build.zig" \
    "$fx_worktree/tests/fxnk/"
step public-surface run_in_dir "$fx_worktree" ./scripts/check-public-surface.sh
audit_step
step release-safe-build run_in_dir "$fx_worktree" \
    "$zig_bin" build -Doptimize=ReleaseSafe
canary_step

if [ ! -d "$fx_worktree/tests/e2e/node_modules" ]; then
    step e2e-dependencies run_in_dir "$fx_worktree/tests/e2e" \
        "$bun_bin" install --frozen-lockfile
fi

cli_pattern='system prompt files replace and append in command-line order|repeatable --skills-dir roots load in invocation order|--skills-dir remains usable without HOME|FX_EFFORT overrides the configured effort for fx ask without saving it'
bun_step cli-integration 4 env TMUX_TMPDIR="$scratch/tmux" \
    "$bun_bin" test --max-concurrency 1 \
    --test-name-pattern "$cli_pattern" ./cli.test.ts
bun_step ade-integration 3 env TMUX_TMPDIR="$scratch/tmux" FX_REQUIRE_TMUX=1 \
    "$bun_bin" test --max-concurrency 1 ./ade-event-feed.test.ts
bun_step credential-broker-integration 2 \
    "$bun_bin" test --max-concurrency 1 ./codex-credential-broker.test.ts
voice_pattern='voice control'
bun_step voice-control-integration 7 \
    "$bun_bin" test --max-concurrency 1 \
    --test-name-pattern "$voice_pattern" ./acp.test.ts

quarantine_jsonl="$scratch/quarantine.jsonl"
: >"$quarantine_jsonl"
while IFS= read -r entry; do
    file=$(printf '%s\n' "$entry" | jq -r '.file')
    pattern=$(printf '%s\n' "$entry" | jq -r '.test_name_pattern')
    while IFS=$'\t' read -r blob_path expected_blob; do
        [ -n "$blob_path" ] || continue
        [ -f "$fx_worktree/$blob_path" ] \
            || die "quarantined input is missing: $blob_path"
        actual_blob=$(git -C "$fx_worktree" hash-object "$blob_path")
        [ "$actual_blob" = "$expected_blob" ] \
            || die "quarantine review required: $blob_path is $actual_blob, expected $expected_blob"
    done < <(printf '%s\n' "$entry" | jq -r '.required_blobs[] | [.path, .oid] | @tsv')

    output="$scratch/$(basename "$file").log"
    set +e
    (
        cd "$fx_worktree/tests/e2e"
        TMUX_TMPDIR="$scratch/tmux" FX_REQUIRE_TMUX=1 \
            "$bun_bin" test --max-concurrency 1 \
            --test-name-pattern "$pattern" "./$(basename "$file")"
    ) >"$output" 2>&1
    test_status=$?
    set -e
    sed -n '1,240p' "$output"
    if [ "$test_status" -eq 0 ]; then
        blob=$(git -C "$fx_worktree" hash-object "$file")
        jq -cn --arg file "$file" --arg blob "$blob" \
            '{file:$file,blob:$blob,status:"pass",failure_count:0,signatures:[]}' \
            >>"$quarantine_jsonl"
    else
        classified=$(python3 "$root/scripts/classify-quarantine.py" \
            --manifest "$manifest" \
            --file "$file" \
            --output "$output" \
            --exit-code "$test_status")
        blob=$(git -C "$fx_worktree" hash-object "$file")
        printf '%s\n' "$classified" | jq -c --arg blob "$blob" \
            '. + {blob:$blob}' >>"$quarantine_jsonl"
    fi
done < <(jq -c '.entries[]' "$manifest")

version_output=$(
    "$fx_worktree/zig-out/bin/fx" --fxnk-version 2>"$scratch/version.stderr"
) || die "fresh binary rejected --fxnk-version"
[ ! -s "$scratch/version.stderr" ] || die "fresh binary wrote stderr for --fxnk-version"
printf '%s\n' "$version_output" \
    | grep -Eq '^fxnk [0-9]+\.[0-9]+\.[0-9]+ \(fx [0-9]+\.[0-9]+\.[0-9]+\)$' \
    || die "fresh binary returned an invalid fxnk identity"
help_output=$("$fx_worktree/zig-out/bin/fx" --help 2>"$scratch/help.stderr") \
    || die "fresh binary rejected --help"
[ ! -s "$scratch/help.stderr" ] || die "fresh binary wrote stderr for --help"
for flag in --system-prompt-file --append-system-prompt-file --skills-dir; do
    printf '%s\n' "$help_output" | grep -F -- "$flag" >/dev/null \
        || die "fresh binary help is missing $flag"
done
start_model_catalog_fixture
models_home="$scratch/models-home"
mkdir -m 0700 "$models_home" "$models_home/.fx"
printf '%s\n' \
    '{"version":1,"access_token":"header.eyJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9hY2NvdW50X2lkIjoiYWNjdF9sb2NhbF9nYXRlIn19.signature","refresh_token":"local-gate-refresh","expires_at_ms":4102444800000,"account_id":"acct_local_gate"}' \
    >"$models_home/.fx/chatgpt-auth.json"
printf '%s\n' '{"provider":"codex","codex_model":"gpt-5.6-sol"}' \
    >"$models_home/.fx/settings.json"
chmod 0600 "$models_home/.fx/chatgpt-auth.json" "$models_home/.fx/settings.json"
models_output=$(HOME="$models_home" AI_GATEWAY_API_KEY= OPENAI_API_KEY= \
    VERCEL_OIDC_TOKEN= \
    FX_AUTO_UPGRADE=0 FX_DISABLE_KEYCHAIN=1 FX_E2E_DISABLE_DOTENV=1 \
    FX_E2E_OPENAI_CODEX_MODELS_URL="$model_catalog_url" \
    MODEL_CATALOG_REQUESTS_FILE="$model_catalog_requests_file" \
    "$fx_worktree/zig-out/bin/fx" models --json 2>"$scratch/models.stderr") \
    || die "fresh binary rejected models --json"
[ ! -s "$scratch/models.stderr" ] || die "fresh binary wrote stderr for models --json"
printf '%s\n' "$models_output" | jq -e \
    'any(.models[]?; (.reasoning_efforts | type == "array") and (.reasoning_efforts | length > 0))' \
    >/dev/null || die "fresh binary model catalog has no reasoning-effort inventory"
stop_model_catalog_fixture
model_catalog_request_count=$(grep -Fxc 'GET /models' \
    "$model_catalog_requests_file" || true)
[ "$model_catalog_request_count" -eq 1 ] \
    || die "fresh binary did not request the loopback model catalog fixture"
printf 'LOCAL-GATE %-24s pass\n' fresh-binary

finished_at=$(date +%s)
duration=$((finished_at - started_at))
quarantine=$(jq -s . "$quarantine_jsonl")
recorded_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

if [ "$record" -eq 1 ]; then
    verify_recordable_state
    state_dir="${FXNK_STATE_DIR:-$HOME/.local/state/fxnk}"
    receipt_dir="$state_dir/local-gates"
    mkdir -p "$receipt_dir"
    chmod 0700 "$state_dir" "$receipt_dir"
    receipt="$receipt_dir/$fx_sha.json"
    umask 077
    pending_receipt=$(mktemp "$receipt_dir/.$fx_sha.XXXXXX")
    jq -n \
        --arg sha "$fx_sha" \
        --arg authority "$authority" \
        --arg os "$kernel" \
        --arg arch "$machine" \
        --arg contract_digest "$contract_digest" \
        --arg upstream_sha "$upstream_sha" \
        --arg recorded_at "$recorded_at" \
        --argjson duration "$duration" \
        --argjson quarantine "$quarantine" \
        '{schema:1,authority:$authority,fx_sha:$sha,platform:{os:$os,arch:$arch},
          contract_digest:$contract_digest,
          upstream:{ref:"origin/main",sha:$upstream_sha},
          outcomes:{hosted_ci_composition:"pass",
            format:"pass",public_surface:"pass",direct_write_audit:"pass",
            release_safe_build:"pass",
            fxnk_unit_canaries:"pass",cli_integration:"pass",ade_integration:"pass",
            credential_broker_integration:"pass",
            voice_control_integration:"pass",
            fresh_binary:"pass",quarantine:$quarantine},
          duration_seconds:$duration,recorded_at:$recorded_at}' \
        >"$pending_receipt"
    chmod 0600 "$pending_receipt"
    mv "$pending_receipt" "$receipt" \
        || die "could not atomically record the local gate receipt"
    pending_receipt=
    printf 'RECEIPT %s\n' "$receipt"
fi

printf 'LOCAL-GATE %s %ss\n' "$worktree_subject" "$duration"
