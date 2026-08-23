# fxnk context

**Workshop** — This repository, which owns the specification, maintenance
process, and installer for the local Fx fork.
_Avoid_: wrapper, patch repo.

**Integration branch** — `possibilities/fx:integration`, containing every
carried feature and serving as the only source the installer builds.
_Avoid_: install branch, local main.

**Carried feature** — Behavior required by `WORKSHOP.md` that is not yet
available in a suitable upstream form and therefore remains implemented on the
integration branch.
_Avoid_: permanent patch, downstream fix.

**Maintenance cycle** — One `/maintain` run that reviews upstream movement and
PRs, reconciles every carried feature, gates and publishes integration, updates
the scratchpad, and installs the published result.
_Avoid_: update, install.

**Installer** — `scripts/install.sh`, which only converges the published
integration branch into a ReleaseSafe binary on the system path.
_Avoid_: maintainer, updater.
