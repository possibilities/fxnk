# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-26
- Upstream base and Main mirror:
  `56a1166d388952717dec4d31eec01eb68f72c1c0`
- Published and installed Integration:
  `c0f3ec0efd79ff8c4ff897fdc072a9f0ce3d508a`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/c0f3ec0efd79ff8c4ff897fdc072a9f0ce3d508a.json`;
  contract `dda3b1585f37009a4b76dd453fa5c0c79c456f926a4ec5825df3840be15e5f01`;
  final replay completed in 30 seconds with 36 of 36 canaries. `ship-gate.sh`
  printed `SHIP c0f3ec0efd79ff8c4ff897fdc072a9f0ce3d508a`.
- Installed SHA-256:
  `4e973593860bfbefb7997fa251141af9f36eaf36a74039877ee63ce33e9b0fad`.
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

Integration composes fifteen durable published carry heads. Every head below
is an ancestor of published Integration:

- `carry/ade-event-feed` `a25f826`; `carry/edited-git-roots` `f3839e3`
- `carry/effort` `a63c4b2`; `carry/effort-catalog` `486ed38`
- `carry/external-editor` `ae7f258`; `carry/fxnk-version` `c2367f9`
- `carry/invocation-skill-roots` `f448756`; `carry/resume-bounds` `e828a5d`
- `carry/session-naming` `a639bc0`; `carry/system-prompt-files` `e30152d`
- `carry/local-gate-support` `b985554`
- `carry/libfx-provider-authorization` `7590e90`
- `carry/hosted-full-ci` `905e62f`
- `carry/terminal-probe-determinism` `1faba71`
- `carry/notification-sound-single-flight` `c0f3ec0`

All fifteen carry heads were rewritten onto current Main or their declared
dependency. Session naming and edited-root recovery declare the ADE feed as
their base dependency. Local gate support contains the complete product
composition, libfx authorization depends on that gate support, and the hosted
CI, terminal-probe, and notification-sound carries remain independent
Main-based heads.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- On macOS, notification sound playback is single-flight per Fx process:
  overlapping `afplay` cues are dropped, playback rearms after waiter reap,
  and every attention cue still emits one unconditional terminal BEL. The
  injected-spawner canary proves one spawn while held, BEL delivery for every
  cue, and rearming after reap.
- Focused and recorded proof both completed with 36 of 36 downstream canaries.
  Three subagent-manager probes and six render/replay probes passed with zero
  quarantine failures or signatures.
- Post-install reconciliation check/apply/check preserved every unrelated fork
  head, left all fifteen published carry heads as ancestors of Integration,
  and found zero `DELETEME/*` refs. The bound checkout is clean on Integration.
  Style extraction reports no drift.
- The gate reads its contract from the path it is invoked through:
  `local-gate.sh` sets `root` from its own location, so
  `~/code/fxnk/scripts/local-gate.sh` uses whatever that working tree has
  checked out, not `main`. While `~/code/fxnk` sat on an unrelated branch, that
  path served a stale 20-canary contract. A receipt bound to a digest that is
  not `main`'s would look valid forever, which is worse than an honest failure.
  `refs/heads/main` now lives permanently at `~/code/fxnk-main`; gate from
  there or from a worktree proved byte-identical to `main`, and compare the
  four contract files rather than trusting the branch name.
- Full CI run `33026184061` for `c0f3ec0` is running and remains nonblocking
  observability; its receipt is
  `~/.local/state/fxnk/full-ci/c0f3ec0efd79ff8c4ff897fdc072a9f0ce3d508a.json`.
- The feature landing installed Integration immediately but did not move fmx,
  AgentStart, or another consumer pin; the requested consumer release remains
  a separate act.

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
