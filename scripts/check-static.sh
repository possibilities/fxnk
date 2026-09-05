#!/bin/bash
# Called under .githooks/pre-push's shared lock and deadline, locally and in CI.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v shellcheck >/dev/null || { printf 'Install shellcheck before pushing.\n' >&2; exit 1; }
shellcheck --severity=warning scripts/*.sh tests/validate.sh \
    tests/install-transaction.sh tests/local-gate/receipt-transaction.sh \
    tests/ci-watch/verdict-transaction.sh tests/ci-watch/fixtures/*.sh
for script in scripts/*.sh tests/*.sh tests/*/*.sh tests/*/fixtures/*.sh; do
    bash -n "$script"
done
ruby -c scripts/validate-full-ci-workflow.rb >/dev/null
python3 scripts/check-contracts.py
printf 'Static checks passed.\n'
