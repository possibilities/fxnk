#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

fail() {
    printf 'validate: %s\n' "$*" >&2
    exit 1
}

bash -n scripts/install.sh
bash -n scripts/local-gate.sh
bash -n scripts/gate-contract.sh
bash -n scripts/ship-gate.sh
bash -n scripts/reconcile-branches.sh
bash -n scripts/configure-supervision.sh
bash -n tests/install-transaction.sh
bash -n tests/supervision-transaction.sh
bash -n tests/local-gate/receipt-transaction.sh
bash -n scripts/style-extract.sh
bash -n scripts/style-swatch.sh
bash -n scripts/style-capture.sh
bash -n scripts/style-view.sh
bash -n scripts/prefix-mode-demo.sh
bash -n scripts/fmx-release-local.sh
[ -x scripts/install.sh ] || fail "scripts/install.sh is not executable"
[ -x scripts/local-gate.sh ] || fail "scripts/local-gate.sh is not executable"
[ -x scripts/classify-quarantine.py ] \
    || fail "scripts/classify-quarantine.py is not executable"
[ -x scripts/gate-contract.sh ] || fail "scripts/gate-contract.sh is not executable"
[ -x scripts/ship-gate.sh ] || fail "scripts/ship-gate.sh is not executable"
[ -x scripts/reconcile-branches.sh ] \
    || fail "scripts/reconcile-branches.sh is not executable"
[ -x scripts/configure-supervision.sh ] \
    || fail "scripts/configure-supervision.sh is not executable"
[ -x scripts/fmx-release-local.sh ] \
    || fail "scripts/fmx-release-local.sh is not executable"
[ -x tests/install-transaction.sh ] \
    || fail "tests/install-transaction.sh is not executable"
[ -x tests/supervision-transaction.sh ] \
    || fail "tests/supervision-transaction.sh is not executable"
[ -x tests/local-gate/receipt-transaction.sh ] \
    || fail "tests/local-gate/receipt-transaction.sh is not executable"
for style_script in style-extract.sh style-swatch.sh style-capture.sh style-view.sh prefix-mode-demo.sh; do
    [ -x "scripts/$style_script" ] \
        || fail "scripts/$style_script is not executable"
done
[ -f style/tokens.json ] || fail "style/tokens.json is missing"
jq -e '.roles.divider.dark.fg.hex and (.retint_map | length > 0)' style/tokens.json >/dev/null \
    || fail "style/tokens.json is not the expected token shape"
grep -Fx '## Style guide' MAINTAIN.md >/dev/null \
    || fail "MAINTAIN.md is missing the section: ## Style guide"
# The viewer must at least parse and resolve against its pinned toolkit.
if command -v bun >/dev/null; then
    (cd style/viewer \
        && { [ -d node_modules ] || bun install --frozen-lockfile >/dev/null; } \
        && bun build index.ts --target=bun --external '@opentui/*' --outfile=/dev/null >/dev/null \
        && bun build prefix-mode.ts --target=bun --external '@opentui/*' --outfile=/dev/null >/dev/null \
        && bun test prefix-mode.test.ts >/dev/null) \
        || fail "style/viewer does not build"
fi
[ "$(readlink CLAUDE.md)" = AGENTS.md ] || fail "CLAUDE.md must link to AGENTS.md"

plan=$(scripts/install.sh --check)
for required in \
    'source: fork/integration' \
    'maintained by /maintain' \
    "supervision: install fxnk's local report-and-route policy" \
    'build ReleaseSafe' \
    'install atomically'; do
    printf '%s\n' "$plan" | grep -F "$required" >/dev/null \
        || fail "installer plan is missing: $required"
done

for supervision_contract in \
    'durable published `carry/<feature>` head' \
    'Treat every Fx merge candidate as report-and-route evidence' \
    'Never force-push or delete a'; do
    grep -F "$supervision_contract" supervision/SUPERVISE.md >/dev/null \
        || fail "the supervision policy omits: $supervision_contract"
done
grep -F '"$script_dir/configure-supervision.sh" --install' scripts/install.sh >/dev/null \
    || fail "the installer does not converge Fx supervision"

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
grep -F 'paired commits' AGENTS.md >/dev/null \
    || fail "agent guidance does not require paired Fx and inventory commits"
grep -F 'The user does not need to mention maintenance' AGENTS.md >/dev/null \
    || fail "agent guidance does not classify ordinary Fx feature requests"
fx_checkout="${FXNK_FX_CHECKOUT:-$HOME/src/fx}"
if git -C "$fx_checkout" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    features_section=$(awk '
        /^## Features$/ { inside = 1; next }
        /^## / && inside { exit }
        inside { print }
    ' MAINTAIN.md)
    mapped_carries=$(printf '%s\n' "$features_section" \
        | sed -n 's/^| `\(carry\/[^`]*\)` |.*$/\1/p')
    [ -z "$(printf '%s\n' "$mapped_carries" | sort | uniq -d)" ] \
        || fail "MAINTAIN.md Features maps a carry more than once"
    while IFS= read -r carry; do
        [ -n "$carry" ] || continue
        printf '%s\n' "$mapped_carries" | grep -Fx "$carry" >/dev/null \
            || fail "MAINTAIN.md Features does not map local branch: $carry"
    done < <(git -C "$fx_checkout" for-each-ref \
        --format='%(refname:short)' refs/heads/carry/)
    while IFS= read -r carry; do
        [ -n "$carry" ] || continue
        git -C "$fx_checkout" show-ref --verify --quiet "refs/heads/$carry" \
            || fail "MAINTAIN.md Features maps a missing local branch: $carry"
    done <<<"$mapped_carries"
fi
grep -F 'scripts/ship-gate.sh' MAINTAIN.md >/dev/null \
    || fail "the gate does not name the ship gate"
grep -F 'scripts/local-gate.sh' MAINTAIN.md >/dev/null \
    || fail "the gate does not name the local development gate"
grep -F 'Full CI is nonblocking observability' MAINTAIN.md >/dev/null \
    || fail "the gate does not state that Full CI is nonblocking"
grep -F 'scripts/ci-watch.sh' MAINTAIN.md >/dev/null \
    || fail "the gate does not name the Full CI watcher"
# shellcheck disable=SC2088 # Match the literal documented path, not a real one.
grep -F '~/.local/state/fxnk/full-ci/pending.json' MAINTAIN.md >/dev/null \
    || fail "the gate does not make an open verdict a cycle input"
grep -Fx '### Hosted Full CI' MAINTAIN.md >/dev/null \
    || fail "the inventory does not carry the hosted Full CI trigger and serialization"
grep -Fx '### fmx distribution' MAINTAIN.md >/dev/null \
    || fail "the inventory does not carry fmx's private Fx distribution"
scripts/fmx-release-local.sh --help | grep -F 'build --worktree PATH' >/dev/null \
    || fail "the local fmx Fx release fallback has no usable help"
grep -F -- '--environment=development' scripts/fmx-release-local.sh >/dev/null \
    || fail "the local fmx Fx release fallback does not request local OIDC"
grep -F 'export VERCEL_ENV=development' scripts/fmx-release-local.sh >/dev/null \
    || fail "the local fmx Fx release fallback does not identify local OIDC"
if grep -F -- '--add-random-suffix=' scripts/fmx-release-local.sh >/dev/null; then
    fail "the local fmx Fx release fallback stringifies a Blob boolean flag"
fi
grep -F 'overwrite_args=(--allow-overwrite=true)' scripts/fmx-release-local.sh >/dev/null \
    || fail "the local fmx Fx release fallback does not gate mutable overwrite"
grep -F 'prune_historical_fx_releases' scripts/fmx-release-local.sh >/dev/null \
    || fail "the local fmx Fx release fallback does not prune prior releases"
for local_release_contract in \
    'scripts/fmx-release-local.sh' \
    'stop the exact still-active hosted run before' \
    'delete every older exact-commit release only after' \
    'strategy.max-parallel: 1' \
    'Linux Docker host is not a macOS runner'; do
    grep -F "$local_release_contract" MAINTAIN.md >/dev/null \
        || fail "the local fmx Fx release contract omits: $local_release_contract"
done
for distribution_contract in \
    '`FMX_FX_VERSION`' \
    'atomically installs the real native executable as' \
    'replace the separate `fx` installed by this Workshop for AgentStart' \
    '`FX_AUTO_UPGRADE=0`'; do
    grep -F "$distribution_contract" MAINTAIN.md >/dev/null \
        || fail "the fmx distribution contract omits: $distribution_contract"
done
# shellcheck disable=SC2016 # Match the literal documented SHA variable.
grep -F 'scripts/install.sh --install --sha "$integration_sha"' MAINTAIN.md >/dev/null \
    || fail "the consumer does not name the installer"
for consumer_handoff in \
    'fx_integration_sha' \
    '~/code/agentstart/tests/validate.sh' \
    '~/code/agentstart/scripts/install.sh --install' \
    'compare the installed `collab` manifest'; do
    grep -F "$consumer_handoff" MAINTAIN.md >/dev/null \
        || fail "the consumer omits the AgentStart handoff: $consumer_handoff"
done
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
    'MAINTAIN_PRESERVE_OPEN_PRS=0'; do
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

if grep -Eq 'gh run|Full suite \(' scripts/ship-gate.sh; then
    fail "ship gate still treats hosted Full CI as shipping authority"
fi
# shellcheck disable=SC2016 # Match the literal receipt path expression.
grep -F 'local-gates/$expected_sha.json' scripts/ship-gate.sh >/dev/null \
    || fail "ship gate does not require an exact-SHA local receipt"
grep -F 'fxnk_gate_contract_digest' scripts/ship-gate.sh >/dev/null \
    || fail "ship gate does not bind the receipt to the gate contract"
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
printf '%s\n' "$main_gate_output" | grep -F 'published branch must be integration' >/dev/null \
    || fail "ship gate does not reject a branch other than integration"
final_gate_tail=$(tail -n 10 scripts/ship-gate.sh)
printf '%s\n' "$final_gate_tail" | grep -F 'verify_local_branch' >/dev/null \
    || fail "ship gate does not recheck local state immediately before SHIP"
printf '%s\n' "$final_gate_tail" | grep -F 'remote_branch_sha' >/dev/null \
    || fail "ship gate does not recheck the remote branch immediately before SHIP"

# The watcher declares exactly the subject the spec states, and gates nothing.
watch_declared=$(scripts/ci-watch.sh --declare)
printf '%s\n' "$watch_declared" | jq -e \
    '.repo == "possibilities/fx" and .branch == "integration" and
     .workflow == "full-ci.yml"' >/dev/null \
    || fail "the watcher does not declare the published integration subject"
if grep -Eq 'ci-watch' scripts/ship-gate.sh scripts/local-gate.sh scripts/install.sh; then
    fail "a gate or the installer depends on the nonblocking watcher"
fi
if grep -Eq 'git push|git rebase|--record' scripts/ci-watch.sh; then
    fail "the watcher does more than observe and escalate"
fi
grep -F 'terminal-notifier' scripts/ci-watch.sh >/dev/null \
    || fail "the watcher has no way to reach the human"
grep -F 'fxnk.maintain' scripts/ci-watch.sh >/dev/null \
    || fail "the watcher does not use the declared notification group"
grep -F 'heartbeat_seconds' scripts/ci-watch.sh >/dev/null \
    || fail "the watcher cannot prove it is still running"
grep -F 'classification=unclassified' scripts/ci-watch.sh >/dev/null \
    || fail "the watcher guesses instead of escalating what it cannot classify"
grep -F 'aggregate_job_prefix' scripts/ci-watch.sh >/dev/null \
    || fail "the watcher lets aggregate jobs stand in for real evidence"
grep -F 'lock_stale_seconds' scripts/ci-watch.sh >/dev/null \
    || fail "the watcher does not serialize overlapping polls"
grep -F 'overdue: true' MAINTAIN.md >/dev/null \
    || fail "the gate does not make an overdue branch a cycle input"
grep -F 'once a day when nothing has happened' MAINTAIN.md >/dev/null \
    || fail "the gate does not state the watcher's daily heartbeat"
scripts/ci-watch-install.sh --check | grep -F 'scripts/ci-watch.sh' >/dev/null \
    || fail "the launchd template does not render the watcher path"
if scripts/ci-watch-install.sh --check | grep -F '__FXNK_' >/dev/null; then
    fail "the launchd template rendered with unresolved placeholders"
fi
if [ -f "$root/.git" ]; then
    set +e
    worktree_install=$(scripts/ci-watch-install.sh --install 2>&1)
    worktree_install_status=$?
    set -e
    [ "$worktree_install_status" -ne 0 ] \
        || fail "the watcher installed launchd from a temporary worktree"
    printf '%s\n' "$worktree_install" | grep -F 'canonical checkout' >/dev/null \
        || fail "the worktree install refusal was not explained"
fi

tests/install-transaction.sh
tests/local-gate/receipt-transaction.sh
tests/ci-watch/verdict-transaction.sh

printf 'fxnk validation passed.\n'
