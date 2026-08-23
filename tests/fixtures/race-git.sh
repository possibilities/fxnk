#!/bin/bash

set -euo pipefail

real_git=${FXNK_REAL_GIT:?}
trigger=${FXNK_RACE_TRIGGER:-push}

for argument in "$@"; do
    if [ "$argument" = "$trigger" ] \
        && mkdir "${FXNK_RACE_LOCK:?}" 2>/dev/null; then
        case "${FXNK_RACE_ACTION:-update-ref}" in
            update-ref)
                "$real_git" --git-dir="${FXNK_RACE_REPO:?}" update-ref \
                    "${FXNK_RACE_REF:?}" "${FXNK_RACE_SHA:?}"
                ;;
            write-pr-fixture)
                printf '%s\n' "${FXNK_RACE_PR_LINES:?}" \
                    >"${FXNK_RACE_PR_FILE:?}"
                ;;
            *)
                printf 'race-git: unknown action: %s\n' \
                    "$FXNK_RACE_ACTION" >&2
                exit 64
                ;;
        esac
        break
    fi
done

exec "$real_git" "$@"
