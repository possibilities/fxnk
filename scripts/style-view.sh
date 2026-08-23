#!/bin/bash
# Open the visual style guide: a small OpenTUI rendering of style/tokens.json
# for humans. Keys inside: 1-5 or arrows switch section, t toggles dark/light,
# q quits.
#
# The viewer lives in style/viewer/ and pins @opentui/core to the version fmx
# uses, so what it renders is what fmx's own toolkit produces from the same
# values. Dependencies install on first run (bun, frozen lockfile).
#
# Usage: style-view.sh [--theme dark|light]

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root/style/viewer"

command -v bun > /dev/null || {
    printf 'style-view: bun is required (https://bun.sh)\n' >&2
    exit 1
}
[ -d node_modules ] || bun install --frozen-lockfile
exec bun index.ts "$@"
