# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Fx delivery: 2026-09-07. Captured upstream `3c58c8051be288079d6d23fe90bb7b08f9841dc8`
  is mirrored as Main. All thirty durable carry heads are published together
  in Integration `e6ef2148c63f304883de21768bcfcdbf97c4d833`. The bound checkout is clean,
  and local, published, and installed Integration agree exactly.
- Local development gate receipt:
  `~/.local/state/fxnk/local-gates/e6ef2148c63f304883de21768bcfcdbf97c4d833.json`.
  Contract digest: `7f6cdbbe97656f7a3607a285d53fe2cff4c4c0c31995f99c15a6e998cfcc982d`.
  The recorded gate passed in 157 seconds: 135/135 native canaries,
  CLI 4/4, ADE 3/3, credential broker 4/4, voice 7/7, all 95 carried E2E
  definitions across 13 owners (every selected execution verified), six
  terminal replay probes, and fresh-binary checks. No quarantine was used.
  The preceding full gate on the same SHA passed in 249 seconds.
- Installed SHA-256: `577ae67607aba3c373f6605eb256cde6188c751eaf46ab583aa27045ac817cce`.
  `/Users/arthack/.local/bin/fx --fxnk-version` reports
  `fxnk 0.5.0 (fx 0.0.8)`. The installer alone built and rebound the checkout;
  the independent auto-updater remains disabled.
- AgentStart consumer commit: `16750931dbc4876b95c76b8d467eb58b1b018b73` on pushed Main.
  Its pin, installer plan, validation fixture, fleet map, and regenerated fleet
  snapshot name `e6ef2148c63f304883de21768bcfcdbf97c4d833`. `tests/validate.sh` passes.
  The first full convergence stopped at Agentdesk's capture gate while the
  desktop was locked. The operator reran `scripts/install.sh --install` and
  reported its normal final guidance-linking step. Both installed harness
  guidance symlinks, the `collab` source/invocation policy, and the exact Fx
  install receipt were then verified. The consumer handoff and cycle are complete.
  Full `--install` ends after guidance linking; the explicit "content convergence
  complete" message belongs only to `--content`.
- AgentStart's authorized `scripts/sync-skills` completed separately. The
  installed `collab` interface matches agentguidance's source template exactly;
  its generated `allow_implicit_invocation: false` matches source
  `disable-model-invocation: true`. The fleet snapshot regenerated successfully.
  The former retired-Pi and retired-spelling snapshot blockers are resolved.
  fmx remains deprecated and is not a consumer.

## Audited-upstream frontier

- Complete through `3c58c8051be288079d6d23fe90bb7b08f9841dc8` on 2026-09-07. Read all
  110 commits (39 first-parent merges) in
  `65d76390260d3daeccb258e873be144c1e6160c4..3c58c8051be288079d6d23fe90bb7b08f9841dc8`,
  including the Fx 0.0.8 release. Each carry received one disposition:
  **0 retired, 7 repaired, 23 unchanged**. No material stance change and no
  unresolved product decision; upstream complements the retained contracts.
- Meaningful groups: original provider text/reasoning/message boundaries
  survive interruption, resume, and compaction; terminal failures retain
  diagnostics and usage; current-log recovery copies, staged session
  publication, and continuation cache changes; unified auth status and
  recovery/compaction admission; durable subagent task/reply/failure replay
  with current `run`/`message` actions; Ctrl-C draft clearing and retained
  transcript/paragraph geometry; MCP scoped-package arguments and sign-in
  after logout; explicit skill-load notices and content-derived locations;
  asynchronous Node/CJS/Wasm loading and package qualification; Bun 1.4.2,
  Linux addon ABI baseline, backend probes, and terminal cleanup.
- [Exact audited range](https://github.com/vercel-labs/fx/compare/65d76390260d3daeccb258e873be144c1e6160c4...3c58c8051be288079d6d23fe90bb7b08f9841dc8)
  and [pinned changelog](https://github.com/vercel-labs/fx/blob/3c58c8051be288079d6d23fe90bb7b08f9841dc8/CHANGELOG.md).
  The 0.0.8 changelog covers a wider release interval; it supplements this audit.
- Direct Codex operation beyond 64 sequential provider calls remains
  upstream-owned at `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no carry exists.

## Carried state

Every exact head below is published and is an ancestor of Integration
`e6ef2148c63f304883de21768bcfcdbf97c4d833`. The disposition evidence records this cycle's
upstream interaction; `MAINTAIN.md` § Features remains the behavioral and
retirement authority. A carry retires only when verified upstream behavior
satisfies its full named contract. Historical request branches are evidence only.
The exact-composition gate covers every row; focused repair proof follows.

| Carry | Published head | Disposition | Audit evidence |
| --- | --- | --- | --- |
| `carry/acp-capability-gates` | `38e7ef668b1434c008bb40e04fbd828758222c3d` | unchanged | Upstream subagent result changes retain injected native tool authority; suppression remains absent upstream. |
| `carry/acp-permission-policy` | `25357373abcd4a66bb4bed2a47289e969f93c6ac` | unchanged | Full-access UI rename does not replace invocation policy precedence or denies. |
| `carry/acp-project-instructions` | `5a9114dd78947546ea0412e934813325e4af7470` | unchanged | Instruction-refresh notices complement process-wide suppression; retain launch policy. |
| `carry/acp-state-isolation` | `08c8a8bfadb2f29312581e6c10faf993e9c6fc0c` | repair | New interactive status settings lookup must use selected profile; auth source probe retains isolation. |
| `carry/acp-tool-selection` | `6d62ce6ae74662491bc909f71b2687c0ec54e5fc` | unchanged | Upstream shell validates zero timeout earlier; bounded one-shot selection still independently narrows schema/dispatch. |
| `carry/acp-voice-control` | `126dcf58d0e29f8a56fe489bd03515e75697eafa` | unchanged | Child result reporting retains same phase/kind registry; FIFO, lifecycle and turn identities remain required. |
| `carry/ade-event-feed` | `7fc5a6b17a205d4642b2d770fc721f67b6eaf98a` | repair | Raw history finalization test migration preserves TurnStarted hook and prompt admission alongside compaction. |
| `carry/agent-shape-sessions` | `1e3030ff7347b31d31e49283dde5c29ee6ce707b` | repair | Merge v4 replay/legacy-ranking cache with shape provenance; restore account identity through all listings and recovery. |
| `carry/codex-credential-authority` | `344b280dc465a8b1c9a52eecce567478d64ec80f` | unchanged | Unified auth status/recovery does not expose broker leases; selected-account pre-refresh pin and borrow refusal remain. |
| `carry/edited-git-roots` | `60a5895988ba8ebffb25f4072d3b261ea245e13d` | unchanged | Raw history/provider/subagent changes retain mutation and command observation sites; no upstream ADE root checkpoint. |
| `carry/effort` | `793fb19e440b15174b24d9b87aea38f648e757f9` | unchanged | No upstream replacement for process FX_EFFORT and ACP launch parity. |
| `carry/effort-catalog` | `815f8549691dda5eae9482af0b2358d457bbd82f` | unchanged | Model catalog effort projection remains required; no changed catalog schema. |
| `carry/exclusive-skill-roots` | `fe6b9ac23a51fa63c0d43d1ee14342f7a6d7f678` | unchanged | Content-derived location namespaces complement selected root authority, do not replace exclusivity. |
| `carry/external-editor` | `49b28eea51881220a79876b9eb1910e2c466ea7e` | unchanged | Ctrl-C draft clearing does not replace editor handoff or alter tty restoration. |
| `carry/fmx-distribution` | `2b312a52356134b71adf7c69af76e69291e68430` | unchanged | Alias of hosted-full-ci; no independent semantic work. |
| `carry/fmx-work-control` | `f96d4afca33725ae2cc7b128a01d48fbd5d30b04` | unchanged | Ctrl-C/input and finalization changes retain queue/steer admission and authenticated endpoint. |
| `carry/fxnk-version` | `7c39a94c8c343514666df0530d5cf8295d71f6a2` | unchanged | Upstream release changes embedded Fx version only; fork probe remains required. |
| `carry/hosted-full-ci` | `2b312a52356134b71adf7c69af76e69291e68430` | unchanged | Upstream expands package qualification; fork Integration-only admission remains required. |
| `carry/invocation-skill-roots` | `2a204a7b6eb05b6ce215dd82682e5d8df60fffd8` | unchanged | Skill load notices/namespaces use supplied catalog; ordered invocation roots remain necessary. |
| `carry/launch-control-continuity` | `f6f765bcd444262056e114eff9b0d7ef7a8fd2dc` | unchanged | Recompose profile/account and new provider replay paths while retaining exact relaunch controls; no standalone semantic repair. |
| `carry/libfx-provider-authorization` | `89dce9e46f8d0d4b95620425fedbeed8dbdd3baf` | repair | Async Node loader retains tagged authorization and rejects Codex WASM; repair missing packaged internal module. |
| `carry/local-gate-support` | `aa5bc3ffc3bccda33cadcae63cf577a388fe5317` | repair | Register status, checkpoint-title, summary/cache and picker regression canaries; import their actual owners. |
| `carry/notification-sound-single-flight` | `59801236854c109e246fdc1c29f0969b58912fe4` | unchanged | No upstream replacement or changed native player lifetime. |
| `carry/resume-bounds` | `3f96deb4dbcaa389d915abb32a751668455222c3` | unchanged | Retained geometry repair complements candidate viewport acceptance; carry predicate remains necessary. |
| `carry/session-naming` | `4b84f1bdbf8e7f435cdc579b69c073877ee96e7a` | repair | Shutdown settles completed prompts; recovered checkpoint-only histories keep title open until first real prompt. |
| `carry/state-auth-borrowing` | `fd9758056cb54f7493072d46fd3a7b3ca45e78a1` | unchanged | Auth recovery fixes retain selected provider and read-only explicit credential authority. |
| `carry/state-system-prompts` | `3af6a4b36fa0a2bc82fd8bd07f39bbbac67d341b` | unchanged | No upstream conventional selected-state prompt files; retain precedence. |
| `carry/structured-inference` | `a0a9269eca5d77b7596ee2ccc83867305556c685` | repair | Preserve already-read terminal outcome across replay serialization; map typed terminal failures durably. |
| `carry/system-prompt-files` | `0f2dfc721fe7d7bb19b4b26a2600b020f9c83ddb` | unchanged | README usage merge only; override/append contract unchanged. |
| `carry/terminal-probe-determinism` | `f9f62c9540e51c96ba40267ff63d3898b559ded1` | unchanged | No upstream replacement of dual Ctrl-X recognition or settled-tape test contract. |

## Current notes

- Selected-profile isolation: new interactive status uses the selected
  profile rather than ambient preferences. Focused native status tests passed
  5/5; a real TUI `/status` probe passed with conflicting and malformed ambient
  settings, clean stderr, and unchanged settings (1 test, 16 assertions).
- ADE: raw-history test migration retains TurnStarted observation, and
  prompt-admission hooks coexist with upstream compaction. Full ADE tests pass.
- Agent-shape sessions: cache v5 preserves upstream v4 visible/excluded and
  legacy-ranking machinery plus canonical hydration. Review also closed a
  preexisting inventory gap: account identity survives discovery, clones,
  cache, CLI JSON/text, ACP provenance, and narrow resume menus. Native cache
  and picker tests, CLI/ACP 2/2 (24 assertions), and actual 40/80-column picker
  interactions passed. Menu provenance clipping found by review was repaired.
- libfx authorization: async Node loading passes effective tagged auth through
  Wasm fallback and rejects Codex before Wasm instantiation. Review also found
  and repaired the preexisting omission of `internal.js` from package, demo,
  and development-release closure. All 25 actual-addon Bun SDK scripts passed;
  Node and Bun native Codex probes passed. An actual Wasm build exercised
  promised assets and fallback with tagged Gateway auth in Node and Bun,
  checking the auth header and exactly one inference per case. Bun native auth
  fixtures reexec with fake endpoints inherited at startup, since changing
  `process.env` alone does not change libc `getenv`.
- Session naming: shutdown keeps naming lifetime and upstream prompt settling.
  Upstream recovery copies made the previously latent checkpoint-only title
  hazard reachable. A reopened copy without a prompt keeps title ownership
  open for its first real prompt; an explicit title stays authoritative.
  Native ownership tests passed 4/4, and actual recovery/ask E2E passed 6/6.
- Structured inference: upstream original provider replay is preserved while
  an already-read terminal result wins cancellation. Failure wins over refusal
  or tool output. Typed rate-limit/provider/gateway-timeout/server failures
  retain durable outcome, usage, response identity, retryability, and replay.
  Focused tests passed 83/83 and actual structured E2E passed.
- Local gate support registers and imports the five new status, checkpoint
  title, cache, and picker canaries: 135 total. Workshop gate summaries and the
  fake-zig fixture require that exact total. Missing-target receipt tests clear
  the cycle's `MAINTAIN_UPSTREAM_SHA` so they actually exercise an absent target.
- One initial recorded gate on predecessor `f3642665` saw a recovery fixture
  seed process exit 1, before any recovery operation. The preceding full gate,
  100 bounded seed reproductions, and four focused recovery variants passed.
  The old fixture discarded subprocess output, so the original cause remains
  unknown. Commit `4b84f1bd` adds stage/stdout/stderr/signal/timeout diagnostics
  on the owning carry. Both complete gate runs passed on the final composition;
  no failure signature, quarantine, or automatic retry was added. Preserve this
  observation if the seed path fails again.
- Independent adversarial reviews covered authorization, lifecycle, session
  provenance, and naming. Concrete findings were repaired and rechecked.
  `MAINTAIN.md` now fully requires the status, provenance, async-auth/package,
  durable typed-failure, and recovered-title boundaries. Upstream still does
  not replace these carries; no carry retirement or upstream offer is pending.
- Composition contains only committed carry heads. The existing admission
  hooks and dependency graph remain authoritative. Accepted rerere resolutions
  were reread against both sides; replay reports were inspected for dropped
  lines. Keep rerere enabled, but do not trust its old corrupt
  `src/core/agent/worker_runtime.zig` return-type resolution.
- Pinned reconciliation `--check`, `--apply`, and final `--check` passed against
  the captured upstream. All 32 publication targets match the frozen manifest;
  all other heads in the 175-head fork graph are unchanged. Supervision uses
  trunk `integration` and mirror `main`; its check passes. Style extraction
  from installed Integration reports no drift. Terminal quarantine blobs still
  match their committed pins, with all six probes passing.
- `DELETEME/carry/launch-permission-mode` remains exactly
  `ed0b75e490a63263149918e7d3af95470768aa2c`, recording the prior explicit
  human decision. Maintenance never moves it or infers another deletion.
- Hosted Full CI is nonblocking observability and was not awaited for shipping.
  Agentsource's fleet-wide watcher owns later failure reporting. The complete
  native suite is not a Local gate step.
- AgentVoice's separate complete non-Cove regression last passed on `e1b20262`
  (2026-09-04); this cycle's broker 4/4 and voice 7/7 gate checks passed.
- Upstream retains `terminal:exec` as a legacy alias for `shell`; bare
  `terminal` is unknown. `ask` retains the fork's invocation controls. Current
  subagent public actions are `run` and `message`; obsolete schemas stay retired.
- The model-capability design at
  `~/handoffs/2026-09-04-fx-model-capability-exposure-design.md` remains outside
  this mandate with no promised start.
- Do not retire `/Users/arthack/src/fx/.git` or `/Users/arthack/src`.
  `/Volumes/Scratch/fx-maintain-20260904.J4a8X0/launch-control-continuity`
  remains an unrelated old-store worktree with 25 dirty paths, left untouched.
- Cycle leases, audit subjects, focused logs, gate logs, and publication proof
  are in `/tmp/fx-maintain-20260907.oxw55E`. All 31 clean cycle-owned worktrees under
  `/Volumes/Scratch/fx-maintain-20260907.wnNTUg` and the extra Wasm build prefix
  were removed after publication and installed-delivery recording, with no
  live process using their paths. Their branches and commits remain available.
  The maintenance board item is complete after the operator rerun and
  verification of the consumer postconditions.

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
- 2026-09-05: Audited the 15 commits in `478960a8..65d76390` (0 retired, 2
  repaired, 28 unchanged), repaired the sixteen deterministic hosted-CI
  failures on `ca773013` on their owning carries, moved two more
  composition-only artifacts onto heads (a retired canary registration and
  the steer-site admission hook, with voice control now depending on session
  naming), widened the Local gate to every carried root E2E test, passed the
  130-canary exact-SHA gate, atomically published and installed
  `61eb3da1`, and advanced AgentStart's exact consumer pin.
- 2026-09-06: Retired the redundant fxnk-specific Full CI polling daemon,
  local verdict ledger, and heartbeat while keeping hosted Full CI unchanged;
  Agentsource's fleet-wide local watcher remains the error-reporting owner.
- 2026-09-07: Audited all 110 commits in `65d76390..3c58c805`, including Fx
  0.0.8 (0 retired, 7 repaired, 23 unchanged; no material stance change).
  Reconciled selected-profile status, ADE finalization, shape/cache provenance,
  async libfx authorization/package closure, recovered title ownership,
  structured terminal outcomes, and gate canary ownership. Passed the
  135-canary exact-SHA gate and all 95 carried E2E definitions, atomically
  published all thirty carries with Main and Integration, and installed
  `e6ef2148`. AgentStart `16750931` pins it, validates, syncs resources,
  and regenerates the fleet snapshot. The operator's full installer rerun
  reached normal completion; guidance links, the collab manifest, and installed
  Fx receipt were verified, clearing the locked-desktop blocker. Audit frontier advances to
  `3c58c805`; the unrelated old dirty worktree and explicit marker are retained.

## Open before the next upstream absorb (2026-09-07)

- If the recovery fixture seed fails again, use the newly retained subprocess
  diagnostics to identify its cause; the original unrepeatable exit was not
  explained or quarantined.
- Retire the old Fx store only after its owner resolves the 25 dirty paths in
  `/Volumes/Scratch/fx-maintain-20260904.J4a8X0/launch-control-continuity`.
