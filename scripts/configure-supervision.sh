#!/bin/bash

set -euo pipefail

die() {
    printf 'fxnk supervision: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/configure-supervision.sh --install|--check\n'
}

case "${1:-}" in
    --install)
        [ "$#" -eq 1 ] || {
            usage >&2
            exit 64
        }
        install=1
        ;;
    --check)
        [ "$#" -eq 1 ] || {
            usage >&2
            exit 64
        }
        install=0
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

root=$(cd "$(dirname "$0")/.." && pwd)
checkout="${FXNK_FX_CHECKOUT:-$HOME/source/vercel-labs--fx}"
source_policy="$root/supervision/SUPERVISE.md"
target_policy="$checkout/SUPERVISE.md"
managed_marker='<!-- Managed by fxnk. Run scripts/configure-supervision.sh --install to converge it. -->'

[ -f "$source_policy" ] || die "managed policy is missing: $source_policy"
git -C "$checkout" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || die "$checkout is not a git worktree"

common_dir=$(git -C "$checkout" rev-parse --git-common-dir)
case "$common_dir" in
    /*) ;;
    *) common_dir="$checkout/$common_dir" ;;
esac
exclude_file="$common_dir/info/exclude"

if [ "$install" -eq 0 ]; then
    [ "$(git -C "$checkout" config --get supervisor.trunk || true)" = integration ] \
        || die "$checkout does not configure supervisor.trunk=integration"
    if [ ! -f "$target_policy" ] \
        || ! cmp -s "$source_policy" "$target_policy"; then
        die "$target_policy does not match fxnk's managed policy"
    fi
    git -C "$checkout" check-ignore -q SUPERVISE.md \
        || die "$target_policy is not excluded from the upstream checkout"
    printf 'Fx supervision configuration is current.\n'
    exit 0
fi

if [ -e "$target_policy" ] \
    && ! grep -Fx "$managed_marker" "$target_policy" >/dev/null; then
    die "$target_policy is not owned by fxnk; refusing to replace it"
fi

mkdir -p "$(dirname "$exclude_file")"
touch "$exclude_file"
if ! git -C "$checkout" check-ignore -q SUPERVISE.md; then
    printf '\nSUPERVISE.md\n' >>"$exclude_file"
fi

tmp_policy="$target_policy.new.$$"
cleanup() {
    rm -f -- "$tmp_policy"
}
trap cleanup EXIT
cp "$source_policy" "$tmp_policy"
chmod 0644 "$tmp_policy"
mv "$tmp_policy" "$target_policy"
git -C "$checkout" config supervisor.trunk integration

"$0" --check >/dev/null
printf 'Installed Fx supervision policy in %s.\n' "$checkout"
