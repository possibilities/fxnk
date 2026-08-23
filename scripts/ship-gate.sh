#!/bin/bash

set -euo pipefail

die() {
    printf 'fxnk ship gate: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: scripts/ship-gate.sh --worktree PATH --candidate BRANCH --sha SHA

Verify that a temporary fork candidate still names SHA, the local candidate
worktree is clean at SHA, current upstream is contained in SHA, and all four
Full CI aggregate jobs succeeded for SHA. Prints "SHIP <sha>" on success.
EOF
}

candidate_worktree=
candidate_branch=
expected_sha=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --worktree)
            [ "$#" -ge 2 ] || die "--worktree requires a path"
            candidate_worktree=$2
            shift 2
            ;;
        --candidate)
            [ "$#" -ge 2 ] || die "--candidate requires a branch"
            candidate_branch=$2
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

[ -n "$candidate_worktree" ] || die "--worktree is required"
[ -n "$candidate_branch" ] || die "--candidate is required"
[ -n "$expected_sha" ] || die "--sha is required"

command -v git >/dev/null 2>&1 || die "git is required"
command -v gh >/dev/null 2>&1 || die "gh is required"
command -v jq >/dev/null 2>&1 || die "jq is required"

[ "${#expected_sha}" -eq 40 ] \
    || die "--sha must be a full 40-character lowercase commit SHA"
case "$expected_sha" in
    *[!0-9a-f]*)
        die "--sha must be a full 40-character lowercase commit SHA"
        ;;
esac
git check-ref-format --branch "$candidate_branch" >/dev/null 2>&1 \
    || die "invalid candidate branch: $candidate_branch"
case "$candidate_branch" in
    integration | main)
        die "candidate must be a temporary branch, not $candidate_branch"
        ;;
esac

[ "$(git -C "$candidate_worktree" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] \
    || die "$candidate_worktree is not a git worktree"

verify_local_candidate() {
    local local_sha
    local_sha=$(git -C "$candidate_worktree" rev-parse HEAD) \
        || die "could not read candidate worktree HEAD"
    [ "$local_sha" = "$expected_sha" ] \
        || die "candidate worktree is at $local_sha, expected $expected_sha"
    [ -z "$(git -C "$candidate_worktree" status --porcelain)" ] \
        || die "candidate worktree has local changes"
}

verify_local_candidate

remote_candidate_sha() {
    local listing
    listing=$(git -C "$candidate_worktree" ls-remote --heads fork \
        "refs/heads/$candidate_branch") \
        || die "could not read fork/$candidate_branch"
    [ -n "$listing" ] || die "fork/$candidate_branch does not exist"
    printf '%s\n' "$listing" | awk 'NR == 1 { print $1 }'
}

published_candidate=$(remote_candidate_sha)
[ "$published_candidate" = "$expected_sha" ] \
    || die "fork/$candidate_branch is at $published_candidate, expected $expected_sha"

runs=$(gh run list --repo possibilities/fx --workflow full-ci.yml \
    --branch "$candidate_branch" --commit "$expected_sha" --limit 20 \
    --json databaseId,headBranch,headSha,status,conclusion,url) \
    || die "could not list Full CI runs"
run=$(printf '%s\n' "$runs" | jq -c --arg branch "$candidate_branch" \
    --arg sha "$expected_sha" '
        map(select(.headBranch == $branch and .headSha == $sha))
        | sort_by(.databaseId)
        | last // empty
    ') || die "could not parse Full CI runs"
[ -n "$run" ] || die "no Full CI run found for fork/$candidate_branch@$expected_sha"

run_id=$(printf '%s\n' "$run" | jq -r '.databaseId')
run_status=$(printf '%s\n' "$run" | jq -r '.status')
run_conclusion=$(printf '%s\n' "$run" | jq -r '.conclusion')
run_url=$(printf '%s\n' "$run" | jq -r '.url')
[ "$run_status" = completed ] \
    || die "Full CI run $run_url is $run_status"
[ "$run_conclusion" = success ] \
    || die "Full CI run $run_url concluded $run_conclusion"

run_detail=$(gh run view "$run_id" --repo possibilities/fx \
    --json headBranch,headSha,status,conclusion,jobs,url) \
    || die "could not inspect Full CI run $run_id"
printf '%s\n' "$run_detail" | jq -e --arg branch "$candidate_branch" \
    --arg sha "$expected_sha" '
        .headBranch == $branch and
        .headSha == $sha and
        .status == "completed" and
        .conclusion == "success" and
        ([.jobs[] | select(.name | startswith("Full suite ("))] as $jobs |
            ($jobs | length) == 4 and
            ([
                "Full suite (linux-x86_64)",
                "Full suite (linux-aarch64)",
                "Full suite (macos-x86_64)",
                "Full suite (macos-aarch64)"
            ] - ($jobs | map(.name)) | length) == 0 and
            all($jobs[];
                .status == "completed" and .conclusion == "success"))
    ' >/dev/null || die "Full CI did not pass all four exact-SHA aggregate jobs"

# Re-read both moving remote refs after CI inspection. The publication command
# still uses the starting integration tip as an exact force-with-lease.
published_candidate=$(remote_candidate_sha)
[ "$published_candidate" = "$expected_sha" ] \
    || die "fork/$candidate_branch moved to $published_candidate during the gate"
git -C "$candidate_worktree" fetch --quiet origin main \
    || die "could not refresh origin/main"
upstream_sha=$(git -C "$candidate_worktree" rev-parse refs/remotes/origin/main)
git -C "$candidate_worktree" merge-base --is-ancestor \
    "$upstream_sha" "$expected_sha" \
    || die "candidate does not contain current origin/main at $upstream_sha"

# Leave no network, CI, or fetch operation between these final state checks and
# SHIP. The lease-protected integration push remains a separate explicit step.
verify_local_candidate
published_candidate=$(remote_candidate_sha)
[ "$published_candidate" = "$expected_sha" ] \
    || die "fork/$candidate_branch moved to $published_candidate during the gate"

printf 'SHIP %s\n' "$expected_sha"
