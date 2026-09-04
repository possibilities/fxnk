# Fx fork maintenance

This repository delivers and maintains our local fork of
[`vercel-labs/fx`](https://github.com/vercel-labs/fx). It owns the behavior we
want independently of upstream review or publication while continuously
rebuilding that behavior on one captured upstream Fx snapshot per cycle.
`/maintain` — the shared
`maintain` skill — runs a maintenance cycle from this file; this file is the
whole of what that skill knows about Fx.

## Purpose

Keep a published `integration` branch of Fx that carries every feature below,
rebuilt on the cycle's once-captured upstream target, and installed on this
machine by this repository's own installer. The fork is not a place to develop Fx in general:
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
- Maintenance target: one `/maintain` invocation captures the upstream Main
  SHA once before fetching and binds the entire audit, replay, gate,
  publication, and final reconciliation to that exact commit. Never refetch or
  rebase onto an upstream advance during the same invocation; any later tip is
  work for the next maintenance cycle.
- Integration branch: `integration`, containing every carried feature together.
  It is the fork's GitHub default branch, the base and merge target for
  downstream development, and the only branch the installer consumes. One
  publication lease serializes exact-leased updates.
- Composition: stable published `carry/<feature>` heads, one per current entry
  in the feature inventory. Develop each carry in its own worktree from the
  cycle's captured Main or a declared carry dependency, then compose every
  carry into Integration. Every published carry head must be an ancestor of
  published Integration. During upstream maintenance, replay each carry on
  the cycle's captured Main or its declared dependency and publish the proved
  graph under exact leases.
- Publication: standing authorization. Pushing the declared carry heads and
  Integration to `fork` needs no
  per-cycle approval and is not a question to bring to the operator. A green
  Local development gate on the exact Integration composition containing every
  changed carry is the authority that permits it, so an unproved composition is
  never published no matter who asks. This authorizes
  only `fork/integration` and the current declared `fork/carry/*` refs: `origin`
  and all other fork heads stay untouched.
- Installation: immediate, and not a second decision. Work merged to
  Integration is installed as part of landing it — run
  `scripts/install.sh --install --sha <published sha>` without asking, because
  the gate that permitted publication is the whole quality bar and a second
  approval adds a step without adding assurance. A published Integration this
  machine is not running is the drift this repository exists to prevent. In the
  operator's vocabulary "build" and "install" both name that one command, which
  aligns the checkout, builds ReleaseSafe, and installs atomically. A consumer's
  own pin — AgentStart's `fx_integration_sha`, for instance — is a separate
  release act and moves only when that consumer's release says so.
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
  `SUPERVISE.md` policy file, and
  `scripts/reconcile-branches.sh --configure-supervision` converges this model
  into the checkout's own `supervisor.*` git config, which is where advisory
  tools read it — `/tend` judges a worktree against Integration and never
  proposes removing a carry head's worktree. That config is derived state, not
  a second declaration: `--check-supervision` verifies it, and that this
  section still names these branches. Supervision keeps
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

Launch controls are global and apply to fresh interactive TUI launches, TUI
resume and controlled relaunch paths, and ACP whenever the controlled
capability exists on those surfaces. A feature requested through ACP is not
ACP-scoped by default. An ACP-only control must name its protocol-specific
boundary; `--no-acp-mcp` is one because only an ACP client supplies ACP MCP
servers.

| Carry | Feature entry |
| --- | --- |
| `carry/fxnk-version` | Fork identity |
| `carry/system-prompt-files` | System prompts |
| `carry/effort` | Effort |
| `carry/effort-catalog` | Effort |
| `carry/ade-event-feed` | ADE event feed |
| `carry/fmx-work-control` | Semantic work control |
| `carry/edited-git-roots` | ADE event feed |
| `carry/session-naming` | Native session naming |
| `carry/structured-inference` | Structured subscription inference |
| `carry/libfx-provider-authorization` | Libfx provider authorization |
| `carry/codex-credential-authority` | Codex credential authority |
| `carry/acp-voice-control` | ACP voice control |
| `carry/invocation-skill-roots` | Invocation skill roots |
| `carry/external-editor` | External editor support |
| `carry/notification-sound-single-flight` | Notification sound availability |
| `carry/resume-bounds` | Reliability |
| `carry/local-gate-support` | Local gate support |
| `carry/terminal-probe-determinism` | Terminal probe determinism |
| `carry/hosted-full-ci` | Hosted Full CI |
| `carry/fmx-distribution` | Hosted Full CI |
| `carry/acp-capability-gates` | Launch capability gates |
| `carry/acp-tool-selection` | Native-tool selection |
| `carry/exclusive-skill-roots` | Exclusive skill roots |
| `carry/acp-project-instructions` | Project instructions |
| `carry/acp-permission-policy` | Launch permission policy |
| `carry/acp-state-isolation` | State isolation |
| `carry/launch-control-continuity` | Launch-control continuity |
| `carry/state-auth-borrowing` | State isolation |
| `carry/state-system-prompts` | State system prompts |
| `carry/agent-shape-sessions` | Agent shape and session provenance |

### Fork identity

- Support the intentionally undocumented `--fxnk-version` consumer probe. It
  exits zero with empty stderr and one exact stdout line in the form
  `fxnk <fxnk-version> (fx <fx-version>)`. The independent fxnk version follows
  semantic versioning for downstream consumer compatibility; the Fx version
  remains the current upstream source version.

### System prompts

- Support `--append-system-prompt-file` and `--system-prompt-file` for appending
  to and replacing the system prompt.

### Launch capability gates

- Support global `--no-native-tools` on interactive TUI and ACP launches. The
  empty set is authoritative for both model advertisement and dispatch;
  neither the main session nor an in-process child may recover the built-in
  default set.
- Let `fx acp --no-acp-mcp` refuse client-supplied `mcpServers` before any MCP
  process starts. This control is ACP-only because an interactive TUI has no
  client-supplied ACP MCP configuration. Keep native-tool and ACP-MCP admission
  independent.

### Native-tool selection

- `carry/acp-tool-selection` depends on `carry/acp-capability-gates`, which
  owns the shared native-tool suppression boundary and launch grammar.
- Support repeatable global `--tool NAME` on interactive TUI and ACP launches.
  Supplying no `--tool` preserves the complete current native set; the first
  occurrence switches the process to an allowlist. Reject unknown selections
  at startup and apply the resolved set to both tool advertisement and dispatch
  for the main session and every in-process child. Reject combining any
  `--tool` selection with `--no-native-tools`.
- One test in that file is pending under nonblocking Full CI: "ACP native
  tool selection narrows schema and rejects terminal session actions before
  permission". Its advertisement and refusal halves pass, so the narrowed
  schema and the session-action refusal are proved. It stops where an admitted
  one-shot run stalls instead of executing. Two causes were found and fixed on
  the way there, both the same blind spot: the terminal lease tracker and
  command admission each read only a flat `action` and never looked inside a
  wrapped `request`, so a narrowed call wedged the turn and was denied command
  authority. What remains is a third stall past admission, not a fixture
  problem, and the gap reaches only this selection.
- `tests/e2e/acp.test.ts` owns this carry's end-to-end proof. An earlier
  replay fused its two subagent tests into one `test(` call with two name
  strings and orphaned the upstream body, which stopped the whole file
  parsing; the gate never runs that file, so nothing caught it. Upstream's
  cancellation test is restored verbatim beside the carry's own
  native-tool propagation test. A replay that touches this file re-checks that
  it still parses.
- Treat `terminal:exec` as the one-shot specification of upstream's shell tool
  rather than its interactive surface. Upstream renamed the tool from
  `terminal` to `shell` and now advertises it to the model under that name, so
  no alias work remains there; the selector keeps its `terminal:exec` spelling,
  and there is deliberately no `shell:exec` spelling. Advertise only the
  bounded `request.action = "run"` shape, narrower than upstream's own
  process-only specification, which also admits `interact` and `stop`.
  Preserve that exact command authority whether the model-facing request is
  still wrapped or has already been normalized for internal dispatch, and
  enforce it at dispatch as well as in advertisement: a run that is still
  running when the tool returns is stopped rather than retained. A role that
  selects it may execute permission-admitted one-shot commands but cannot
  start, observe, write to, stop, or otherwise acquire or retain an
  interactive shell session.

### Current upstream managed-subagent contract

- Compose upstream's model-safe `subagent` surface without reopening its
  internal control schema. The model receives only one wrapped request with
  `run`, `wait`, `send`, or `stop`; `run` accepts a task plus optional exact
  model and effort, returns the model-facing child handle, and Fx owns child
  naming, persistence, inspection bounds, relationship state, notifications,
  permissions, and lifecycle translation. The reversible compact handle is a
  presentation boundary, not a second child identity.
- Preserve the fork's ADE, permission, and work-control authorities across
  that upstream change. Managed children still publish their exact durable
  session and owning-main attribution to ADE, and automatic review remains
  scoped to the exact action, targets, origin, bounded masked prior results,
  and canonical root-request context. Neither a task string nor the compact
  handle widens execution authority.

### Exclusive skill roots

- Support global `--no-default-skills` alongside repeatable `--skills-dir`.
  Apply the policy to interactive TUI and ACP launches. When selected, discover
  skills only from the invocation roots in flag order; do not scan workspace,
  managed-profile, or compatibility roots. An empty invocation list
  intentionally produces no skill catalog.
- Keep the option invocation-only. It does not mutate managed skill storage,
  and controlled relaunches preserve the same exclusive-root policy.

### Project instructions

- Support global `--no-project-instructions` on interactive TUI and ACP
  launches. It suppresses repository instruction-file discovery and
  model-visible project prose for that process while retaining current runtime
  facts such as working directory, date, Git state, tool guidance, and
  permission guidance.
- Keep the launch option distinct from stored project `context` configuration:
  it does not rewrite workspace settings and cannot be reopened by an
  `AGENTS.md`, `CLAUDE.md`, or compatible instruction file below the launch
  directory.

### Launch permission policy

- Support global `--permissions-file FILE` on interactive TUI and ACP launches.
  Load the existing permission-rule JSON shape before agent startup.
  Canonicalize the file path, reject unreadable or malformed policy, and use
  its rules as the process's configured permission policy instead of ambient
  profile, workspace, or project permission rules.
- Preserve Fx's ordinary per-session exact-grant semantics without allowing a
  saved grant to override a launch-policy deny. Command rules retain the
  existing static parse requirement, so compound shell syntax does not inherit
  a simple-command allow.

### State isolation

- `carry/state-auth-borrowing` depends on `carry/acp-state-isolation`: the
  borrowed credential is only meaningful beside a selected state root. It
  declares its narrow canaries on `carry/local-gate-support`, which owns the
  gate inventory.
- Support global `--state-dir DIR` on interactive TUI and ACP launches. It
  selects the Fx profile/state root for that process, covering settings,
  authorization, profile-level instructions, managed and profile-global
  skills, MCP configuration and credentials, memories, prompt history and
  usage, and durable sessions. Canonicalize and validate the root before agent
  startup; session discovery and resume may not cross into the default or
  another selected state root.
- Do not implement state isolation by changing the process or subprocess
  `HOME`. Shell commands and MCP processes retain the operator's normal home
  environment. Workspace instruction and skill discovery retains that real
  home boundary while profile-global discovery uses the selected root.
- Keep workspace, selected-profile, and invocation skill roots as separate
  authorities during discovery and refresh. Workspace ancestor skills always
  resolve against the real workspace home, profile-global skills always
  resolve against the selected state profile, and ordered invocation roots
  remain visible without allowing either home to leak globals into the other.
- Let an explicit selected-state launch set `FX_AUTH_READ_ONLY_HOME` to one
  canonical existing Fx profile home. Fx borrows only an already-valid saved
  provider credential from that profile at startup; it never copies, refreshes,
  deletes, or replaces credential bytes there. Settings, provider/model choice,
  instructions, skills, MCP state, memories, history, usage, and sessions stay
  rooted beneath `--state-dir`, and authentication actions continue to target
  that selected state root. Reject the override without `--state-dir`, reject
  noncanonical or unusable paths, and leave the ordinary isolated behavior
  unchanged when the variable is absent.
- Support `FX_PROVIDER=gateway|codex|grok` as a process-only provider selection
  override paired with existing `FX_MODEL` and `FX_EFFORT` overrides. The
  Codex and Grok providers must have an explicit process model or a model in
  the selected state profile; Gateway retains its compiled default. Invalid or
  empty provider values fail before Agent startup. This does not import
  provider or model preferences from a borrowed authorization profile.

### State system prompts

- `carry/state-system-prompts` depends on both
  `carry/launch-control-continuity` and `carry/local-gate-support`: the former
  composes the shared prompt-file and state-root launch controls, while the
  latter supplies the narrow downstream canary contract.
- For an explicit `--state-dir DIR` launch, recognize the exact case-sensitive
  conventional files `<DIR>/.fx/SYSTEM.md` and
  `<DIR>/.fx/SYSTEM_APPEND.md`. `SYSTEM.md` replaces Fx's built-in system
  prompt; `SYSTEM_APPEND.md` appends to it with the same blank-line separation
  as `--append-system-prompt-file`. Apply the result to interactive TUI,
  resume, and ACP main agents and their in-process children. Do not discover
  either convention from the ambient/default home when `--state-dir` is
  absent.
- Keep explicit invocation controls authoritative. `--system-prompt-file`
  bypasses state prompt discovery entirely, while each
  `--append-system-prompt-file` appends after the state-derived prompt. When
  discovery is active, fail before agent or MCP startup if both conventional
  names exist rather than choosing one implicitly.
- Apply the existing regular-file, readable UTF-8, NUL-free, and combined
  256 KiB custom-prompt limits across every active state and invocation file.
  `--no-project-instructions` does not suppress a state system prompt, and a
  controlled relaunch or resume re-reads it through the preserved state root.

### Agent shape and session provenance

- `carry/agent-shape-sessions` depends on `carry/state-system-prompts`, which
  supplies the composed launch controls, state-root conventions, and focused
  gate support this behavior separates into explicit authorities.
- Treat the agent's shape, credential identity, and writable history as three
  independent launch axes on interactive TUI, resume, ask, and ACP launches.
  `--state-dir DIR` continues to select all three together. `--shape DIR`
  selects only the prompt, skills, MCP configuration, native-tool selection,
  permission policy, and project-instruction inputs that define behavior;
  `--identity DIR` selects only an already-valid saved provider credential;
  and `--history-dir DIR` selects only durable sessions, prompt history, and
  profile usage. Canonicalize every selected directory before startup and do
  not change the process or subprocess `HOME`.
- A shape root uses its conventional `.fx/SYSTEM.md` or
  `.fx/SYSTEM_APPEND.md`, its `.fx/skills` directory as an ordered invocation
  root, and its `.fx/mcp.json` when present. An explicit `--mcp-config FILE`
  selects one canonical regular MCP configuration file and wins over that
  convention without moving MCP credentials out of the identity/profile
  authority. Existing explicit prompt and skill options retain their current
  precedence, exclusivity, and invocation-only behavior.
- `--identity DIR` is an explicit operator selection and may stand without
  `--state-dir`, but it borrows the selected profile under the same read-only
  credential contract as `FX_AUTH_READ_ONLY_HOME`: never copy, refresh,
  delete, or replace bytes there. Keep the environment form's existing
  `--state-dir` precondition, and reject a launch that names both authorities
  instead of silently choosing an account.
- Derive a non-secret SHA-256 shape identity from the fully resolved launch
  declaration: prompt text by content; skill roots, MCP configuration, and
  permission policy by canonical path; selected tools; and the boolean launch
  suppressions. Pair it with a bounded UTF-8 display label, while treating the
  digest rather than that mutable prose as the authority.
- Stamp new durable sessions, turn authority, and usage generations with the
  shape identity and label plus the existing non-secret credential source and
  credential identity. Keep old sessions readable, preserve the trailing-key
  and exact-variant compatibility rules, reject malformed digests or a
  credential identity without its source, and never place an access token,
  refresh token, API key, or serialized credential in provenance. Session
  listings and usage grouping must make shape and account provenance visible
  without changing the history root that owns those records.

### Launch-control continuity

- `carry/launch-control-continuity` depends on
  `carry/system-prompt-files`, `carry/invocation-skill-roots`,
  `carry/acp-capability-gates`, `carry/acp-tool-selection`,
  `carry/exclusive-skill-roots`, `carry/acp-project-instructions`,
  `carry/acp-permission-policy`, and `carry/acp-state-isolation`.
- Preserve every selected global launch control when an interactive TUI
  upgrades, replaces itself, and resumes its session. This includes prompt,
  context, directory, native-tool, skill-root, project-instruction,
  permission-policy, and state-root controls. If process replacement fails,
  print a shell-safe recovery command that preserves the same selections.
- The fork previously carried the private `fx.private-launch-provider`
  boundary, in schema 1 and in a schema 2 that added `resume_status`. Both are
  retired; the fork carries no launch provider, and nothing replaces it.
- The fork also used to carry `--record` through upgrade relaunch, rebuilding
  the flag into the replacement invocation so an active terminal recording
  survived the restart. Upstream has internalized terminal recording, so
  `--record` is no longer a launch control and `InteractiveLaunch` no longer
  carries it. The fork no longer carries that relaunch plumbing, and the
  recovery command it printed no longer names the flag.

### Effort

- Support `FX_EFFORT` with parity to `FX_MODEL`, and support
  `fx acp --effort` alongside `fx acp --model`.
- Include supported efforts in the model catalog and structured surfaces such
  as `fx models --json`, so an ADE can present valid models and efforts for each
  provider.

### ADE event feed

- The E2E fixture's scope ends at the feed itself. It drives one main turn, a
  question, a subagent turn with a permission answered on the mirrored main
  prompt, and both agents' completion, then asserts session discovery on disk:
  parent and child both persist and the parent is the session holding the child
  registry, which is what keeps a child private to it. It deliberately does not
  drive the resume picker, whose semantics belong to upstream, and it does not
  wait for a child's own text in the parent pane, because upstream renders a
  child there as a tool-call summary.

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

### Semantic work control

- Let a native interactive Fx opt into one private Unix work-control endpoint
  through a complete host-supplied socket path, instance identity, and bearer
  token. Bind the endpoint mode 0600, authenticate every bounded schema-1
  request, echo the instance identity in every response, and remove only the
  socket Fx itself bound. A partial configuration or a configured endpoint that
  cannot bind fails startup; an unconfigured Fx has no listener.
- Accept one request and return one correlated response per connection. Keep
  socket reads, writes, peers, frames, and outstanding application work bounded
  so a silent or malformed controller never delays the terminal, the model
  worker, shutdown, or another Fx process.
- Expose only the main Agent's semantic work operations: inspect the active
  turn identity and admission-ordered prompt queue; queue text work; steer the
  active turn with Fx's safe queue fallback; cooperatively interrupt the active
  turn and pause queued work for review; update or delete one queued item by
  stable turn identity; and resume a paused queue from its head. Return the
  authoritative post-operation snapshot with every successful mutation.
- Route queueing and steering through the same prompt admission path as native
  interactive submission, with an explicit empty image and skill set rather
  than borrowing composer state. Preserve Fx's one FIFO and steering race:
  steering targets the active turn when possible and demotes in place to
  ordinary queued work when that turn wins the race.
- Do not expose permission decisions, question answers, session transitions,
  subagent control, runtime settings, queue reordering, arbitrary-item start,
  or a second prompt execution path. Reject mutation while the human's queue
  editor is visible, and reject text replacement for queued work carrying
  images, skill bindings, or an editable native review draft.
- Keep work control independent of the ADE event feed. Command replies are
  reliable acknowledgements of native state changes; ADE remains passive,
  best-effort lifecycle telemetry and cannot become a command transport.
- Preserve the existing authenticated Work-control schema 1 unchanged. The
  fork previously also carried a distinct `fx.launch-admission-final`
  boundary for coordinated native launches, with a durable admission and
  pre-start cancellation decision and a retained final receipt. That boundary
  is retired; work control exposes no launch admission or receipt surface.

### Native session naming

- The fork previously accepted an explicit `--name` display name on a native
  interactive launch, resume, and controlled relaunch. That launch control is
  retired. Session names are set by `/rename` and by automatic generation
  only, and the fork carries no launch-time naming flag. The retirement took
  that flag's E2E fixture with it, so the local gate's `ade-integration` step
  now expects three tests in `tests/e2e/ade-event-feed.test.ts`, not four.
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
  This carry keeps `carry/ade-event-feed` as its branch dependency for live
  consumer updates. Exact relaunch and recovery conformance is an Integration
  composition invariant with the separate `carry/launch-control-continuity`
  head; do not fold that carry into the session-naming head. The composed
  provider conformance covers `/new` followed by exact resume, directory
  rebinding, selected-state-root isolation, immutable launch-control
  reapplication, and explicit-name non-leakage without inventing a second
  resume implementation.

### Structured subscription inference

- `carry/structured-inference` depends on `carry/hosted-full-ci` and no product
  carry. Use the ordinary native Fx profile's Codex subscription credentials,
  native OAuth refresh, authenticated model catalog, strict Responses schema
  transport, and local JSON Schema validation; do not route through libfx,
  NAPI, an interactive App, or an Agent loop.
- Expose one versioned local request boundary that accepts an exact catalog
  model and supported effort, prompt, object output schema, caller key, and
  cancellation. Admit only an exact pair from the authenticated catalog, make
  one tool-free provider request with no session identity, locally validate
  the result, and return the value with credential/catalog/provider provenance
  and an idempotent terminal receipt.
- Same-key retries replay the terminal receipt, conflicting reuse is rejected,
  and recovery preserves completed, cancelled, refused, and provider-failed
  outcomes across a lost response or process restart until acknowledgement.
  Cancellation before provider admission wins durably; after admission it is
  best effort and the authoritative provider outcome wins.
- Never advertise or dispatch tools, start MCP or background work, create an
  interactive Conversation or session directory, create a Worktree, or expose
  Workplace policy. This narrow Core/native-executable primitive is not libfx,
  generic headless Agent execution, or the later Manager-facing direct-
  inference product mode.

### Libfx provider authorization

- Let native Node `createFxAgent()` accept one tagged `auth` entry or an
  ordered list for Gateway and Codex. The first entry selects the initial
  provider; provider switching may select only an authorization the host
  supplied. Do not compile Grok into native libfx.
- libfx takes upstream's flat `apiKey` and `model` options. Upstream 49fc251a
  made `createFxAgent()` refuse `env` outright and routed native agents through
  the same option validation as WebAssembly ones, so `env.AI_GATEWAY_API_KEY`
  is no longer Gateway shorthand. Translate a tagged `auth` entry into those
  flat options before upstream's guard runs. Keep native Gateway and Codex
  behind one public Agent instance with `prompt()`, `checkpoint()`,
  `setConfig()`, `configOptions`, and `close()`; expose only host-supplied
  providers for switching, and do not restore the retired public sub-session
  API. Browser and direct WebAssembly agents remain Gateway-only.
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

### Codex credential authority

- `carry/codex-credential-authority` depends on
  `carry/libfx-provider-authorization`, which owns the fork's Codex
  session-store and account-pinning behavior. Its consumer is AgentVoice,
  whose voice sidecar holds no login, credential store, ambient key, or
  refresh token and receives bounded runtime leases from Fx alone.
- Support global `--codex-credential-fd <n>` on interactive TUI, resume, and
  ACP launches, and reject it on every other command. Activation is
  all-or-none: with the flag the broker is serving before any other startup
  callback runs and before `fx acp` answers `initialize`, or the launch fails.
  Without it nothing is exposed. The descriptor number is the only capability
  in argv, and the channel appears in no environment variable, log, telemetry
  record, crash output, or generic JSON-RPC surface. Standard input, output,
  and error are never accepted. Fx sets close-on-exec on its end before
  anything the bootstrap can spawn exists.
- Serve one persistent, sequential, length-prefixed schema 1 channel on that
  descriptor: 64 KiB maximum frame, one request in flight, every response
  correlated to its request id. The idle wait for the next request is
  unbounded because the channel is persistent, while a frame that has begun
  carries a read and write deadline so a stalled partial frame fails instead
  of holding the channel. Writes are SIGPIPE-safe through `MSG_NOSIGNAL` on
  Linux and `SO_NOSIGPIPE` on macOS; both are declared platforms.
- Bind admission to the socket, not to the caller's word. The peer's effective
  UID must equal Fx's own, the peer PID is pinned at the first admitted
  request and re-read from the socket on every later one, and a one-time
  per-instance nonce issued in the hello frame must be echoed by every
  request. A refusal answers once with `unauthorized` and ends the channel.
  Record the honest bound: a connected local stream's peer credentials are
  fixed when it is created, so the PID pin cannot observe a descriptor passed
  onward over `SCM_RIGHTS` and the nonce is what actually defeats a leaked
  descriptor. The PID comparison is proved by a narrow canary against the same
  production admission path rather than claimed end to end.
- Expose exactly `codex.credential.resolve { minimum_validity_seconds }` and
  `codex.credential.refresh { account_id, prior_generation }`. A success
  result carries exactly `access_token`, `account_id`, `refresh_deadline` in
  whole epoch seconds, and `generation`, and nothing else: never a refresh
  token, a plan, a serialized session, or any store representation. A
  resolution floor of 313 seconds keeps a delivered lease usable past the
  consumer's own request timeout and transport grace.
- Build the authority on upstream's unified auth runtime, not on the retired
  credential store or a direct `chatgpt_oauth` reach-through.
  `auth_runtime.prepareCredential` establishes the pin at activation,
  `auth_runtime.refreshCredentialForAccount` serves both the stored
  observation and the forced rotation with account pinning built in, and
  `credential_authority.derive` is the identity every later load, OAuth
  result, persisted rotation, and broker response is compared against. Refresh
  is serialized by generation: the current generation rotates once, an older
  generation receives the already newer lease unchanged, and a future
  generation fails.
- Fail closed rather than lease authority Fx may not rotate. Host-managed
  authentication (`FX_AUTH_MODE=host-managed`) has nothing to lease, and a
  borrowed read-only profile is refused before the broker starts. The broker
  reads `FX_AUTH_READ_ONLY_HOME` by name rather than importing
  `carry/state-auth-borrowing`, so the refusal holds whether or not that head
  is composed.
- Keep the broker out of the ADE event feed and out of semantic work control.
  It is an authority channel, not telemetry and not a command transport.
- The launch control is intentionally undocumented, like `--fxnk-version`: it
  is a private contract with one consumer and appears in no help output.
  `tests/e2e/codex-credential-broker.test.ts` is its consumer-shaped proof and
  runs as its own gate step.
- The host must let go of its own copy of Fx's end once Fx holds it. Both
  descriptors name one open file description, so a parent that keeps reading
  competes for the consumer's request bytes and can restore the non-blocking
  mode Fx cleared. That is the consumer's ordinary descriptor hygiene rather
  than something Fx can enforce, and it is what made the consumer-shaped test
  fail about one run in four until the harness dropped that end on the child's
  spawn.
- `--codex-credential-fd` is a global launch control and must precede the
  command: `fx --codex-credential-fd 3 acp` activates the broker under ACP,
  while `fx acp --codex-credential-fd 3` is rejected by the ACP grammar. A
  consumer will guess the second form first; document the first.

### ACP voice control

- `carry/acp-voice-control` declares `carry/fmx-work-control` and
  `carry/ade-event-feed` as its dependencies and reuses both rather than
  restating them. Steering and queueing go through the same `WorkerRuntime`
  FIFO the work-control socket drives, the queue is encoded by work control's
  own writer, and every lifecycle record carries the ADE reducer's
  `agent_state` and `attention_kind` with the ADE spellings. Its consumer is
  AgentVoice, whose voice layer talks to one parent ACP session and never
  addresses a child directly.
- Serve `_fx/session/steer { sessionId, text }` under `fx acp`, answering
  `{ turnId, disposition, snapshot }`. With a turn active the text is admitted
  into that turn as genuine in-flight steering, `disposition` is `steering`,
  and `turnId` names the active turn, because that is the turn the person is
  redirecting. With the session idle the text is queued, `disposition` is
  `queued`, `turnId` names the turn it created, and that turn starts without a
  second `session/prompt`. The method never answers "Session is busy" and is
  served while the same client's `session/prompt` is outstanding, whose
  eventual `stopReason` still ends its turn. Steering text is user-authored
  and is never reinterpreted as a subagent message.
- Do not add a second prompt execution path for this. One ACP turn runner
  owns the admission-ordered queue, marks the worker's active turn identity
  before execution, and releases that ownership only while observing the queue
  empty, so work admitted as a turn ends is always somebody's responsibility.
  The ACP agent watches the worker's own cancel flag, which is what lets one
  signal mean steering when the boundary owns it and interruption when an
  explicit cancel cleared that ownership.
- Serve `_fx/session/snapshot { sessionId }` with work control's exact queue
  encoding plus `children`: the parent's own registry with each child's id,
  name, `one_off`/`persistent` kind, and `idle`/`running`/`awaiting_approval`/
  `interrupted`/`finished` phase. A one-off child has no agent name, so its
  session id names it. Turn identities are decimal strings on every surface,
  matching work control.
- Publish lifecycle to the client as `session/update` notifications whose
  `sessionUpdate` kind is `_fx/lifecycle`, with a monotonic per-session
  `sequence` that restarts at one for each session. Every record carries
  `turn_id`, `agent_role`, `agent_name`, `agent_state`, and `attention_kind`.
  The events are `fx_started`, `turn_started`, `turn_ended`,
  `attention_raised`, `attention_cleared`, `question_raised`, `child_changed`,
  and `stop`. `turn_ended` adds the outcome and the provider disposition, and
  `session/cancel` produces `turn_ended` with outcome `interrupted`. Open a
  session's feed lazily with its first record rather than when the session is
  created: a session that does nothing must publish nothing, because an ACP
  client counting notifications is entitled to see none it did not ask for.
  Native `agent_message_chunk`, `tool_call`, and `tool_call_update` keep
  streaming, and `agent_message_chunk` gains `turn_id` so a turn's assistant
  text is recoverable per turn. Do not put that text in a lifecycle record
  instead: it would reach the client twice, and what the client renders is
  what the presented stream says.
- Take the turn and attention edges from the shared hook runtime rather than
  instrumenting the ACP path a second time, so the main agent and every
  in-process child publish through one seam. Register before the runtime is
  frozen; a handler added after the freeze never runs.
- Keep the ADE feed's single-surface subagent approval contract. A child's
  approval reaches a person only through its parent, so when a child enters
  `awaiting_approval` the fork publishes `child_changed` for the child and
  `attention_raised { permission, agent_name }` for the parent, issues
  `session/request_permission` on the parent session carrying the child's role,
  name, and id, and clears both on the answer. The observer polls the parent's
  own child and approval registries and never blocks on one outstanding answer
  while another child changes.
- Relay a question the client can answer: `question_raised` carries the
  question id, text, options, and the complete batch, and
  `_fx/session/question { sessionId, questionId, answer }` answers it, with
  `answers` for a batch of more than one. The relay borrows the correlated
  outbound slot a permission uses, so cancelling the session releases an
  outstanding question exactly as it releases a pending permission, and it is
  never announced to the client as an outbound request the client did not make.
- Advertise the extension in `initialize` as
  `agentCapabilities._fx = { steer, snapshot, lifecycle, question }`, where
  `lifecycle` is the envelope revision rather than a boolean, so the consumer
  flips its steering capability without probing. Expose the process identity
  in the same response and on demand from `_fx/status`: build revision,
  version, auth, model source, connected providers, permission mode, and the
  resolved model and effort. Report what this process resolved rather than
  re-reading the credential store on every call.
- Document the wire contract in `docs/acp-voice-control.md` and keep it true.

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

### Notification sound availability

- On macOS, keep at most one `afplay` notification process in flight per Fx
  process. Drop overlapping sound cues rather than queueing them, then allow a
  later cue after the active player has been reaped. Keep the terminal BEL
  unconditional and emit it once for every attention cue, including cues whose
  sound is dropped.
- Carry this bound even though the unbounded player is upstream behavior. An
  ordinary retry loop while a permission is pending can otherwise create enough
  concurrent players to exhaust the per-user process table and make the whole
  machine unable to start processes; any upstream report remains historical
  evidence rather than a dependency.

### Reliability

- Resuming a saved session must accept a candidate transcript that remains
  within the terminal even when it extends beyond stale prior viewport bounds.
- Direct Codex sessions must remain usable beyond 64 sequential provider calls
  without leaking usage reservations.
- Generate every fresh native session identity as a compact URL-safe token
  whose first byte is alphanumeric, so it always satisfies the coordinated
  launch wire instead of intermittently beginning with `-` or `_`.

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
- Keep the ADE integration fixture on the current model-facing command
  contract: its managed child emits a wrapped, bounded `shell.run`, not the
  retired `terminal`/`start` shape. An unsupported legacy tool call makes the
  child continue to a fake-gateway response that can never satisfy the parent,
  disguising a stale fixture as a network timeout instead of exercising the
  intended subagent permission and Git-root events.
- Create that ADE fixture child through the current wrapped `subagent.run`
  request and assert its task-derived display label. Do not restore internal
  create-only fields such as caller-chosen child name, persistence mode, or
  permission mode to the model fixture; those are Fx-owned translations under
  the managed-subagent contract.
- Review the quarantined subagent probes against the current upstream managed
  request shape. The isolation and always-approval probes now create children
  with wrapped `subagent.run` and address the generated task label/model-safe
  handle, while retaining their ownership, external-write, canonical-scope,
  and approval-resolution assertions. That migration does not admit a new
  quarantine signature: only the declared tmux teardown and pane-predicate
  runtime timeouts remain eligible.
- Keep narrow canaries for selected-state read-only credential borrowing and
  process provider selection, workspace/profile/invocation skill-root
  separation, leading-alphanumeric session identities, bounded one-shot
  native-tool selection, and tool-free structured inference. Keep narrow canaries
  for the Codex credential broker as well: peer and nonce admission, one
  generation rotation with the stale and future cases, the exact four-field
  lease, persistent framing with a stalled-frame deadline, fail-closed
  host-managed and borrowed authority, the all-or-none launch grammar, and the
  broker starting before every other interactive startup callback. This carry owns
  the whole gate inventory: a carry based on a dependency that has no
  `tests/fxnk/runner.zig` declares its canaries here rather than on its own
  head. The gate exercises the fresh native binary against
  isolated state roots and deterministic local provider/catalog fixtures,
  proves the structured path creates no session, and keeps any opt-in real
  subscription smoke separate from deterministic shipping proof.

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

- Start the fork's hosted Full CI automatically only when maintenance publishes
  Integration, and allow manual dispatch. Publishing the Main mirror or any
  declared carry head must start no run.
- Keep `carry/hosted-full-ci` as the common base dependency of every other
  carry, with its exact workflow blob inherited unchanged by each published
  carry head and the final Integration composition. GitHub evaluates a pushed
  branch's own workflow, so a carry based directly on upstream would restore
  upstream's broad non-Main trigger even when Integration itself is correct.
- Leave unrelated and `DELETEME/*` heads unchanged as the branch model
  requires; maintenance does not rewrite their historical workflow blobs.
  Moving one of those refs is outside standing publication authority and must
  assess that head's own workflow as part of the separately authorized action.
- Serialize the maintained workflow into one constant concurrency group with
  in-progress cancellation, so at most one suite from Integration or a manual
  dispatch of that workflow runs at once and a newer Integration tip cancels
  the maintained run in flight. Historical workflow blobs on preserved heads
  are outside this guarantee. Only the current tip's verdict is worth waiting
  for, and a suite that never completes under sustained churn is an accepted
  cost because Full CI gates nothing.
- Fx and fxnk publish no consumer-specific binaries, archives, checksums,
  mutable pointers, installer payload, or release tags. The Integration Git
  branch is source publication, not a binary release, and remains the only
  source this Workshop's installer builds.
- `carry/fmx-distribution` carries no Fx source of its own. Its private binary
  distribution for the now-deprecated fmx was retired, so its whole content
  is the Integration-only Full CI trigger this entry describes and
  `carry/hosted-full-ci` owns. The head is kept only because removing a
  `carry/*` ref is an explicit `DELETEME/` decision; do not read its empty
  diff as a missing carry, and do not base new work on it.

## Gate

The Local development gate is the only blocking test authority. Run focused
checks from each changed carry worktree, compose all current carry heads into a
clean candidate, then run the gate from that exact composition worktree before
publishing any affected carry:

```sh
MAINTAIN_UPSTREAM_SHA="$cycle_upstream_sha" \
  ~/code/fxnk/scripts/local-gate.sh --worktree "$composition_worktree"
```

The gate runs formatting, the public-surface audit, and upstream's direct-write
audit, first proves that the exact candidate HEAD contains
`carry/hosted-full-ci` and preserves its exact workflow blob, builds
ReleaseSafe, executes the narrow `test-fxnk` native target, runs focused CLI,
ADE, and Codex credential broker integration tests, and exercises the fresh
binary. It also runs bounded probes
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
MAINTAIN_UPSTREAM_SHA="$cycle_upstream_sha" \
  ~/code/fxnk/scripts/local-gate.sh \
    --worktree "$integration_worktree" \
    --record
```

The record is an atomic mode-0600 JSON receipt under
`~/.local/state/fxnk/local-gates/`, bound to the Fx SHA, pinned upstream SHA,
platform, gate-contract digest, quarantine outcomes, and duration. Publish that
exact Integration commit once with the lease captured at invocation start. Then run
the project-owned ship gate; it re-reads the remote Integration branch,
validates the exact-SHA receipt and current contract, and prints `SHIP <sha>`
only when every local, remote, and receipt identity still agrees. Upstream
currency is deliberately not a ship or gate condition: the receipt records the
cycle's pinned `origin/main` SHA, and an upstream advance is ignored until the
next one-shot maintenance invocation rather than restarting this one:

```sh
MAINTAIN_UPSTREAM_SHA="$cycle_upstream_sha" \
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

This repository also owns the fxnk style guide for fx-derived surfaces:
`style/STYLE.md`, its machine-readable ground truth `style/tokens.json`, and
the rendered references in `style/captures/`. The agentbrowse OpenTUI
frontend treats fx as its living style guide; this is where that edge is
documented and kept true.

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
   update `style/viewer/index.ts` in the same commit. Its `@opentui/core`
   pin is fxnk's own; bump it deliberately when a consumer needs a newer
   toolkit, and re-prove the viewer in the same commit.
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

Carve-outs are the one part of the guide that is not extracted. Surfaces an
fxnk-based host needs and fx never draws — today the tray's agent rows,
surfaces drawn over the stage, and the unused field around a smaller sizing owner — are designed
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
