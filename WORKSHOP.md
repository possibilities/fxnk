# Fx fork workshop

This repository delivers and maintains our local fork of
[`vercel-labs/fx`](https://github.com/vercel-labs/fx). It owns the behavior we
want independently of upstream review or publication while continuously
rebuilding that behavior on current upstream Fx.

Run `scripts/install.sh --install` to build the published `fork/integration`
branch from `~/src/fx` and install it on the system path. Installation consumes
the published branch; it does not rebase or otherwise maintain the fork.

Run `/maintain` from this repository to perform a maintenance cycle. The
repo-local `maintain` skill owns that operating procedure.

## Branch model

- `integration` contains every feature installed locally. It is the only branch
  the installer consumes.
- Each carried feature may use a local carry branch while being developed or
  repaired. Integration owns the installed commits; carry branches are never
  install sources.
- Existing upstream pull requests and issues are historical references. Their
  branches are not maintained, and maintenance never relies on upstream action.
- An upstream implementation replaces a carried patch only after its behavior
  is verified against this inventory.
- Reuse recorded rerere resolutions when they remain semantically correct.

## Features

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
