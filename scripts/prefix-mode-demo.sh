#!/bin/bash
# Open the full-screen fmx prefix-mode design lab. The prototype uses fxnk's
# extracted style tokens and the same pinned OpenTUI release as fmx.
#
# Usage: prefix-mode-demo.sh [--theme dark|light] [--treatment 1-6]
#                              [--reduced-motion]

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root/style/viewer"

command -v bun > /dev/null || {
    printf 'prefix-mode-demo: bun is required (https://bun.sh)\n' >&2
    exit 1
}
[ -d node_modules ] || bun install --frozen-lockfile
exec bun prefix-mode.ts "$@"
