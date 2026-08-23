#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

fail() {
    printf 'validate: %s\n' "$*" >&2
    exit 1
}

bash -n scripts/install.sh
bash -n scripts/ship-gate.sh
bash -n scripts/reconcile-branches.sh
bash -n tests/install-transaction.sh
bash -n scripts/style-extract.sh
bash -n scripts/style-swatch.sh
bash -n scripts/style-capture.sh
[ -x scripts/install.sh ] || fail "scripts/install.sh is not executable"
[ -x scripts/ship-gate.sh ] || fail "scripts/ship-gate.sh is not executable"
[ -x scripts/reconcile-branches.sh ] \
    || fail "scripts/reconcile-branches.sh is not executable"
[ -x tests/install-transaction.sh ] \
    || fail "tests/install-transaction.sh is not executable"
for style_script in style-extract.sh style-swatch.sh style-capture.sh; do
    [ -x "scripts/$style_script" ] \
        || fail "scripts/$style_script is not executable"
done
[ -f style/tokens.json ] || fail "style/tokens.json is missing"
jq -e '.roles.divider.dark.fg.hex and (.retint_map | length > 0)' style/tokens.json >/dev/null \
    || fail "style/tokens.json is not the expected token shape"
grep -Fx '## Style guide' MAINTAIN.md >/dev/null \
    || fail "MAINTAIN.md is missing the section: ## Style guide"
[ "$(readlink CLAUDE.md)" = AGENTS.md ] || fail "CLAUDE.md must link to AGENTS.md"

plan=$(scripts/install.sh --check)
for required in \
    'source: fork/integration' \
    'maintained by /maintain' \
    'build ReleaseSafe' \
    'install atomically'; do
    printf '%s\n' "$plan" | grep -F "$required" >/dev/null \
        || fail "installer plan is missing: $required"
done

# shellcheck disable=SC2016 # Match the installer's literal branch expressions.
grep -F 'local_integration_sha=$(git -C "$fx_checkout" rev-parse' scripts/install.sh >/dev/null \
    || fail "installer does not remember the local integration tip"
# shellcheck disable=SC2016 # Match the installer's literal branch expressions.
grep -F '[ "$local_integration_sha" = "$installed_before_fetch" ]' scripts/install.sh >/dev/null \
    || fail "installer does not accept the installed commit receipt"
# shellcheck disable=SC2016 # Match the installer's literal branch expressions.
grep -F 'worktree add --quiet --detach' scripts/install.sh >/dev/null \
    || fail "installer does not build the published tip in a detached worktree"
# shellcheck disable=SC2016 # Match the installer's literal branch expressions.
grep -F 'branch --quiet --force' scripts/install.sh >/dev/null \
    || fail "installer does not align integration to the published tip"
grep -F 'has unpublished commits' scripts/install.sh >/dev/null \
    || fail "installer does not reject unpublished integration commits"
grep -F "jq '.auto_upgrade = false'" scripts/install.sh >/dev/null \
    || fail "installer does not disable Fx auto-upgrade"
if grep -Eq 'git .*rebase|push .*force' scripts/install.sh; then
    fail "installer contains maintenance behavior"
fi

# The spec has every section the shared maintain skill reads by name.
for section in Purpose Upstream 'Branch model' Features Gate Consumer Notify; do
    grep -Fx "## $section" MAINTAIN.md >/dev/null \
        || fail "MAINTAIN.md is missing the section: ## $section"
done
grep -F 'scripts/ship-gate.sh' MAINTAIN.md >/dev/null \
    || fail "the gate does not name the ship gate"
# shellcheck disable=SC2016 # Match literal Markdown text.
grep -F 'all four `Full suite (...)` aggregates' MAINTAIN.md >/dev/null \
    || fail "the gate does not require every Full CI aggregate"
grep -F 'scripts/install.sh --install' MAINTAIN.md >/dev/null \
    || fail "the consumer does not name the installer"
# shellcheck disable=SC2016 # Match literal Markdown text.
grep -F 'Title: `Fx Maintenance`' MAINTAIN.md >/dev/null \
    || fail "the notification title is missing"
if grep -F 'agentwiki' MAINTAIN.md >/dev/null; then
    fail "the spec depends on an external wiki policy"
fi

# The namespace entrypoint declares exactly the branch model the spec states
# and defers every mechanic to the shared script.
for declared in \
    'MAINTAIN_FORK_REPO=possibilities/fx' \
    'MAINTAIN_UPSTREAM_REPO=vercel-labs/fx' \
    'MAINTAIN_MAIN_BRANCH=main' \
    'MAINTAIN_INTEGRATION_BRANCH=integration' \
    'MAINTAIN_CARRY_PREFIX=carry/' \
    'MAINTAIN_QUARANTINE_PREFIX=DELETEME/' \
    'MAINTAIN_PRESERVE_OPEN_PRS=1'; do
    grep -F "export $declared" scripts/reconcile-branches.sh >/dev/null \
        || fail "branch entrypoint does not declare $declared"
done
if grep -E 'git .*(push|fetch|update-ref)' scripts/reconcile-branches.sh >/dev/null; then
    fail "branch entrypoint carries namespace mechanics of its own"
fi
set +e
missing_skill_output=$(MAINTAIN_SKILL_DIR=/nonexistent scripts/reconcile-branches.sh --check 2>&1)
missing_skill_status=$?
set -e
[ "$missing_skill_status" -ne 0 ] || fail "branch entrypoint ran without the shared script"
printf '%s\n' "$missing_skill_output" | grep -F 'the maintain skill is not installed' >/dev/null \
    || fail "branch entrypoint does not explain a missing shared script"

grep -F 'Full suite (linux-x86_64)' scripts/ship-gate.sh >/dev/null \
    || fail "ship gate does not require the Linux x86_64 aggregate"
grep -F 'Full suite (linux-aarch64)' scripts/ship-gate.sh >/dev/null \
    || fail "ship gate does not require the Linux aarch64 aggregate"
grep -F 'Full suite (macos-x86_64)' scripts/ship-gate.sh >/dev/null \
    || fail "ship gate does not require the macOS x86_64 aggregate"
grep -F 'Full suite (macos-aarch64)' scripts/ship-gate.sh >/dev/null \
    || fail "ship gate does not require the macOS aarch64 aggregate"
grep -F 'merge-base --is-ancestor' scripts/ship-gate.sh >/dev/null \
    || fail "ship gate does not require current upstream ancestry"
gate_test_sha=0000000000000000000000000000000000000000
set +e
integration_gate_output=$(scripts/ship-gate.sh \
    --worktree "$root/does-not-exist" \
    --branch integration \
    --sha "$gate_test_sha" 2>&1)
integration_gate_status=$?
main_gate_output=$(scripts/ship-gate.sh \
    --worktree "$root/does-not-exist" \
    --branch main \
    --sha "$gate_test_sha" 2>&1)
main_gate_status=$?
set -e
[ "$integration_gate_status" -ne 0 ] \
    || fail "ship gate unexpectedly accepted a missing integration worktree"
printf '%s\n' "$integration_gate_output" | grep -F 'is not a git worktree' >/dev/null \
    || fail "ship gate does not accept integration as a published branch"
[ "$main_gate_status" -ne 0 ] \
    || fail "ship gate accepted the upstream main mirror"
printf '%s\n' "$main_gate_output" | grep -F 'must not be the upstream mirror' >/dev/null \
    || fail "ship gate does not reject the upstream main mirror"
final_gate_tail=$(tail -n 10 scripts/ship-gate.sh)
printf '%s\n' "$final_gate_tail" | grep -F 'verify_local_branch' >/dev/null \
    || fail "ship gate does not recheck local state immediately before SHIP"
printf '%s\n' "$final_gate_tail" | grep -F 'remote_branch_sha' >/dev/null \
    || fail "ship gate does not recheck the remote branch immediately before SHIP"

tests/install-transaction.sh

printf 'fxnk validation passed.\n'
