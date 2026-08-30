#!/bin/bash

set -euo pipefail

if [ "${1:-}" = fmt ]; then
    exit 0
fi
if [ "${1:-}" = build ]; then
    mkdir -p zig-out/bin
    cp "$FXNK_TEST_FAKE_FX" zig-out/bin/fx
    chmod +x zig-out/bin/fx
    if [ "${2:-}" = test-fxnk ]; then
        printf 'FXNK-CANARIES 53/53 passed\n'
    fi
    exit 0
fi
exit 1
