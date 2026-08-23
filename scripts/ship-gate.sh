#!/bin/bash

set -euo pipefail

die() {
    printf 'fxnk ship gate: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: scripts/ship-gate.sh --worktree PATH --branch BRANCH --sha SHA

Verify that a published fork branch still names SHA, the local worktree is
clean at SHA, current upstream is contained in SHA, and all four Full CI
aggregate jobs succeeded for SHA. Prints "SHIP <sha>" on success.
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
command -v gh >/dev/null 2>&1 || die "gh is required"
command -v jq >/dev/null 2>&1 || die "jq is required"

[ "${#expected_sha}" -eq 40 ] \
    || die "--sha must be a full 40-character lowercase commit SHA"
case "$expected_sha" in
    *[!0-9a-f]*)
        die "--sha must be a full 40-character lowercase commit SHA"
        ;;
esac
git check-ref-format --branch "$published_branch" >/dev/null 2>&1 \
    || die "invalid published branch: $published_branch"
case "$published_branch" in
    main)
        die "published branch must not be the upstream mirror: $published_branch"
        ;;
esac

[ "$(git -C "$branch_worktree" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] \
    || die "$branch_worktree is not a git worktree"

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

runs=$(gh run list --repo possibilities/fx --workflow full-ci.yml \
    --branch "$published_branch" --commit "$expected_sha" --limit 20 \
    --json databaseId,headBranch,headSha,status,conclusion,url) \
    || die "could not list Full CI runs"
run=$(printf '%s\n' "$runs" | jq -c --arg branch "$published_branch" \
    --arg sha "$expected_sha" '
        map(select(.headBranch == $branch and .headSha == $sha))
        | sort_by(.databaseId)
        | last // empty
    ') || die "could not parse Full CI runs"
[ -n "$run" ] || die "no Full CI run found for fork/$published_branch@$expected_sha"

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
printf '%s\n' "$run_detail" | jq -e --arg branch "$published_branch" \
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

# Re-read the moving remote ref after CI inspection.
published_sha=$(remote_branch_sha)
[ "$published_sha" = "$expected_sha" ] \
    || die "fork/$published_branch moved to $published_sha during the gate"
git -C "$branch_worktree" fetch --quiet origin main \
    || die "could not refresh origin/main"
upstream_sha=$(git -C "$branch_worktree" rev-parse refs/remotes/origin/main)
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
