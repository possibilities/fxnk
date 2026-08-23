# fxnk agent guidance

This repository owns delivery and maintenance of the operator's local Fx fork.
Read `CONTEXT.md`, `MAINTAIN.md`, and `SCRATCHPAD.md` before changing the fork
or its installer.

## Ownership

- `MAINTAIN.md` is the project specification and the whole of what the shared
  `maintain` skill knows about Fx: purpose, upstream and our stance toward it,
  branch model, the feature inventory that must remain true, the gate, the
  consumer, and the notification. Its section headings are fixed — the skill
  reads them by name — so add to a section rather than renaming one.
- `/maintain` is the shared `maintain` skill in `~/code/agentguidance`, the
  operating procedure for every fork workshop on this machine. Fx-specific
  procedure belongs in `MAINTAIN.md`, never in a copy of the skill here.
- `SCRATCHPAD.md` is current maintenance state, not a second specification or
  an unbounded transcript.
- `style/` is the fx style guide for fmx: `style/STYLE.md` (prose for fmx
  developers), `style/tokens.json` (extracted ground truth; on conflict it
  wins), and `style/captures/` (swatch sheets and welcome-screen PNGs).
  `style/viewer/` is the interactive visual guide (bun + `@opentui/core`,
  pinned to fmx's version), opened with `scripts/style-view.sh`.
  `scripts/style-extract.sh`, `scripts/style-swatch.sh`, and
  `scripts/style-capture.sh` maintain the artifacts; the methodology is
  `MAINTAIN.md` section "Style guide". The scripts read `~/src/fx` and never
  write outside this repository.
- `scripts/install.sh` consumes the published `fork/integration` branch. It
  must not rebase, push, inspect PRs, or decide which patches should be carried.
- `scripts/reconcile-branches.sh` is the thin entrypoint to the skill's shared
  namespace script: it declares the branch model `MAINTAIN.md` states and
  nothing else. The mechanics — mirror `main`, publish `carry/*`, preserve
  exact open-PR heads, move every other non-quarantine fork branch to
  `DELETEME/<original>` in one atomic leased push — live and are tested in
  agentguidance (`skills/maintain/scripts/`, `tests/branch-policy.sh`).
- Upstream pull requests are historical references only. Maintenance may read
  them for evidence, but must not update their branches or mutate the requests.
  Only the exact heads of currently open requests retain their original names.

The checkout being maintained is `~/src/fx`, with `fork` pointing to
`possibilities/fx` and `origin` pointing to `vercel-labs/fx`. Its
`integration` branch is the only install source. Read that checkout's
`AGENTS.md` completely before modifying or validating Fx.

## Working topology

Work directly on `main` in this repository. Outside this repository, create a
dedicated worktree and carry branch, commit the finished change, merge it into
the target repository's `main` or integration branch as appropriate, and remove
the worktree after the merge. Never do feature work in the bound Fx checkout or
push a carry branch onto a historical upstream PR branch.

Maintenance owns the complete fork branch namespace. It must preserve unknown
work by moving it to `DELETEME/<original>` at the same commit, never by deleting
it. Existing `DELETEME/*` branches are permanent quarantine and are not removed
automatically.

Keep Fx's rerere support enabled. A recorded resolution is evidence, not proof:
after upstream changes, reread the affected behavior before accepting it.

## Validation

Run:

```sh
tests/validate.sh
```

Installer changes also require an isolated real install using temporary binary,
state, and settings paths, followed by execution of the built binary. Fx feature
work follows every build, focused-test, Full CI, and real-binary requirement in
`~/src/fx/AGENTS.md`.

Finished work lands on `main` and is pushed. The installer may rebind a clean
local integration branch only after proving it still equals the installed
commit receipt or the pre-fetch remote-tracking tip. It builds a detached
published candidate before changing the bound checkout. Never edit the
installed Fx binary or live receipts by hand; rerun the installer.
