#!/bin/bash

set -euo pipefail

die() {
    printf 'fxnk installer: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/install.sh --install|--check\n'
}

case "${1:-}" in
    --install)
        ;;
    --check)
        check_only=1
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
fx_branch=integration
fx_fork_url="${FXNK_FX_FORK_URL:-https://github.com/possibilities/fx.git}"
fx_upstream_url="${FXNK_FX_UPSTREAM_URL:-https://github.com/vercel-labs/fx.git}"
fx_bin="${FXNK_FX_BIN:-$HOME/.local/bin/fx}"
fx_settings="${FXNK_FX_SETTINGS:-$HOME/.fx/settings.json}"
state_dir="${FXNK_STATE_DIR:-$HOME/.local/state/fxnk}"
commit_receipt="$state_dir/fx-built-commit"
digest_receipt="$state_dir/fx-built-sha256"
zig_bin="${FXNK_ZIG_BIN:-$(command -v zig || true)}"

if [ "${check_only:-0}" -eq 1 ]; then
    cat <<EOF
Fx fork installation:
  checkout: $fx_checkout
  source: fork/$fx_branch ($fx_fork_url)
  upstream: origin/main ($fx_upstream_url; maintained by /maintain)
  binary: $fx_bin
  receipts: $state_dir
  action: fast-forward to the published integration branch, build ReleaseSafe, and install atomically
EOF
    exit 0
fi

[ "$(uname -s)" = Darwin ] || die "macOS is required"
[ "$(id -u)" -ne 0 ] || die "run as the target user, not root"
if [ -z "$zig_bin" ] || [ ! -x "$zig_bin" ]; then
    die "zig is required"
fi
command -v git >/dev/null 2>&1 || die "git is required"
command -v jq >/dev/null 2>&1 || die "jq is required"
command -v shasum >/dev/null 2>&1 || die "shasum is required"

remote_matches() {
    local actual="$1" expected_https="$2" expected_ssh="$3"
    case "$actual" in
        "$expected_https" | "${expected_https%.git}" | "$expected_ssh") return 0 ;;
        *) return 1 ;;
    esac
}

ensure_remote() {
    local name="$1" wanted="$2" expected_https="$3" expected_ssh="$4" actual
    actual=$(git -C "$fx_checkout" remote get-url "$name" 2>/dev/null || true)
    if [ -z "$actual" ]; then
        git -C "$fx_checkout" remote add "$name" "$wanted" \
            || die "could not add the Fx $name remote"
    elif [ "$actual" != "$wanted" ] \
        && ! remote_matches "$actual" "$expected_https" "$expected_ssh"; then
        die "$fx_checkout remote $name points at $actual"
    fi
}

disable_auto_upgrade() {
    local settings_dir tmp_settings
    settings_dir=$(dirname "$fx_settings")
    mkdir -p "$settings_dir"
    tmp_settings="$settings_dir/.settings.json.new.$$"
    umask 077
    if [ -f "$fx_settings" ]; then
        jq '.auto_upgrade = false' "$fx_settings" >"$tmp_settings" \
            || die "Fx settings are not valid JSON: $fx_settings"
    else
        printf '{"auto_upgrade":false}\n' >"$tmp_settings"
    fi
    chmod 0600 "$tmp_settings"
    mv "$tmp_settings" "$fx_settings"
}

if [ ! -e "$fx_checkout" ]; then
    printf 'Cloning fork/%s into %s.\n' "$fx_branch" "$fx_checkout"
    mkdir -p "$(dirname "$fx_checkout")"
    git clone --quiet --origin fork --branch "$fx_branch" \
        "$fx_fork_url" "$fx_checkout" \
        || die "could not clone fork/$fx_branch into $fx_checkout"
fi

git -C "$fx_checkout" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || die "$fx_checkout is not a git worktree"
ensure_remote fork "$fx_fork_url" \
    'https://github.com/possibilities/fx.git' 'git@github.com:possibilities/fx.git'
ensure_remote origin "$fx_upstream_url" \
    'https://github.com/vercel-labs/fx.git' 'git@github.com:vercel-labs/fx.git'

[ -z "$(git -C "$fx_checkout" status --porcelain)" ] \
    || die "$fx_checkout has local changes; refusing to install them"
git -C "$fx_checkout" fetch --quiet fork "$fx_branch" \
    || die "could not fetch fork/$fx_branch"

if ! git -C "$fx_checkout" rev-parse --verify --quiet \
    "refs/heads/$fx_branch" >/dev/null; then
    git -C "$fx_checkout" branch --quiet "$fx_branch" "fork/$fx_branch" \
        || die "could not create the local integration branch"
fi

current_branch=$(git -C "$fx_checkout" branch --show-current)
if [ "$current_branch" != "$fx_branch" ]; then
    git -C "$fx_checkout" switch --quiet "$fx_branch" \
        || die "could not switch from $current_branch to $fx_branch"
fi
git -C "$fx_checkout" merge --quiet --ff-only "fork/$fx_branch" \
    || die "$fx_branch cannot fast-forward to fork/$fx_branch"

head=$(git -C "$fx_checkout" rev-parse HEAD)
fork_head=$(git -C "$fx_checkout" rev-parse "fork/$fx_branch")
[ "$head" = "$fork_head" ] \
    || die "$fx_checkout@$fx_branch has unpublished commits"
short=$(git -C "$fx_checkout" rev-parse --short HEAD)

if [ -x "$fx_bin" ] && [ -f "$commit_receipt" ] \
    && [ -f "$digest_receipt" ] \
    && [ "$(cat "$commit_receipt")" = "$head" ] \
    && [ "$(shasum -a 256 "$fx_bin" | awk '{print $1}')" \
        = "$(cat "$digest_receipt")" ]; then
    disable_auto_upgrade
    printf 'Fx integration %s is already installed at %s.\n' "$short" "$fx_bin"
    exit 0
fi

printf 'Building Fx integration at %s.\n' "$short"
(
    cd "$fx_checkout"
    "$zig_bin" build -Doptimize=ReleaseSafe
)
built_bin="$fx_checkout/zig-out/bin/fx"
[ -x "$built_bin" ] || die "Fx build did not produce $built_bin"

mkdir -p "$(dirname "$fx_bin")" "$state_dir"
tmp_bin="$fx_bin.new.$$"
tmp_commit="$commit_receipt.new.$$"
tmp_digest="$digest_receipt.new.$$"
cp "$built_bin" "$tmp_bin"
chmod 0755 "$tmp_bin"
printf '%s\n' "$head" >"$tmp_commit"
shasum -a 256 "$tmp_bin" | awk '{print $1}' >"$tmp_digest"
mv "$tmp_bin" "$fx_bin"
mv "$tmp_commit" "$commit_receipt"
mv "$tmp_digest" "$digest_receipt"
disable_auto_upgrade

printf 'Installed Fx integration %s to %s; auto-upgrade is disabled.\n' \
    "$short" "$fx_bin"
