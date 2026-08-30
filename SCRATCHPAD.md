# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Current maintenance: 2026-08-29. Hosted Full CI admission repair, exact
  atomic publication, direct installation, branch reconciliation, and the
  exact fmx and AgentStart consumer handoffs are complete.
- Upstream base and Main mirror:
  `bb2dc7d557642c7e1c2e89176ca7721281dfb08c`
- Published and installed Integration:
  `559bbd62cc4bdc338f2a135d4b5175bf5b662416`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/559bbd62cc4bdc338f2a135d4b5175bf5b662416.json`;
  contract `e5d4748ef3479c0b90077fc245cd50a6ad532ca84dd31b17acf2214101ea67dc`;
  recorded replay completed in 30 seconds with 53 of 53 canaries.
  `ship-gate.sh` printed
  `SHIP 559bbd62cc4bdc338f2a135d4b5175bf5b662416`.
- Installed SHA-256:
  `eb9d4a52dcd7614576b276a0ea317b7af1fd5e945e72d2859c44c5f8f3c1f95b`.
  The receipt, clean bound checkout, published ref, installed `fx`, and fmx's
  installed `fmx-fx` all match; both binaries report
  `fxnk 0.5.0 (fx 0.0.7)`, and Fx auto-upgrade is disabled.
- Both quarantine files recorded `pass` with zero failures and no signatures.
  Semantic review accepted subagent-manager blob
  `0e747981a4efd7c6d33296f83deed2cb59d47273` and render-replay blob
  `f09bf04a887405faad341f1bdea32e1bee455892`; the shared tmux-helper pin
  remains `a7ace9b57f359a8f845dad045edef6c5a3cc5626`.

## Carried state

Integration composes twenty-five durable published carry heads. Every head below
is an ancestor of published Integration:

- `carry/acp-capability-gates`
  `0ea733dad97905c104add58078a1d41d67c2f1c7`
- `carry/acp-permission-policy`
  `ea84d68326116f85ff186b5bda5fb0df14acdc5b`
- `carry/acp-project-instructions`
  `6f9f7fab71ee4e609067d621d2b0d87c12748dde`
- `carry/acp-state-isolation`
  `2877b87a3f0f145a114735128a643585ca952526`
- `carry/acp-tool-selection`
  `7c46afc5ad14c3e4d231fa7338104d3464bcd3d3`
- `carry/ade-event-feed`
  `3bee87e9fe5423118c0b11c21324d86377669860`
- `carry/edited-git-roots`
  `05dd093e4b52424fd09d667427e1c1fc32961db6`
- `carry/effort` `bc68bc0a63e48669cddb6e276e7f82312625485a`
- `carry/effort-catalog`
  `278746736536788231068d2bacccd11722ba8a6f`
- `carry/exclusive-skill-roots`
  `dce94f4e50551a7052388b9f622d120d370c01c9`
- `carry/external-editor`
  `a935ef1edc4a81b5ac3775bac581849dcdffc7fe`
- `carry/fmx-distribution`
  `9b523376ff564d9806eb57c5a68502a300fe9627`
- `carry/fmx-work-control`
  `22c9252e258325118d90ffeb4916246a9e2fc737`
- `carry/fxnk-version`
  `fabf45e7d39b93663133e31ea69b3af327a396e7`
- `carry/hosted-full-ci`
  `e635935db2a3c3506e52497e16044f8481909482`
- `carry/invocation-skill-roots`
  `b752e5f2311e9e8e42cc247eba9410e3918fee88`
- `carry/launch-control-continuity`
  `566b4331d05da782007eb324dacdb7b63f2e5f10`
- `carry/libfx-provider-authorization`
  `d0352193110905dee7e96d4dd3d8be38da79de81`
- `carry/local-gate-support`
  `77a7862667d8a6d933c8f6f8112b6d8b4bf79adb`
- `carry/notification-sound-single-flight`
  `b1725286442e5b7d468351e6d7b47cbb4a0e81d8`
- `carry/resume-bounds`
  `3d26d06936afe3db7c8ede001f93d0f184767016`
- `carry/session-naming`
  `cf7e6485aaf78c29f5d2e5075f51c7898cf56236`
- `carry/state-system-prompts`
  `5a046c70d1ac8aaffc15081f8864c6518e15ebf9`
- `carry/system-prompt-files`
  `6cd5c871d8ec2ec791446c8a268b380e36c8e4c4`
- `carry/terminal-probe-determinism`
  `381bb01ef1e568048ede68ac937501f706befa10`

All twenty-five carry heads are based on current Main or their declared
dependency. Session naming and edited-root recovery declare the ADE feed as
their base dependency. Local gate support contains the complete product
composition, libfx authorization depends on that gate support, and the hosted
CI, terminal-probe, notification-sound, and semantic-work-control carries
remain independent Main-based heads. Native-tool selection depends on the
shared capability gate; launch-control continuity depends on every prompt,
skill, context, permission, tool, and state launch-control carry. State system
prompts depends on launch continuity and local gate support.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- Fx now exposes one authenticated semantic work-control endpoint per opted-in
  interactive main Agent. Snapshot, queue, steer-with-safe-fallback,
  cooperative interrupt, queued-item update/delete, and queue resume use Fx's
  native admission order and return authoritative post-operation state. The
  surface does not control permissions, questions, sessions, subagents,
  settings, or queue reordering, and remains independent of ADE.
- fmx `13076bc5c27c3de8dbe866549f346fcb89cad164` retains the eleven-tool
  stdio MCP surface and advances its exact Fx source pin to Integration
  `559bbd62`. Canonical validation passed typecheck and 326 tests with 17
  intentional gated skips, the PTY E2E passed, and the installed `fmx-fx` is
  byte-identical to the installed `fx`.
- AgentStart `6f914dec2c567f074f07a3d9dbaad51c1068fc78` advances the exact
  Integration pin, its check-plan assertion, and the fleet pin map. Full
  validation and convergence passed; `fmx doctor` passes, both Fx binaries
  report `fxnk 0.5.0 (fx 0.0.7)`, and the installed Collab manifest is the
  expected policy-qualified form of agentguidance's source template.
- Focused, unrecorded, and recorded proof completed with all 53 downstream
  canaries, four CLI regressions, three ADE E2Es, the semantic work-control
  integration probe, three subagent-manager probes, six render/replay probes,
  and fresh-binary checks passing.
- Post-install reconciliation check/apply/check left Main, Integration, and all
  twenty-five declared carries exact, preserved every unrelated fork head,
  and found no `DELETEME/*` ref. The bound checkout is clean on Integration.
  Style extraction reports no drift.
- The gate reads its contract from the path it is invoked through:
  `local-gate.sh` sets `root` from its own location. Invoke the canonical
  `~/code/fxnk/scripts/local-gate.sh` while that checkout is clean on `main`,
  or prove a different Workshop worktree's four contract files byte-identical
  to `main`; a branch label alone does not establish the receipt contract.
- Hosted Full CI blob `a512d762b94e9b964f2983c545be1bf2cf7f8de3`
  admits only Integration pushes and manual dispatch and uses one constant
  cancelling concurrency group. Run `33284331921` is the sole post-repair run,
  for `559bbd62`, and remains queued as nonblocking observability. The
  superseded `121cae8` Integration run and all 24 carry runs created by the old
  workflow are cancelled; post-repair reconciliation created zero carry runs.
- The watcher refreshed
  `~/.local/state/fxnk/full-ci/pending.json`; it remains overdue while the
  current run waits and retains three historical obligations. The `c83be4d7`
  split-HOME initialization defects are repaired and gated in the current
  composition, the `ec1cbc3a` canary-runner and inventory defects were repaired
  before green `309a0e5a`, and `0deb9806` never received a run. These receipts
  remain historical evidence under the watcher's retention policy rather than
  shipping authority.

## History

- 2026-08-22: Seeded the pre-maintenance inventory while establishing the
  installer and `/maintain` infrastructure. No fork maintenance was performed.
- 2026-08-23: Completed the first maintenance cycles, carried the initial
  feature set plus fork identity, installed the published branch, and added
  ADE event feed, native session naming, invocation skill roots, and edited
  Git-root recovery.
- 2026-08-24: Replaced Full CI shipping authority with the exact-SHA Local
  development gate, linearized downstream development on Integration, retired
  support for upstream PRs and remote feature branches, replayed onto current
  upstream, published and installed `0fa09b0`, and reconciled the fork to Main,
  Integration, and permanent quarantine only.
- 2026-08-24: Replayed the downstream stack onto `ccba4a7`, added native libfx
  Codex provider authorization with explicit session ownership and restore-path
  MCP isolation, published and installed `ec1cbc3`, and advanced fxnk to 0.4.0.
- 2026-08-24: Diagnosed the open Full CI failure on `ec1cbc3` to the canary
  runner's location inside `src/`, restored the two absent inventory features
  (canary runner outside `src/`, Integration-only serialized Full CI), replayed
  onto `c864c67` at fx 0.0.6, and published and installed `309a0e5`.
- 2026-08-24: Found the Ctrl-X probe's encoding defect behind a quarantine
  signature that called it flaky, retired the last assertion-shaped signature,
  and finished the cycle on `0deb980` after it was published outside the cycle
  and the lease was spent.
- 2026-08-25: Removed automatic deletion inference from shared maintenance,
  restored 152 fork heads from accidental `DELETEME/*` names, reconstructed
  fourteen current feature carries on upstream `fff3f63`, proved their exact
  composition with the Local gate, atomically published Main, the carries, and
  Integration, and installed `1b81973`.
- 2026-08-25: Replayed all fourteen carries through two further upstream
  advances onto `cca8be5`, refreshed the terminal quarantine helper pin,
  atomically published and installed `409055c`, advanced AgentStart's exact
  consumer pin, and verified 158 fork heads with zero `DELETEME/*` refs.
- 2026-08-26: Reworked ADE and upstream Herdr as independent projections of one
  lifecycle reducer, ordered accepted attention resolution before worker
  release, replayed all carries onto `fed5aa2`, atomically published and
  installed `ca376a67`, and advanced AgentStart's exact consumer pin.
- 2026-08-26: Added single-flight macOS notification sounds, replayed fifteen
  carries onto `56a1166`, semantically refreshed the terminal quarantine pin,
  passed the 36-canary gate, atomically published and installed `c0f3ec0`, and
  preserved unrelated fork refs and the extracted style guide.
- 2026-08-27: Added fmx distribution, replayed sixteen carries onto `139a77a`,
  published and installed `c8c928a6`, advanced fmx and AgentStart, then
  recovered the omitted Workshop closure by reconciling stale local carry/Main
  refs and recording the delivered state without losing any commit.
- 2026-08-27: Added shared launch controls across fresh TUI, resumed and
  relaunched TUI, and ACP; replayed twenty-three carries onto `c011b118`, passed
  all 41 Local-gate canaries, published and installed `c1ef6261`, advanced the
  fmx and AgentStart pins, and completed full AgentStart convergence.
- 2026-08-29: Repaired and replayed all twenty-three carries onto `cef08aa0`,
  reconciled unpublished fmx-distribution work without loss, closed the ADE
  approval-cancellation race, passed the 44-canary exact-SHA gate, atomically
  published and installed `d5e5da7`, and advanced fmx's source pin.
- 2026-08-29: Added explicit state-root system prompt conventions as the
  twenty-fourth carry, passed the 45-canary exact-SHA gate, atomically
  published and installed `fdc7dc0`, and advanced both fmx and AgentStart's
  exact consumer pins.
- 2026-08-29: Added authenticated semantic work control as the twenty-fifth
  carry, replayed every carry onto `bb2dc7d`, passed the 51-canary exact-SHA
  gate, atomically published and installed `121cae8`, replaced fmx automation
  with its eleven-tool MCP surface, and advanced AgentStart's exact consumer
  pin and fleet map.
- 2026-08-29: Restricted hosted Full CI to Integration and manual dispatch,
  repaired the initialization regressions its branch flood exposed, passed the
  53-canary exact-SHA gate, atomically published and installed `559bbd62`,
  advanced fmx and AgentStart, cancelled the obsolete runs, and reconciled all
  twenty-five carries without creating another carry run.
