# fxnk context

**Workshop** — This repository, which owns the specification (`MAINTAIN.md`),
maintenance state, and installer for the local Fx fork; the maintenance
procedure itself is the shared `maintain` skill, which every workshop runs.
_Avoid_: wrapper, patch repo.

**Integration branch** — `possibilities/fx:integration`, containing every
carried feature, serving as the fork's default development branch, and
remaining the only source the installer builds.
_Avoid_: install branch, local main.

**Main mirror** — Local `main` and `possibilities/fx:main`, both fast-forwarded
to the exact current `vercel-labs/fx:main` during every maintenance cycle.
_Avoid_: integration base, development main.

**Carried feature** — Behavior required by `MAINTAIN.md` that is not yet
available in a suitable upstream form and therefore remains implemented on the
integration branch.
_Avoid_: permanent patch, downstream fix.

**Historical upstream reference** — An upstream pull request, issue, or commit
that explains a carried feature or may later replace it. It is evidence only.
The Workshop does not update, support, or preserve a request branch and never
depends on upstream action.
_Avoid_: active contribution, maintained PR, open offer.

**Carry branch** — A durable published `carry/<feature>` head containing one
current downstream behavior, based on Main or a declared carry dependency and
composed into Integration. Its name remains stable across upstream refreshes.
_Avoid_: patch branch, PR branch, temporary feature branch.

**DELETEME branch** — An explicit human marker at
`DELETEME/<original-name>` recording a decision to remove that named fork
branch. Maintenance never creates the marker by heuristic and never treats an
unknown branch as deletion intent.
_Avoid_: quarantine branch, stale branch, automatic archive.

**Maintenance cycle** — One `/maintain` run that reviews upstream movement and
historical references, reconciles every carried feature, passes the Local
development gate, publishes Integration, updates the scratchpad, and installs
the published result.
_Avoid_: update, install.

**Local development gate** — The macOS-arm64 proof owned by this Workshop and
run from an Fx worktree. It combines a ReleaseSafe build, narrow carried-unit
canaries, focused deterministic integration tests, fresh-binary probes, and an
explicit upstream terminal quarantine; it is the only blocking test authority.
_Avoid_: carve-out, Full CI, smoke test.

**Gate receipt** — A mode-0600 atomic JSON record proving that one exact Fx SHA
passed the current Local development gate contract against one exact upstream
revision. A changed gate or quarantine contract invalidates an older receipt.
_Avoid_: CI result, approval, mutable status.

**Installer** — `scripts/install.sh`, which only converges the published
integration branch into a ReleaseSafe binary on the system path.
_Avoid_: maintainer, updater.

**fmx Fx source pin** — The exact published Integration commit in fmx's
`fx.json`. Fmx's own source installer builds it as the private `fmx-fx` and
never replaces the separate `fx` binary the Workshop Installer manages.
_Avoid_: binary release, Fx installer, moving latest.

**Supervision policy** — fxnk's tracked `supervision/SUPERVISE.md`, installed
locally into the upstream checkout with `supervisor.trunk=integration`. It keeps
Fx work visible to `supervise` while routing product integration to the
carry/composition workflow.
_Avoid_: repository documentation, supervisor integration recipe.

**Provider authorization** — One tagged libfx `auth` entry, or an ordered list
of entries, that supplies the credential authority for each enabled provider;
the first entry selects the initial provider and later switching remains inside
that set.
_Avoid_: provider option, ambient credential fallback.

**Launch controls** — Orthogonal global Fx CLI options that define an
interactive TUI or ACP process's model-visible context, native tools, skill
roots, permission policy, MCP admission, and state root. A control applies to
both surfaces whenever the underlying capability exists on both; an ACP-only
control names a protocol-specific boundary. Role-specific launch commands
compose these primitives outside Fx; Fx does not encode orchestrator or player
roles.
_Avoid_: agent profile, ACP mode, prompt preset.

**State system prompt** — An optional conventional prompt file in the selected
state root: `.fx/SYSTEM.md` replaces Fx's built-in system prompt, while
`.fx/SYSTEM_APPEND.md` appends to it. It is part of an explicit `--state-dir`
launch and remains distinct from profile or project instructions.
_Avoid_: profile instructions, state instructions, prompt preset.

**ADE event feed** — Fx's opt-in, versioned, best-effort NDJSON lifecycle
stream from an interactive TUI and its in-process agents to an ADE-owned Unix
socket. The ADE supplies the socket and an opaque instance identity; Fx
supplies agent and session context without presentation policy.
_Avoid_: Herdr feed, control socket, ask feed.

**Work-control endpoint** — Fx's opt-in, authenticated Unix request/reply
surface for one interactive main Agent's semantic queue, steering, and
interruption operations. Fx owns scheduling and race resolution; the host
supplies the endpoint identity and authority, while ADE remains a separate
one-way lifecycle feed.
_Avoid_: ADE control, terminal injection, prompt socket, public API.

**Launch-admission boundary** — Fx's distinct versioned, role-neutral local
contract for exact native launch metadata, caller-keyed initial semantic
admission or pre-start cancellation, and acknowledged final process receipts.
It reuses native Work-control admission semantics without changing the
Work-control schema or assigning lifecycle meaning to an opaque caller key.
_Avoid_: Work-control v2, fmx lifecycle, Worker launch protocol.

**Structured subscription inference** — Fx's versioned local one-shot boundary
for tool-free Codex-subscription inference using an exact catalog model and
effort, caller key, and output schema. It creates no Agent or Conversation and
contains no caller-specific product policy.
_Avoid_: libfx, headless agent, direct inference mode.

**Full CI verdict** — The recorded outcome of one hosted Full CI run for one
exact published Integration SHA, written by `scripts/ci-watch.sh` under
`~/.local/state/fxnk/full-ci/`. It is evidence that the slow suite eventually
ran; it never authorizes or prevents shipping.
_Avoid_: gate result, approval, receipt.

**Deferred verdict** — A published Integration SHA that has no completed Full
CI verdict yet, because the suite is still running, was cancelled by a newer
publication, or never started. Deferred is normal; overdue is escalated.
_Avoid_: pending gate, blocked ship.

**Carve-out** — a surface an fxnk-based host needs that fx never draws (a tray
row, a modal, or unused Client space), designed from fx's principles and recorded in
`style/STYLE.md`
§ "Carve-outs", with the viewer rendering it from ramp tokens. It is not
extracted, invisible to `style-extract.sh --check`, and never reconciled
toward fx; a maintenance cycle revisits one only if upstream grows the
surface.
_Avoid_: exception, override, host theme.
