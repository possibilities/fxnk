# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-24
- Upstream base and Main mirror:
  `c864c677722679c4d5fb9473f1e8c41e4156df94`
- Published and installed Integration:
  `309a0e5ae420a625cb4ec6f77250f9f234284edf`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/309a0e5ae420a625cb4ec6f77250f9f234284edf.json`;
  contract `25339f07a698080624024b163064998e05288d5f85cab06d785b668bd6d1ac83`;
  final replay completed in 61 seconds. `ship-gate.sh` printed
  `SHIP 309a0e5ae420a625cb4ec6f77250f9f234284edf`.
- Installed SHA-256:
  `9d00932ff2a2c5cbf6b9a05961854332a46faf0ab76167853fa5a2a597dc04fa`.
  The receipt, clean bound checkout, published ref, and installed binary all
  match; `--fxnk-version` reports `fxnk 0.4.0 (fx 0.0.6)` on one exact stdout
  line with empty stderr, `auto_upgrade` is `false`, and a real `fx ask` turn
  through the installed binary returned its exact expected answer and exited
  zero.

## Carried state

Integration is one linear six-commit downstream stack on the upstream base:

- `2d9a43555cd6815738d44c084bebfe60710ca063` applies the carried product
  behaviors: fork identity, system-prompt files, effort override and catalog,
  ADE event feed and edited-root recovery, native session naming,
  invocation-scoped skill roots, external-editor support, and transcript
  resume bounds. The former clean carry heads remain preserved only under
  `DELETEME/carry/*`; they are not development or publication branches.
- `43a246cd6bd742c4e250d2bd93300ffdf35bed00` adds the terminal replay coverage
  to the narrow downstream canary target.
- `cadb9f593cb10846ff9fe4a0cee614cd1a82e0f3` keeps the narrow canary target on
  Zig's ordinary incremental cache path, so an unchanged post-commit rerun
  reuses the selected graph. A changed upstream graph still incurs a cold
  ReleaseSafe build.
- `558f840f474e80914610d52a0dea12f7cc38bbcb` adds explicit Gateway and Codex
  provider authorization to native libfx, including bounded optimistic OAuth
  session stores, account pinning, refresh write-back, native-only Codex
  catalogs and streaming, browser rejection, and strict native MCP isolation
  across session creation and restoration.
- `0570690ef94da9f2dfb601e81c33a3dbf219142a` keeps the narrow canary runner at
  `tests/fxnk/runner.zig`, outside the `src/` tree upstream's direct-write
  audit scans.
- `309a0e5ae420a625cb4ec6f77250f9f234284edf` starts hosted Full CI only for
  Integration and manual dispatch, under one constant concurrency group with
  in-progress cancellation.
- The gate selects 20 carried canaries; all 20 passed on the published commit.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- Two inventory features were absent from the previously published Integration
  and were restored this cycle. Both had been built on the local, unpublished
  `feature/ci-observability` branch and were lost when the previous cycle
  replayed the stack without them. Absence in `MAINTAIN.md` § Features is work,
  and this is the concrete failure mode that rule exists to catch.
- The open Full CI `real_failure` on `ec1cbc3` was not flakiness. The canary
  runner sat at `src/fxnk_test_runner.zig`, and upstream's direct-write audit
  scans `src/` only, so the runner's seven `std.debug.print` sites reported as
  unclassified and failed the deterministic E2E suite identically on all four
  architectures. Moving the runner restored `classified=86 unclassified=0`.
  The `ec1cbc3` entry stays in the watcher's book until it ages out of the
  carry window; it is diagnosed and fixed, not pending.
- `tui-command-permissions.test.ts` "fx ask permits a child to create a nested
  canonical child" also failed that hosted run and is not covered by the
  quarantine. It passes locally on the published commit in 626 ms. It drives a
  fake gateway through racing promises and a 100 ms release timer, so it reads
  as load-sensitive rather than as a downstream regression. Watch whether it
  recurs; do not quarantine on one hosted observation.
- The integration-only Full CI trigger governs branches whose history carries
  the new workflow file, which includes every candidate cut from current
  Integration. Long-quarantined heads still carry their own older workflow
  files; they are already created, so they start nothing.
- The Local development gate is the only blocking authority. Full CI is
  nonblocking late observability; the run for `309a0e5` was still in progress
  at hand-over and was not awaited.
- The macOS-arm64 terminal quarantine remains narrow and blob-bound. The final
  receipt quarantined only `ctrl-x-child-row-race` in
  `tui-subagent-manager.test.ts` at blob
  `86db02dfb2f985b911dfd13edbeb41019e108342`; the other two selected manager
  probes passed. All six selected `tui-render-replay.test.ts` probes passed at
  blob `0ed09c27daa896ecd05e8458670b694b8326c005`; the shared tmux helper is
  `b6429696da4f7196df190d3212013fd855dc0e77`.
- Upstream moved 15 commits and released v0.0.6. The only carry-relevant
  interactions were reread rather than trusted to a clean rebase:
  `terminal.zig` replaced `OwnedInput.parsed.value` with an arena-owned
  `value`, which our ADE root tracking does not touch because it parses the
  raw arguments JSON itself; `auto_classifier.zig` gained a test only; and
  `mcp_runtime.zig` has no carry overlap. Carry and upstream diffs overlap in
  four files only.
- The pre-existing `~/src/fx-feature-ci-observability` worktree held the two
  restored behaviors on the local, unpublished `feature/ci-observability`
  branch. Now that both are landed in Integration, the operator authorized
  removing that worktree and it is gone. The local branch still exists and
  carries nothing Integration lacks.
- `possibilities/fx` defaults to `integration`. Fork and local `main` mirror
  current upstream exactly. Branch reconciliation found no new head to move
  before the cycle and quarantined only this cycle's candidate afterwards.
- Upstream PRs #242, #244, #320, and #323 are closed historical references.
  The workshop does not update, support, or preserve their branches.
- `scripts/style-extract.sh --check` reported no drift at `309a0e5`, so the
  viewer and captures needed no regeneration.

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
