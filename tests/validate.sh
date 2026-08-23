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
bash -n tests/branch-policy.sh
bash -n tests/fixtures/race-git.sh
[ -x scripts/install.sh ] || fail "scripts/install.sh is not executable"
[ -x scripts/ship-gate.sh ] || fail "scripts/ship-gate.sh is not executable"
[ -x scripts/reconcile-branches.sh ] \
    || fail "scripts/reconcile-branches.sh is not executable"
[ -x tests/install-transaction.sh ] \
    || fail "tests/install-transaction.sh is not executable"
[ -x tests/branch-policy.sh ] \
    || fail "tests/branch-policy.sh is not executable"
[ -x tests/fixtures/race-git.sh ] \
    || fail "tests/fixtures/race-git.sh is not executable"
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

grep -F 'DELETEME/' scripts/reconcile-branches.sh >/dev/null \
    || fail "branch reconciliation does not quarantine stale heads"
grep -F -- '--force-with-lease' scripts/reconcile-branches.sh >/dev/null \
    || fail "branch reconciliation does not use exact ref leases"
grep -F -- '--atomic' scripts/reconcile-branches.sh >/dev/null \
    || fail "branch reconciliation does not use atomic pushes"
grep -F 'open pull-request heads' scripts/reconcile-branches.sh >/dev/null \
    || fail "branch reconciliation does not inventory open PR heads"

grep -F 'name: maintain' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill name is missing"
grep -F 'description:' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill description is missing"
grep -F 'WORKSHOP.md' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not read the project specification"
grep -F 'SCRATCHPAD.md' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not maintain current state"
grep -F -- '--force-with-lease' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not protect integration publication"
grep -F 'push the exact candidate commit' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not gate an unpublished integration candidate"
grep -F 'independent adversarial review' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not require substantial-work review"
grep -F 'otherwise mutate the requests' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not protect historical upstream requests"
grep -F 'This skill is the complete operating contract for the Fx fork.' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill is not self-contained"
grep -F 'sole published install source' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not define the integration branch contract"
grep -F 'tip observed at the start of the cycle' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not pin the integration publication lease"
# shellcheck disable=SC2016 # The capture must retain the runtime variable.
grep -F 'starting_integration_sha=$(' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not capture the starting integration tip"
grep -F "grep -Eq '^[0-9a-f]{40}$'" skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not validate the starting integration tip"
grep -F 'scripts/ship-gate.sh' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not provide a concrete final ship gate"
# shellcheck disable=SC2016 # Match literal Markdown and shell variable text.
grep -F 'all four `Full suite (...)` aggregates' skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not require every Full CI aggregate"
# shellcheck disable=SC2016 # The lease command must retain the runtime variable.
grep -F -- '--force-with-lease="refs/heads/integration:$starting_integration_sha"' \
    skills/maintain/SKILL.md >/dev/null \
    || fail "maintain skill does not provide an exact integration lease command"
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
final_gate_tail=$(tail -n 10 scripts/ship-gate.sh)
printf '%s\n' "$final_gate_tail" | grep -F 'verify_local_candidate' >/dev/null \
    || fail "ship gate does not recheck local state immediately before SHIP"
printf '%s\n' "$final_gate_tail" | grep -F 'remote_candidate_sha' >/dev/null \
    || fail "ship gate does not recheck the remote candidate immediately before SHIP"
if grep -F 'agentwiki' skills/maintain/SKILL.md >/dev/null; then
    fail "maintain skill depends on an external wiki policy"
fi

tests/branch-policy.sh
tests/install-transaction.sh

printf 'fxnk validation passed.\n'
