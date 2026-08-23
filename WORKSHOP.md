# Fx fork workshop

This repository delivers and maintains our local fork of
[`vercel-labs/fx`](https://github.com/vercel-labs/fx). It is a place for
experiments that may become upstream contributions and for features that we
choose to carry locally while continuing to follow upstream.

Run `scripts/install.sh --install` to build the published `fork/integration`
branch from `~/src/fx` and install it on the system path. Installation consumes
the published branch; it does not rebase or otherwise maintain the fork.

Run `/maintain` from this repository to perform a maintenance cycle. The
repo-local `maintain` skill owns that operating procedure.

## Branch model

- `integration` contains every feature installed locally. It is the only branch
  the installer consumes.
- A patch offered upstream lives on its own PR branch. Its review history can
  move independently from the local integration implementation.
- Local-only feature branches are allowed when the best integration patch and
  the best upstream contribution need different shapes.
- Reuse recorded rerere resolutions when they remain semantically correct.

## Features

### System prompts

- Support `--append-system-prompt-file` and `--system-prompt-file` for appending
  to and replacing the system prompt.

### Effort

- Support `FX_EFFORT` and `--effort` with parity to `FX_MODEL` and `--model`.
- Include supported efforts in the model catalog and structured surfaces such
  as `fx model --json`, so an ADE can present valid models and efforts for each
  provider.

### External editor support

- Support the common `Ctrl+G` binding to open the composer in `$EDITOR`, moving
  Fx's existing `Ctrl+G` behavior to another binding.

### Scope

- Features only need a complete Codex-provider experience today. Supporting
  every provider is welcome when it is straightforward, but must not dilute
  the Codex path.
