#!/bin/bash

# Bind scripts/ci-watch.sh to launchd so the verdict keeps arriving without a
# session running. Rendering is idempotent: the same inputs produce the same
# plist, and installing again replaces the loaded job.

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
label=io.arthack.fxnk.watch-ci
legacy_label=fxnk.ci-watch
marker="fxnk-installer-owned: $label.v1"
template="$root/launchd/$label.plist"

die() {
    printf 'fxnk ci watch install: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: scripts/ci-watch-install.sh [--install | --check | --status | --uninstall]\n'
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
        --status)
            action=status
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
legacy_plist="$agent_dir/$legacy_label.plist"
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

render_legacy() {
    render | sed \
        -e "/<!-- $marker -->/d" \
        -e "s|$label|$legacy_label|g"
}

current_owned() {
    [ -f "$plist" ] && [ ! -L "$plist" ] &&
        grep -Fqx "<!-- $marker -->" "$plist"
}

show_status() {
    ownership=absent
    if [ -e "$plist" ]; then
        if current_owned; then
            ownership=owned
        else
            ownership=foreign
        fi
    fi

    loaded=false
    service=''
    if command -v launchctl >/dev/null 2>&1; then
        service=$(launchctl print "gui/$(id -u)/$label" 2>/dev/null) && loaded=true || true
    fi
    state=$(printf '%s\n' "$service" | sed -n 's/^[[:space:]]*state = //p' | sed -n '1p')
    pid=$(printf '%s\n' "$service" | sed -n 's/^[[:space:]]*pid = //p' | sed -n '1p')
    last_exit=$(printf '%s\n' "$service" | sed -n 's/^[[:space:]]*last exit code = //p' | sed -n '1p')
    log_bytes=0
    [ ! -f "$log" ] || log_bytes=$(wc -c <"$log" | tr -d '[:space:]')

    printf 'label: %s\n' "$label"
    printf 'plist: %s\n' "$plist"
    printf 'ownership: %s\n' "$ownership"
    printf 'loaded: %s\n' "$loaded"
    printf 'state: %s\n' "${state:-not-loaded}"
    printf 'pid: %s\n' "${pid:-none}"
    printf 'last exit: %s\n' "${last_exit:-unknown}"
    printf 'log: %s\n' "$log"
    printf 'log bytes: %s\n' "$log_bytes"
}

case "$action" in
    check)
        render
        ;;
    status)
        show_status
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
        if [ -e "$plist" ] && ! current_owned; then
            die "refusing to replace unowned LaunchAgent: $plist"
        fi
        legacy_owned=0
        if [ -e "$legacy_plist" ]; then
            [ -f "$legacy_plist" ] && [ ! -L "$legacy_plist" ] &&
                cmp -s "$legacy_plist" <(render_legacy) \
                || die "refusing to replace unowned legacy LaunchAgent: $legacy_plist"
            legacy_owned=1
        fi
        current_active=0
        legacy_active=0
        if command -v launchctl >/dev/null 2>&1; then
            launchctl print "gui/$(id -u)/$label" >/dev/null 2>&1 && current_active=1 || true
            launchctl print "gui/$(id -u)/$legacy_label" >/dev/null 2>&1 && legacy_active=1 || true
            if [ "$current_active" -eq 1 ] && [ ! -e "$plist" ]; then
                die "refusing to replace loaded LaunchAgent without an owned plist: $label"
            fi
            if [ "$legacy_active" -eq 1 ] && [ "$legacy_owned" -eq 0 ]; then
                die "refusing to replace loaded legacy LaunchAgent without an owned plist: $legacy_label"
            fi
        fi
        previous=''
        if [ -e "$plist" ]; then
            previous=$(mktemp "$agent_dir/.$label.previous.XXXXXX")
            cp -p "$plist" "$previous"
        fi
        pending=$(mktemp "$agent_dir/.$label.plist.XXXXXX")
        render >"$pending"
        chmod 0644 "$pending"
        mv "$pending" "$plist" || die "could not install $plist"
        migration_complete=0
        if command -v launchctl >/dev/null 2>&1; then
            if [ "$current_active" -eq 1 ]; then
                launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
            fi
            if [ "$legacy_active" -eq 1 ]; then
                launchctl bootout "gui/$(id -u)/$legacy_label" >/dev/null 2>&1 || true
            fi
            if ! launchctl bootstrap "gui/$(id -u)" "$plist"; then
                if [ -n "$previous" ]; then
                    mv "$previous" "$plist"
                    previous=''
                else
                    rm -f -- "$plist"
                fi
                [ "$current_active" -eq 0 ] ||
                    launchctl bootstrap "gui/$(id -u)" "$plist" >/dev/null 2>&1 || true
                [ "$legacy_active" -eq 0 ] ||
                    launchctl bootstrap "gui/$(id -u)" "$legacy_plist" >/dev/null 2>&1 || true
                die "launchctl refused to bootstrap $label"
            fi
            launchctl enable "gui/$(id -u)/$label" >/dev/null 2>&1 || true
            migration_complete=1
        fi
        [ -z "$previous" ] || rm -f -- "$previous"
        if [ "$legacy_owned" -eq 1 ] && [ "$migration_complete" -eq 1 ]; then
            rm -- "$legacy_plist"
            printf 'REPLACED %s\n' "$legacy_plist"
        fi
        printf 'INSTALLED %s\n' "$plist"
        ;;
    uninstall)
        if [ -e "$plist" ]; then
            current_owned || die "refusing to remove unowned LaunchAgent: $plist"
        fi
        if command -v launchctl >/dev/null 2>&1; then
            launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
        fi
        rm -f -- "$plist"
        printf 'REMOVED %s\n' "$plist"
        ;;
esac
