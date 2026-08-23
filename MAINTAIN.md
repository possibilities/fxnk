# Fx fork maintenance

This repository delivers and maintains our local fork of
[`vercel-labs/fx`](https://github.com/vercel-labs/fx). It owns the behavior we
want independently of upstream review or publication while continuously
rebuilding that behavior on current upstream Fx. `/maintain` — the shared
`maintain` skill — runs a maintenance cycle from this file; this file is the
whole of what that skill knows about Fx.

## Purpose

Keep a published `integration` branch of Fx that carries every feature below,
rebuilt on current upstream every cycle, and installed on this machine by this
repository's own installer. The fork is not a place to develop Fx in general:
a feature lives here because we need it before — or instead of — upstream
shipping it.

## Upstream

- Bound checkout: `~/src/fx`. `origin` is `vercel-labs/fx`; `fork` is
  `possibilities/fx`. Read `~/src/fx/AGENTS.md` completely before touching Fx.
- Contribution conventions: high volume; every pull request needs one `type:`
  label, a Full CI matrix (Linux and macOS, x86_64 and arm64) with four
  `Full suite (...)` aggregates, changelog rules, and `CONTRIBUTING.md`.
  Landing is uncertain — our requests have stayed open for weeks, and one need
  was satisfied by someone else's merge — so nothing here waits on upstream.
- What we offer: whole features, shaped like upstream, when the shape is
  clear; we do not chase them. The existing pull requests (#242, #244, #320,
  #323) and issues are historical references only — their branches are not
  maintained, nobody tends them, and maintenance never relies on upstream
  action. Reviving one would be a deliberate act outside the cycle, never a
  side effect of it.
- "Landed" means merged into `vercel-labs/fx:main` and verified against the
  inventory below by reading the code and exercising its path. A carried patch
  is retired only then.

## Branch model

- Mirror branch: `main`, an exact mirror of `vercel-labs/fx:main` locally and on
  the fork. Never an integration base with downstream-only commits.
- Integration branch: `integration`, containing every carried feature together.
  It is the only branch the installer consumes and never a feature-development
  branch.
- Composition: carry heads. Each carried feature has a stable moving
  `carry/<feature>` branch, published to the fork for visibility, developed or
  repaired in its own worktree on current `origin/main`, and composed — only
  its committed, reviewed head — into a scratch integration candidate in
  dependency order. Carry branches are never install sources and never track or
  push to a pull-request branch, even when they contain related commits.
- Quarantine prefix: `DELETEME/`. Any fork head other than `main`,
  `integration`, a current `carry/*`, or a preserved open-request head is moved
  at the same commit to `DELETEME/<original-name>`. Existing `DELETEME/*`
  heads are permanent: reported, never removed automatically.
- Open pull-request heads: preserved. The exact head of a currently open
  request from the fork keeps its name only while the request is open; a
  closed request's head receives no special treatment.
- Rerere: relied on. The bound checkout keeps it enabled; a recorded
  resolution is reused when it remains semantically correct and rechecked
  after upstream changes.
- `scripts/reconcile-branches.sh` is this repository's entrypoint to the
  shared namespace script; it declares these values and nothing else.

## Features

### Fork identity

- Support the intentionally undocumented `--fxnk-version` consumer probe. It
  exits zero with empty stderr and one exact stdout line in the form
  `fxnk <fxnk-version> (fx <fx-version>)`. The independent fxnk version follows
  semantic versioning for downstream consumer compatibility; the Fx version
  remains the current upstream source version.

### System prompts

- Support `--append-system-prompt-file` and `--system-prompt-file` for appending
  to and replacing the system prompt.

### Effort

- Support `FX_EFFORT` with parity to `FX_MODEL`, and support
  `fx acp --effort` alongside `fx acp --model`.
- Include supported efforts in the model catalog and structured surfaces such
  as `fx models --json`, so an ADE can present valid models and efforts for each
  provider.

### External editor support

- Support the common `Ctrl+G` binding to open the composer in `$EDITOR`, moving
  Fx's existing update behavior to `Ctrl+T`.

### Reliability

- Resuming a saved session must accept a candidate transcript that remains
  within the terminal even when it extends beyond stale prior viewport bounds.
- Direct Codex sessions must remain usable beyond 64 sequential provider calls
  without leaking usage reservations.

### Scope

- Features only need a complete Codex-provider experience today. Supporting
  every provider is welcome when it is straightforward, but must not dilute
  the Codex path.

## Gate

From the candidate worktree, following current Fx guidance:

```sh
zig fmt --check src/
./scripts/check-public-surface.sh
zig build -Doptimize=ReleaseSafe
fx_zdotdir=$(mktemp -d)
ZDOTDIR="$fx_zdotdir" zig build test -Doptimize=ReleaseSafe
rmdir "$fx_zdotdir"
```

Also run focused tests for every changed feature and exercise each changed
happy path with that worktree's freshly built `./zig-out/bin/fx`.

External proof is required before publication: push the exact candidate
commit to a newly named temporary branch on `possibilities/fx`, require Full
CI for that SHA under `~/src/fx/AGENTS.md`, and run the project-owned ship
gate, which re-reads the remote candidate, refreshes current upstream, and
prints `SHIP <sha>` only when the local worktree, remote candidate, upstream
ancestry, workflow run, and all four `Full suite (...)` aggregates agree on
the exact commit:

```sh
~/code/fxnk/scripts/ship-gate.sh \
  --worktree "$candidate_worktree" \
  --candidate "$candidate_branch" \
  --sha "$candidate_sha"
```

## Consumer

The installer. After the leased push of `integration`, run:

```sh
~/code/fxnk/scripts/install.sh --install
```

It proves any existing local integration tip from the installed commit receipt
(or the pre-fetch remote-tracking ref on a first install), builds the published
commit ReleaseSafe in a detached temporary worktree, and only then rebinds the
clean checkout and atomically replaces the binary and receipts under
`~/.local/state/fxnk`, with Fx's `auto_upgrade` set to `false`. It does not
rebase, push, inspect requests, or decide which patches are carried. Never edit
the installed binary or live receipts by hand; rerun the installer.

## Notify

- Title: `Fx Maintenance`
- Group: `fxnk.maintain`
