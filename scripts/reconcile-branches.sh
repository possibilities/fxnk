#!/bin/bash

set -euo pipefail

die() {
    printf 'fxnk branches: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/reconcile-branches.sh --check|--apply\n'
}

case "${1:-}" in
    --check)
        mode=check
        ;;
    --apply)
        mode=apply
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
[ "$#" -eq 1 ] || {
    usage >&2
    exit 64
}

fx_checkout="${FXNK_FX_CHECKOUT:-$HOME/src/fx}"
fork_remote="${FXNK_FORK_REMOTE:-fork}"
origin_remote="${FXNK_ORIGIN_REMOTE:-origin}"
fork_repo="${FXNK_FORK_REPO:-possibilities/fx}"
upstream_repo="${FXNK_UPSTREAM_REPO:-vercel-labs/fx}"
open_pr_heads_override="${FXNK_OPEN_PR_HEADS_FILE:-}"
allow_local_remotes="${FXNK_ALLOW_LOCAL_REMOTES:-0}"

command -v git >/dev/null 2>&1 || die "git is required"
command -v awk >/dev/null 2>&1 || die "awk is required"
command -v cmp >/dev/null 2>&1 || die "cmp is required"
if [ -z "$open_pr_heads_override" ]; then
    command -v gh >/dev/null 2>&1 || die "gh is required"
fi
git -C "$fx_checkout" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || die "$fx_checkout is not a git worktree"
[ -z "$(git -C "$fx_checkout" status --porcelain)" ] \
    || die "$fx_checkout has local changes"

verify_remote() {
    local remote="$1" repo="$2" actual="$3"
    [ "$allow_local_remotes" -eq 1 ] && return 0
    case "$actual" in
        "https://github.com/$repo" | "https://github.com/$repo.git" \
            | "git@github.com:$repo.git") return 0 ;;
        *) die "$fx_checkout remote $remote points at $actual" ;;
    esac
}

fork_url=$(git -C "$fx_checkout" remote get-url "$fork_remote" 2>/dev/null) \
    || die "$fx_checkout has no $fork_remote remote"
origin_url=$(git -C "$fx_checkout" remote get-url "$origin_remote" 2>/dev/null) \
    || die "$fx_checkout has no $origin_remote remote"
verify_remote "$fork_remote" "$fork_repo" "$fork_url"
verify_remote "$origin_remote" "$upstream_repo" "$origin_url"

scratch_root=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-branches.XXXXXX")
remote_heads="$scratch_root/remote-heads"
open_pr_heads="$scratch_root/open-pr-heads"
local_carries="$scratch_root/local-carries"
quarantine_plan="$scratch_root/quarantine-plan"
open_pr_heads_recheck="$scratch_root/open-pr-heads-recheck"
snapshot_repo="$scratch_root/snapshot.git"

cleanup() {
    local status=$?
    trap - EXIT
    rm -rf -- "$scratch_root"
    exit "$status"
}
trap cleanup EXIT

lookup_sha() {
    local file="$1" branch="$2"
    awk -F '\t' -v branch="$branch" '
        $1 == branch { print $2; found = 1; exit }
        END { if (!found) exit 1 }
    ' "$file"
}

has_branch() {
    local file="$1" branch="$2"
    awk -F '\t' -v branch="$branch" '
        $1 == branch { found = 1; exit }
        END { exit(found ? 0 : 1) }
    ' "$file"
}

git init --quiet --bare "$snapshot_repo" \
    || die "could not create a temporary branch snapshot"
git --git-dir="$snapshot_repo" fetch --quiet --no-tags "$origin_url" \
    '+refs/heads/main:refs/fxnk/origin/main' \
    || die "could not snapshot $origin_remote/main"
git --git-dir="$snapshot_repo" fetch --quiet --no-tags "$fork_url" \
    '+refs/heads/*:refs/fxnk/fork/*' \
    || die "could not snapshot $fork_remote branches"
git --git-dir="$snapshot_repo" fetch --quiet --no-tags "$fx_checkout" \
    '+refs/heads/*:refs/fxnk/local/*' \
    || die "could not snapshot local branches"

git --git-dir="$snapshot_repo" for-each-ref \
    --format='%(refname:strip=3)%09%(objectname)' refs/fxnk/fork/ \
    | LC_ALL=C sort >"$remote_heads"

git -C "$fx_checkout" for-each-ref \
    --format='%(refname:short)%09%(objectname)' refs/heads/carry/ \
    | LC_ALL=C sort >"$local_carries"

inventory_open_pr_heads() {
    local output="$1"
    if [ -n "$open_pr_heads_override" ]; then
        [ -f "$open_pr_heads_override" ] \
            || die "open-PR head fixture does not exist: $open_pr_heads_override"
        awk 'NF { if (NF < 2) exit 2; print $1 "\t" $2 "\t" (NF >= 3 ? $3 : "?") }' \
            "$open_pr_heads_override" | LC_ALL=C sort >"$output" \
            || die "open-PR head fixture is invalid"
    else
        gh api --paginate \
            "repos/$upstream_repo/pulls?state=open&per_page=100" \
            --jq '.[] | [.head.ref, .head.sha, (.head.repo.full_name // ""), .number] | @tsv' \
            | awk -F '\t' -v fork_repo="$fork_repo" \
                '$3 == fork_repo { print $1 "\t" $2 "\t" $4 }' \
            | LC_ALL=C sort >"$output" \
            || die "could not inventory open pull-request heads"
    fi
}

inventory_open_pr_heads "$open_pr_heads"

origin_main_sha=$(git --git-dir="$snapshot_repo" rev-parse refs/fxnk/origin/main)
fork_main_sha=$(lookup_sha "$remote_heads" main) \
    || die "$fork_remote/main is missing"
integration_sha=$(lookup_sha "$remote_heads" integration) \
    || die "$fork_remote/integration is missing"
local_integration_sha=$(git -C "$fx_checkout" rev-parse \
    refs/heads/integration 2>/dev/null) \
    || die "local integration is missing"
[ "$local_integration_sha" = "$integration_sha" ] \
    || die "local integration does not match $fork_remote/integration; install it first"

if git -C "$fx_checkout" rev-parse --verify --quiet \
    refs/heads/main >/dev/null; then
    local_main_sha=$(git -C "$fx_checkout" rev-parse refs/heads/main)
    git --git-dir="$snapshot_repo" merge-base --is-ancestor \
        "$local_main_sha" "$origin_main_sha" \
        || die "local main has commits outside $origin_remote/main"
else
    local_main_sha=missing
fi
git --git-dir="$snapshot_repo" merge-base --is-ancestor \
    "$fork_main_sha" "$origin_main_sha" \
    || die "$fork_remote/main has commits outside $origin_remote/main"

while IFS=$'\t' read -r branch sha pr_number; do
    [ -n "$branch" ] || continue
    case "$branch" in
        main|integration|carry/*|DELETEME/*)
            die "open PR #$pr_number uses reserved maintenance branch $branch"
            ;;
    esac
    remote_sha=$(lookup_sha "$remote_heads" "$branch") \
        || die "open PR #$pr_number head $branch is missing from $fork_remote"
    [ "$remote_sha" = "$sha" ] \
        || die "open PR #$pr_number head $branch moved during inventory"
done <"$open_pr_heads"

while IFS=$'\t' read -r branch sha; do
    [ -n "$branch" ] || continue
    git check-ref-format "refs/heads/$branch" >/dev/null \
        || die "invalid carry branch: $branch"
    git --git-dir="$snapshot_repo" merge-base --is-ancestor \
        "$sha" "$integration_sha" \
        || die "$branch is not included in $fork_remote/integration"
done <"$local_carries"

: >"$quarantine_plan"
# lookup_sha opens the same immutable snapshot independently; neither reader
# writes it. ShellCheck otherwise mistakes the nested read for a pipeline race.
# shellcheck disable=SC2094
while IFS=$'\t' read -r branch sha; do
    [ -n "$branch" ] || continue
    case "$branch" in
        main|integration|DELETEME/*)
            continue
            ;;
        carry/*)
            if has_branch "$local_carries" "$branch"; then
                continue
            fi
            ;;
        *)
            if has_branch "$open_pr_heads" "$branch"; then
                continue
            fi
            ;;
    esac
    target="DELETEME/$branch"
    if target_sha=$(lookup_sha "$remote_heads" "$target" 2>/dev/null); then
        [ "$target_sha" = "$sha" ] \
            || die "quarantine target $target already names another commit"
    fi
    printf '%s\t%s\t%s\n' "$branch" "$sha" "$target" \
        >>"$quarantine_plan"
done <"$remote_heads"

printf 'MAIN %s -> %s\n' "$fork_main_sha" "$origin_main_sha"
printf 'KEEP integration %s\n' "$integration_sha"
while IFS=$'\t' read -r branch sha; do
    [ -n "$branch" ] || continue
    if remote_sha=$(lookup_sha "$remote_heads" "$branch" 2>/dev/null); then
        printf 'PUBLISH %s %s -> %s\n' "$branch" "$remote_sha" "$sha"
    else
        printf 'PUBLISH %s missing -> %s\n' "$branch" "$sha"
    fi
done <"$local_carries"
while IFS=$'\t' read -r branch sha pr_number; do
    [ -n "$branch" ] || continue
    printf 'KEEP-PR #%s %s %s\n' "$pr_number" "$branch" "$sha"
done <"$open_pr_heads"
while IFS=$'\t' read -r branch sha; do
    case "$branch" in
        DELETEME/*) printf 'KEEP-QUARANTINE %s %s\n' "$branch" "$sha" ;;
    esac
done <"$remote_heads"
while IFS=$'\t' read -r branch sha target; do
    [ -n "$branch" ] || continue
    printf 'QUARANTINE %s %s -> %s\n' "$branch" "$sha" "$target"
done <"$quarantine_plan"

[ "$mode" = apply ] || exit 0

if [ "$local_main_sha" != "$origin_main_sha" ] \
    && git -C "$fx_checkout" worktree list --porcelain \
        | awk '$1 == "branch" && $2 == "refs/heads/main" { found = 1 }
               END { exit(found ? 0 : 1) }'; then
    die "local main is checked out in another worktree"
fi

inventory_open_pr_heads "$open_pr_heads_recheck"
cmp -s "$open_pr_heads" "$open_pr_heads_recheck" \
    || die "open pull-request heads changed since planning; rerun"

leases=("--force-with-lease=refs/heads/main:$fork_main_sha")
leases+=("--force-with-lease=refs/heads/integration:$integration_sha")
refspecs=("$origin_main_sha:refs/heads/main")
refspecs+=("$integration_sha:refs/heads/integration")
while IFS=$'\t' read -r branch sha; do
    [ -n "$branch" ] || continue
    if remote_sha=$(lookup_sha "$remote_heads" "$branch" 2>/dev/null); then
        leases+=("--force-with-lease=refs/heads/$branch:$remote_sha")
    else
        leases+=("--force-with-lease=refs/heads/$branch:")
    fi
    refspecs+=("$sha:refs/heads/$branch")
done <"$local_carries"
while IFS=$'\t' read -r branch sha target; do
    [ -n "$branch" ] || continue
    leases+=("--force-with-lease=refs/heads/$branch:$sha")
    if target_sha=$(lookup_sha "$remote_heads" "$target" 2>/dev/null); then
        leases+=("--force-with-lease=refs/heads/$target:$target_sha")
        refspecs+=("$target_sha:refs/heads/$target")
    else
        leases+=("--force-with-lease=refs/heads/$target:")
        refspecs+=("$sha:refs/heads/$target")
    fi
    refspecs+=(":refs/heads/$branch")
done <"$quarantine_plan"

git --git-dir="$snapshot_repo" push --quiet --atomic \
    "${leases[@]}" "$fork_url" "${refspecs[@]}" \
    || die "could not atomically apply the fork branch policy"

git -C "$fx_checkout" fetch --quiet --no-tags "$snapshot_repo" \
    '+refs/fxnk/origin/main:refs/remotes/origin/main' \
    || die "could not refresh $origin_remote/main tracking"
git -C "$fx_checkout" fetch --quiet --prune "$fork_remote" \
    || die "could not refresh $fork_remote tracking refs"

if [ "$local_main_sha" != "$origin_main_sha" ]; then
    git -C "$fx_checkout" branch --force main "$origin_main_sha" \
        || die "could not fast-forward local main"
fi
git -C "$fx_checkout" branch --set-upstream-to="$origin_remote/main" main \
    >/dev/null || die "could not make local main pull from $origin_remote/main"
git -C "$fx_checkout" config branch.main.pushRemote "$fork_remote"

while IFS=$'\t' read -r branch sha; do
    [ -n "$branch" ] || continue
    git -C "$fx_checkout" branch --set-upstream-to="$fork_remote/$branch" \
        "$branch" >/dev/null \
        || die "could not track published $fork_remote/$branch"
    git -C "$fx_checkout" config "branch.$branch.pushRemote" "$fork_remote"
done <"$local_carries"

printf 'Applied fork branch policy: main mirrored, carries published, and stale branches quarantined.\n'
