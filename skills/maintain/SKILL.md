---
name: maintain
description: Maintain fxnk's local Fx fork by reconciling upstream changes, carried features, integration, and upstream pull requests. Use for /maintain or when asked to perform an Fx fork maintenance cycle; use the installer alone for installation without maintenance.
---

# Maintain the Fx fork

Keep the published integration branch current without losing the behavior in
`WORKSHOP.md`. Treat ordinary reconciliation, feature repair, gating, and
publication as the authorized work of a `/maintain` invocation. Ask the human
only when an upstream change creates a consequential product choice that the
workshop and existing implementation do not resolve.

## Establish the state

1. Read `AGENTS.md`, `CONTEXT.md`, `WORKSHOP.md`, and `SCRATCHPAD.md` in this
   repository. Read `~/src/fx/AGENTS.md` completely before touching Fx.
2. Read the durable fork contract with
   `agentwiki get fork-rebase-policy --json` when `agentwiki` is available.
3. Confirm fxnk is clean on `main`. Confirm `~/src/fx` is clean, its `fork`
   remote is `possibilities/fx`, its `origin` is `vercel-labs/fx`, rerere is
   enabled, and the published install branch is `integration`.
4. Fetch both remotes. Compare upstream and integration with the last completed
   baseline in the scratchpad. Read every upstream commit in that interval,
   grouping related changes before deciding whether they affect a carried
   feature.
5. Survey every open pull request authored by the current GitHub user against
   `vercel-labs/fx`. Record CI, review state, mergeability, labels, maintainer
   activity, and relevant merged or closed replacements. Do not comment, label,
   close, or otherwise mutate a pull request without separate authorization.

## Reconcile the fork

- Walk every feature in `WORKSHOP.md`; absence is work, not a status note.
- Prefer an upstream implementation when it fully satisfies the required
  behavior. Retire a carried patch only after verifying the upstream code and
  exercising its path, not merely because a PR merged or closed.
- When upstream changes code a carried patch calls, reread that interaction
  even if Git reports a clean rebase. Accept a rerere resolution only after the
  same semantic review.
- Use dedicated worktrees and branches for all work outside fxnk. Keep upstream
  PR branches separate from local integration implementations when their
  histories or review needs differ.
- Rebase integration in a scratch worktree onto current `origin/main`. Resolve
  conflicts and repair or add carried features there. Never leave the bound
  checkout mid-rebase.
- Preserve the old published integration ref and installed binary until the new
  candidate passes its gate. Publish only with an exact `--force-with-lease`
  against the previously observed `fork/integration` tip.

## Gate and publish

Follow the current Fx guidance. At minimum, from the candidate worktree:

```sh
zig fmt --check src/
./scripts/check-public-surface.sh
zig build -Doptimize=ReleaseSafe
fx_zdotdir=$(mktemp -d)
ZDOTDIR="$fx_zdotdir" zig build test -Doptimize=ReleaseSafe
rmdir "$fx_zdotdir"
```

Also run focused tests for every changed feature and exercise each changed happy
path with that worktree's freshly built `./zig-out/bin/fx`. A PR branch is not
ready until its exact-commit Full CI and ship gate satisfy `~/src/fx/AGENTS.md`.

After the integration candidate passes, push it with the lease and invoke the
fxnk installer, which fast-forwards the bound checkout to that published tip:

```sh
~/code/fxnk/scripts/install.sh --install
```

If rebase, validation, or publication fails, leave the previous integration
branch and installed binary in place. Report the exact failed gate and retain a
useful worktree when it is needed for follow-up.

## Maintain the scratchpad

Update `SCRATCHPAD.md` during the cycle, not as an afterthought:

- replace the completed baseline with the exact upstream and integration SHAs;
- keep one current entry per carried feature, including implementation branch,
  upstream replacement or PR, verification evidence, and retirement condition;
- keep current PR attention items and noteworthy upstream opportunities;
- retain rerere or conflict context only while it can change a later decision;
- remove superseded state and append one compact dated history entry.

Do not duplicate the workshop's feature specification, paste command logs, or
store secrets. Commit and push scratchpad changes on fxnk `main` after the fork
and installation state they describe are real.

## Notify and close

Interesting new upstream capabilities, a blocked maintenance gate, or a product
decision needing the human gets both a transcript report and a macOS
notification when `terminal-notifier` is available:

```sh
terminal-notifier -title "Fx Maintenance" -message "<concise outcome>" \
  -group fxnk.maintain
```

Finish with the installed integration SHA, feature disposition, PR attention
items, checks run, scratchpad commit, and anything deliberately left for the
human. Silence is appropriate when no noteworthy capability or decision was
found.
