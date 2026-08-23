#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

fail() {
    printf 'validate: %s\n' "$*" >&2
    exit 1
}

bash -n scripts/install.sh
[ -x scripts/install.sh ] || fail "scripts/install.sh is not executable"
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

# shellcheck disable=SC2016 # Match the installer's literal branch expression.
grep -F 'merge --quiet --ff-only "fork/$fx_branch"' scripts/install.sh >/dev/null \
    || fail "installer does not fast-forward only to published integration"
grep -F 'has unpublished commits' scripts/install.sh >/dev/null \
    || fail "installer does not reject unpublished integration commits"
grep -F "jq '.auto_upgrade = false'" scripts/install.sh >/dev/null \
    || fail "installer does not disable Fx auto-upgrade"
if grep -Eq 'git .*rebase|push .*force' scripts/install.sh; then
    fail "installer contains maintenance behavior"
fi

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

printf 'fxnk validation passed.\n'
