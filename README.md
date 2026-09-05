# fxnk

A Workshop for maintaining and installing the `possibilities/fx` fork. Each
maintenance invocation rebuilds selected Fx features on one upstream commit
captured before the cycle's exact-object fetch, then publishes them through the
fork's Integration branch.

## Consumers

AgentStart is the consumer. It pins the exact approved Integration commit as
`fx_integration_sha` in its own installer and builds `~/.local/bin/fx` from
that source. Fxnk publishes no binaries; the Integration branch is source
publication, and `scripts/install.sh` here builds it for this machine.

## Before pushing

Run `scripts/install-hooks.sh` once from the canonical checkout to install
the static pre-push check for all worktrees. It checks each outgoing commit's
shell syntax, ShellCheck warnings, documentation, carry graph, and style token
shape. CI and `tests/validate.sh` run the same static check. To check current
edits without pushing, run `python3 .githooks/pre-push --check`.

The hook requires Python 3.9+, Bash, Ruby, and ShellCheck already installed.
It performs no dependency installs, network requests, builds, or runtime
tests. All repositories using this hook share one kernel lock under
`~/.cache/local-static-checks/`; a busy check fails after 15 seconds, and
one push has a 30-second checking deadline. Committed snapshots are limited
to 8 MiB, 512 files, and 16 distinct tips per push. Deletions need no check.
Temporary snapshots are removed automatically; working files and the index
are never changed. Existing hook configurations are retained and reported.

`python3 tests/pre-push.py` exercises exact-commit checks, linked worktrees,
lock contention, deadlines, input bounds, and existing-hook preservation
using small local Git fixtures. Full validation remains a separate command
because it also exercises transaction suites and can build the style viewer.
