# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-26
- Upstream base and Main mirror:
  `fed5aa24333b4efc7190b453f94e69a425c31716`
- Published and installed Integration:
  `ca376a67ff2c4e256dff14051fcdc711ad941444`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/ca376a67ff2c4e256dff14051fcdc711ad941444.json`;
  contract `c0d1fca65f9d17cb1c992b9a0b5de3520759e8caa8d41d20242b710a7f0a75f8`;
  final replay completed in 35 seconds with 23 of 23 canaries. `ship-gate.sh`
  printed `SHIP ca376a67ff2c4e256dff14051fcdc711ad941444`.
- Installed SHA-256:
  `8c5bb56937345fd425f7db6849d7b49fbdb74549f0b3e1cb34016255b0b71b05`.
  The receipt, clean bound checkout, published ref, and installed binary all
  match; `--fxnk-version` reports `fxnk 0.5.0 (fx 0.0.6)` on one exact stdout
  line with empty stderr, the installed hash matches its receipt, and
  `auto_upgrade` is `false`.
- Both quarantine files recorded `pass` with zero failures and no signatures.
  The quarantine was declared and not invoked; its shared tmux-helper pin is
  `a7ace9b57f359a8f845dad045edef6c5a3cc5626`.

## Carried state

Integration composes fourteen durable published carry heads. Every head below
is an ancestor of published Integration:

- `carry/ade-event-feed` `4520949`; `carry/edited-git-roots` `38a328a`
- `carry/effort` `28f71d1`; `carry/effort-catalog` `0f6f467`
- `carry/external-editor` `0d47162`; `carry/fxnk-version` `c19952d`
- `carry/invocation-skill-roots` `d3538cd`; `carry/resume-bounds` `b623fef`
- `carry/session-naming` `03be66f`; `carry/system-prompt-files` `5064267`
- `carry/local-gate-support` `db7dadc`
- `carry/libfx-provider-authorization` `3a06964`
- `carry/hosted-full-ci` `18b870b`
- `carry/terminal-probe-determinism` `ec6c7e7`

The first ten feature carries were reconstructed from their feature-specific
commits on current Main; session naming and edited-root recovery declare the ADE
feed as their base dependency. Local gate support contains the complete product
composition, libfx authorization depends on that gate support, and the hosted
CI and terminal-probe carries remain independent Main-based heads.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- The ADE feed and upstream Herdr integration are now transport-independent
  projections of one lifecycle reducer. Enabling either leaves the other
  unchanged. An accepted interactive attention decision publishes the
  attributed `AttentionResolved` before releasing its worker; stale or
  unmatched decisions stay silent, and terminal closure clears abandoned
  attention without a synthetic resolution.
- Focused proof covered 140 question-related ReleaseSafe tests, 34
  attention-related tests, the accepted-decision ordering test, three ADE
  real-process E2E cases, capability discovery, direct Codex
  authorization/catalog/401 replay, the native libfx suite, and the declared
  non-JSPI loader fallback. A fresh adversarial review of the exact candidate
  found no issues.
- Post-install reconciliation check/apply/check preserved all 142 unrelated
  fork heads exactly, left the fourteen published carry heads as ancestors of
  Integration, and found zero `DELETEME/*` refs. The bound checkout is clean on
  Integration. Style extraction reports no drift.
- The gate reads its contract from the path it is invoked through:
  `local-gate.sh` sets `root` from its own location, so
  `~/code/fxnk/scripts/local-gate.sh` uses whatever that working tree has
  checked out, not `main`. While `~/code/fxnk` sat on an unrelated branch, that
  path served a stale 20-canary contract. A receipt bound to a digest that is
  not `main`'s would look valid forever, which is worse than an honest failure.
  `refs/heads/main` now lives permanently at `~/code/fxnk-main`; gate from
  there or from a worktree proved byte-identical to `main`, and compare the
  four contract files rather than trusting the branch name.
- Full CI run `32939098183` for `ca376a67` is running and remains nonblocking
  observability; its receipt is
  `~/.local/state/fxnk/full-ci/ca376a67ff2c4e256dff14051fcdc711ad941444.json`.
- AgentStart commit `a47ade2` pins this exact Integration consumer SHA and is
  published on `main`. Its validation passed, the full installer proved the Fx
  pin and all repository-owned content with Herdr isolated from the older live
  server, and the installed `collab` manifest differs from its source only by
  the renderer-owned invocation policy. The final unrelated AgentDesk capture
  probe could not run because macOS reported no displays available.

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
