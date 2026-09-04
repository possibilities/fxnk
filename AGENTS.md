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
- Every behavior the fork carries is reversed into `MAINTAIN.md` § Features by
  the same requested unit of work that builds it. Fx and this Workshop are
  separate repositories, so this means paired commits rather than one Git
  commit. The inventory commit is part of the feature, never a follow-up: a
  carried feature the inventory does not name is unfinished, because the next
  cycle reconciles only what that section states.
- `SCRATCHPAD.md` is current maintenance state, not a second specification or
  an unbounded transcript.
- `style/` is the fxnk style guide for fx-derived surfaces such as the
  agentbrowse OpenTUI frontend: `style/STYLE.md` (developer prose),
  `style/tokens.json` (extracted ground truth; on conflict it
  wins), and `style/captures/` (swatch sheets and welcome-screen PNGs).
  `style/viewer/` is the interactive visual guide (bun + `@opentui/core`,
  fxnk's own pin), opened with `scripts/style-view.sh`.
  `scripts/style-extract.sh`, `scripts/style-swatch.sh`, and
  `scripts/style-capture.sh` maintain the artifacts; the methodology is
  `MAINTAIN.md` section "Style guide". The scripts read `~/src/fx` and never
  write outside this repository.
- `scripts/install.sh` consumes the published `fork/integration` branch. It
  must not rebase, push, inspect PRs, or decide which patches should be carried.
  It also converges fxnk's local-only `SUPERVISE.md` and
  `supervisor.trunk=integration` configuration so a fresh checkout cannot
  mistake an Integration-only fast-forward for a valid carried-feature landing.
- `scripts/reconcile-branches.sh` is the thin entrypoint to the skill's shared
  branch script: it declares the branch model `MAINTAIN.md` states and nothing
  else. The mechanics — mirror `main`, publish declared `carry/*` heads, and
  leave every other fork head unchanged — live and are tested in
  agentguidance (`skills/maintain/scripts/`, `tests/branch-policy.sh`).
- Upstream pull requests are historical references only. Maintenance may read
  them for evidence, but must not update, support, or preserve their branches.
  Regular maintenance does not open or tend upstream requests.

The checkout being maintained is `~/src/fx`, with `fork` pointing to
`possibilities/fx` and `origin` pointing to `vercel-labs/fx`. Its
`integration` branch is the only install source. Read that checkout's
`AGENTS.md` completely before modifying or validating Fx.

## Adding or changing Fx behavior

A request made from this Workshop to add or change Fx behavior is carried
feature work unless current upstream already satisfies the requested contract.
The user does not need to mention maintenance, `MAINTAIN.md`, or a carry branch.

Before implementation:

1. Read `MAINTAIN.md` § Features and decide whether the request extends an
   existing inventory entry or needs a new one.
2. Add or revise the behavioral contract there and name the corresponding
   `carry/<feature>` head in the carry map. Describe observable behavior, scope,
   and important boundaries rather than implementation or temporary status.
3. Develop the Fx implementation on that named carry head. A genuinely new
   carry and its inventory entry are one deliverable.

Do not gate, publish, compose into Integration, or call the feature finished
until both the Fx implementation commit and the paired Workshop inventory
commit exist. If the request extends an existing behavior, update its entry
when the old wording does not fully require the new behavior. Run
`tests/validate.sh` after creating or renaming a carry; when the Fx checkout is
available, it rejects local `carry/*` heads absent from § Features.

## Working topology

Work directly on `main` in this repository. Outside this repository, develop
each carried Fx feature in a dedicated worktree on its `carry/<feature>` branch,
based on the cycle's captured Main or a declared carry dependency. Gate and
publish that carry, compose it into Integration, and remove the worktree after
the published result is installed. Run focused checks in the carry worktree and
the Local development gate in the exact composition worktree containing it.
Never do feature work in the bound Fx checkout or push onto a historical
upstream PR branch.

Maintenance owns only Main, Integration, and the declared `carry/*` heads.
Every other fork head remains unchanged. Creating, moving, or removing a
`DELETEME/<original>` ref requires an explicit human decision naming that
branch; maintenance never infers deletion from age, ownership, request state,
or namespace.

The generic `supervise` skill provides visibility and guarded worktree reaping
for Fx, but never integrates Fx product branches. Its one-trunk fast-forward
cannot publish the carry heads and exact Integration composition together.
`supervision/SUPERVISE.md` is the source for the local checkout policy;
`scripts/configure-supervision.sh` installs and verifies it.

Keep Fx's rerere support enabled. A recorded resolution is evidence, not proof:
after upstream changes, reread the affected behavior before accepting it.

## Validation

Run:

```sh
tests/validate.sh
```

Installer changes also require an isolated real install using temporary binary,
state, and settings paths, followed by execution of the built binary. Fx feature
work follows the Local development gate and real-binary requirements in
`~/src/fx/AGENTS.md`. Hosted Full CI is nonblocking observability and is never a
shipping prerequisite.

Finished work lands on `main` and is pushed. The installer may rebind a clean
local integration branch only after receiving the exact SHA approved by the
ship gate, proving the branch still equals the installed commit receipt or the
pre-fetch remote-tracking tip, and re-reading the published ref. It builds that
exact SHA detached before changing the bound checkout. Never edit the installed
Fx binary or live receipts by hand; rerun the installer.
