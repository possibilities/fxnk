# fxnk context

**Workshop** — This repository, which owns the specification (`MAINTAIN.md`),
maintenance state, and installer for the local Fx fork; the maintenance
procedure itself is the shared `maintain` skill, which every workshop runs.
_Avoid_: wrapper, patch repo.

**Integration branch** — `possibilities/fx:integration`, containing every
carried feature and serving as the only source the installer builds.
_Avoid_: install branch, local main.

**Main mirror** — Local `main` and `possibilities/fx:main`, both fast-forwarded
to the exact current `vercel-labs/fx:main` during every maintenance cycle.
_Avoid_: integration base, development main.

**Carried feature** — Behavior required by `MAINTAIN.md` that is not yet
available in a suitable upstream form and therefore remains implemented on the
integration branch.
_Avoid_: permanent patch, downstream fix.

**Historical upstream reference** — An upstream pull request, issue, or commit
that explains a carried feature or may later replace it. It is evidence only.
An open pull request keeps its frozen head branch; the Workshop does not update
that branch or depend on upstream action.
_Avoid_: active contribution, maintained PR.

**Carry branch** — A Workshop-owned `carry/<feature>` branch, published to the
fork for visibility and used to develop or repair one carried feature before
its commits are composed into integration. It never tracks or updates a pull
request branch.
_Avoid_: PR branch, install branch.

**Quarantine branch** — A preserved fork branch renamed to
`DELETEME/<original-name>` because it is neither core, carried, nor the head of
an open pull request. Maintenance never deletes quarantine branches.
_Avoid_: deleted branch, archive tag.

**Maintenance cycle** — One `/maintain` run that reviews upstream movement and
historical references, reconciles every carried feature, gates and publishes
integration, updates the scratchpad, and installs the published result.
_Avoid_: update, install.

**Installer** — `scripts/install.sh`, which only converges the published
integration branch into a ReleaseSafe binary on the system path.
_Avoid_: maintainer, updater.

**ADE event feed** — Fx's opt-in, versioned, best-effort NDJSON lifecycle
stream from an interactive TUI and its in-process agents to an ADE-owned Unix
socket. The ADE supplies the socket and an opaque instance identity; Fx
supplies agent and session context without presentation policy.
_Avoid_: Herdr feed, control socket, ask feed.
