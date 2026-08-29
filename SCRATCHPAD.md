# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Current maintenance: 2026-08-29. Semantic work control publication, direct
  installation, branch reconciliation, and the exact fmx and AgentStart
  consumer handoffs are complete.
- Upstream base and Main mirror:
  `bb2dc7d557642c7e1c2e89176ca7721281dfb08c`
- Published and installed Integration:
  `121cae8b8e0a3db57d8d7efe7c44edbcebdb3d99`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/121cae8b8e0a3db57d8d7efe7c44edbcebdb3d99.json`;
  contract `db2c6ad32cdc45d933eb0b909c48ffa7f06cb648a94e806b85b1c21bd7401f29`;
  recorded replay completed in 31 seconds with 51 of 51 canaries.
  `ship-gate.sh` printed
  `SHIP 121cae8b8e0a3db57d8d7efe7c44edbcebdb3d99`.
- Installed SHA-256:
  `fd4fdef84d56627e55055eec386ed9270a722e97fb1275186aca07ab4de99c91`.
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
  `7715ce9958c18319be94b8d823999bda4270211f`
- `carry/acp-permission-policy`
  `a14644e715d4855818c87593d8ba47596abaec95`
- `carry/acp-project-instructions`
  `5c1fb088c2aeb66b1cf1c80563baa1fe3fa3241d`
- `carry/acp-state-isolation`
  `9c65ee3cc180b7719d135aab5d82e27317ea782e`
- `carry/acp-tool-selection`
  `676c17d67bdea6ad43125b70b549972bc767d34c`
- `carry/ade-event-feed`
  `08375fa06bbfb6cfa57be6428f911b957950258e`
- `carry/edited-git-roots`
  `e0b7eb10a5b68cacf86e2a3b42beedf53f719078`
- `carry/effort` `3f0e685c76cfac172866efae1c4c3dfc272d7e25`
- `carry/effort-catalog`
  `849c13a29703eac5b34b11c78ce36b0983cb5e94`
- `carry/exclusive-skill-roots`
  `4702d8770e5958e8e83ef00210ca95de5265a3a9`
- `carry/external-editor`
  `faac3d74a99f49fcfd2a72eff8e8e3a803c74cdf`
- `carry/fmx-distribution`
  `f9b2223a205bc6ab988d8001f52df43ab605ba54`
- `carry/fmx-work-control`
  `87c86133246dbd294fb6797cf72dacbff0bb5ac0`
- `carry/fxnk-version`
  `267071423fc1e79e21061ac0fc465855b571a202`
- `carry/hosted-full-ci`
  `43aed65fcb8f1097d098a49e650bb4fff104f8f9`
- `carry/invocation-skill-roots`
  `5a54146cd750d61e4f72e920d4d71310d5729dcd`
- `carry/launch-control-continuity`
  `a331cd93fb5fe5d0e7e4d9b1979e94f6e71df1e5`
- `carry/libfx-provider-authorization`
  `aaeb980aefcc5e1c582e1c7a6c89c4e29a816a28`
- `carry/local-gate-support`
  `9eed78ac3801c91e697bff88fc566d0fc0bd9575`
- `carry/notification-sound-single-flight`
  `2db825fc50ad1ddda04248e5a1860349ff818831`
- `carry/resume-bounds`
  `2aa8b631fc10533ac164467686c3b4748e640679`
- `carry/session-naming`
  `ed90ce2201bf9cb6c1235d060482078efdf15a9c`
- `carry/state-system-prompts`
  `6d72707d94112088d5a356bcaab7d084c7151e26`
- `carry/system-prompt-files`
  `3d8aa7942e486cfb0ab084097419143fe79b0b40`
- `carry/terminal-probe-determinism`
  `5e9881712dfaf10648c7fb6cf6f3cee643455cad`

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
- fmx `bc612f96fc8ee1a203ff410fb7b5281971832d29` replaces automated CLI
  control with an eleven-tool stdio MCP server. It has no `control` or `bus`
  subcommands, launch-agent compatibility tool, prompt-paste path, wait tool,
  Runtime event stream, or phase scaffolding. Agent work mirrors only Fx's
  native Work API. Canonical validation passed typecheck and 326 tests with 17
  intentional gated skips and zero failures; the merge tree exactly matches
  the validated feature tree.
- AgentStart `17ff8a497752d154ffa9013a7a8d84a1470ecf3b` advances the exact
  Integration pin and records the MCP and Work-socket fleet edges. Its full
  validation and convergence passed; `fmx` and `fmx-mcp` resolve to canonical
  fmx source, `fmx doctor` passes, and the installed Collab manifest and skill
  are the expected policy-qualified and fully rendered forms of agentguidance's
  source templates.
- Focused, unrecorded, and recorded proof completed with all 51 downstream
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
- Full CI run `33277352293` for `121cae8` remains pending/running and is
  nonblocking observability; its receipt is
  `~/.local/state/fxnk/full-ci/121cae8b8e0a3db57d8d7efe7c44edbcebdb3d99.json`.

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
