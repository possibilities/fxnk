# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-27
- Upstream base and Main mirror:
  `139a77a1f4ace3b319be5397692c542d05535283`
- Published and installed Integration:
  `c8c928a6bd795f583745b79d31db60e55d445f7f`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/c8c928a6bd795f583745b79d31db60e55d445f7f.json`;
  contract `f2f7d6d78ec7d640794dbe4abfe47ea26b657f565cbbcdcef41693c37f03d281`;
  final replay completed in 217 seconds with 36 of 36 canaries.
  `ship-gate.sh` printed
  `SHIP c8c928a6bd795f583745b79d31db60e55d445f7f`.
- Installed SHA-256:
  `3dc04784ab3088b9cd6946a5284cc6ed9ef64aa75519138d62db01adbe1d8b01`.
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

Integration composes sixteen durable published carry heads. Every head below
is an ancestor of published Integration:

- `carry/ade-event-feed` `9bb0e08`; `carry/edited-git-roots` `4425933`
- `carry/effort` `120ed3f`; `carry/effort-catalog` `307eaff`
- `carry/external-editor` `71754c3`; `carry/fxnk-version` `bd7102a`
- `carry/invocation-skill-roots` `0993488`; `carry/resume-bounds` `6bf6b65`
- `carry/session-naming` `377a934`; `carry/system-prompt-files` `c217164`
- `carry/local-gate-support` `b081e35`
- `carry/libfx-provider-authorization` `6d024e3`
- `carry/hosted-full-ci` `6e5c81a`
- `carry/terminal-probe-determinism` `066c243`
- `carry/notification-sound-single-flight` `05c0f2f`
- `carry/fmx-distribution` `e49f16b`

All sixteen carry heads were rewritten onto current Main or their declared
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
  head, left all sixteen published carry heads as ancestors of Integration,
  and found zero `DELETEME/*` refs. The bound checkout is clean on Integration.
  Style extraction reports no drift.
- The fmx distribution landing itself completed correctly: the gate,
  publication, install, AgentStart pin, native `fx`/`fmx-fx` hashes, and smoke
  probes all agree on `c8c928a6`. Its cross-repository session then declared
  the work safe to close before the Workshop's post-handover reconciliation,
  scratchpad update, and cycle-worktree cleanup. The 2026-08-27 recovery found
  every worktree clean and every commit named, rebound the sixteen stale local
  carry refs to the published graph under exact comparisons, and atomically
  advanced fork/local Main to `139a77a1`; no product rollback or reinstall was
  needed.
- The gate reads its contract from the path it is invoked through:
  `local-gate.sh` sets `root` from its own location. Invoke the canonical
  `~/code/fxnk/scripts/local-gate.sh` while that checkout is clean on `main`,
  or prove a different Workshop worktree's four contract files byte-identical
  to `main`; a branch label alone does not establish the receipt contract.
- Full CI run `33040094733` for `c8c928a6` is queued and remains nonblocking
  observability; its receipt is
  `~/.local/state/fxnk/full-ci/c8c928a6bd795f583745b79d31db60e55d445f7f.json`.
- AgentStart pins `c8c928a6` and its installer provides byte-identical native
  `fx` and `fmx-fx` binaries while keeping fmx editable through its Bun link.

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
