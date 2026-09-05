# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Current maintenance: 2026-09-05. One-shot upstream snapshot
  `478960a8ab9315507e0a40d4434df71898fadf13` is mirrored as Main. Thirty
  durable carries are published in installed Integration
  `ca773013b48be68451ed363f168f0a3251e50db2`; the bound checkout is clean,
  and local and remote Integration agree exactly.
- Local development gate receipt:
  `~/.local/state/fxnk/local-gates/ca773013b48be68451ed363f168f0a3251e50db2.json`.
  Contract digest:
  `6568ea9fefedad18ea3673951fe1891224f0cd443c41e7bf168b8cb7bfee34c6`.
  The 109-second gate passed 130 of 130 canaries, CLI 4/4, ADE 3/3,
  credential broker 4/4, voice 7/7, and quarantine 1/1.
- Installed SHA-256:
  `5cde9075c6cb1d6e91fd821abafd1cedffcd5b01695c7513c9ba228691d4eced`.
  `/Users/arthack/.local/bin/fx --fxnk-version` reports
  `fxnk 0.5.0 (fx 0.0.7)`.
- AgentStart's exact Fx consumer handoff is
  `9e56e555b69ad77c0feec04508f8685778f790b6`: the pin, installer plan line,
  validation fixture, fleet map, and fleet snapshot name `ca773013`, its
  validation passes on the committed tree, and its convergence installed Fx
  `ca773013` before stopping at an unrelated guard (the retired-Pi cleanup
  requires the reviewed AgentLaunch commit on AgentLaunch's pushed `main`).
  AgentStart's `main` holds fourteen unpushed commits including operator
  work; this cycle pushed nothing there. fmx remains deprecated and is not a
  consumer.

## Audited-upstream frontier

- Complete through `478960a8ab9315507e0a40d4434df71898fadf13` on
  2026-09-05. The 578 commits in
  `ef03b480874a49a9cc508c39b7b98214c34178ee..478960a8ab9315507e0a40d4434df71898fadf13`
  (122 first-parent merges; 413 of them delivered on 2026-09-04 without a
  disposition audit, 165 new) were read in groups and every carried feature
  received one disposition: 0 retired, 18 repaired, 12 unchanged. The
  Reliability entry's alphanumeric session-identity bound was retired as a
  bullet; its resume viewport bound stays carried.
- Direct Codex operation beyond 64 sequential provider calls remains the
  upstream-owned reliability behavior at
  `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream carry exists.

## Carried state

Integration composes thirty durable published carry heads. Every head below is
an ancestor of published Integration:

- `carry/acp-capability-gates` `0512ed4127407adee5fe4dfc8e900908cb51cb7e`
- `carry/acp-permission-policy` `856c0fde453ff15e08bc34c0984f347bf55453d7`
- `carry/acp-project-instructions` `9ff20aecd71f7e13b2ca5306f0e84f5cff949324`
- `carry/acp-state-isolation` `4c470a2e80b3c71d706a0922e9f0e83c4c64af77`
- `carry/acp-tool-selection` `d29152922e0ca3ea72990460371361c6b5d16818`
- `carry/acp-voice-control` `4740133920344a2e3f4b625c1130a84b34f60ebb`
- `carry/ade-event-feed` `65eb9a2d86a5d66747d3f72ee95815bc90e8c9e0`
- `carry/agent-shape-sessions` `6a33df0f33fc85277a78ccbca0158139d4b7df20`
- `carry/codex-credential-authority` `cf05dd3cc2385835b4adeff44f49a8ef45f2d342`
- `carry/edited-git-roots` `dc4b5c532b39fe41cd2e29bdfd347738d785fdde`
- `carry/effort` `af8d76ee89a3063d323a71805ba57b13dace2d70`
- `carry/effort-catalog` `95ae2a4a3b83e16cee7b5acbc0e892e16f604c3f`
- `carry/exclusive-skill-roots` `ce4751fb95d9d44f137de57ba33a70b43d25ca39`
- `carry/external-editor` `e8c474e6338fb7c32b32a10d6720797f5d10b41a`
- `carry/fmx-distribution` `44d35547847fc2f71abdb01e0f814177bb7cabed`
- `carry/fmx-work-control` `e4ed29e9c1bd8172b8f75a516cf93f96807c4f12`
- `carry/fxnk-version` `b8f723d095ee2df7e58caf37117a8ef4a2772bf6`
- `carry/hosted-full-ci` `44d35547847fc2f71abdb01e0f814177bb7cabed`
- `carry/invocation-skill-roots` `43be6fba14fd964f03781578460a7405b3e1a3d2`
- `carry/launch-control-continuity` `599ed00e7c54a21c849cb9b6d45e3eddd41d7b94`
- `carry/libfx-provider-authorization`
  `3f7989b672d5b07c8af6cf479975c89182f154f2`
- `carry/local-gate-support` `8c55103bb40dbd99ad569c0bb3750458f8afd05f`
- `carry/notification-sound-single-flight`
  `8b214748c7c8d7f5b6546c2545fb8a85dfd62b4e`
- `carry/resume-bounds` `3658c038ae185cff7a0aedbfd7f2efb2f77a9d1c`
- `carry/session-naming` `4eedd66c74dcdd93527373d550795dba92f43cdf`
- `carry/state-auth-borrowing` `3cf9346ca174c96b04c8922e7fb8971fcb0a1e51`
- `carry/state-system-prompts` `c72c3091c186799d93c93a5507341d45518c057e`
- `carry/structured-inference` `be98268b45517593823b901ed9972a3a23179eef`
- `carry/system-prompt-files` `c694a89a27cb884324847f076f645622820ad5e3`
- `carry/terminal-probe-determinism` `1bc1b669f72ed7e55d3c87d17856ff2ef76104a8`

All thirty heads are exact published refs and ancestors of Integration. The
2026-09-05 reconciliation matched Main, Integration, and every carry to the
declared graph while leaving unrelated fork heads unchanged.

## Current notes

- Exact branch reconciliation against captured upstream `478960a8` passes for
  Main, Integration, and all thirty carry refs. Supervision is configured and
  verified with trunk `integration` and mirror `main`. Style extraction from
  installed Integration `ca773013` reports no drift.
- The fork remote now pushes over SSH
  (`remote.fork.pushurl = git@github.com:possibilities/fx.git`; the fetch URL
  is unchanged). The HTTPS credential is the gh OAuth token without the
  `workflow` scope, and upstream's interval changed two workflow files, so the
  whole atomic HTTPS publication was refused before anything moved.
- `carry/launch-permission-mode` exists on the fork at
  `ed0b75e490a63263149918e7d3af95470768aa2c` but is absent from § Features and
  from the local checkout. Maintenance leaves it unchanged; whether it becomes
  a declared carry or `DELETEME/carry/launch-permission-mode` is an explicit
  human decision.
- The 2026-09-04 Integration carried work that existed only in its composed
  commit: the ADE feed probe on upstream's managed-subagent and shell shapes,
  the credential broker's selected-profile leases and explicit borrow fact,
  the upgrade-relaunch guard for a live broker channel, and the broker E2E
  coverage of those paths. This cycle moved all of it onto carry heads
  (`carry/ade-event-feed`, `carry/codex-credential-authority`), and
  `carry/codex-credential-authority` now depends on
  `carry/agent-shape-sessions`. Composition-only code must not recur: every
  candidate is a merge of committed carry heads and nothing else.
- Upstream's Responses text reconciliation (#677) abandons a completed
  terminal event when cancellation is pending; structured inference reverses
  that on `carry/structured-inference`, and its restated upstream tests
  document the rule. Reread the reducer on every upstream change to
  `src/gateway/responses_protocol.zig`.
- Upstream's conversation storage (#608) derives and commits the first-turn
  title itself. `carry/session-naming` keeps a title committed through the
  rename path authoritative over that derivation, installs the derived title
  under the commit lock without relocking, and treats a saved session's
  derived title as durable native metadata.
- The selected-profile Codex account pin lives on
  `carry/launch-control-continuity`, where `--state-dir` meets the
  account-pinned session store, not on `carry/codex-credential-authority`.
- Hosted Full CI: `~/.local/state/fxnk/full-ci/pending.json` holds fifteen open
  obligations for superseded Integration SHAs (`e1b20262` and older),
  overdue since 2026-08-31. This cycle repaired the composition failures those runs exposed in the carries themselves (the E2E shard weights name codex-credential-broker.test.ts, the native failures and the CLI-catalog crash are fixed and proved by canaries); the watcher records the verdict for the new Integration SHA on its own, and a red verdict there is the next cycle's first task.
- The full native suite (`zig build test`) is not a gate step. Run on this
  machine it reports 8619 tests with only shell-profile noise failing (five
  `run_command`/`command_runner` tests read this machine's zsh startup output);
  the hosted run is the clean-environment proof.
- AgentVoice last passed its complete non-Cove voice and credential broker
  regression on Integration `e1b20262` (2026-09-04). The broker wire contract
  is unchanged in `ca773013`; its selected-profile and borrowed-authority
  binding is restored there.
- The model-capability design at
  `~/handoffs/2026-09-04-fx-model-capability-exposure-design.md` is not part of
  this mandate and has no promised start.
- Do not retire `/Users/arthack/src/fx/.git` or `/Users/arthack/src` yet.
  `/Volumes/Scratch/fx-maintain-20260904.J4a8X0/launch-control-continuity`
  remains an old-store worktree with 25 dirty paths and must be handled by its
  owner before retirement. The abandoned 2026-09-04 Codex cycle's scratch
  directory `/Volumes/Scratch/fxnk-maintain-20260904-01xxds8n` holds only
  non-worktree files now; its worktrees are gone.
- The copied rerere cache still contains a known corrupt resolution for
  `src/core/agent/worker_runtime.zig`: it stacks two return types on
  `admitPromptObserved`. Never accept that resolution as proof; clear or
  bypass it and re-derive the merge by hand. Every resolution this cycle
  accepted was compared against a mechanical three-way merge first.

## History

- 2026-08-22: Seeded the pre-maintenance inventory while establishing the
  installer and `/maintain` infrastructure. No fork maintenance was performed.
- 2026-08-23: Completed the first maintenance cycles, carried the initial
  feature set plus fork identity, installed the published branch, and added
  ADE event feed, native session naming, invocation skill roots, and edited
  Git-root recovery.
- 2026-08-24: Replaced Full CI shipping authority with the exact-SHA Local
  development gate, linearized downstream development on Integration, retired
  support for upstream PRs and remote feature branches, replayed onto current
  upstream, published and installed `0fa09b0`, and reconciled the fork to Main,
  Integration, and permanent quarantine only.
- 2026-08-24: Replayed the downstream stack onto `ccba4a7`, added native libfx
  Codex provider authorization with explicit session ownership and restore-path
  MCP isolation, published and installed `ec1cbc3`, and advanced fxnk to 0.4.0.
- 2026-08-24: Diagnosed the open Full CI failure on `ec1cbc3` to the canary
  runner's location inside `src/`, restored the two absent inventory features
  (canary runner outside `src/`, Integration-only serialized Full CI), replayed
  onto `c864c67` at fx 0.0.6, and published and installed `309a0e5`.
- 2026-08-24: Found the Ctrl-X probe's encoding defect behind a quarantine
  signature that called it flaky, retired the last assertion-shaped signature,
  and finished the cycle on `0deb980` after it was published outside the cycle
  and the lease was spent.
- 2026-08-25: Removed automatic deletion inference from shared maintenance,
  restored 152 fork heads from accidental `DELETEME/*` names, reconstructed
  fourteen current feature carries on upstream `fff3f63`, proved their exact
  composition with the Local gate, atomically published Main, the carries, and
  Integration, and installed `1b81973`.
- 2026-08-25: Replayed all fourteen carries through two further upstream
  advances onto `cca8be5`, refreshed the terminal quarantine helper pin,
  atomically published and installed `409055c`, advanced AgentStart's exact
  consumer pin, and verified 158 fork heads with zero `DELETEME/*` refs.
- 2026-08-26: Reworked ADE and upstream Herdr as independent projections of one
  lifecycle reducer, ordered accepted attention resolution before worker
  release, replayed all carries onto `fed5aa2`, atomically published and
  installed `ca376a67`, and advanced AgentStart's exact consumer pin.
- 2026-08-26: Added single-flight macOS notification sounds, replayed fifteen
  carries onto `56a1166`, semantically refreshed the terminal quarantine pin,
  passed the 36-canary gate, atomically published and installed `c0f3ec0`, and
  preserved unrelated fork refs and the extracted style guide.
- 2026-08-27: Added fmx distribution, replayed sixteen carries onto `139a77a`,
  published and installed `c8c928a6`, advanced fmx and AgentStart, then
  recovered the omitted Workshop closure by reconciling stale local carry/Main
  refs and recording the delivered state without losing any commit.
- 2026-08-27: Added shared launch controls across fresh TUI, resumed and
  relaunched TUI, and ACP; replayed twenty-three carries onto `c011b118`, passed
  all 41 Local-gate canaries, published and installed `c1ef6261`, advanced the
  fmx and AgentStart pins, and completed full AgentStart convergence.
- 2026-08-29: Repaired and replayed all twenty-three carries onto `cef08aa0`,
  reconciled unpublished fmx-distribution work without loss, closed the ADE
  approval-cancellation race, passed the 44-canary exact-SHA gate, atomically
  published and installed `d5e5da7`, and advanced fmx's source pin.
- 2026-08-29: Added explicit state-root system prompt conventions as the
  twenty-fourth carry, passed the 45-canary exact-SHA gate, atomically
  published and installed `fdc7dc0`, and advanced both fmx and AgentStart's
  exact consumer pins.
- 2026-08-29: Added authenticated semantic work control as the twenty-fifth
  carry, replayed every carry onto `bb2dc7d`, passed the 51-canary exact-SHA
  gate, atomically published and installed `121cae8`, replaced fmx automation
  with its eleven-tool MCP surface, and advanced AgentStart's exact consumer
  pin and fleet map.
- 2026-08-29: Restricted hosted Full CI to Integration and manual dispatch,
  repaired the initialization regressions its branch flood exposed, passed the
  53-canary exact-SHA gate, atomically published and installed `559bbd62`,
  advanced fmx and AgentStart, cancelled the obsolete runs, and reconciled all
  twenty-five carries without creating another carry run.
- 2026-08-29: Migrated audit provenance by reconstructing the complete
  `c011b118` to `bb2dc7d` upstream interval: 144 commits including Fx 0.0.7,
  with 0 carries retired, 17 repaired, and 8 unchanged; delivery remains at
  `559bbd62`.
- 2026-08-31: Audited the fifteen commits in `bb2dc7d..ef03b480`, with
  0 carries retired, 9 repaired, and 16 unchanged; repaired selected-profile
  MCP mutation, replayed and gated all twenty-five carries with 61 canaries,
  atomically published and installed `beadc01a`, advanced fmx and AgentStart,
  and reconciled the graph without moving any unrelated head or starting a
  carry run.
- 2026-09-03: Deprecated fmx as a consumer. Removed the fmx source-identity
  entry, validation, glossary term, README usage, and the viewer's fmx pin
  rule; re-mapped `carry/fmx-distribution` to Hosted Full CI and kept both
  `carry/fmx-*` heads and their features unchanged.
- 2026-09-04: Captured the one-shot upstream target `964c040`, composed and
  installed Integration `e1b20262` with thirty carries including the five new
  voice-control, agent-shape/session, credential-authority, state-borrowing,
  and structured-inference heads, passed the 116-canary Local gate, advanced
  AgentStart to `9da5d08`, and recorded Hosted Full CI's nonblocking
  composition failures for a future snapshot.
- 2026-09-05: Audited the 578 commits in `ef03b480..478960a8` (0 retired, 18
  repaired, 12 unchanged), replayed all thirty carries onto `478960a8` through
  the shell, managed-subagent, conversation-manifest, MCP, provider-auth, and
  libfx rebuilds, repaired the composition-only work the previous delivery
  left in its Integration commit, added the hosted-CI blind-spot and
  selected-profile canaries, passed the 130-canary exact-SHA gate, atomically
  published and installed `ca773013`, and advanced AgentStart's exact
  consumer pin.

## Open before the next upstream absorb (2026-09-05)

- Decide `carry/launch-permission-mode` on the fork: declare it in § Features
  or name it `DELETEME/carry/launch-permission-mode`. Maintenance will not
  infer either.
- Hosted Full CI must reach a verdict for `ca773013`; the watcher
  records it. A red verdict there, or a persisting `unclassified` obligation
  for a superseded SHA, is the next cycle's first task.
- `tests/e2e/acp.test.ts` is parsed by the gate's `e2e-structure` step but run
  by no step; its skill-catalog assertions were rewritten by upstream #650 and
  are proved only by the hosted run.
- Replay helpers from the 2026-09-04 cycle remain under `scripts/resolvers/`;
  this cycle's helpers were disposable scratch and are not kept.
- Retire the old Fx store only after the owner resolves the 25 dirty paths in
  `/Volumes/Scratch/fx-maintain-20260904.J4a8X0/launch-control-continuity`.
