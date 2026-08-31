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
        [ "${FX_E2E_OPENAI_CODEX_MODELS_URL:-}" = \
            'http://127.0.0.1:31337/models' ] || exit 1
        [ -n "${MODEL_CATALOG_REQUESTS_FILE:-}" ] || exit 1
        printf 'GET /models\n' >>"$MODEL_CATALOG_REQUESTS_FILE"
        printf '{"models":[{"reasoning_efforts":["low"]}]}\n'
        ;;
    *)
        exit 1
        ;;
esac
