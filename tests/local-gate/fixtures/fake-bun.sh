#!/bin/bash

set -euo pipefail

if [ "${FXNK_TEST_FAKE_BUN_QUARANTINE:-0}" -eq 1 ] \
    && [[ " $* " == *' ./quarantined.test.ts '* ]]; then
    printf 'error: fixture\n'
    printf '(fail) fixture\n'
    printf '1 fail\n'
    exit 1
fi

case " $* " in
    *' ./cli.test.ts '* | *' ./ade-event-feed.test.ts '*)
        printf '3 pass\n0 fail\n'
        ;;
    *)
        printf '1 pass\n0 fail\n'
        ;;
esac
