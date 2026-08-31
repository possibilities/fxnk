#!/bin/bash

set -euo pipefail

if [ "${FXNK_TEST_FAKE_BUN_QUARANTINE:-0}" -eq 1 ] \
    && [[ " $* " == *' ./quarantined.test.ts '* ]]; then
    printf 'error: fixture\n'
    printf '(fail) fixture\n'
    printf '1 fail\n'
    exit 1
fi

if [[ " $* " == *' tests/e2e/render-lab/audit-direct-writes.ts '* ]]; then
    if [ "${FXNK_TEST_FAKE_BUN_AUDIT_FAIL:-0}" -eq 1 ]; then
        printf 'unclassified_direct_write src/fixture.zig:1 '
        printf 'function=main primitive=debug_print: std.debug.print("x", .{});\n'
        printf 'error: direct-write audit found 1 unclassified site(s)\n'
        exit 1
    fi
    printf 'direct-write audit passed . frame_commit=1 classified=1 unclassified=0\n'
    exit 0
fi

case " $* " in
    *' ./cli.test.ts '*)
        printf '4 pass\n0 fail\n'
        ;;
    *' ./ade-event-feed.test.ts '*)
        printf '4 pass\n0 fail\n'
        ;;
    *)
        printf '1 pass\n0 fail\n'
        ;;
esac
