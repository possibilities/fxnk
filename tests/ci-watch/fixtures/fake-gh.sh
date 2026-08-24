#!/bin/bash

set -euo pipefail

printf '%s\n' "$*" >>"${FXNK_TEST_GH_CALLS:-/dev/null}"

case "$1" in
    api)
        case "$2" in
            */git/ref/heads/*)
                printf '%s\n' "${FXNK_TEST_GH_TIP:?}"
                ;;
            */commits/*)
                printf '%s\n' "${FXNK_TEST_GH_TIP_DATE:?}"
                ;;
            *)
                printf 'fake gh: unexpected api %s\n' "$2" >&2
                exit 1
                ;;
        esac
        ;;
    run)
        case "$2" in
            list)
                cat "${FXNK_TEST_GH_RUNS:?}"
                ;;
            view)
                if [[ " $* " == *' --log-failed '* ]]; then
                    cat "${FXNK_TEST_GH_LOG:-/dev/null}"
                else
                    cat "${FXNK_TEST_GH_JOBS:-/dev/null}"
                fi
                ;;
            rerun)
                [ "${FXNK_TEST_GH_RERUN_FAILS:-0}" -eq 0 ] || exit 1
                ;;
            *)
                printf 'fake gh: unexpected run %s\n' "$2" >&2
                exit 1
                ;;
        esac
        ;;
    *)
        printf 'fake gh: unexpected command %s\n' "$1" >&2
        exit 1
        ;;
esac
