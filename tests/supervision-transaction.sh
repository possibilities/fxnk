#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)

fail() {
    printf 'supervision-transaction: %s\n' "$*" >&2
    exit 1
}

test_root=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-supervision-test.XXXXXX")
cleanup() {
    local status=$?
    trap - EXIT
    rm -rf -- "$test_root"
    exit "$status"
}
trap cleanup EXIT

checkout="$test_root/fx"
git init --quiet "$checkout"

FXNK_FX_CHECKOUT="$checkout" \
    "$root/scripts/configure-supervision.sh" --install >/dev/null

[ "$(git -C "$checkout" config --get supervisor.trunk)" = integration ] \
    || fail "install did not configure the Integration trunk"
cmp -s "$root/supervision/SUPERVISE.md" "$checkout/SUPERVISE.md" \
    || fail "install did not copy the managed policy exactly"
git -C "$checkout" check-ignore -q SUPERVISE.md \
    || fail "install did not exclude the local policy"
FXNK_FX_CHECKOUT="$checkout" \
    "$root/scripts/configure-supervision.sh" --check >/dev/null

printf '\nstale\n' >>"$checkout/SUPERVISE.md"
set +e
check_output=$(FXNK_FX_CHECKOUT="$checkout" \
    "$root/scripts/configure-supervision.sh" --check 2>&1)
check_status=$?
set -e
[ "$check_status" -ne 0 ] || fail "check accepted a stale policy"
printf '%s\n' "$check_output" | grep -F 'does not match' >/dev/null \
    || fail "check did not explain the stale policy"
FXNK_FX_CHECKOUT="$checkout" \
    "$root/scripts/configure-supervision.sh" --install >/dev/null

unowned_checkout="$test_root/unowned"
git init --quiet "$unowned_checkout"
printf 'operator policy\n' >"$unowned_checkout/SUPERVISE.md"
set +e
unowned_output=$(FXNK_FX_CHECKOUT="$unowned_checkout" \
    "$root/scripts/configure-supervision.sh" --install 2>&1)
unowned_status=$?
set -e
[ "$unowned_status" -ne 0 ] \
    || fail "install replaced an unowned policy"
printf '%s\n' "$unowned_output" | grep -F 'is not owned by fxnk' >/dev/null \
    || fail "install did not explain the unowned policy refusal"
[ "$(cat "$unowned_checkout/SUPERVISE.md")" = 'operator policy' ] \
    || fail "install changed an unowned policy"

printf 'supervision transaction validation passed.\n'
