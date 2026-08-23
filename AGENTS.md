# fxnk agent guidance

This repository owns delivery and maintenance of the operator's local Fx fork.
Read `CONTEXT.md`, `WORKSHOP.md`, and `SCRATCHPAD.md` before changing the fork
or its installer.

## Ownership

- `WORKSHOP.md` is the project specification: purpose, branch model, and the
  feature inventory that must remain true.
- `skills/maintain/SKILL.md` is the operating procedure for `/maintain`.
- `SCRATCHPAD.md` is current maintenance state, not a second specification or
  an unbounded transcript.
- `scripts/install.sh` consumes the published `fork/integration` branch. It
  must not rebase, push, inspect PRs, or decide which patches should be carried.
- Upstream pull requests are historical references only. Maintenance may read
  them for evidence, but must not update their branches or mutate the requests.

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
