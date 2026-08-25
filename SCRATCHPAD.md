# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-25
- Upstream base and Main mirror:
  `fff3f63e348dec846bb235332974226bd2feae26`
- Published and installed Integration:
  `1b81973907d00c52db6f65da53403096df26dbb1`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/1b81973907d00c52db6f65da53403096df26dbb1.json`;
  contract `184de1412edea30a68fd1811e66afe7388b338eb30cba3d247103aa4de087370`;
  final replay completed in 213 seconds with 22 of 22 canaries. `ship-gate.sh`
  printed `SHIP 1b81973907d00c52db6f65da53403096df26dbb1`.
- Installed SHA-256:
  `8195cb462da0f699b79238a52fac3e708154dec42b9dbe5dc4c8db27bc0f7d8c`.
  The receipt, clean bound checkout, published ref, and installed binary all
  match; `--fxnk-version` reports `fxnk 0.4.0 (fx 0.0.6)` on one exact stdout
  line with empty stderr, the installed hash matches its receipt, and
  `auto_upgrade` is `false`.
- Both quarantine files recorded `pass` with zero failures and no signatures.
  The quarantine was declared and not invoked.

## Carried state

Integration composes fourteen durable published carry heads. Every head below
is an ancestor of published Integration:

- `carry/ade-event-feed` `529861d`; `carry/edited-git-roots` `176b991`
- `carry/effort` `07c9d14`; `carry/effort-catalog` `8b35122`
- `carry/external-editor` `dac0f95`; `carry/fxnk-version` `ec0394f`
- `carry/invocation-skill-roots` `4bbbb89`; `carry/resume-bounds` `896ef36`
- `carry/session-naming` `a4a8e69`; `carry/system-prompt-files` `4ff6936`
- `carry/local-gate-support` `036fbe2`
- `carry/libfx-provider-authorization` `94aabc5`
- `carry/hosted-full-ci` `73958ad`
- `carry/terminal-probe-determinism` `16a6544`

The first ten feature carries were reconstructed from their feature-specific
commits on current Main; session naming and edited-root recovery declare the ADE
feed as their base dependency. Local gate support contains the complete product
composition, libfx authorization depends on that gate support, and the hosted
CI and terminal-probe carries remain independent Main-based heads.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- Branch repair completed on 2026-08-25. The fork has 158 heads: 14 current
  `carry/*` heads and 144 ordinary heads including Main and Integration. All
  152 accidental `DELETEME/*` renames were atomically restored to their
  original names and SHAs; no `DELETEME/*` ref remains. Reconciliation owns
  only Main, Integration, and declared carries. A future deletion marker
  requires an explicit human decision naming the branch.
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
- Full CI for `1b81973` is nonblocking and was still running when the exact-SHA
  Local gate, publication, ship gate, and install completed.

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
