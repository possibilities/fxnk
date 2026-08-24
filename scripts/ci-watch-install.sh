#!/bin/bash

# Bind scripts/ci-watch.sh to launchd so the verdict keeps arriving without a
# session running. Rendering is idempotent: the same inputs produce the same
# plist, and installing again replaces the loaded job.

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
label=fxnk.ci-watch
template="$root/launchd/$label.plist"

die() {
    printf 'fxnk ci watch install: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/ci-watch-install.sh [--install | --check | --uninstall]\n'
}

action=check
while [ "$#" -gt 0 ]; do
    case "$1" in
        --install)
            action=install
            shift
            ;;
        --check)
            action=check
            shift
            ;;
        --uninstall)
            action=uninstall
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

[ -f "$template" ] || die "launchd template is missing: $template"
watch="$root/scripts/ci-watch.sh"
[ -x "$watch" ] || die "scripts/ci-watch.sh is not executable"

agent_dir="${FXNK_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
plist="$agent_dir/$label.plist"
state_dir="${FXNK_STATE_DIR:-$HOME/.local/state/fxnk}"
log="$state_dir/ci-watch.log"
# launchd starts with a minimal PATH; gh, jq, and terminal-notifier all live in
# the Homebrew prefix on this machine.
render_path="${FXNK_CI_WATCH_PATH:-/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin}"

render() {
    sed \
        -e "s|__FXNK_WATCH__|$watch|g" \
        -e "s|__FXNK_PATH__|$render_path|g" \
        -e "s|__FXNK_LOG__|$log|g" \
        "$template"
}

case "$action" in
    check)
        render
        ;;
    install)
        # launchd holds this path for months. A linked worktree is temporary by
        # definition, so installing from one leaves a job pointing at a
        # directory that maintenance will reap.
        if [ -f "$root/.git" ] && [ "${FXNK_ALLOW_WORKTREE_INSTALL:-0}" -ne 1 ]; then
            die "install from the canonical checkout, not the worktree $root"
        fi
        mkdir -p "$agent_dir" "$state_dir"
        chmod 0700 "$state_dir"
        pending=$(mktemp "$agent_dir/.$label.plist.XXXXXX")
        render >"$pending"
        chmod 0644 "$pending"
        mv "$pending" "$plist" || die "could not install $plist"
        if command -v launchctl >/dev/null 2>&1; then
            launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
            launchctl bootstrap "gui/$(id -u)" "$plist" \
                || die "launchctl refused to bootstrap $label"
            launchctl enable "gui/$(id -u)/$label" >/dev/null 2>&1 || true
        fi
        printf 'INSTALLED %s\n' "$plist"
        ;;
    uninstall)
        if command -v launchctl >/dev/null 2>&1; then
            launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
        fi
        rm -f -- "$plist"
        printf 'REMOVED %s\n' "$plist"
        ;;
esac
