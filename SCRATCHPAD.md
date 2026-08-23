# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: 2026-08-23
- Upstream base: `04e0ae0b2076ccabb3c972351f5f0fbf2f67cc93`
- Published and installed integration:
  `87fcac544d2f2ec576c099e4a794e3fa4e80b3bf`
- Candidate quarantine ref:
  `fork/DELETEME/maintain/candidate-20260823-1`
- Full CI: run `32618954329`; all 20 matrix jobs and all four
  `Full suite (...)` aggregates passed for the published commit.
- Ship gate: `SHIP 87fcac544d2f2ec576c099e4a794e3fa4e80b3bf`
- Installed SHA-256:
  `c2147372cc1d426604b8efe38f8129319ffe8d925bc59df9deb051aa171a017a`;
  the receipt matches and `auto_upgrade` is `false`.

## Carried state

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
  all name `04e0ae0b2076ccabb3c972351f5f0fbf2f67cc93`; all five carry heads are
  published under matching `fork/carry/*` names; open PR heads #242, #244,
  #320, and #323 remain frozen under their existing names; and 134 other heads
  were preserved at the same commits under `DELETEME/*`. No branch remains
  pending quarantine.
- Local `main` pulls from `origin/main` and pushes to `fork/main`. Every local
  carry branch tracks and pushes only its matching `fork/carry/*` ref.
- All six completed `fxnk-*` feature and integration worktrees were removed
  after publication and live installation. The local carry branches and exact
  commits remain available for the next reconciliation.
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
