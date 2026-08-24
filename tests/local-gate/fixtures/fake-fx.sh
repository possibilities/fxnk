#!/bin/bash

set -euo pipefail

case "${1:-}" in
    --fxnk-version)
        printf 'fxnk 9.9.9 (fx 8.8.8)\n'
        ;;
    --help)
        printf '%s\n' '--system-prompt-file --append-system-prompt-file --skills-dir'
        ;;
    models)
        [ "${2:-}" = --json ] || exit 1
        printf '{"models":[{"reasoning_efforts":["low"]}]}\n'
        ;;
    *)
        exit 1
        ;;
esac
