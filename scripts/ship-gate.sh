#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck disable=SC1091 # Resolved from this script's repository root.
source "$root/scripts/gate-contract.sh"

die() {
    printf 'fxnk ship gate: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: scripts/ship-gate.sh --worktree PATH --branch BRANCH --sha SHA

Verify that a published fork branch still names SHA, the local worktree is
clean at SHA, current upstream is contained in SHA, and the macOS-arm64 local
gate receipt proves SHA under the current gate contract. Prints "SHIP <sha>"
on success.
EOF
}

branch_worktree=
published_branch=
expected_sha=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --worktree)
            [ "$#" -ge 2 ] || die "--worktree requires a path"
            branch_worktree=$2
            shift 2
            ;;
        --branch)
            [ "$#" -ge 2 ] || die "--branch requires a branch"
            published_branch=$2
            shift 2
            ;;
        --sha)
            [ "$#" -ge 2 ] || die "--sha requires a commit"
            expected_sha=$2
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

[ -n "$branch_worktree" ] || die "--worktree is required"
[ -n "$published_branch" ] || die "--branch is required"
[ -n "$expected_sha" ] || die "--sha is required"

command -v git >/dev/null 2>&1 || die "git is required"
command -v jq >/dev/null 2>&1 || die "jq is required"
command -v shasum >/dev/null 2>&1 || die "shasum is required"

test_mode="${FXNK_LOCAL_GATE_TESTING:-0}"
case "$test_mode" in
    0|1) ;;
    *) die "FXNK_LOCAL_GATE_TESTING must be 0 or 1" ;;
esac
if [ "$test_mode" -eq 0 ]; then
    [ -z "${FXNK_LOCAL_GATE_MANIFEST+x}" ] \
        || die "FXNK_LOCAL_GATE_MANIFEST is available only in test mode"
    [ "$(uname -s)" = Darwin ] || die "shipping requires macOS"
    [ "$(uname -m)" = arm64 ] || die "shipping requires macOS arm64"
    receipt_authority='local'
else
    receipt_authority='test'
fi

[ "${#expected_sha}" -eq 40 ] \
    || die "--sha must be a full 40-character lowercase commit SHA"
case "$expected_sha" in
    *[!0-9a-f]*)
        die "--sha must be a full 40-character lowercase commit SHA"
        ;;
esac
git check-ref-format --branch "$published_branch" >/dev/null 2>&1 \
    || die "invalid published branch: $published_branch"
[ "$published_branch" = integration ] \
    || die "published branch must be integration: $published_branch"

[ "$(git -C "$branch_worktree" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] \
    || die "$branch_worktree is not a git worktree"
if [ "$test_mode" -eq 0 ]; then
    fork_url=$(git -C "$branch_worktree" remote get-url fork 2>/dev/null) \
        || die "$branch_worktree has no fork remote"
    origin_url=$(git -C "$branch_worktree" remote get-url origin 2>/dev/null) \
        || die "$branch_worktree has no origin remote"
    case "$fork_url" in
        https://github.com/possibilities/fx | \
        https://github.com/possibilities/fx.git | \
        git@github.com:possibilities/fx.git) ;;
        *) die "$branch_worktree fork points at $fork_url" ;;
    esac
    case "$origin_url" in
        https://github.com/vercel-labs/fx | \
        https://github.com/vercel-labs/fx.git | \
        git@github.com:vercel-labs/fx.git) ;;
        *) die "$branch_worktree origin points at $origin_url" ;;
    esac
fi

verify_local_branch() {
    local local_sha
    local_sha=$(git -C "$branch_worktree" rev-parse HEAD) \
        || die "could not read branch worktree HEAD"
    [ "$local_sha" = "$expected_sha" ] \
        || die "branch worktree is at $local_sha, expected $expected_sha"
    [ -z "$(git -C "$branch_worktree" status --porcelain)" ] \
        || die "branch worktree has local changes"
}

verify_local_branch

remote_branch_sha() {
    local listing
    listing=$(git -C "$branch_worktree" ls-remote --heads fork \
        "refs/heads/$published_branch") \
        || die "could not read fork/$published_branch"
    [ -n "$listing" ] || die "fork/$published_branch does not exist"
    printf '%s\n' "$listing" | awk 'NR == 1 { print $1 }'
}

published_sha=$(remote_branch_sha)
[ "$published_sha" = "$expected_sha" ] \
    || die "fork/$published_branch is at $published_sha, expected $expected_sha"

manifest="${FXNK_LOCAL_GATE_MANIFEST:-$root/gate/macos-arm64-quarantine.json}"
[ -f "$manifest" ] || die "quarantine manifest is missing: $manifest"
while IFS=$'\t' read -r blob_path expected_blob; do
    [ -n "$blob_path" ] || continue
    actual_blob=$(git -C "$branch_worktree" rev-parse \
        "$expected_sha:$blob_path" 2>/dev/null) \
        || die "published commit is missing quarantined input: $blob_path"
    [ "$actual_blob" = "$expected_blob" ] \
        || die "quarantine review required: $blob_path is $actual_blob, expected $expected_blob"
done < <(jq -r '.entries[].required_blobs[] | [.path, .oid] | @tsv' "$manifest")
contract_digest=$(fxnk_gate_contract_digest "$root" "$manifest")
state_dir="${FXNK_STATE_DIR:-$HOME/.local/state/fxnk}"
receipt="$state_dir/local-gates/$expected_sha.json"
[ -f "$receipt" ] && [ ! -L "$receipt" ] \
    || die "no regular local gate receipt for $expected_sha"
[ "$(stat -f '%u' "$receipt")" = "$(id -u)" ] \
    || die "local gate receipt is not owned by the current user"
[ "$(stat -f '%Lp' "$receipt")" = 600 ] \
    || die "local gate receipt must have mode 0600"
jq -e \
    --arg sha "$expected_sha" \
    --arg authority "$receipt_authority" \
    --arg digest "$contract_digest" \
    --slurpfile manifest "$manifest" '
        (.outcomes.quarantine) as $quarantine |
        .schema == 1 and
        .authority == $authority and
        .fx_sha == $sha and
        .platform == {os:"Darwin",arch:"arm64"} and
        .contract_digest == $digest and
        .upstream.ref == "origin/main" and
        (.upstream.sha | test("^[0-9a-f]{40}$")) and
        .outcomes.format == "pass" and
        .outcomes.public_surface == "pass" and
        .outcomes.release_safe_build == "pass" and
        .outcomes.fxnk_unit_canaries == "pass" and
        .outcomes.cli_integration == "pass" and
        .outcomes.ade_integration == "pass" and
        .outcomes.credential_broker_integration == "pass" and
        .outcomes.fresh_binary == "pass" and
        (.duration_seconds | type == "number" and . >= 0) and
        (.recorded_at | type == "string" and length > 0) and
        (.outcomes.quarantine | length) == ($manifest[0].entries | length) and
        all($manifest[0].entries[];
            . as $entry |
            ([$quarantine[] |
                select(.file == $entry.file and
                    .blob == ($entry.required_blobs[] |
                        select(.path == $entry.file) | .oid) and
                    (.failure_count | type == "number" and . >= 0) and
                    ((.status == "pass" and .failure_count == 0 and
                        .signatures == []) or
                     (.status == "quarantined" and .failure_count > 0 and
                        (.signatures | length) > 0 and
                        all(.signatures[];
                            . as $signature |
                            any($entry.allowed_signatures[];
                                .id == $signature)))))]
             | length) == 1)
    ' "$receipt" >/dev/null \
    || die "local gate receipt does not prove the current gate contract for $expected_sha"
receipt_upstream_sha=$(jq -r '.upstream.sha' "$receipt")

# Re-read the moving remote ref after receipt inspection.
published_sha=$(remote_branch_sha)
[ "$published_sha" = "$expected_sha" ] \
    || die "fork/$published_branch moved to $published_sha during the gate"
git -C "$branch_worktree" fetch --quiet origin main \
    || die "could not refresh origin/main"
upstream_sha=$(git -C "$branch_worktree" rev-parse refs/remotes/origin/main)
[ "$receipt_upstream_sha" = "$upstream_sha" ] \
    || die "local gate receipt covered origin/main at $receipt_upstream_sha, current origin/main is $upstream_sha"
git -C "$branch_worktree" merge-base --is-ancestor \
    "$upstream_sha" "$expected_sha" \
    || die "published branch does not contain current origin/main at $upstream_sha"

# Leave no network, CI, or fetch operation between these final state checks and
# SHIP.
verify_local_branch
published_sha=$(remote_branch_sha)
[ "$published_sha" = "$expected_sha" ] \
    || die "fork/$published_branch moved to $published_sha during the gate"

printf 'SHIP %s\n' "$expected_sha"
