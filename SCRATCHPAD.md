# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-24
- Upstream base and Main mirror:
  `f79d2ca4d6faa0c9cdf700f454b3b045a7b227e4`
- Published and installed Integration:
  `0fa09b02a0c76d88bdb942d1d35ccdb9c228e9ea`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/0fa09b02a0c76d88bdb942d1d35ccdb9c228e9ea.json`;
  contract `5135afc869e9fa2cee80f9173f8ad9d33de149f342a191274dfbcde9d8702d00`;
  cold replay completed in 372 seconds. `ship-gate.sh` printed
  `SHIP 0fa09b02a0c76d88bdb942d1d35ccdb9c228e9ea`.
- Installed SHA-256:
  `dadf2108e46a89b29f8cdf005db165d142db2041948ee8ea6747b39fe9e0fb68`.
  The receipt, clean bound checkout, published ref, and installed binary all
  match; `--fxnk-version` reports `fxnk 0.3.0 (fx 0.0.5)`, `auto_upgrade` is
  `false`, the model catalog exposes reasoning efforts, and the installed TUI
  opened `/help` and exited cleanly through `/quit`.

## Carried state

Integration is one linear three-commit downstream stack on the upstream base:

- `59486198a4a16097d90eb070f06dacd9b8d971e7` applies the carried product
  behaviors: fork identity, system-prompt files, effort override and catalog,
  ADE event feed and edited-root recovery, native session naming,
  invocation-scoped skill roots, external-editor support, and transcript
  resume bounds. The former clean carry heads remain preserved only under
  `DELETEME/carry/*`; they are not development or publication branches.
- `5156b0b040e26cee3beac79e6ae53815aafea973` adds the terminal replay coverage
  to the narrow downstream canary target.
- `0fa09b02a0c76d88bdb942d1d35ccdb9c228e9ea` keeps the 17-canary target on
  Zig's ordinary incremental cache path, so an unchanged post-commit rerun is
  sub-second. A changed upstream graph still incurs a cold ReleaseSafe build.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- The Local development gate is the only blocking authority. Full CI is
  nonblocking late observability and was neither awaited nor consulted for
  this shipment. Upstream's `full-ci.yml` ignores pushes to `main`, so upstream
  merge commits normally receive no Full CI run.
- The macOS-arm64 terminal quarantine remains narrow and blob-bound. The final
  receipt quarantined only `ctrl-x-child-row-race` in
  `tui-subagent-manager.test.ts` at blob
  `86db02dfb2f985b911dfd13edbeb41019e108342`; the other two selected manager
  probes passed. All six selected `tui-render-replay.test.ts` probes passed at
  blob `0ed09c27daa896ecd05e8458670b694b8326c005`; the shared tmux helper is
  `b6429696da4f7196df190d3212013fd855dc0e77`.
- The quarantine is based on chronic surface fragility, not a blamed upstream
  regression: serialized macOS-arm64 probes produced 43/45 passes on upstream
  `78a1835`, 44/45 on upstream `88cb3da`, and 44/45 on the former downstream
  candidate `5e81d90`, with varying failures. Hosted CI job `97485268413`
  instead showed a seven-test tmux teardown cascade under load.
- `possibilities/fx` now defaults to `integration`. Fork and local `main` mirror
  current upstream exactly. Branch reconciliation moved every former carry,
  historical PR, and candidate head to its same commit under `DELETEME/*`;
  the final check reports no unexplained live head.
- Upstream PRs #242, #244, #320, and #323 are closed historical references.
  The workshop does not update, support, or preserve their branches.
- `scripts/style-extract.sh --check` reported no drift after the bound checkout
  moved to the installed Integration tip.

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
