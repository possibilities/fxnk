# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Current maintenance: 2026-08-27. Fork publication, direct installation, the
  exact fmx and AgentStart pin handoff, and full AgentStart convergence are
  complete.
- Upstream base and Main mirror:
  `c011b118f41ca6950e1f5e3deb38950ab0771a74`
- Published and installed Integration:
  `c1ef62613bf26b4a604eae8d0674c42d59906b04`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/c1ef62613bf26b4a604eae8d0674c42d59906b04.json`;
  contract `7ca3c441014fd9d612e2b3772bdcc4cca0da913fe85650b397d75950268626f8`;
  final replay completed in 30 seconds with 41 of 41 canaries.
  `ship-gate.sh` printed
  `SHIP c1ef62613bf26b4a604eae8d0674c42d59906b04`.
- Installed SHA-256:
  `f2fb421242c126348545922e234e87de4bb31559f47abaea528e6ac5ddec0013`.
  The receipt, clean bound checkout, published ref, and installed binary all
  match; `--fxnk-version` reports `fxnk 0.5.0 (fx 0.0.6)` on one exact stdout
  line with empty stderr, the installed hash matches its receipt, and
  `auto_upgrade` is `false`.
- Both quarantine files recorded `pass` with zero failures and no signatures.
  Semantic review accepted the subagent-manager pin
  `7cb24b3a49c45f6cdeee4abae0feeaeceeedf9e8` after upstream's unrelated
  `/models` to `/model` test rename; the shared tmux-helper pin remains
  `a7ace9b57f359a8f845dad045edef6c5a3cc5626`.

## Carried state

Integration composes twenty-three durable published carry heads. Every head below
is an ancestor of published Integration:

- `carry/ade-event-feed` `a5ce060`; `carry/edited-git-roots` `f3d1f80`
- `carry/effort` `3d797cf`; `carry/effort-catalog` `06c00ab`
- `carry/external-editor` `4a87b72`; `carry/fxnk-version` `7e685e6`
- `carry/invocation-skill-roots` `e782e09`; `carry/resume-bounds` `d8c3e91`
- `carry/session-naming` `98baae4`; `carry/system-prompt-files` `cfac41e`
- `carry/local-gate-support` `b603d98`
- `carry/libfx-provider-authorization` `f5f4535`
- `carry/hosted-full-ci` `a29e1b8`
- `carry/terminal-probe-determinism` `8f93cb0`
- `carry/notification-sound-single-flight` `34bf08a`
- `carry/fmx-distribution` `d0012fb`
- `carry/acp-capability-gates` `e5339ec`
- `carry/acp-tool-selection` `378e956`
- `carry/exclusive-skill-roots` `bbe1a06`
- `carry/acp-project-instructions` `5021efd`
- `carry/acp-state-isolation` `4899ecc`
- `carry/acp-permission-policy` `950e23a`
- `carry/launch-control-continuity` `c1ef626`

All twenty-three carry heads were rewritten onto current Main or their declared
dependency. Session naming and edited-root recovery declare the ADE feed as
their base dependency. Local gate support contains the complete product
composition, libfx authorization depends on that gate support, and the hosted
CI, terminal-probe, and notification-sound carries remain independent
Main-based heads. Native-tool selection depends on the shared capability gate;
launch-control continuity depends on every prompt, skill, context, permission,
tool, and state launch-control carry.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- Global launch controls now cover fresh TUI, TUI resume and upgrade relaunch,
  and ACP wherever the capability exists. `--no-native-tools`, `--tool`,
  `--no-default-skills`, `--skills-dir`, `--no-project-instructions`,
  `--permissions-file`, and `--state-dir` are shared; `--no-acp-mcp` remains
  ACP-only because only an ACP client supplies ACP MCP servers.
- Manual managed-PTY proof launched a TUI with the shared controls, observed
  only the launch permission policy, confirmed selected-state writes never
  entered ambient Home, and resumed the selected-state session with the same
  controls. An ACP initialize/session-new exchange exercised the shared
  controls plus `--tool read_file` and `--no-acp-mcp`.
- Focused and recorded proof completed with 41 of 41 downstream canaries.
  Three subagent-manager probes and six render/replay probes passed with zero
  quarantine failures or signatures.
- Post-install reconciliation check/apply/check preserved 142 unrelated fork
  heads, left all twenty-three published carry heads as ancestors of
  Integration, and found zero `DELETEME/*` refs. The bound checkout is clean on
  Integration. Style extraction reports no drift.
- fmx pin commit `2e69cec` and AgentStart pin commit `857dec8` carry the
  published SHA. AgentStart validation and fmx's focused pin/setup tests
  passed; installed `fx` and `fmx-fx` are byte-identical and report the
  expected fork identity.
- Full AgentStart convergence completed successfully once an active display
  was available. The one permitted local in-process preflight used no remote
  access or GUI input, and its generated capture files were moved to Trash
  without being opened. The installer's served-screen-capture gate then
  passed. The installed `collab` skill and OpenAI manifest match a fresh render
  byte-for-byte.
- The gate reads its contract from the path it is invoked through:
  `local-gate.sh` sets `root` from its own location. Invoke the canonical
  `~/code/fxnk/scripts/local-gate.sh` while that checkout is clean on `main`,
  or prove a different Workshop worktree's four contract files byte-identical
  to `main`; a branch label alone does not establish the receipt contract.
- Full CI run `33069447046` for `c1ef6261` is queued and remains nonblocking
  observability; its receipt is
  `~/.local/state/fxnk/full-ci/c1ef62613bf26b4a604eae8d0674c42d59906b04.json`.

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
