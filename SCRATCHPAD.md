# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-23
- Upstream base: `ef1d0d0c6a1a87a621fc54d23f86ffec51755779`
- Published and installed integration:
  `f3f66eaf150ce434b7f3493d4b9b1dfe3fa2597e`
- Full CI: run `32685083951`; all 20 matrix jobs and all four
  `Full suite (...)` aggregates passed for the published commit.
- Ship gate: `SHIP f3f66eaf150ce434b7f3493d4b9b1dfe3fa2597e`
- Installed SHA-256:
  `08d7344f8e5b2b60a05ba32562c2ae3ca9c9083e10eff19b2e1a22bb57316f7b`;
  the receipt and installed binary match, `--fxnk-version` reports
  `fxnk 0.3.0 (fx 0.0.5)` with empty stderr, and `auto_upgrade` is `false`.
- The installed-binary ADE proof passed 1 test with 43 assertions through a
  fake local gateway and a real one-off subagent terminal write. It observed
  `FxStarted` first, `FxStopped` last, ordered Git-root revisions `[1, 2]`, a
  subagent `GitRootDiscovered` at revision 2, and a matching mode-0600
  checkpoint containing both canonical roots.

## Carried state

- Fork identity: `carry/fxnk-version` at
  `b38b3da1a964a1849039b5301084dafea397a272`, present in the installed
  integration. The intentionally undocumented `--fxnk-version` probe reports
  `fxnk 0.3.0 (fx 0.0.5)` with the exact
  exit/stdout/stderr contract, while remaining absent from top-level help.

- ADE event feed: `carry/ade-event-feed` at
  `cefad999c96d12a42201ac60f46ed0c45e1a916c`, recorded in integration by the
  ancestry-only merge `f6e2db9`. Interactive TUI main agents and in-process
  subagents publish the schema-1 feed; ask and ACP publish nothing, and the
  independent Herdr integration remains unchanged.
- Edited Git roots: `carry/edited-git-roots` at
  `9967c975a0caeccef1f9f5559e590c5dfc8c346e`, integrated by
  `f3f66eaf150ce434b7f3493d4b9b1dfe3fa2597e`. `FX_ADE_CHECKPOINT_PATH`
  provides ordered schema-1 recovery, and additive `GitRootDiscovered` events
  retain subagent and owning-main attribution.
- Native session naming: `carry/session-naming` at
  `6426b1d1a06a290ce6beae2da74616734aca71d6`, present in the installed
  integration and dependent on the ADE feed for `SessionMetadataChanged`.
- Invocation skill roots: `carry/invocation-skill-roots` at
  `9cc2340b8fd7f135e9ac6e9a56a550b36982c204`, present in the installed
  integration. Integration-only repair
  `8135ada589c9de8a47eaaf3013752638520f4516` must be folded into this clean
  carry during the next recomposition.

- External editor: `carry/external-editor` at
  `2fd2e6903693d089cc950f91cb532ef2868b3a12`, integrated by
  `bec7f3f782d66c025c76ea41b6e74ca9a8cc99b9`. Historical PR #242 is
  evidence only. Four Ctrl+G editor/terminal paths and the Ctrl+T update reload
  passed before the common gate.
- Effort override: `carry/effort` at
  `03189b4113dcbd193f97db68f1e4d93bd5a72072`, integrated by
  `70de66c79f9dae0786874ee304ae00d421e44a79`. Historical PRs #320 and #323
  are evidence only. Environment, ACP Gateway, direct-Codex, doctor, and
  startup/resume non-persistence paths passed before the common gate.
- Transcript resume bounds: `carry/resume-bounds` at
  `39ab792786629c87215c6f81618fd5eb43e461a9`, integrated by
  `4d9a217c8b9bbd4d081e60f51c665757a188dd47`. Historical PR #244 and
  upstream PR #345 are comparison evidence only. Resume candidate and alias
  paths passed before the common gate.
- Effort catalog: `carry/effort-catalog` at
  `111b2cd3d181ca905e57fcf605cb20a602ef9bbe`, integrated by
  `093be891bba1656f54843e4aceaad969142e917d` and final expectation repair
  `87fcac544d2f2ec576c099e4a794e3fa4e80b3bf`. Codex, Gateway, text, and JSON
  catalog paths passed before the common gate.
- System-prompt files: `carry/system-prompt-files` at
  `c7f5129a273534364812c1e09fc0b7209741673a`, integrated by
  `4083dd9498b9dd0f151a6b33cdf63c9ce6a54af5` with compact-help repair
  `bb46b224b838af0fcae2d5cd5b87645752e6f0d8`. PR #314 and issue #362 are
  design evidence only. Replacement, append, repeat, ownership, help, and OOM
  paths passed before the common gate.
- Codex usage capacity: satisfied by upstream merge
  `dd409c27a7719e4dccaa30152c4e9087ec30edea` from PR #291. The retired carry
  `d27b547395ad1b3916884d1d8538afbeea660083` is absent from integration;
  65 sequential direct-Codex calls passed before the common gate.

## Current notes

- Fork branches were reconciled on 2026-08-23: local, origin, and fork `main`
  all name `ef1d0d0c6a1a87a621fc54d23f86ffec51755779`; all ten completed carry
  heads are published under matching `fork/carry/*` names; open PR heads #242,
  #244, #320, and #323 remain frozen under their existing names; and every
  other fork head is preserved under `DELETEME/*`. The two ADE candidate heads
  were moved to `DELETEME/maintain/candidate-20260823-ade-event-feed-{1,2}`.
  No branch remains pending quarantine. Administrative CI runs triggered by
  the reconciliation were cancelled.
- Local `main` pulls from `origin/main` and pushes to `fork/main`. Every
  completed local carry branch tracks and pushes only its matching
  `fork/carry/*` ref; a newly opened carry may track its `origin/main` base
  until its first publication.
- Completed `fxnk-*` feature and integration worktrees are removed after
  publication and live installation. Their local carry branches and exact
  commits remain available for the next reconciliation; unrelated in-progress
  worktrees are left alone.
- Installer commit `1229441` handles lease-rewritten integration by proving
  the prior local tip from the install receipt or pre-fetch tracking ref,
  building detached, and rolling back checkout and artifacts on failure. Its
  injected transaction test and an isolated real rewrite/install both passed.

## History

- 2026-08-22: Seeded the pre-maintenance inventory while establishing the
  installer and `/maintain` infrastructure. No fork maintenance was performed.
- 2026-08-23: Completed the first maintenance cycle on current upstream,
  carried five feature heads, retired the redundant capacity patch, passed the
  exact-SHA Full CI and ship gate, published and installed integration, and
  hardened `/maintain` plus the installer from the observed rewrite behavior.
- 2026-08-23: Added the independent fxnk identity probe as a sixth carried
  feature, passed exact-SHA Full CI and the ship gate, published and installed
  integration, and left concurrent feature work isolated.
- 2026-08-23: Added the generic ADE event feed, native session naming,
  invocation-scoped skill roots, and edited Git-root recovery/events; upgraded
  the fork identity to 0.3.0; batched the serialized Integration publications;
  passed exact-SHA Full CI and the ship gate; installed and exercised the
  published binary; and reconciled the complete fork branch namespace.
