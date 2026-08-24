# Fx fork maintenance

This repository delivers and maintains our local fork of
[`vercel-labs/fx`](https://github.com/vercel-labs/fx). It owns the behavior we
want independently of upstream review or publication while continuously
rebuilding that behavior on current upstream Fx. `/maintain` — the shared
`maintain` skill — runs a maintenance cycle from this file; this file is the
whole of what that skill knows about Fx.

## Purpose

Keep a published `integration` branch of Fx that carries every feature below,
rebuilt on current upstream every cycle, and installed on this machine by this
repository's own installer. The fork is not a place to develop Fx in general:
a feature lives here because we need it before — or instead of — upstream
shipping it.

## Upstream

- Bound checkout: `~/src/fx`. `origin` is `vercel-labs/fx`; `fork` is
  `possibilities/fx`. Read `~/src/fx/AGENTS.md` completely before touching Fx.
- Contribution conventions: high volume; every pull request needs one `type:`
  label, a Full CI matrix (Linux and macOS, x86_64 and arm64) with four
  `Full suite (...)` aggregates, changelog rules, and `CONTRIBUTING.md`.
  Landing is uncertain — our requests have stayed open for weeks, and one need
  was satisfied by someone else's merge — so nothing here waits on upstream.
- What we offer: whole features, shaped like upstream, when the shape is
  clear; we do not chase them. The existing pull requests (#242, #244, #320,
  #323) and issues are historical references only — their branches are not
  maintained, nobody tends them, and maintenance never relies on upstream
  action. Reviving one would be a deliberate act outside the cycle, never a
  side effect of it.
- "Landed" means merged into `vercel-labs/fx:main` and verified against the
  inventory below by reading the code and exercising its path. A carried patch
  is retired only then.

## Branch model

- Mirror branch: `main`, an exact mirror of `vercel-labs/fx:main` locally and on
  the fork. Never an integration base with downstream-only commits.
- Integration branch: `integration`, containing every carried feature together.
  It is the only branch the installer consumes and never a feature-development
  branch. A maintenance cycle publishes its locally proved composition once,
  before the slow Full CI wait. Other agents may branch from that exact
  published commit while the owning cycle monitors it, but they do not advance
  `integration` until that cycle finishes its gate.
- Composition: carry heads. Each carried feature has a stable moving
  `carry/<feature>` branch, published to the fork for visibility, developed or
  repaired in its own worktree on current `origin/main`, and composed — only
  its committed, reviewed head — into a clean integration worktree in
  dependency order. The resulting commit is published directly to
  `integration` with an exact force-with-lease after the focused local gate.
  Carry branches are never install sources and never track or push to a
  pull-request branch, even when they contain related commits.
- Quarantine prefix: `DELETEME/`. Any fork head other than `main`,
  `integration`, a current `carry/*`, or a preserved open-request head is moved
  at the same commit to `DELETEME/<original-name>`. Existing `DELETEME/*`
  heads are permanent: reported, never removed automatically.
- Open pull-request heads: preserved. The exact head of a currently open
  request from the fork keeps its name only while the request is open; a
  closed request's head receives no special treatment.
- Rerere: relied on. The bound checkout keeps it enabled; a recorded
  resolution is reused when it remains semantically correct and rechecked
  after upstream changes.
- `scripts/reconcile-branches.sh` is this repository's entrypoint to the
  shared namespace script; it declares these values and nothing else.

## Features

### Fork identity

- Support the intentionally undocumented `--fxnk-version` consumer probe. It
  exits zero with empty stderr and one exact stdout line in the form
  `fxnk <fxnk-version> (fx <fx-version>)`. The independent fxnk version follows
  semantic versioning for downstream consumer compatibility; the Fx version
  remains the current upstream source version.

### System prompts

- Support `--append-system-prompt-file` and `--system-prompt-file` for appending
  to and replacing the system prompt.

### Effort

- Support `FX_EFFORT` with parity to `FX_MODEL`, and support
  `fx acp --effort` alongside `fx acp --model`.
- Include supported efforts in the model catalog and structured surfaces such
  as `fx models --json`, so an ADE can present valid models and efforts for each
  provider.

### ADE event feed

- Provide the opt-in schema `1` ADE event feed documented in
  `docs/ade-event-feed.md`. An ADE binds a shared POSIX Unix socket and launches
  each interactive Fx TUI with both `FX_ADE_SOCKET_PATH` and its own opaque
  `FX_ADE_INSTANCE_ID`; Fx returns that identity unchanged on every record.
- Publish `FxStarted`, `SessionChanged`, `PromptQueued`, `TurnStarted`,
  `PreToolUse`, `Stop`, `PostTurnEnd`, `AttentionRequired`, and `FxStopped` as
  newline-delimited JSON. Delivery remains passive, asynchronous, bounded,
  ordered per process, and best-effort, so an absent or slow ADE cannot block
  agent work or shutdown.
- Install the feed only in the interactive TUI. `fx ask` and `fx acp` publish
  nothing. Do not filter in-process subagents: every main-agent and subagent
  lifecycle record carries its own session identity, child records also carry
  the parent main-session identity, and all records retain the ADE instance
  identity.
- Keep the ADE feed independent of the existing Herdr integration. Enabling one
  must not enable, disable, filter, or otherwise change the behavior of the
  other.

### External editor support

- Support the common `Ctrl+G` binding to open the composer in `$EDITOR`, moving
  Fx's existing update behavior to `Ctrl+T`.

### Reliability

- Resuming a saved session must accept a candidate transcript that remains
  within the terminal even when it extends beyond stale prior viewport bounds.
- Direct Codex sessions must remain usable beyond 64 sequential provider calls
  without leaking usage reservations.

### Scope

- Features only need a complete Codex-provider experience today. Supporting
  every provider is welcome when it is straightforward, but must not dilute
  the Codex path.

## Gate

From each changed carry worktree and the composed integration worktree, follow
the focused local part of current Fx guidance:

```sh
zig fmt --check src/
./scripts/check-public-surface.sh
zig build -Doptimize=ReleaseSafe
```

Also run focused tests for every changed feature and exercise each changed
happy path with that worktree's freshly built `./zig-out/bin/fx`.

Do not run the complete slow Zig suite or deterministic E2E suite locally as a
maintenance gate. After the focused proofs pass, refresh `origin/main` and
`fork/integration`, compose the final commit, and publish it once to
`fork/integration` with an exact force-with-lease against the integration tip
captured before composition. Publication makes the commit available as the
base for subsequent feature work, but does not authorize installation or
completion of the maintenance cycle.

The integration push starts Full CI. Hand that exact SHA to a standing monitor
and stop occupying the feature-development loop while the slow suite runs.
The monitor owns reruns and repair-forward work for real failures and does not
finish until the exact-SHA run satisfies current `~/src/fx/AGENTS.md` guidance
and all four `Full suite (...)` aggregates pass. A stale, superseded, partial,
cancelled, skipped, or failed run is not proof.

After Full CI succeeds, run the project-owned ship gate. It re-reads the remote
integration branch, refreshes current upstream, and prints `SHIP <sha>` only
when the local worktree, published integration commit, upstream ancestry,
workflow run, and all four aggregates agree on the exact commit:

```sh
~/code/fxnk/scripts/ship-gate.sh \
  --worktree "$integration_worktree" \
  --branch integration \
  --sha "$integration_sha"
```

## Consumer

The installer. Only after the ship gate passes for the still-published
integration SHA, run:

```sh
~/code/fxnk/scripts/install.sh --install
```

It proves any existing local integration tip from the installed commit receipt
(or the pre-fetch remote-tracking ref on a first install), builds the published
commit ReleaseSafe in a detached temporary worktree, and only then rebinds the
clean checkout and atomically replaces the binary and receipts under
`~/.local/state/fxnk`, with Fx's `auto_upgrade` set to `false`. It does not
rebase, push, inspect requests, or decide which patches are carried. Never edit
the installed binary or live receipts by hand; rerun the installer.

## Notify

- Title: `Fx Maintenance`
- Group: `fxnk.maintain`

## Style guide

This repository also owns the fx style guide for fmx: `style/STYLE.md`, its
machine-readable ground truth `style/tokens.json`, and the rendered
references in `style/captures/`. fmx (`~/code/fmx`) treats fx as its living
style guide; this is where that edge is documented and kept true.

Methodology, run whenever the bound checkout's `integration` moves (every
maintenance cycle qualifies, since carried features can touch UI):

1. `scripts/style-extract.sh --check` — re-extracts the tokens from
   `~/src/fx` and diffs against the committed `style/tokens.json`, ignoring
   the generated stamp. No drift: done. Drift: run it without `--check`,
   read the diff, and update the tables and prose in `style/STYLE.md` to
   agree — the tables mirror tokens.json and must never contradict it.
2. After any token drift, prove the interactive viewer still works:
   `scripts/style-view.sh` must open, switch all six sections, and toggle
   themes against the new tokens.json. The viewer (`style/viewer/`, bun +
   `@opentui/core`) reads tokens.json generically, so most drift needs no
   code change; a schema change in tokens.json is the exception and must
   update `style/viewer/index.ts` in the same commit. Keep its
   `@opentui/core` pin matched to fmx's (`~/code/fmx/package.json`) —
   rendering with fmx's own toolkit version is the point.
3. After any token drift, regenerate the visual references:
   `scripts/style-capture.sh` (swatch sheets from tokens.json, plus
   welcome-screen PNGs of the freshly built `~/src/fx/zig-out/bin/fx` in
   both `FX_THEME` values). Commit the changed captures; they are small and
   diffable.
4. If the extractor itself fails, fx refactored a styling site. Re-derive
   the sites with the census greps below, fix the extractor's parsers, and
   reconcile STYLE.md prose against what actually changed.

Discovery method (how the styling sites were found, and how to find them
again after a refactor) — run in `~/src/fx`:

```sh
# every file carrying SGR color literals, ranked; excludes tests
grep -rlE '38;5;|38;2;|48;5;|48;2;' src --include='*.zig' | grep -v _test
# the distinct color indices in use (a new index = a palette change)
grep -rhoE '(38|48);5;[0-9]+' src --include='*.zig' | sort | uniq -c | sort -rn
# theme selection and live-update machinery
grep -rn 'initTheme\|detectTheme\|FX_THEME\|2031\|997' src --include='*.zig'
```

The extractor's five parsed sites (role palette `src/ui/render.zig`
`initTheme`, syntax palettes `code_highlight.zig`, assistant tokens
`presentation/ansi.zig`, prompt card `user_message_card.zig`, retint map
`store.zig`) are the authoritative producers; scattered literal SGR strings
elsewhere in fx are always dark-ramp values covered by the retint map, so
tracking the five sites plus the index census is complete coverage.

Carve-outs are the one part of the guide that is not extracted. fx has no
tabs, docks, trays, or modals, so surfaces fmx needs and fx never draws —
today the Tools panel's rule tab, the tray's agent rows, and the surfaces
drawn over the stage — are designed from fx's principles and recorded in
`style/STYLE.md` § "Carve-outs", with the viewer's "carve-outs" section
rendering them from ramp tokens. They are deliberately absent from
`tokens.json`, invisible to `style-extract.sh --check`, and must never be
"reconciled" toward fx: drift there is a design decision, not token drift.
If upstream fx ever grows one of these surfaces, the carve-out becomes a
candidate for extraction and the section is revisited in that cycle.

The scripts read the fx checkout and never write to it; `style-capture.sh`
requires an existing `zig-out/bin/fx` build and refuses to build one itself.
The style guide never gates shipping: drift is follow-up work for the cycle,
not a reason to hold the integration publish.
