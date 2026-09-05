# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Current maintenance: 2026-09-05, second cycle. One-shot upstream snapshot
  `65d76390260d3daeccb258e873be144c1e6160c4` is mirrored as Main. Thirty
  durable carries are published in installed Integration
  `61eb3da1b8f4286fa52694cf9b032c241ddba224`; the bound checkout is clean,
  and local and remote Integration agree exactly.
- Local development gate receipt:
  `~/.local/state/fxnk/local-gates/61eb3da1b8f4286fa52694cf9b032c241ddba224.json`.
  Contract digest:
  `404718b76b5a1b120be79a05f826ba503abe2b6fb50b8ae0274bd0ce774279e3`.
  The 236-second gate passed 130 of 130 canaries, CLI 4/4, ADE 3/3,
  credential broker 4/4, voice 7/7, every carried root E2E test
  (89 tests across 12 owners), and quarantine
  1/1.
- Installed SHA-256:
  `eea93182dc4d6f666442ae765c1374dcf6442e54bbdd0fd27765fb15e6e96934`.
  `/Users/arthack/.local/bin/fx --fxnk-version` reports
  `fxnk 0.5.0 (fx 0.0.7)`.
- AgentStart's exact Fx consumer handoff is
  `03bc13ce6087d343d3c7356f91c99c900b7cd1b5`: the pin, installer plan line,
  validation fixture, and fleet map name `61eb3da1`. Its validation passes on
  a clean worktree of that commit, its convergence installed Fx `61eb3da1`
  before stopping at the unrelated retired-Pi guard, its fleet snapshot could
  not be regenerated behind the snapshot guard, and its `main` is pushed.
  fmx remains deprecated and is not a consumer.

## Audited-upstream frontier

- Complete through `65d76390260d3daeccb258e873be144c1e6160c4` on
  2026-09-05. The 15 commits in
  `478960a8ab9315507e0a40d4434df71898fadf13..65d76390260d3daeccb258e873be144c1e6160c4`
  (5 first-parent merges: immediate steering transcript #682, provider event
  framing #681, Gateway auth diagnostics #683, conversation summary
  separation #684, reviewer metadata tolerance #685) were read in groups and
  every carried feature received one disposition: 0 retired, 2 repaired,
  28 unchanged. The same cycle repaired the sixteen deterministic hosted-CI
  failures the previous Integration `ca773013` exposed, each on the carry
  that owns the failing test.
- Direct Codex operation beyond 64 sequential provider calls remains the
  upstream-owned reliability behavior at
  `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream carry exists.

## Carried state

Integration composes thirty durable published carry heads. Every head below is
an ancestor of published Integration:

- `carry/acp-capability-gates` `bf72e5ea0422b635c03bf905c827b853185e0425`
- `carry/acp-permission-policy` `b059fe3285882e75051d23b1630c931f144d231f`
- `carry/acp-project-instructions` `74ebaa4aa92264a8ec0f37ac6732425c56a87067`
- `carry/acp-state-isolation` `d5e361cd4d34418ed359db882bc22e0a6dd45fcb`
- `carry/acp-tool-selection` `404a80ae6eabd30eb30f6ba4e5b30ad46f821266`
- `carry/acp-voice-control` `f34dbfec730c7e92f1734076b90ecc3aa0a070d4`
- `carry/ade-event-feed` `6ac2b52657653a8295da22656bab7973e97268bc`
- `carry/agent-shape-sessions` `962a5b6cc0c5222b5c6aee9cc29324ae5e17a307`
- `carry/codex-credential-authority` `f3725c78a73ff0d61b59211329d2f35780aadc67`
- `carry/edited-git-roots` `40258020901ffb1c98e7ac61b5e53e11dad30b5e`
- `carry/effort` `453276f83bb9925bf7dce37f8b062ecfba495e5e`
- `carry/effort-catalog` `12ea5f7f21b32c7819aedb5b07a2411a1cdab0ae`
- `carry/exclusive-skill-roots` `5359be0c7802f81aeaf473f7aad1d13a5597fcd6`
- `carry/external-editor` `bbd2a073ec0e518952b53fb2741d51032f168fb0`
- `carry/fmx-distribution` `f5cd558b189c65fbc25a299ffecfabf1e76c5bcb`
- `carry/fmx-work-control` `8414eac74c4cd0fdd4d740ee9d97139fae3ac339`
- `carry/fxnk-version` `509a19f9b8a35aaf7fc71d053f3956b6bef36be1`
- `carry/hosted-full-ci` `f5cd558b189c65fbc25a299ffecfabf1e76c5bcb`
- `carry/invocation-skill-roots` `158171acffb0a650e3ec561df11ea140eb768d7c`
- `carry/launch-control-continuity` `10ac80db8b681380dab470433406adfab0c459ae`
- `carry/libfx-provider-authorization`
  `b96afa8dc224b6663b32ebed347f7a5b98426967`
- `carry/local-gate-support` `21b89a5bd2fd25956cf579f1122f5f2fc0805bfc`
- `carry/notification-sound-single-flight`
  `f3d09cefbfe2ef99f141f24d581e3fe8abd7ee03`
- `carry/resume-bounds` `29d3514a50d73df0370d26ce46806b6290e7173c`
- `carry/session-naming` `7a65da551fa684018117fb76cf654a523e0e7ede`
- `carry/state-auth-borrowing` `64948967e9bc0475915e5551d7686736fa68bf01`
- `carry/state-system-prompts` `e3f9449c3375b0104f1700afac75ca8aeefc375e`
- `carry/structured-inference` `38c5a8c43a49f00b388e90151a9daf2963e5f661`
- `carry/system-prompt-files` `04452d82c1bf0c7488749323fa68d165cd450532`
- `carry/terminal-probe-determinism` `a2b2762ae1cf68c0b7adc8f8e7ec8124ee5b6d83`

All thirty heads are exact published refs and ancestors of Integration. The
2026-09-05 reconciliation matched Main, Integration, and every carry to the
declared graph while leaving unrelated fork heads unchanged.

## Current notes

- Exact branch reconciliation against captured upstream `65d76390` passes for
  Main, Integration, and all thirty carry refs. Supervision is configured and
  verified with trunk `integration` and mirror `main`. Style extraction from
  installed Integration `61eb3da1` reports no drift.
- `DELETEME/carry/launch-permission-mode` records the 2026-09-05 human
  decision to close the abandoned agentworkplace carry; maintenance reports
  it and never moves it.
- Composition-only code must not recur: every candidate is a merge of
  committed carry heads and nothing else. This cycle found two more artifacts
  that only a recorded merge resolution had been dropping, and moved each onto
  a head: `carry/ade-event-feed` registered a canary for a test upstream had
  removed, and the work-control steer site's lifecycle hook and naming
  admission met only in Integration, so `carry/acp-voice-control` now depends
  on `carry/session-naming` and composes that site itself.
- The local gate runs every carried root E2E test: each test in a root owner
  whose text differs from the captured upstream, or every test of an owner
  that differs only in shared helpers, selected by name and required to
  execute exactly. Upstream's unchanged tests remain hosted-CI observability.
  Every deterministic hosted failure on `ca773013` lived in a carried test
  that no local step ran; that blind spot is closed.
- Upstream's Codex catalog refresh (#628) rejects any catalog that does not
  list the reviewer model `gpt-5.6-luna` and advertises client version
  0.153.0; every fork catalog fixture now serves the reviewer model, and the
  structured inference provenance names the refreshed version.
- Upstream's MCP rebuild (#639) starts every server with legacy
  initialization unless `FX_MCP_PROTOCOL_VERSION=2026-07-28` is present, and
  offers the panel's logout only for a server that connected with
  credentials; the ACP state-root and selected-profile pending-trust probes
  follow both rules.
- Upstream's Responses text reconciliation (#677) abandons a completed
  terminal event when cancellation is pending; structured inference reverses
  that on `carry/structured-inference`, and its restated upstream tests
  document the rule. Reread the reducer on every upstream change to
  `src/gateway/responses_protocol.zig`; #681's complete-event framing kept
  the rule.
- Upstream's conversation storage (#608) derives and commits the first-turn
  title itself. `carry/session-naming` keeps a title committed through the
  rename path authoritative over that derivation, installs the derived title
  under the commit lock without relocking, and treats a saved session's
  derived title as durable native metadata. Its one title request per saved
  session is excluded from upstream's provider-preparation request counts.
- The selected-profile Codex account pin lives on
  `carry/launch-control-continuity`, where `--state-dir` meets the
  account-pinned session store, not on `carry/codex-credential-authority`.
- Hosted Full CI: `~/.local/state/fxnk/full-ci/pending.json` holds seven open obligations and is overdue; the recorded verdict for `ca773013` is `failed` (sixteen deterministic failures, every one repaired in this cycle on its owning carry, plus native races that did not reproduce locally in forty runs). The watcher records the verdict for `61eb3da1` on its own; a red verdict there is the next cycle's first task.
- The full native suite (`zig build test`) is not a gate step. Run on this
  machine it reports only shell-profile noise failing; the hosted run is the
  clean-environment proof.
- AgentVoice last passed its complete non-Cove voice and credential broker
  regression on Integration `e1b20262` (2026-09-04). The broker wire contract
  is unchanged in `61eb3da1`.
- Upstream's shell-managed execution keeps the legacy `terminal:exec`
  selection token as an alias of the `shell` tool; a bare `terminal`
  selection is unknown. The `ask` launch retains permission policy,
  project-instruction, state-root, skill-policy, and native-tool controls,
  and every usage line those gates print names it; CLI probes that need a
  refused launch use `fx models`.
- Adversarial review of this cycle's five behavior changes found no defect.
  One latent hazard is recorded, not applied: `createNativeSession` marks a
  present derived title committed, and a non-empty history with no prompt
  candidate would derive the "Untitled session" placeholder as present. No
  production path creates such a session today; guard it with a prompt
  candidate check if a same-process copy or fork feature lands.
- The model-capability design at
  `~/handoffs/2026-09-04-fx-model-capability-exposure-design.md` is not part of
  this mandate and has no promised start.
- Do not retire `/Users/arthack/src/fx/.git` or `/Users/arthack/src` yet.
  `/Volumes/Scratch/fx-maintain-20260904.J4a8X0/launch-control-continuity`
  remains an old-store worktree with 25 dirty paths and must be handled by its
  owner before retirement.
- The copied rerere cache still contains a known corrupt resolution for
  `src/core/agent/worker_runtime.zig`: it stacks two return types on
  `admitPromptObserved`. Never accept that resolution as proof; clear or
  bypass it and re-derive the merge by hand. Every resolution this cycle
  accepted was compared against the two sides line by line first, and the
  steer-site resolution was re-recorded.

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

## Open before the next upstream absorb (2026-09-05)

- Hosted Full CI must reach a verdict for `61eb3da1`; the watcher
  records it. A red verdict there, or a persisting `unclassified` obligation
  for a superseded SHA, is the next cycle's first task. The native races the
  `ca773013` run also showed (0 of 40 local reproductions) are recorded, not
  repaired.
- AgentStart's convergence stops after installing Fx at its retired-Pi
  guard: AgentLaunch's pushed `main` (`8ba25149`) is two commits past the
  reviewed retirement commit `c4bb316d` ("smoke: read the deployed-sha mode
  with GNU stat first", "ci: pin bun to 1.4.2"). Advancing the reviewed
  commit is a human review, not maintenance.
- AgentStart's fleet snapshot guard refuses the managed `plannotator` skill's
  retired `pi` spelling, so `site/public/fleet-resources.json` still embeds
  the previous Fx pin `ca773013` until that skill or the guard changes.
- Replay helpers from the 2026-09-04 cycle remain under `scripts/resolvers/`;
  this cycle's helpers were disposable scratch and are not kept.
- Retire the old Fx store only after the owner resolves the 25 dirty paths in
  `/Volumes/Scratch/fx-maintain-20260904.J4a8X0/launch-control-continuity`.
