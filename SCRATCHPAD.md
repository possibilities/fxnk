# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-24
- Upstream base and Main mirror:
  `c864c677722679c4d5fb9473f1e8c41e4156df94`
- Published and installed Integration:
  `0deb9806b7c968bd97ae1c068720778306b5a9c3`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/0deb9806b7c968bd97ae1c068720778306b5a9c3.json`;
  contract `184de1412edea30a68fd1811e66afe7388b338eb30cba3d247103aa4de087370`;
  final replay completed in 32 seconds with 22 of 22 canaries. `ship-gate.sh`
  printed `SHIP 0deb9806b7c968bd97ae1c068720778306b5a9c3`.
- Installed SHA-256:
  `3717cc07fd70f7d9fdc5e8e6fa1d0da6b2ce68a002ae72c03e346a012d6b52b6`.
  The receipt, clean bound checkout, published ref, and installed binary all
  match; `--fxnk-version` reports `fxnk 0.4.0 (fx 0.0.6)` on one exact stdout
  line with empty stderr, `auto_upgrade` is `false`, and a real `fx ask` turn
  through the installed binary returned its exact expected answer and exited
  zero.
- Both quarantine files recorded `pass` with zero failures and no signatures.
  The quarantine was declared and not invoked.

## Carried state

Integration is one linear eight-commit downstream stack on the upstream base:

- `2d9a43555cd6815738d44c084bebfe60710ca063` applies the carried product
  behaviors: fork identity, system-prompt files, effort override and catalog,
  ADE event feed and edited-root recovery, native session naming,
  invocation-scoped skill roots, external-editor support, and transcript
  resume bounds.
- `43a246cd6bd742c4e250d2bd93300ffdf35bed00` adds the terminal replay coverage
  to the narrow downstream canary target.
- `cadb9f593cb10846ff9fe4a0cee614cd1a82e0f3` keeps the narrow canary target on
  Zig's ordinary incremental cache path.
- `558f840f474e80914610d52a0dea12f7cc38bbcb` adds explicit Gateway and Codex
  provider authorization to native libfx.
- `0570690ef94da9f2dfb601e81c33a3dbf219142a` keeps the narrow canary runner at
  `tests/fxnk/runner.zig`, outside the `src/` tree upstream's direct-write
  audit scans.
- `309a0e5ae420a625cb4ec6f77250f9f234284edf` starts hosted Full CI only for
  Integration and manual dispatch, under one constant concurrency group.
- `472b016928a2e09cd07d2fced74696cf2868d3ca` freezes a captured session title
  and reads the naming stream to completion instead of aborting it. Not this
  cycle's work; it arrived on Integration from a sibling worktree mid-cycle
  and took the canary inventory from 20 to 22.
- `0deb9806b7c968bd97ae1c068720778306b5a9c3` matches both Ctrl-X input
  encodings in the subagent handoff probe and asserts on a settled tape.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- The Ctrl-X isolation probe was never flaky. It searched recorded input
  frames for the C0 byte `0x18` while the terminal sent the CSI-u form
  `ESC[120;5u`, so it failed on every run wherever that keyboard protocol is
  negotiated, and a thirty second retry loop made a constant failure look like
  a slow one. The tape held the frame at the right position the whole time.
  Matching either encoding produced 5 of 5 clean runs at about three seconds
  each. The `ctrl-x-child-row-race` signature is retired and the quarantine now
  carries no assertion-shaped signature at all.
- That is the general lesson worth keeping: a tolerated signature is how a real
  defect hides, and a retry loop that spends its whole budget re-reading
  evidence it already holds is a disguised constant failure. The gate contract
  test now proves both halves — a declared timeout still quarantines, and the
  old assertion log is refused.
- Publication of `0deb980` to the fork was performed outside this cycle, by
  another agent on the operator's direct instruction, without this cycle's
  ship gate. The content is the exact tree this cycle rebased and verified, and
  the remote ended 0 ahead of local, so the cycle was finished rather than
  re-run: there was nothing left to publish and a re-run would have rebuilt an
  identical commit to push a ref already pointing at it. What was lost cannot
  be recovered by an after-the-fact receipt — for a window the fork carried a
  commit nothing had certified. The receipt and ship gate recorded here prove
  the installed state, not the push.
- That publication consumed this cycle's lease. The captured value was
  `309a0e5` and the remote is now `0deb980`, so the lease is spent. Any further
  publication needs a fresh cycle capturing a fresh lease. Nothing was forced.
- The gate reads its contract from the path it is invoked through:
  `local-gate.sh` sets `root` from its own location, so
  `~/code/fxnk/scripts/local-gate.sh` uses whatever that working tree has
  checked out, not `main`. While `~/code/fxnk` sat on an unrelated branch, that
  path served a stale 20-canary contract. A receipt bound to a digest that is
  not `main`'s would look valid forever, which is worse than an honest failure.
  `refs/heads/main` now lives permanently at `~/code/fxnk-main`; gate from
  there or from a worktree proved byte-identical to `main`, and compare the
  four contract files rather than trusting the branch name.
- The macOS-arm64 quarantine is now two runtime timeout signatures only, for
  tmux teardown and pane predicates, pinned to blobs
  `de1a0efe1a6022d81a3e391be027c225ac2f1c26` (subagent manager),
  `b3cf55fc0d3a34186e99bb71d99ce8c220e92edd` (tmux helpers), and
  `0ed09c27daa896ecd05e8458670b694b8326c005` (render replay).
- Upstream's own hosted CI shows the same tmux fragility on its own branches:
  of the last 40 Full CI runs, 23 succeeded, 11 were cancelled, and 4 failed —
  two single-shard macOS TTY flakes, one of them `persistent child pointer drag
  replaces the selected composer range` in this same file, and two deterministic
  cross-platform breakages in native unit tests. Real breakage and tmux
  fragility have visibly different shapes, which is what the signature-and-blob
  binding relies on.
- `tui-command-permissions.test.ts` "fx ask permits a child to create a nested
  canonical child" failed the hosted run for `ec1cbc3` and is not quarantined.
  It passes locally in 626 ms and drives a fake gateway through racing promises
  and a 100 ms timer. Watch whether it recurs; do not quarantine on one hosted
  observation.
- Full CI for `0deb980` was not awaited. It gates nothing.
- `scripts/style-extract.sh --check` reported no drift at `0deb980`.

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
