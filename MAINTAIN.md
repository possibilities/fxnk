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
  branch. One publication lease serializes exact-leased updates. During a
  coordinated batch, each owner may publish its locally proved composition and
  immediately hand the exact new tip and lease to the next owner; intermediate
  tips are available as composition bases but are not installed or treated as
  completed maintenance cycles. Only the declared final combined tip enters
  the slow Full CI gate.
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

Every entry is a behavior the fork must keep. Work that adds one writes its
entry in the same change; an unrecorded feature is unfinished work, because a
later cycle reconciles only what this section names.

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

### Session naming

- Name an unnamed interactive session from its first prompt and adopt the
  generated title through the same durable sidecar and index path a manual
  rename uses. The interactive TUI only: `fx ask` and `fx acp` never name.
- Keep the request a bounded one-shot. It carries its own instruction and a
  bounded excerpt of that prompt with mentioned files inlined, and it carries
  no tools, no agent system prompt, no session identity, and no reply beyond
  the length a title needs. It runs off the agent worker, never delays or
  blocks a turn, and stays silent on failure.
- Resolve the naming model and effort per provider from `session_naming`
  settings merged across profile and workspace. Codex compiles in a default;
  a provider whose model does not resolve simply does not name.

### ADE event feed

- Provide the opt-in schema `1` ADE event feed documented in
  `docs/ade-event-feed.md`. An ADE binds a shared POSIX Unix socket and launches
  each interactive Fx TUI with both `FX_ADE_SOCKET_PATH` and its own opaque
  `FX_ADE_INSTANCE_ID`; Fx returns that identity unchanged on every record.
- Publish `FxStarted`, `SessionChanged`, `SessionMetadataChanged`,
  `PromptQueued`, `TurnStarted`, `PreToolUse`, `Stop`, `PostTurnEnd`,
  `AttentionRequired`, `GitRootDiscovered`, and `FxStopped` as
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
- Support optional `FX_ADE_CHECKPOINT_PATH` as an ADE-owned recovery path. Fx
  atomically replaces it at mode 0600 with output-only schema 1 containing
  `schema: 1`, the ADE `instance_id`, a monotonic `revision`, and ordered,
  canonical, deduplicated `git_roots`. Malformed, stale, and identity-mismatched
  prior contents are replaced rather than imported; the process-lifetime set
  survives `/new`, `/resume`, session changes, ADE reconnects, and socket
  unavailability.
- Seed edited-root tracking from the launch directory and add roots after
  successful built-in write, edit, delete, rename, and copy mutations. Add the
  enclosing root of a terminal command's declared resolved working directory
  only when Fx's existing command-effect classifier says `filesystem_write`;
  `terminal start` additionally requires explicit `return_when=exit` and exit
  status zero. Do not infer hidden shell `cd` destinations or arbitrary shell
  side effects.
- Publish each newly deduplicated root as `GitRootDiscovered` with
  `git_root: string`, the in-memory root-set `revision: u64`, and one of
  `launch_directory`, `file_mutation`, `terminal_write`,
  `subagent_file_mutation`, or `subagent_terminal_write`. Child observations
  retain the child session and owning main-session identity while contributing
  to the parent Fx process's ordered set. Treat a regular `.git` marker as a
  linked worktree only after bounded `gitdir:` parsing, canonical resolution,
  and directory validation, and expose the checkout root rather than its
  common Git directory.
- Attempt checkpoint replacement before the corresponding event, but keep both
  operations best-effort: an I/O failure may leave the checkpoint behind the
  in-memory revision and does not suppress the event or tool result. Bound the
  observation queue by record count and owned bytes, drop on pressure, and
  discard queued observations at shutdown; at most one already-started native
  filesystem operation may extend orderly shutdown.

### Native session naming

- For the first admitted prompt of each saved interactive main session, start
  at most one best-effort, nonblocking title request through the active
  provider. Use profile-owned per-provider model, effort, and timeout settings;
  Codex defaults to `gpt-5.4-mini` at low effort.
- Remove a leading slash command and its long flags, expand readable `@path`
  mentions relative to the workspace or home, and send a UTF-8-safe bounded
  excerpt. Install fallback and generated titles through the native `/rename`
  persistence path before publishing `SessionMetadataChanged`; manual rename
  and session changes invalidate stale work.
- Keep automatic naming disabled for `fx ask`, `fx acp`, subagents, and
  disabled or unconfigured providers. Naming must not block agent lifecycle.
  This carry depends on the ADE event feed for live consumer updates.

### Invocation skill roots

- Support repeatable `--skills-dir PATH` and `--skills-dir=PATH` global options
  on interactive, resume, ask, ACP, PR, and issue launches.
- Canonicalize and load invocation roots in flag order before automatically
  discovered roots. Compose them with system-prompt-file options regardless of
  flag order, preserve them across controlled relaunches, and reject unusable
  paths before agent startup.
- Keep invocation skill roots invocation-only. They are never saved and do not
  change the managed skill installation root.

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
maintenance gate. In particular, do not invoke monolithic `zig build test`
with a runner `--test-filter`: Fx's build graph still executes the complete
native suite. Use a narrow Zig harness or target, isolated Bun E2E files, the
ReleaseSafe build, and a real freshly built binary; leave the complete native
and deterministic E2E suites to Full CI. After the focused proofs pass,
refresh `origin/main` and `fork/integration`, compose the final commit, and
publish it once to `fork/integration` with an exact force-with-lease against
the integration tip captured before composition. Publication makes the commit
available as the base for subsequent feature work, but does not authorize
installation or completion of the maintenance cycle.

When several proved carries are queued, batch their publications. The current
owner publishes one exact-leased Integration tip, reports that SHA, and hands
the publication lease directly to the next owner without waiting for Full CI,
the ship gate, or installation. Each successor composes on the exact published
tip it received. Full CI starts automatically for every push; cancel a
superseded intermediate run once its successor is published, and never treat an
intermediate result as gate evidence. Do not cancel the one run selected for
the declared final combined tip, and cancel duplicate same-SHA runs only after
identifying which exact run is the keeper.

Hand the final combined Integration SHA to a standing monitor and stop
occupying the feature-development loop while the slow suite runs. The monitor
owns duplicate cancellation, reruns, and repair-forward work for real failures
and does not finish until one exact-SHA run satisfies current
`~/src/fx/AGENTS.md` guidance and all four `Full suite (...)` aggregates pass. A
stale, superseded, partial, cancelled, skipped, or failed run is not proof.

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
today the Tools panel's rule tab, the tray's agent rows, the surfaces drawn
over the stage, and the unused field around a smaller sizing owner — are
designed from fx's principles and recorded in
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
