#!/bin/bash

set -euo pipefail

[ "${1:-}" = build ] || exit 64
mkdir -p zig-out/bin
cp /usr/bin/true zig-out/bin/fx
chmod 0755 zig-out/bin/fx
