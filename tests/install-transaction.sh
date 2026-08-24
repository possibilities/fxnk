#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
if [ "$(uname -s)" != Darwin ]; then
    printf 'installer transaction validation skipped: macOS is required.\n'
    exit 0
fi

fail() {
    printf 'install-transaction: %s\n' "$*" >&2
    exit 1
}

test_root=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-transaction-test.XXXXXX")
cleanup_test() {
    local status=$?
    trap - EXIT
    rm -rf -- "$test_root"
    exit "$status"
}
trap cleanup_test EXIT

seed="$test_root/seed"
fork_repo="$test_root/fork.git"
upstream_repo="$test_root/upstream.git"
checkout="$test_root/checkout"
test_bin="$test_root/bin/fx"
state_dir="$test_root/state"
settings="$test_root/profile/settings.json"
count_file="$test_root/mv-count"

git init --quiet "$seed"
git -C "$seed" config user.name fxnk-test
git -C "$seed" config user.email fxnk@example.invalid
printf 'old\n' >"$seed/version"
git -C "$seed" add version
git -C "$seed" commit --quiet -m old
old_sha=$(git -C "$seed" rev-parse HEAD)
git -C "$seed" switch --quiet --orphan rewritten
printf 'new\n' >"$seed/version"
git -C "$seed" add version
git -C "$seed" commit --quiet -m new
new_sha=$(git -C "$seed" rev-parse HEAD)

git clone --quiet --bare "$seed" "$fork_repo"
git clone --quiet --bare "$seed" "$upstream_repo"
git --git-dir="$fork_repo" update-ref refs/heads/integration "$old_sha"
git clone --quiet --origin fork --branch integration "$fork_repo" "$checkout"
git -C "$checkout" remote add origin "$upstream_repo"
git -C "$checkout" config user.name fxnk-test
git -C "$checkout" config user.email fxnk@example.invalid

mkdir -p "$(dirname "$test_bin")" "$state_dir" "$(dirname "$settings")"
cp /usr/bin/true "$test_bin"
chmod 0755 "$test_bin"
printf '%s\n' "$old_sha" >"$state_dir/fx-built-commit"
shasum -a 256 "$test_bin" | awk '{print $1}' \
    >"$state_dir/fx-built-sha256"
printf '{"auto_upgrade":true}\n' >"$settings"
old_digest=$(shasum -a 256 "$test_bin" | awk '{print $1}')

# Model a maintenance lease rewrite whose push has already advanced the shared
# remote-tracking ref while the bound branch and installed receipt remain old.
git --git-dir="$fork_repo" update-ref refs/heads/integration "$new_sha"
git -C "$checkout" fetch --quiet fork integration
[ "$(git -C "$checkout" rev-parse integration)" = "$old_sha" ] \
    || fail "fixture did not retain the old local integration tip"
[ "$(git -C "$checkout" rev-parse fork/integration)" = "$new_sha" ] \
    || fail "fixture did not advance the remote-tracking tip"

set +e
transaction_output=$(
    PATH="$root/tests/fixtures/fail-bin:$PATH" \
    FXNK_TEST_MV_COUNT_FILE="$count_file" \
    FXNK_TEST_MV_FAIL_AT=2 \
    FXNK_FX_CHECKOUT="$checkout" \
    FXNK_FX_FORK_URL="$fork_repo" \
    FXNK_FX_UPSTREAM_URL="$upstream_repo" \
    FXNK_FX_BIN="$test_bin" \
    FXNK_STATE_DIR="$state_dir" \
    FXNK_FX_SETTINGS="$settings" \
    FXNK_ZIG_BIN="$root/tests/fixtures/fake-zig.sh" \
    "$root/scripts/install.sh" --install --sha "$new_sha" 2>&1
)
transaction_status=$?
set -e
[ "$transaction_status" -ne 0 ] \
    || fail "injected artifact move did not fail the installer"
printf '%s\n' "$transaction_output" \
    | grep -F 'could not commit the Fx installation transaction' >/dev/null \
    || fail "artifact failure was not reported"
[ "$(git -C "$checkout" branch --show-current)" = integration ] \
    || fail "failed transaction did not restore the original branch"
[ "$(git -C "$checkout" rev-parse HEAD)" = "$old_sha" ] \
    || fail "failed transaction did not restore the original commit"
[ "$(cat "$state_dir/fx-built-commit")" = "$old_sha" ] \
    || fail "failed transaction changed the commit receipt"
[ "$(cat "$state_dir/fx-built-sha256")" = "$old_digest" ] \
    || fail "failed transaction changed the digest receipt"
[ "$(shasum -a 256 "$test_bin" | awk '{print $1}')" = "$old_digest" ] \
    || fail "failed transaction changed the installed binary"
[ "$(jq -r '.auto_upgrade' "$settings")" = true ] \
    || fail "failed transaction changed the settings"
[ "$(git -C "$checkout" worktree list --porcelain \
    | grep -c '^worktree ')" -eq 1 ] \
    || fail "failed transaction leaked a build worktree"

FXNK_FX_CHECKOUT="$checkout" \
FXNK_FX_FORK_URL="$fork_repo" \
FXNK_FX_UPSTREAM_URL="$upstream_repo" \
FXNK_FX_BIN="$test_bin" \
FXNK_STATE_DIR="$state_dir" \
FXNK_FX_SETTINGS="$settings" \
FXNK_ZIG_BIN="$root/tests/fixtures/fake-zig.sh" \
"$root/scripts/install.sh" --install --sha "$new_sha" >/dev/null

[ "$(git -C "$checkout" rev-parse HEAD)" = "$new_sha" ] \
    || fail "successful transaction did not bind the published commit"
[ "$(cat "$state_dir/fx-built-commit")" = "$new_sha" ] \
    || fail "successful transaction did not update the commit receipt"
[ "$(shasum -a 256 "$test_bin" | awk '{print $1}')" \
    = "$(cat "$state_dir/fx-built-sha256")" ] \
    || fail "successful transaction did not record the binary digest"
[ "$(jq -r '.auto_upgrade' "$settings")" = false ] \
    || fail "successful transaction did not disable auto-upgrade"
"$test_bin" --help >/dev/null

# An already installed candidate does not rebuild, while a new unpublished
# local commit is rejected before either the checkout or binary changes.
FXNK_FX_CHECKOUT="$checkout" \
FXNK_FX_FORK_URL="$fork_repo" \
FXNK_FX_UPSTREAM_URL="$upstream_repo" \
FXNK_FX_BIN="$test_bin" \
FXNK_STATE_DIR="$state_dir" \
FXNK_FX_SETTINGS="$settings" \
FXNK_ZIG_BIN=/usr/bin/false \
"$root/scripts/install.sh" --install --sha "$new_sha" >/dev/null

git -C "$checkout" commit --quiet --allow-empty -m unpublished
published_digest=$(shasum -a 256 "$test_bin" | awk '{print $1}')
set +e
unpublished_output=$(
    FXNK_FX_CHECKOUT="$checkout" \
    FXNK_FX_FORK_URL="$fork_repo" \
    FXNK_FX_UPSTREAM_URL="$upstream_repo" \
    FXNK_FX_BIN="$test_bin" \
    FXNK_STATE_DIR="$state_dir" \
    FXNK_FX_SETTINGS="$settings" \
    FXNK_ZIG_BIN="$root/tests/fixtures/fake-zig.sh" \
    "$root/scripts/install.sh" --install --sha "$new_sha" 2>&1
)
unpublished_status=$?
set -e
[ "$unpublished_status" -ne 0 ] \
    || fail "unpublished integration commit was accepted"
printf '%s\n' "$unpublished_output" \
    | grep -F 'has unpublished commits' >/dev/null \
    || fail "unpublished integration refusal was not reported"
[ "$(shasum -a 256 "$test_bin" | awk '{print $1}')" \
    = "$published_digest" ] \
    || fail "unpublished integration refusal changed the binary"

printf 'installer transaction validation passed.\n'
