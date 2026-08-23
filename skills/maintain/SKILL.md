---
name: maintain
description: Maintain fxnk's locally owned Fx patch stack by reconciling current upstream with every required behavior and publishing a gated integration build. Use for /maintain or an Fx fork maintenance cycle; use the installer alone for installation without maintenance.
---

# Maintain the Fx fork

Keep the published integration branch current without losing the behavior in
`WORKSHOP.md`. Treat ordinary reconciliation, feature repair, gating, and
publication as the authorized work of a `/maintain` invocation. Ask the human
only when an upstream change creates a consequential product choice that the
workshop and existing implementation do not resolve.

## Fork contract

This skill is the complete operating contract for the Fx fork. Do not depend
on a wiki page, an upstream request, or remembered branch state to fill in its
rules.

- `~/src/fx` is the bound checkout. `origin` is `vercel-labs/fx`; `fork` is
  `possibilities/fx`; rerere stays enabled.
- `fork/integration` is the sole published install source. It contains every
  required behavior together, but it is never a feature-development branch.
- Each cycle constructs a new integration candidate on current `origin/main`
  and composes the accepted carry heads onto it. The resulting lease-protected
  rewrite is expected; never merge upstream into the old published branch or
  force-update it in place while reconciling features.
- A carried feature is built or repaired on a dedicated local carry branch in
  its own worktree, based on current `origin/main`. Compose only committed,
  reviewed carry heads into a scratch integration worktree.
- Historical pull requests, issues, and their branches are evidence only.
  Never use them as live dependencies, publication targets, or work queues;
  never update or otherwise mutate them during maintenance.
- Keep the previously published integration ref and installed binary intact
  while working. A failed rebase, build, test, review, CI run, or ship gate
  publishes and installs nothing.
- Publish a candidate to a new temporary branch on `fork`, gate that exact
  commit, then update `fork/integration` with `--force-with-lease` against the
  tip observed at the start of the cycle. Only the installer may bind the
  checkout and installed binary to the newly published integration commit.

## Establish the state

1. Read `AGENTS.md`, `CONTEXT.md`, `WORKSHOP.md`, and `SCRATCHPAD.md` in this
   repository. Read `~/src/fx/AGENTS.md` completely before touching Fx.
2. Confirm fxnk is clean on `main`. Confirm `~/src/fx` is clean, its `fork`
   remote is `possibilities/fx`, its `origin` is `vercel-labs/fx`, rerere is
   enabled, and the published install branch is `integration`. Before fetching,
   capture and validate its exact remote tip for the later publication lease:

   ```sh
   starting_integration_sha=$(
     git -C ~/src/fx ls-remote --exit-code --heads fork \
       refs/heads/integration | awk 'NR == 1 { print $1 }'
   ) || exit 1
   printf '%s\n' "$starting_integration_sha" |
     grep -Eq '^[0-9a-f]{40}$' || exit 1
   ```

   Retain that exact value for the entire cycle; do not recompute it after a
   fetch or immediately before publication.
3. Fetch both remotes. Compare upstream and integration with the last completed
   baseline in the scratchpad. Read every upstream commit in that interval,
   grouping related changes before deciding whether they affect a carried
   feature.
4. For each carried feature, inspect current upstream code and any historical
   upstream reference in the scratchpad for a possible replacement or
   interaction. These references are evidence only: do not rebase or push their
   branches, or comment on, label, close, edit, or otherwise mutate the requests.

## Reconcile the fork

- Walk every feature in `WORKSHOP.md`; absence is work, not a status note.
- Prefer an upstream implementation when it fully satisfies the required
  behavior. Retire a carried patch only after verifying the upstream code and
  exercising its path, not merely because a PR merged or closed.
- Maintain each absent or incomplete behavior on a dedicated local carry branch
  and compose its reviewed commits into integration. Historical upstream PR
  heads are never dependencies or publication targets.
- When upstream changes code a carried patch calls, reread that interaction
  even if Git reports a clean rebase. Accept a rerere resolution only after the
  same semantic review.
- Use dedicated worktrees and branches for all work outside fxnk. Keep upstream
  references untouched and never perform feature work in the bound checkout.
- For a substantial feature repair, conflict resolution, or cross-cutting
  integration, obtain an independent adversarial review when another agent is
  available. Repair every concrete finding or record why it does not apply.
- Start the scratch integration candidate at current `origin/main`, then
  compose the reviewed carry heads there in dependency order. Rebase or repair
  a carry branch in its own worktree when upstream movement requires it; do not
  merge upstream into the previously published integration history. Repair or
  add a feature on its carry branch, not directly on integration. Never leave
  the bound checkout mid-rebase.
- Preserve the old published integration ref and installed binary until the new
  candidate passes its gate. Publish only with an exact `--force-with-lease`
  against the previously observed `fork/integration` tip.

## Gate and publish

Follow the current Fx guidance. At minimum, from the candidate worktree:

```sh
zig fmt --check src/
./scripts/check-public-surface.sh
zig build -Doptimize=ReleaseSafe
fx_zdotdir=$(mktemp -d)
ZDOTDIR="$fx_zdotdir" zig build test -Doptimize=ReleaseSafe
rmdir "$fx_zdotdir"
```

Also run focused tests for every changed feature and exercise each changed happy
path with that worktree's freshly built `./zig-out/bin/fx`.

Before publishing integration, push the exact candidate commit to a newly named
temporary branch on `possibilities/fx` without changing `fork/integration` or a
historical request branch. Require Full CI and the final ship gate for that
exact SHA under `~/src/fx/AGENTS.md`. A stale, partial, skipped, cancelled, or
merely local result is not sufficient. Run the project-owned gate; it re-reads
the remote candidate, refreshes current upstream, and prints `SHIP <sha>` only
when the local worktree, remote candidate, upstream ancestry, workflow run, and
all four `Full suite (...)` aggregates agree on the exact commit:

```sh
~/code/fxnk/scripts/ship-gate.sh \
  --worktree "$candidate_worktree" \
  --candidate "$candidate_branch" \
  --sha "$candidate_sha"
```

Re-read `fork/integration` immediately before publication, then use the exact
starting tip recorded before the fetch as the lease value. Publish the gated
commit, never the ambient branch name:

```sh
git -C "$candidate_worktree" push fork \
  "$candidate_sha:refs/heads/integration" \
  --force-with-lease="refs/heads/integration:$starting_integration_sha"
```

After the integration candidate passes and the leased push succeeds, invoke
the fxnk installer. It proves any existing local integration tip from the
installed commit receipt (or the pre-fetch remote-tracking ref on a first
install), builds the published commit in a detached temporary worktree, and
only then rebinds the clean checkout and atomically replaces the binary and
receipts:

```sh
~/code/fxnk/scripts/install.sh --install
```

If rebase, validation, or publication fails, leave the previous integration
branch and installed binary in place. Report the exact failed gate and retain a
useful worktree when it is needed for follow-up.

## Maintain the scratchpad

Update `SCRATCHPAD.md` during the cycle, not as an afterthought:

- replace the completed baseline with the exact upstream and integration SHAs;
- keep one current entry per carried feature, including implementation branch,
  exact integration commit, historical upstream reference or verified
  replacement, verification evidence, and retirement condition;
- keep noteworthy upstream replacement opportunities without tracking PR
  review health or implying that the Workshop maintains those requests;
- retain rerere or conflict context only while it can change a later decision;
- remove superseded state and append one compact dated history entry.

Do not duplicate the workshop's feature specification, paste command logs, or
store secrets. Commit and push scratchpad changes on fxnk `main` after the fork
and installation state they describe are real.

## Notify and close

Interesting new upstream capabilities, a blocked maintenance gate, or a product
decision needing the human gets both a transcript report and a macOS
notification when `terminal-notifier` is available:

```sh
terminal-notifier -title "Fx Maintenance" -message "<concise outcome>" \
  -group fxnk.maintain
```

Finish with the installed integration SHA, feature disposition, checks run,
scratchpad commit, upstream replacements considered, and anything deliberately
left for the human. Silence is appropriate when no noteworthy capability or
decision was found.
