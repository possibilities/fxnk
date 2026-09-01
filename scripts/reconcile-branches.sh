#!/bin/bash

set -euo pipefail

# fxnk's entrypoint to the maintain skill's shared namespace script. It
# declares what MAINTAIN.md's Branch model says — the checkout, the remotes,
# the branch names, the composition model — and nothing else; the mechanics
# (a read-only check from a disposable snapshot and one atomic exact-leased
# push of declared refs that leaves all other heads unchanged) are the skill's
# and are tested there.

skill_dir="${MAINTAIN_SKILL_DIR:-$HOME/.local/share/agentstart/resources/skills/maintain}"
script="$skill_dir/scripts/reconcile-branches.sh"
if [ ! -f "$script" ]; then
    printf 'fxnk branches: the maintain skill is not installed at %s (run ~/code/agentstart/scripts/install.sh --install, or set MAINTAIN_SKILL_DIR)\n' \
        "$skill_dir" >&2
    exit 1
fi

export MAINTAIN_WORKSHOP="$(cd "$(dirname "$0")/.." && pwd)"
export MAINTAIN_CHECKOUT="${FXNK_FX_CHECKOUT:-$HOME/src/fx}"
export MAINTAIN_FORK_REPO=possibilities/fx
export MAINTAIN_UPSTREAM_REPO=vercel-labs/fx
export MAINTAIN_FORK_REMOTE=fork
export MAINTAIN_UPSTREAM_REMOTE=origin
export MAINTAIN_MAIN_BRANCH=main
export MAINTAIN_INTEGRATION_BRANCH=integration
export MAINTAIN_CARRY_PREFIX=carry/
export MAINTAIN_QUARANTINE_PREFIX=DELETEME/
export MAINTAIN_PRESERVE_OPEN_PRS=0

exec bash "$script" "$@"
