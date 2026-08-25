#!/bin/bash

set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)

die() {
    printf 'fxnk installer: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/install.sh --install --sha SHA|--check\n'
}

case "${1:-}" in
    --install)
        [ "$#" -eq 3 ] && [ "${2:-}" = --sha ] || {
            usage >&2
            exit 64
        }
        expected_sha=$3
        [ "${#expected_sha}" -eq 40 ] || die "--sha must be a full lowercase commit SHA"
        case "$expected_sha" in
            *[!0-9a-f]*) die "--sha must be a full lowercase commit SHA" ;;
        esac
        ;;
    --check)
        check_only=1
        [ "$#" -eq 1 ] || {
            usage >&2
            exit 64
        }
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
  supervision: install fxnk's local report-and-route policy and Integration trunk config
  action: align the clean checkout to the published integration branch, build ReleaseSafe, and install atomically
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

stage_auto_upgrade_setting() {
    local settings_dir
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
}

build_root=
build_worktree=
build_worktree_added=0
tmp_bin=
tmp_commit=
tmp_digest=
tmp_settings=
backup_bin=
backup_commit=
backup_digest=
backup_settings=
had_bin=0
had_commit=0
had_digest=0
had_settings=0
checkout_rebound=0
artifacts_committed=0

prepare_artifact_backups() {
    if [ "$already_installed" -eq 0 ]; then
        backup_bin="$fx_bin.old.$$"
        backup_commit="$commit_receipt.old.$$"
        backup_digest="$digest_receipt.old.$$"
        if [ -e "$fx_bin" ] || [ -L "$fx_bin" ]; then
            cp -pP "$fx_bin" "$backup_bin" || return 1
            had_bin=1
        fi
        if [ -e "$commit_receipt" ] || [ -L "$commit_receipt" ]; then
            cp -pP "$commit_receipt" "$backup_commit" || return 1
            had_commit=1
        fi
        if [ -e "$digest_receipt" ] || [ -L "$digest_receipt" ]; then
            cp -pP "$digest_receipt" "$backup_digest" || return 1
            had_digest=1
        fi
    fi
    backup_settings="$fx_settings.old.$$"
    if [ -e "$fx_settings" ] || [ -L "$fx_settings" ]; then
        cp -pP "$fx_settings" "$backup_settings" || return 1
        had_settings=1
    fi
}

restore_artifact() {
    local had_previous="$1" backup="$2" destination="$3"
    if [ "$had_previous" -eq 1 ]; then
        mv "$backup" "$destination" || return 1
    else
        rm -f -- "$destination" || return 1
    fi
}

restore_artifacts() {
    local failed=0
    if [ "$already_installed" -eq 0 ]; then
        restore_artifact "$had_bin" "$backup_bin" "$fx_bin" || failed=1
        restore_artifact "$had_commit" "$backup_commit" \
            "$commit_receipt" || failed=1
        restore_artifact "$had_digest" "$backup_digest" \
            "$digest_receipt" || failed=1
        backup_bin=
        backup_commit=
        backup_digest=
    fi
    restore_artifact "$had_settings" "$backup_settings" "$fx_settings" \
        || failed=1
    backup_settings=
    [ "$failed" -eq 0 ]
}

commit_artifacts() {
    if [ "$already_installed" -eq 0 ]; then
        mv "$tmp_bin" "$fx_bin" || return 1
        tmp_bin=
        mv "$tmp_commit" "$commit_receipt" || return 1
        tmp_commit=
        mv "$tmp_digest" "$digest_receipt" || return 1
        tmp_digest=
    fi
    mv "$tmp_settings" "$fx_settings" || return 1
    tmp_settings=
}

cleanup() {
    local status=$? cleanup_failed=0 temp_path
    trap - EXIT
    if [ "$status" -ne 0 ] && [ "$checkout_rebound" -eq 1 ] \
        && [ "$artifacts_committed" -eq 0 ]; then
        restore_artifacts || cleanup_failed=1
        restore_checkout || cleanup_failed=1
    fi
    if [ "$build_worktree_added" -eq 1 ]; then
        git -C "$fx_checkout" worktree remove --force "$build_worktree" \
            >/dev/null 2>&1 || cleanup_failed=1
    fi
    if [ -n "$build_root" ] && [ -d "$build_root" ]; then
        rmdir "$build_root" >/dev/null 2>&1 || cleanup_failed=1
    fi
    for temp_path in \
        "$tmp_bin" "$tmp_commit" "$tmp_digest" "$tmp_settings" \
        "$backup_bin" "$backup_commit" "$backup_digest" "$backup_settings"; do
        if [ -n "$temp_path" ] \
            && { [ -e "$temp_path" ] || [ -L "$temp_path" ]; }; then
            rm -f -- "$temp_path" || cleanup_failed=1
        fi
    done
    if [ "$cleanup_failed" -ne 0 ]; then
        printf 'fxnk installer: temporary-file cleanup failed\n' >&2
        [ "$status" -ne 0 ] || status=1
    fi
    exit "$status"
}

restore_checkout() {
    git -C "$fx_checkout" switch --quiet --detach "$original_head" \
        || return 1
    if [ "$local_integration_exists" -eq 1 ]; then
        git -C "$fx_checkout" branch --quiet --force \
            "$fx_branch" "$local_integration_sha" || return 1
    elif git -C "$fx_checkout" rev-parse --verify --quiet \
        "refs/heads/$fx_branch" >/dev/null; then
        git -C "$fx_checkout" branch --quiet --delete --force "$fx_branch" \
            || return 1
    fi
    if [ -n "$original_branch" ]; then
        git -C "$fx_checkout" switch --quiet "$original_branch" || return 1
    fi
}

rebind_integration() {
    git -C "$fx_checkout" switch --quiet --detach "$published_sha" \
        || return 1
    if [ "$local_integration_exists" -eq 1 ]; then
        git -C "$fx_checkout" branch --quiet --force \
            "$fx_branch" "$published_sha" || return 1
    else
        git -C "$fx_checkout" branch --quiet "$fx_branch" "$published_sha" \
            || return 1
    fi
    git -C "$fx_checkout" switch --quiet "$fx_branch" || return 1
    git -C "$fx_checkout" branch --quiet \
        --set-upstream-to="fork/$fx_branch" "$fx_branch" || return 1
    [ "$(git -C "$fx_checkout" rev-parse HEAD)" = "$published_sha" ]
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

FXNK_FX_CHECKOUT="$fx_checkout" \
    "$script_dir/configure-supervision.sh" --install

[ -z "$(git -C "$fx_checkout" status --porcelain)" ] \
    || die "$fx_checkout has local changes; refusing to install them"

# A maintenance cycle may lease-rewrite integration onto current upstream.
# Before fetching that move, prove the local branch still equals either the
# installed commit receipt or the previously observed published ref. The
# receipt remains authoritative when a push from another linked worktree has
# already advanced the shared remote-tracking ref.
local_integration_exists=0
local_integration_sha=
if git -C "$fx_checkout" rev-parse --verify --quiet \
    "refs/heads/$fx_branch" >/dev/null; then
    local_integration_exists=1
    local_integration_sha=$(git -C "$fx_checkout" rev-parse \
        "refs/heads/$fx_branch")
    local_integration_is_published=0
    if [ -f "$commit_receipt" ]; then
        installed_before_fetch=$(cat "$commit_receipt")
        if printf '%s\n' "$installed_before_fetch" \
            | grep -Eq '^[0-9a-f]{40}$' \
            && git -C "$fx_checkout" cat-file -e \
                "$installed_before_fetch^{commit}" 2>/dev/null \
            && [ "$local_integration_sha" = "$installed_before_fetch" ]; then
            local_integration_is_published=1
        fi
    fi
    if [ "$local_integration_is_published" -eq 0 ] \
        && git -C "$fx_checkout" rev-parse --verify --quiet \
            "refs/remotes/fork/$fx_branch" >/dev/null; then
        published_before_fetch=$(git -C "$fx_checkout" rev-parse \
            "refs/remotes/fork/$fx_branch")
        if [ "$local_integration_sha" = "$published_before_fetch" ]; then
            local_integration_is_published=1
        fi
    fi
    [ "$local_integration_is_published" -eq 1 ] \
        || die "$fx_branch has unpublished commits; refusing to replace it"
fi

git -C "$fx_checkout" fetch --quiet fork "$fx_branch" \
    || die "could not fetch fork/$fx_branch"
published_sha=$(git -C "$fx_checkout" rev-parse "fork/$fx_branch")
[ "$published_sha" = "$expected_sha" ] \
    || die "fork/$fx_branch is at $published_sha, approved SHA is $expected_sha"
short=$(git -C "$fx_checkout" rev-parse --short "$published_sha")
original_branch=$(git -C "$fx_checkout" branch --show-current)
original_head=$(git -C "$fx_checkout" rev-parse HEAD)
already_installed=0
if [ -x "$fx_bin" ] && [ -f "$commit_receipt" ] \
    && [ -f "$digest_receipt" ] \
    && [ "$(cat "$commit_receipt")" = "$published_sha" ] \
    && [ "$(shasum -a 256 "$fx_bin" | awk '{print $1}')" \
        = "$(cat "$digest_receipt")" ]; then
    already_installed=1
fi

trap cleanup EXIT
if [ "$already_installed" -eq 0 ]; then
    printf 'Building Fx integration at %s.\n' "$short"
    build_root=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-install.XXXXXX")
    build_worktree="$build_root/source"
    build_worktree_added=1
    git -C "$fx_checkout" worktree add --quiet --detach \
        "$build_worktree" "$published_sha" \
        || die "could not create a detached build worktree"
    (
        cd "$build_worktree"
        "$zig_bin" build -Doptimize=ReleaseSafe
    )
    built_bin="$build_worktree/zig-out/bin/fx"
    [ -x "$built_bin" ] || die "Fx build did not produce $built_bin"

    mkdir -p "$(dirname "$fx_bin")" "$state_dir"
    tmp_bin="$fx_bin.new.$$"
    tmp_commit="$commit_receipt.new.$$"
    tmp_digest="$digest_receipt.new.$$"
    cp "$built_bin" "$tmp_bin"
    chmod 0755 "$tmp_bin"
    printf '%s\n' "$published_sha" >"$tmp_commit"
    shasum -a 256 "$tmp_bin" | awk '{print $1}' >"$tmp_digest"

    git -C "$fx_checkout" worktree remove --force "$build_worktree" \
        || die "could not remove the detached build worktree"
    build_worktree_added=0
    rmdir "$build_root" || die "could not remove the build directory"
    build_root=
fi

# Do not let a publication between SHIP and install redirect the consumer.
published_now=$(git -C "$fx_checkout" ls-remote --exit-code --heads fork \
    "refs/heads/$fx_branch" | awk 'NR == 1 { print $1 }') \
    || die "could not re-read fork/$fx_branch before installation"
[ "$published_now" = "$expected_sha" ] \
    || die "fork/$fx_branch moved to $published_now before installation"

stage_auto_upgrade_setting
prepare_artifact_backups \
    || die "could not stage rollback copies of the installed artifacts"

if ! rebind_integration; then
    if ! restore_checkout; then
        die "could not bind $fx_branch to $short or restore the original checkout"
    fi
    die "could not bind $fx_branch to published fork/$fx_branch"
fi
checkout_rebound=1

commit_artifacts || die "could not commit the Fx installation transaction"
artifacts_committed=1

if [ "$already_installed" -eq 1 ]; then
    printf 'Fx integration %s is already installed at %s.\n' "$short" "$fx_bin"
else
    printf 'Installed Fx integration %s to %s; auto-upgrade is disabled.\n' \
        "$short" "$fx_bin"
fi
