# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-24
- Upstream base and Main mirror:
  `ccba4a7cf2f856e2740b442c2ea60b02a7405f8b`
- Published and installed Integration:
  `ec1cbc3aba202348f047791f3466b1ab792caa0b`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/ec1cbc3aba202348f047791f3466b1ab792caa0b.json`;
  contract `acbd3c5b516c5123ae732f6aa4da5d4ce6d619122cfae595aa4681e0e68a3e74`;
  final replay completed in 61 seconds. `ship-gate.sh` printed
  `SHIP ec1cbc3aba202348f047791f3466b1ab792caa0b`.
- Installed SHA-256:
  `7006c85636feee1143947c2c090d8b1f1d14430479c828c724472dff3b4e9a4b`.
  The receipt, clean bound checkout, published ref, and installed binary all
  match; `--fxnk-version` reports `fxnk 0.4.0 (fx 0.0.5)`, `auto_upgrade` is
  `false`, and a real native libfx turn through explicit `fxProfileSession()`
  streamed from Codex and shut down cleanly.

## Carried state

Integration is one linear four-commit downstream stack on the upstream base:

- `9662e70827bf60486bd8cb41ecedd80a48198789` applies the carried product
  behaviors: fork identity, system-prompt files, effort override and catalog,
  ADE event feed and edited-root recovery, native session naming,
  invocation-scoped skill roots, external-editor support, and transcript
  resume bounds. The former clean carry heads remain preserved only under
  `DELETEME/carry/*`; they are not development or publication branches.
- `182ddff22422b74cc557ead0b71673eed0663502` adds the terminal replay coverage
  to the narrow downstream canary target.
- `e29a81138a4a66988b51ce9eb26b093f4baa3dcd` keeps the narrow canary target on
  Zig's ordinary incremental cache path, so an unchanged post-commit rerun
  reuses the selected graph. A changed upstream graph still incurs a cold
  ReleaseSafe build.
- `ec1cbc3aba202348f047791f3466b1ab792caa0b` adds explicit Gateway and Codex
  provider authorization to native libfx, including bounded optimistic OAuth
  session stores, account pinning, refresh write-back, native-only Codex
  catalogs and streaming, browser rejection, and strict native MCP isolation
  across session creation and restoration. The gate now selects 20 carried
  canaries.
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
- 2026-08-24: Replayed the downstream stack onto `ccba4a7`, added native libfx
  Codex provider authorization with explicit session ownership and restore-path
  MCP isolation, published and installed `ec1cbc3`, and advanced fxnk to 0.4.0.
