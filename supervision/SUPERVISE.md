<!-- Managed by fxnk. Run scripts/configure-supervision.sh --install to converge it. -->
# Supervising this repository

Supervise this maintained fork for visibility and guarded worktree cleanup, but
do not integrate product branches here.

- Trunk for ancestry and roster classification: `integration` on the `fork`
  remote (`possibilities/fx`).
- `origin` is `vercel-labs/fx`, upstream. Never push there.
- `main` is an exact upstream mirror. It is never an integration base or a
  target for downstream work.
- The workshop is `~/code/fxnk`; its `MAINTAIN.md` is the authority for branch
  composition, gating, publication, installation, and consumer handoff.

## Why a normal supervised landing is unsafe

Every downstream behavior lives on a durable published `carry/<feature>` head
based on current Main or a declared carry dependency. Integration is an exact,
gated composition of every current carry. Publishing changed carry heads and
Integration is one workshop-owned transaction under exact leases.

The supervisor integrator fast-forwards one trunk branch. It cannot create or
replay the corresponding carry, prove the complete composition, or publish the
multi-ref graph. Fast-forwarding a feature branch directly into Integration
would therefore create behavior with no durable carry owner, and a later
maintenance cycle could lose it while rebuilding on upstream.

Treat every Fx merge candidate as report-and-route evidence, not permission to
integrate. Do not solicit `READY`, run the integrator, rebase the peer onto
Integration, publish a feature branch, or push a carry branch. Tell the human
the exact branch, head, cleanliness, and owner, and route the work to the fxnk
carry/composition workflow.

## What remains yours

Keep Fx on the roster. Raise abandoned or uncommitted work clearly. Reaping is
unchanged: remove only a clean, landed, unowned worktree through the guarded
reaper, while preserving its branch and commit. Never force-push or delete a
branch.
