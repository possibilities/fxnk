# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Last completed maintenance: none
- Initial inventory: 2026-08-22
- Published integration: `2d2bf9123bbe4233e1b26fdcac3e5f4ec74d6f67`
- Upstream observed: `04e0ae0b2076ccabb3c972351f5f0fbf2f67cc93`

## Carried state

- External editor: carried on integration; upstream PR #242 is open. The
  current implementation uses provisional `Ctrl+T`, while the workshop requires
  `Ctrl+G` with the old binding rehomed.
- Transcript resume bounds: carried on integration; upstream PR #244 is open.
- Codex usage capacity: carried on integration from closed PR #245. Upstream PR
  #291 merged on 2026-08-22 and is the candidate replacement to verify and
  retire during the first maintenance cycle.
- Effort override: carried on integration; upstream PR #320 is open.
- System-prompt file flags: not present in the initial integration inventory.
- Effort catalog metadata: not present in the initial integration inventory.

## Upstream requests

- #242 `external-editor-composer`: open, mergeable, blocked, no maintainer
  review, and no Full CI result in the initial inventory.
- #244 `fix/resume-transcript-candidate-row`: open, mergeable, blocked, no
  maintainer review, and no Full CI result in the initial inventory.
- #320 `feat/fx-effort-override`: open, mergeable, blocked, no maintainer
  review, and no Full CI result in the initial inventory.
- #323 `docs/contributing-env-vars`: draft, mergeable, blocked, no maintainer
  review, and no Full CI result in the initial inventory.

## Opportunities and decisions

- First maintenance must compare merged upstream #291 with the carried capacity
  patch before dropping the latter.
- First maintenance must establish implementations for the missing system-prompt
  and effort-catalog features and reconcile the external-editor binding.

## History

- 2026-08-22: Seeded the pre-maintenance inventory while establishing the
  installer and `/maintain` infrastructure. No fork maintenance was performed.
