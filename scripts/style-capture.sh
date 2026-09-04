#!/bin/bash
# Regenerate the visual references in style/captures/.
#
# Two kinds of capture:
#   1. Swatch sheets — style-swatch.sh output saved as replayable ANSI
#      (`cat style/captures/swatch-dark.ansi`) plus a color-stripped .txt.
#      Deterministic; derived purely from style/tokens.json.
#   2. Real fx screens — the fx welcome/input screen driven in a PTY via
#      termctrl, once with FX_THEME=dark and once with FX_THEME=light,
#      saved as .txt (screen text) and .png (rendered image for designers).
#      FX_THEME pins the palette so no OSC 11 answer from the PTY is needed.
#
# The fx binary defaults to the bound checkout's build. This script never
# builds fx itself — build in ~/source/vercel-labs--fx first (`zig build`) or
# pass --fx-bin.
# Running fx creates normal runtime state under ~/.fx (a session directory);
# nothing in the fx checkout is modified.
#
# Usage: style-capture.sh [--fx-bin PATH] [--swatch-only]

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
captures="$root/style/captures"
fx_bin="${FX_BIN:-$HOME/source/vercel-labs--fx/zig-out/bin/fx}"
swatch_only=0

while [ $# -gt 0 ]; do
    case "$1" in
        --fx-bin) fx_bin="$2"; shift ;;
        --swatch-only) swatch_only=1 ;;
        *) printf 'style-capture: unknown argument %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

fail() {
    printf 'style-capture: %s\n' "$*" >&2
    exit 1
}

mkdir -p "$captures"

strip_ansi() {
    sed -E $'s/\x1b\\[[0-9;?]*[a-zA-Z]//g; s/\x1b\\][^\x07\x1b]*(\x07|\x1b\\\\)//g'
}

for theme in dark light; do
    "$root/scripts/style-swatch.sh" --theme "$theme" > "$captures/swatch-$theme.ansi"
    strip_ansi < "$captures/swatch-$theme.ansi" > "$captures/swatch-$theme.txt"
    printf 'style-capture: wrote swatch-%s.ansi/.txt\n' "$theme"
done

[ "$swatch_only" = 1 ] && exit 0

command -v termctrl > /dev/null || fail "termctrl not found; rerun with --swatch-only or install terminal-control"
[ -x "$fx_bin" ] || fail "fx binary missing at $fx_bin — run 'zig build' in ~/source/vercel-labs--fx or pass --fx-bin"

for theme in dark light; do
    session="fxnk-style-$theme"
    termctrl stop "$session" > /dev/null 2>&1 || true
    FX_THEME=$theme termctrl start "$session" --cols 100 --rows 30 -- "$fx_bin"
    termctrl wait "$session" "/help" --timeout 15000 \
        || { termctrl stop "$session" > /dev/null 2>&1 || true; fail "fx ($theme) never reached the welcome screen"; }
    termctrl save "$session" --format txt --format png --out "$captures/fx-welcome-$theme"
    termctrl send "$session" ctrl-c
    termctrl send "$session" ctrl-c
    termctrl stop "$session" > /dev/null 2>&1 || true
    printf 'style-capture: wrote fx-welcome-%s.txt/.png\n' "$theme"
done
