# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Current maintenance: 2026-08-29. State system prompt publication, direct
  installation, branch reconciliation, and the exact fmx and AgentStart
  consumer handoffs are complete.
- Upstream base and Main mirror:
  `cef08aa0f178537e552a931c7863dc4c1487e4a0`
- Published and installed Integration:
  `fdc7dc07257d535076f09ec50dbcb42ff4062bf8`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/fdc7dc07257d535076f09ec50dbcb42ff4062bf8.json`;
  contract `d9bff87e66ff717616dc16f9ee2c9c3a658d63e1687cb2fc79c989e14a53b189`;
  recorded replay completed in 30 seconds with 45 of 45 canaries.
  `ship-gate.sh` printed
  `SHIP fdc7dc07257d535076f09ec50dbcb42ff4062bf8`.
- Installed SHA-256:
  `6fb9df64fdac945a0dc36298b029747d5994137d5caef2be674dd3f9df48c64b`.
  The receipt, clean bound checkout, published ref, installed `fx`, and fmx's
  installed `fmx-fx` all match; both binaries report
  `fxnk 0.5.0 (fx 0.0.7)`, and Fx auto-upgrade is disabled.
- Both quarantine files recorded `pass` with zero failures and no signatures.
  Semantic review accepted subagent-manager blob
  `74ec5fa52301130a195632a229c7c51ddc60fe42` and render-replay blob
  `f09bf04a887405faad341f1bdea32e1bee455892`; the shared tmux-helper pin
  remains `a7ace9b57f359a8f845dad045edef6c5a3cc5626`.

## Carried state

Integration composes twenty-four durable published carry heads. Every head below
is an ancestor of published Integration:

- `carry/ade-event-feed` `2cba771`; `carry/edited-git-roots` `972d139`
- `carry/effort` `d78f1a8`; `carry/effort-catalog` `8f97527`
- `carry/external-editor` `f31275a`; `carry/fxnk-version` `b78a858`
- `carry/invocation-skill-roots` `f44b18c`; `carry/resume-bounds` `02b1f89`
- `carry/session-naming` `0f03ec9`; `carry/system-prompt-files` `098c3fe`
- `carry/local-gate-support` `1036185`
- `carry/libfx-provider-authorization` `d855f69`
- `carry/hosted-full-ci` `fe3b054`
- `carry/terminal-probe-determinism` `99a05c0`
- `carry/notification-sound-single-flight` `bb887dc`
- `carry/fmx-distribution` `8110c3b`
- `carry/acp-capability-gates` `bbdaaca`
- `carry/acp-tool-selection` `3a6f0a1`
- `carry/exclusive-skill-roots` `abf5480`
- `carry/acp-project-instructions` `e0bc571`
- `carry/acp-state-isolation` `ccfd0b3`
- `carry/acp-permission-policy` `50e29c2`
- `carry/launch-control-continuity` `49cdda3`
- `carry/state-system-prompts` `b97150f`

All twenty-four carry heads are based on current Main or their declared
dependency. Session naming and edited-root recovery declare the ADE feed as
their base dependency. Local gate support contains the complete product
composition, libfx authorization depends on that gate support, and the hosted
CI, terminal-probe, and notification-sound carries remain independent
Main-based heads. Native-tool selection depends on the shared capability gate;
launch-control continuity depends on every prompt, skill, context, permission,
tool, and state launch-control carry. State system prompts depends on launch
continuity and local gate support.
- The unpublished fmx-distribution commit `01d33ad` was deliberately reconciled
  into published `8110c3b`; its safety ref remains at the original exact SHA.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- Upstream changed the skills loader contract. The replay repairs both the
  five-argument `loadSkillsFromHome` call and `--skills-dir` behavior without
  `HOME`, the two real failures in hosted run `33116475312` for the superseded
  Integration.
- Independent replay review found and then approved the repair for a child
  cancellation race: exact approval attention tokens are closed before worker
  or waiter release, internal closure emits no synthetic ADE resolution, and a
  delayed Required record cannot reopen a cancelled child. The final exact-SHA
  review approved `d5e5da7` with no findings.
- The ADE resume fixture now selects the original session from either valid
  two-row catalog order rather than depending on timestamp-tied ordering.
- Explicit state roots now select exact case-sensitive `.fx/SYSTEM.md` or
  `.fx/SYSTEM_APPEND.md` conventions across TUI, resume, ACP, and in-process
  children. Explicit replacement bypass, ordered CLI appends, conflict
  failure, relaunch rediscovery, no ambient discovery, and no-follow profile
  traversal are covered by the carry and its focused fresh-binary probes.
- Focused, unrecorded, and recorded proof completed with all 45 downstream
  canaries, the selected-state ACP and TUI E2Es, four CLI regressions, three ADE
  E2Es, three subagent-manager probes, six render/replay probes, and
  fresh-binary checks passing.
- Post-install reconciliation check/apply/check left Main, Integration, and all
  twenty-four declared carries exact, preserved every unrelated fork head,
  and found no `DELETEME/*` ref. The bound checkout is clean on Integration.
  Style extraction reports no drift.
- The original publication lease is preserved at
  `refs/maintain/cef08-20260828/published-integration-lease`; the original
  unpublished fmx-distribution work remains at
  `refs/maintain/cef08-20260828/unpublished-fmx-distribution`.
- fmx pin commit `96cd70f` carries the published SHA. Its macOS arm64 Local
  gate rebuilt and installed the pinned source, passed 364 ordinary tests and
  11 live PTY tests, and proved installed `fx` and `fmx-fx` byte-identical.
- AgentStart pin commit `f089ae0` updates the plan, validation, and fleet map;
  its validation and full convergence passed, including the fmx exact-pin
  equality check and rendered Collab manifest comparison.
- The gate reads its contract from the path it is invoked through:
  `local-gate.sh` sets `root` from its own location. Invoke the canonical
  `~/code/fxnk/scripts/local-gate.sh` while that checkout is clean on `main`,
  or prove a different Workshop worktree's four contract files byte-identical
  to `main`; a branch label alone does not establish the receipt contract.
- The overdue Full CI ledger was revisited. Historical `c83be4d` and `ec1cbc3`
  failures describe loader and canary-runner defects already repaired in the
  current Integration; `0deb980` has no historical run to classify. Full CI
  run `33246694416` for `fdc7dc0` is pending and remains nonblocking
  observability; its receipt is
  `~/.local/state/fxnk/full-ci/fdc7dc07257d535076f09ec50dbcb42ff4062bf8.json`.

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
