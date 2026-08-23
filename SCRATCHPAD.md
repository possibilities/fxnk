# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: none
- Initial inventory: 2026-08-22
- Published integration: `2d2bf9123bbe4233e1b26fdcac3e5f4ec74d6f67`
- Upstream observed: `04e0ae0b2076ccabb3c972351f5f0fbf2f67cc93`

## Carried state

- External editor: carried on integration from historical PR #242. The current
  implementation uses provisional `Ctrl+T`; the local carry must put editing on
  `Ctrl+G` and move update to `Ctrl+T`.
- Transcript resume bounds: carried on integration from historical PR #244.
  Upstream PR #345 addresses a distinct duplicate-row resume bug and is
  comparison evidence, not an install source.
- Codex usage capacity: carried on integration from historical closed PR #245.
  Merged upstream PR #291 is the candidate replacement to verify before
  retiring the carried commit.
- Effort override: carried on integration from historical PR #320. The
  implementation has `FX_EFFORT` but still needs `fx acp --effort`; historical
  docs PR #323 is source material only.
- System-prompt file flags: not present in the initial integration inventory.
- Effort catalog metadata: not present in the initial integration inventory.

## Disposition policy

- Every behavior in `WORKSHOP.md` is locally owned until current upstream code
  is verified to satisfy it.
- Existing pull requests are historical upstream references. Do not rebase or
  push their branches, update their descriptions, comment, label, close, or
  otherwise maintain them.
- Carry branches and integration commits are the maintained implementation.
  Record exact commits and verification evidence here as they land.

## Opportunities and decisions

- First maintenance must compare merged upstream #291 with the carried capacity
  patch before dropping the latter.
- Build the missing system-prompt and effort-catalog features locally, complete
  effort CLI parity, and reconcile the external-editor binding before the first
  maintenance acceptance cycle.
- PR #314 and issue #362 are design evidence for profile system prompts; the
  carried command-line file flags must remain independent of their outcome.

## History

- 2026-08-22: Seeded the pre-maintenance inventory while establishing the
  installer and `/maintain` infrastructure. No fork maintenance was performed.
