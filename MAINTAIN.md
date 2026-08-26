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
- Contribution stance: regular maintenance is downstream-only. We do not open,
  update, support, or preserve upstream pull requests, and we do not wait on
  upstream review. Pull requests #242, #244, #320, and #323 and related issues
  are historical evidence only. A future contribution would require a
  deliberate project decision outside a maintenance cycle.
- Upstream Full CI runs on non-main pushes but normally not on upstream main
  merge commits. Our fork's hosted Full CI therefore remains useful late
  observability across four architectures, not proof that upstream or our
  Integration branch is shippable.
- "Landed" means merged into `vercel-labs/fx:main` and verified against the
  inventory below by reading the code and exercising its path. A carried patch
  is retired only then.

## Branch model

- Mirror branch: `main`, an exact mirror of `vercel-labs/fx:main` locally and on
  the fork. Never an integration base with downstream-only commits.
- Integration branch: `integration`, containing every carried feature together.
  It is the fork's GitHub default branch, the base and merge target for
  downstream development, and the only branch the installer consumes. One
  publication lease serializes exact-leased updates.
- Composition: stable published `carry/<feature>` heads, one per current entry
  in the feature inventory. Develop each carry in its own worktree from current
  Main or a declared carry dependency, then compose every carry into
  Integration. Every published carry head must be an ancestor of published
  Integration. During upstream maintenance, replay each carry on current Main
  or its declared dependency and publish the proved graph under exact leases.
- Publication: standing authorization. Pushing the declared carry heads and
  Integration to `fork` needs no
  per-cycle approval and is not a question to bring to the operator. A green
  Local development gate on the exact Integration composition containing every
  changed carry is the authority that permits it, so an unproved composition is
  never published no matter who asks. This authorizes
  only `fork/integration` and the current declared `fork/carry/*` refs: `origin`
  and all other fork heads stay untouched, and publishing never implies
  installing.
- Deletion marker prefix: `DELETEME/`. Creating, moving, or removing
  `DELETEME/<original-name>` requires an explicit human decision naming the
  branch. Maintenance never infers deletion from branch age, ownership,
  request state, namespace, or absence from the carry inventory. All other
  fork heads remain unchanged.
- Open pull-request heads: not preserved. Requests are historical references,
  and their fork branches are ordinary untouched refs.
- Rerere: relied on. The bound checkout keeps it enabled; a recorded
  resolution is reused when it remains semantically correct and rechecked
  after upstream changes.
- `scripts/reconcile-branches.sh` is this repository's entrypoint to the
  shared namespace script; it declares these values and nothing else.
- `scripts/configure-supervision.sh --install` converges the local-only
  `SUPERVISE.md` and `supervisor.trunk=integration` setting. Supervision keeps
  Fx work visible and may reap clean landed worktrees, but it never integrates
  product branches: a one-trunk fast-forward cannot publish a durable carry and
  the exact Integration composition together.

## Features

Every entry is a behavior the fork must keep. Work that adds one writes its
entry in the same requested unit of work; because the Workshop and Fx are
separate repositories, the specification and implementation land as paired
commits. An unrecorded feature is unfinished work, because a later cycle
reconciles only what this section names. The carry map makes that pairing
explicit; one behavioral entry may need multiple carries, while a requirement
already satisfied by upstream needs none.

| Carry | Feature entry |
| --- | --- |
| `carry/fxnk-version` | Fork identity |
| `carry/system-prompt-files` | System prompts |
| `carry/effort` | Effort |
| `carry/effort-catalog` | Effort |
| `carry/ade-event-feed` | ADE event feed |
| `carry/edited-git-roots` | ADE event feed |
| `carry/session-naming` | Native session naming |
| `carry/libfx-provider-authorization` | Libfx provider authorization |
| `carry/invocation-skill-roots` | Invocation skill roots |
| `carry/external-editor` | External editor support |
| `carry/resume-bounds` | Reliability |
| `carry/local-gate-support` | Local gate support |
| `carry/terminal-probe-determinism` | Terminal probe determinism |
| `carry/hosted-full-ci` | Hosted Full CI |

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
- Publish `FxStarted`, `SessionChanged`, `SessionMetadataChanged`,
  `PromptQueued`, `TurnStarted`, `PreToolUse`, `Stop`, `PostTurnEnd`,
  `AttentionRequired`, `AttentionResolved`, `GitRootDiscovered`, and `FxStopped` as
  newline-delimited JSON. Delivery remains passive, asynchronous, bounded,
  ordered per process, and best-effort, so an absent or slow ADE cannot block
  agent work or shutdown.
- Carry Fx's current semantic snapshot for the record's agent in every schema
  1 context as `agent_state` (`idle`, `working`, or `blocked`) and
  `attention_kind` (`permission`, `question`, `route_recovery`, or null). Derive
  both from one thread-safe reducer keyed independently by the main agent and
  each subagent, so any later record repairs consumer state after an event drop
  or sequence gap. Raise a subagent's `AttentionRequired` for every child
  holding an unresolved approval, not only the one the main approval prompt
  happens to mirror: that prompt shows one child at a time, so an edge on it
  cannot describe a second child blocked at the same instant, and the approval
  registry is the authority for the whole set. The reducer suppresses a child
  already recorded as blocked, so this stays one record per child. Emit `AttentionResolved` with the owning agent working after
  an active user decision is accepted and work can continue.
- The emitter owns its own NDJSON framing invariant and does not trust the
  bytes it is handed. Before splicing caller-supplied tool arguments into a
  record it requires that no raw byte below `0x20` appears inside a string,
  because a raw newline there splits one record across two physical lines, and
  that the whole value parses as JSON, because a malformed value corrupts the
  enclosing record just as surely. Arguments failing either check are replaced
  with `{}` and traced; the record still publishes with everything else intact,
  so one bad tool argument costs its own `arguments` rather than the record or
  the line after it. Do not move this check to the producers and call the
  emitter safe: the integrity flag fx relies on elsewhere defaults to valid and
  is not set on every path that builds tool arguments.
- Install the feed only in the interactive TUI. `fx ask` and `fx acp` publish
  nothing. Do not filter in-process subagents: every main-agent and subagent
  lifecycle record carries its own session identity, child records also carry
  the parent main-session identity, and all records retain the ADE instance
  identity. That parent identity is captured when the child's work is
  admitted rather than read live at emission, for every child record and not
  only discovery: a `/new` or resume landing while a child still runs must not
  reattribute that child's later records to a session which never owned it. A
  caller with no captured identity to offer falls back to the current main
  session.
- Keep the ADE feed and existing Herdr integration as transport-independent
  projections of the shared lifecycle observations. Enabling either must not
  enable, disable, filter, or otherwise change the other. Admit the ADE record
  before any synchronous Herdr report. For a successfully queued prompt, let
  the queue-admission observer return before performing the Herdr report, so
  neither its worker queue mutex nor any reducer or projection lock covers
  Herdr socket I/O or its reply wait. When an interactively presented
  permission, question, or route-recovery decision resolves, Herdr returns to
  working while ADE publishes the attributed `AttentionResolved`. Every surface that
  answers a decision on another agent's behalf publishes that agent's
  resolution: the subagent panel and the mirrored main prompt both route
  through the one observed resolve path, so a child cannot be released without
  its `AttentionResolved`. A denial is an accepted decision and resolves; only
  a stale or rejected submission publishes nothing. Reserve an
  accepted decision with its assigned turn identity and release the waiting
  agent only after that resolution projection returns, so `Stop` and
  `PostTurnEnd` cannot overtake it; stale and rejected decisions publish no
  resolution. That ordering covers an approved relationship too: applying
  the relationship can start the child, so the resolution publishes before the
  continuation runs rather than after it. A continuation that then fails needs
  no compensating record: a retryable failure leaves the approval pending and
  the next sync raises that child's attention again, and a terminal failure
  removes it because the child is genuinely no longer waiting. When orderly turn or process shutdown abandons active attention
  without accepting a decision, publish no synthetic resolution:
  `PostTurnEnd` or `FxStopped` is the terminal closure and clears the snapshot.
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
  excerpt. Normalize the completion to a lowercase hyphenated ASCII slug,
  bounded and re-trimmed, and ask once more when a completion slugs to nothing
  — both attempts spending the admission's single deadline. Install fallback
  and generated titles through the native `/rename` persistence path before
  publishing `SessionMetadataChanged`; manual rename and session changes
  invalidate stale work.
- Keep the request itself a bounded one-shot: its own instruction and that
  excerpt, no tools, no agent system prompt, and no session identity. Freeze
  the captured title once a completed first line or the capture bound settles
  it, then read the stream to its own completion and drop everything after.
  The Codex endpoint rejects a non-streaming request and rejects the Responses
  API output bound, so the capture bound is the only bound available; it
  bounds memory rather than generation, because cancelling the read stops
  neither the tokens already produced nor their billing.
- Keep automatic naming disabled for `fx ask`, `fx acp`, browser and
  WebAssembly hosts, subagents, and disabled or unconfigured providers. Naming
  must not block agent lifecycle.
  This carry depends on the ADE event feed for live consumer updates.

### Libfx provider authorization

- Let native Node `createFxAgent()` accept one tagged `auth` entry or an
  ordered list for Gateway and Codex. The first entry selects the initial
  provider; `env.AI_GATEWAY_API_KEY` remains Gateway shorthand; provider
  switching may select only an authorization the host supplied. Do not compile
  Grok into native libfx.
- Keep Codex credential access explicit. A host may supply a bounded session
  store with opaque load and optimistic revisioned commit operations, or opt
  into the fx profile with `fxProfileSession()`. Never fall back from a custom
  store or an ordinary libfx home to ambient ChatGPT credentials. An explicit
  libfx home also owns profile usage state; do not read or publish that state
  through ambient `HOME`.
- Refresh expired Codex access tokens through the native OAuth transport and
  commit the complete rotated session at the expected revision. Pin an active
  runtime to its selected ChatGPT account and reject a swapped account before
  any refresh request or write-back. Treat conflicts, malformed stores,
  timeouts, cancellation, and stale completions as bounded failures without
  leaking credential bytes or wedging later store operations; quarantine a
  host promise that ignores abort until it actually settles, keep its session
  bytes in a separate scrubbed copy, and close the native runtime on timeout.
- Load the authenticated Codex catalog before native libfx initialization
  succeeds. Select an available Codex model when no model was supplied, reject
  an unavailable explicit model, and fail clearly when the catalog is
  unavailable or has no supported model.
- Keep browser and direct WebAssembly libfx Gateway-only and reject Codex
  authorization before instantiation. Native tools, ACP MCP, background
  processes, Grok, and the native secret store remain unavailable on every
  libfx surface.

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

### Local gate support

- Provide `zig build test-fxnk -Doptimize=ReleaseSafe` as the narrow native
  canary target for every carried behavior. It must not discover or execute the
  complete native suite.
- Keep that canary runner outside `src/`, at `tests/fxnk/runner.zig`. Upstream's
  direct-write audit scans `src/` only, so a downstream harness that prints
  diagnostics belongs beside upstream's own `tests/` Zig support code. Carrying
  an allowlist patch to the audit instead would conflict on a file upstream
  edits continuously.
- Keep the fork's agent guidance aligned with the Workshop-owned Local
  development gate, Integration workflow, and downstream-only contribution
  stance.
- The canary inventory is declared twice and the two must stay identical:
  `build.zig`'s `filters` list decides which tests compile into the narrow
  root, and `tests/fxnk/runner.zig` holds the exact expected names. A name in
  one and not the other fails the gate loudly, which is the point: an upstream
  rebase that drops or renames a carry's test cannot pass in silence.
- Gate the ADE lifecycle reducer itself, not only the serialized wire shape.
  The narrow root imports `src/builtins/hooks/lifecycle_state.zig` so the
  reducer's own canaries run: a non-null `attention_kind` pairs only with
  `blocked`, each agent's snapshot stays independent, and a resolution applies
  only against a matching kind. A consumer rejects a whole record whose
  snapshot breaks that pairing, so it is a wire invariant rather than internal
  tidiness. Gate alongside it that a subagent record carries the child's own
  snapshot rather than the main agent's, and that `sequence` advances through
  both the oversized-record and full-queue drop paths, because "a gap means a
  drop" is what makes the feed's recovery story true.

### Terminal probe determinism

- Recognize a Ctrl-X input frame in both encodings a terminal may send: the C0
  control byte `0x18`, and the CSI-u disambiguated form `ESC [ 120 ; 5 u` that
  a negotiated keyboard protocol produces. Matching only the C0 byte makes a
  correctly recorded handoff read as a missing one, constantly rather than
  intermittently, wherever the richer protocol is active.
- Assert on a settled recording. A tape is complete once fx exits, so a probe
  quits fx and waits for the writing process to leave the process table before
  reading it once. Position markers may come from the live tape through
  `readLiveTapeFrames`, whose name carries that distinction; assertions may
  not. Wait on the process that wrote the file rather than on tmux tearing the
  session down, because the pane shell and server can outlive fx.
- Keep the macOS-arm64 quarantine free of assertion-shaped signatures. Only
  runtime timeouts from tmux teardown and pane predicates may be excused; an
  assertion that fails on that surface blocks and is read as a defect. A
  retry loop that spends its whole budget re-reading evidence it already has
  is a disguised constant failure, not tolerance for flakiness.

### Hosted Full CI

- Start the fork's hosted Full CI only for the Integration branch and manual
  dispatch. No other fork head, quarantine included, may trigger a run.
- Serialize the workflow into one constant concurrency group with in-progress
  cancellation, so at most one suite runs across the whole fork and a newer
  Integration tip cancels the run in flight. Only the current tip's verdict is
  worth waiting for, and a suite that never completes under sustained churn is
  an accepted cost because Full CI gates nothing.

## Gate

The Local development gate is the only blocking test authority. Run focused
checks from each changed carry worktree, compose all current carry heads into a
clean candidate, then run the gate from that exact composition worktree before
publishing any affected carry:

```sh
~/code/fxnk/scripts/local-gate.sh --worktree "$composition_worktree"
```

The gate runs formatting, the public-surface audit, and upstream's direct-write
audit, builds ReleaseSafe, executes the narrow `test-fxnk` native target, runs
focused CLI and ADE integration tests, and exercises the fresh binary. It also runs bounded probes
from the known fragile macOS-arm64 terminal surface. A green probe passes; a
failure is quarantined only when its file and harness blobs still match
`gate/macos-arm64-quarantine.json` and every failure has a declared normalized
signature. A changed blob, undeclared file, assertion, error, or signature
blocks and requires explicit review. This keeps upstream fragility from gating
our work without turning that surface into untested code.

Do not run monolithic `zig build test` or the complete deterministic E2E suite
as a local gate. Full CI is nonblocking observability: it may finish after we
ship, and neither its success nor its failure authorizes or prevents shipping.
It must still eventually reach a verdict. `scripts/ci-watch.sh` records one
verdict per published Integration SHA under `~/.local/state/fxnk/full-ci/` and
escalates a real failure or an overdue verdict to the human. It also reports
once a day when nothing has happened, so a silent watcher reads as broken
rather than as good news. Read
`~/.local/state/fxnk/full-ci/pending.json` at the start of every cycle: an open
obligation there, or `overdue: true`, is work for this cycle, not a status
note. A verdict it could not classify escalates rather than guessing, so an
`unclassified` obligation means read the run, not distrust the watcher. The watcher polls
from launchd, bound once with:

```sh
~/code/fxnk/scripts/ci-watch-install.sh --install
```

The authoritative platform is macOS arm64 because it is the installed consumer
platform; the explicit quarantine prevents chronic upstream terminal failures
on that same platform from swallowing new failures.

After merging the proved feature commit into the final Integration worktree,
rerun the gate with `--record` on the clean exact Integration SHA:

```sh
~/code/fxnk/scripts/local-gate.sh \
  --worktree "$integration_worktree" \
  --record
```

The record is an atomic mode-0600 JSON receipt under
`~/.local/state/fxnk/local-gates/`, bound to the Fx SHA, tracked upstream SHA,
platform, gate-contract digest, quarantine outcomes, and duration. Publish that
exact Integration commit once with the lease captured before refresh. Then run
the project-owned ship gate; it re-reads the remote Integration branch,
refreshes current upstream, validates the exact-SHA receipt and current
contract, and prints `SHIP <sha>` only when every local, remote, receipt, and
upstream identity still agrees:

```sh
~/code/fxnk/scripts/ship-gate.sh \
  --worktree "$integration_worktree" \
  --branch integration \
  --sha "$integration_sha"
```

## Consumer

The installer. Only after the local receipt and ship gate pass for the
still-published Integration SHA, run:

```sh
~/code/fxnk/scripts/install.sh --install --sha "$integration_sha"
```

It proves any existing local integration tip from the installed commit receipt
(or the pre-fetch remote-tracking ref on a first install), builds the published
commit ReleaseSafe in a detached temporary worktree, and only then rebinds the
clean checkout and atomically replaces the binary and receipts under
`~/.local/state/fxnk`, with Fx's `auto_upgrade` set to `false`. It does not
rebase, push, inspect requests, or decide which patches are carried. Never edit
the installed binary or live receipts by hand; rerun the installer.

AgentStart is Fx's consumer and pins that approved SHA rather than following a
moving Integration ref. The maintenance cycle is not complete until it advances
`fx_integration_sha` in `~/code/agentstart/scripts/install.sh`, updates the
matching plan, validation, and fleet-map facts in that checkout, and proves the
handoff with:

```sh
~/code/agentstart/tests/validate.sh
~/code/agentstart/scripts/install.sh --install
```

Then compare the installed `collab` manifest with agentguidance's source
template as AgentStart's own guidance requires. A published and installed Fx
commit with AgentStart still pinned to the prior Integration SHA is unfinished:
the next machine convergence will correctly reject that stale consumer pin.

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

Carve-outs are the one part of the guide that is not extracted. Surfaces fmx
needs and fx never draws — today the tray's agent rows, surfaces drawn over
the stage, and the unused field around a smaller sizing owner — are designed
from fx's principles and recorded in
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
