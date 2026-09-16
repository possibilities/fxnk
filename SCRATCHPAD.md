# Maintenance scratchpad

This is current state for `/maintain`. The skill reconciles it each cycle.

## Baseline

- Fx delivery: 2026-09-16. Captured upstream `a8200bff1621c43476b0fa14f0ed523d09101b70` is mirrored as Main.
  All thirty durable carries are published atomically in Integration `e639de6aded41ae168a8888b920ff71db41877d0`.
  Bound checkout, remote Integration and installed receipt agree exactly.
- Exact macOS-arm64 gate receipt: `~/.local/state/fxnk/local-gates/e639de6aded41ae168a8888b920ff71db41877d0.json`.
  Contract digest: `ab4c706e671b5cc1ab50575a54c11e24f4d52ce374b93078da2d69bc7ddb0a2a`. Full development gate passed
  in 281 seconds; recorded gate passed in 173 seconds.
  Both prove 141/141 native canaries, focused CLI/ADE/broker/voice, 102 carried
  E2E definitions across 14 owners (each selected execution verified), six
  terminal replay probes, and fresh binary/catalog checks. No quarantine used.
- Installed SHA-256: `4d99b8317fc44939942fb6deccc89eb88254bcd98c1ac2cc2800088df1f28edc`. Fx reports `fxnk 0.5.0 (fx 0.0.10)`.
  Only the supported installer built and rebound the checkout; auto-upgrade
  remains disabled.
- AgentStart consumer commit `fe00ccc59fe971ca21e00e428cc7fb38be823193` pins this exact Integration in its
  installer, plan, validation fixture, fleet map and regenerated snapshot.
  Validation passes with canonical `TMPDIR=/private/tmp`; resource sync and
  installed collab manifest comparison pass.
- **Consumer full convergence is assigned to the root agent after this worker
  returns.** Its current LaunchAgent PATH rendering would reload live services.
  Root explicitly reserved `AGENTSTART_PRESERVE_AGENTVOICE_SERVICE=1
  ~/code/agentstart/scripts/install.sh --install` and the coordinated restart.
  Do not claim this final consumer step has run from the Fx delivery alone.

## Audited-upstream frontier

- Complete through `a8200bff1621c43476b0fa14f0ed523d09101b70` on 2026-09-16. All 400 commits in
  `3c58c8051be288079d6d23fe90bb7b08f9841dc8..a8200bff1621c43476b0fa14f0ed523d09101b70` were reviewed with
  disjoint exact commit ledgers. **0 retired, 18 repaired, 12 unchanged.**
  No material contribution stance change; regular maintenance remains
  downstream-only. No product decision remains unresolved.
- Meaningful groups: configured providers and profile-route authority;
  30-second auth freshness cache; managed child topology/feedback; compaction
  and checkpoint lifecycle; durable session and recovery publication; CLI
  provider/model/effort overrides; upstream automatic session titles; ACP tool
  presentation; SDK package/wasm support; terminal rendering and input changes.
- MAINTAIN's stale masked-evidence clause was reconciled to the installed
  bounded unmasked terminal-safe prior-result contract by explicit root decision.
  This cycle introduces no classifier masking policy change.
- Exact source audit and behavioral evidence:
  `/Users/arthack/worktrees/fx/maintain-20260916/evidence/` (`upstream-audit.md`,
  `upstream-commits`, carry reports, focused logs, both gate logs and publication).
- Direct Codex operation beyond 64 sequential provider calls remains
  upstream-owned at `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no carry exists.

## Carried state

Every head below is published and an ancestor of Integration `e639de6aded41ae168a8888b920ff71db41877d0`.
MAINTAIN remains the behavioral and retirement authority. No carry was retired.

| Carry | Published head | Disposition | Audit evidence |
| --- | --- | --- | --- |
| `carry/acp-capability-gates` | `5e9518a692e66043760e5d1c48978dae966b15c6` | repair | Upstream extracted ACP tool-call presentation. Native suppression now delegates through shared presentation nativeToolSet; active tool advertisement/dispatch retains explicit empty authority. Global provider/model flags coexist with suppression. Upstream internal allow_native_tools alone has no equivalent launch admission. |
| `carry/acp-permission-policy` | `9d311dee3aedae01a178aa2bcacfeb8faa41af11` | unchanged | Upstream permission diff removes only unused permissionRuleCategoryForGrant; configured-before-saved denial ordering remains. Launch policy file canonicalization and replacement of ambient rules remains absent upstream. New global model/provider grammar composed without altering policy behavior. |
| `carry/acp-project-instructions` | `ab3d4081afc1c091d1d7a8b3d51f7d943823913a` | repair | Clean merge missed new reconstructProjectContext path, which reopened project prose from retained history. Added early suppression guard plus propagated flag and a cancelling-provider regression. Child model-capability callbacks retain process suppression: deps.project_instructions_enabled still reaches orchestrator context requests, with child propagation alongside new callbacks. No equivalent upstream global suppression. |
| `carry/acp-state-isolation` | `c7ba3129e579bf3da642b2d3754d3fa8800128e8` | repair | Configured provider authentication newly introduced upstream needed selected-profile registry loading instead of provider_catalog.find(.configured) or ambient registry access. Added FromHome registry resolver and native regression. Selected-home ACP/TUI/child refresh callbacks bypass source-only global 30s verification cache; explicit-home refresh remains account-checked. Bounded instruction reconstruction retains distinct real workspace home and selected profile home. Provider override carried through selected startup loader. |
| `carry/acp-tool-selection` | `03aa0f11c5ba03613067e5e8e8132a2d69f5c200` | repair | Upstream historical command display adds session-command fallback. Kept validated wrapped commandArguments extraction before that fallback. Extracted ACP presentation delegates to server.activeToolSet, preserving selected allowlist even for replayed tool presentation. Existing terminal:exec narrowing/stop-on-return survives shell retry-guidance additions. |
| `carry/acp-voice-control` | `8833692ea7d408081d6ef40a0132792fe6f7a1ac` | repair | Retain FIFO steering, shared lifecycle/attention projection, recovery catalog union and managed child identity. |
| `carry/ade-event-feed` | `34b176dbd92ebd828425ca5a0922b71d6fe35b26` | repair | Retain captured root/lifecycle attribution alongside current managed child and prompt admission APIs. |
| `carry/agent-shape-sessions` | `7d2a3a450db71ca01d8580baa803ffd1bcf3a213` | repair | Composed tagged saved provider identities, configured connections resolving from selected definitions despite borrowed built-in identity, explicit shutdown failure semantics and upstream new cold-session metadata with existing provenance. New compaction_prepared checkpoint path lacked shape authority; now stamps the same digest/label as other recovery checkpoints, with regression canary. Discovery/cache/clone paths retain account and shape fields, disposable cache remains v5. |
| `carry/codex-credential-authority` | `4c653e74f196586d3e72364d19d5deb591ab5339` | repair | Broker descriptor lifecycle preserved alongside upstream provider/model launch grammar. ShutdownOutcome save failure propagates before controlled upgrade, while a broker-bound process still refuses replacement that would lose its nonce. Existing startup-order fixture now returns the new shutdown outcome. No token/descriptor authority leaked into argv or environment. |
| `carry/edited-git-roots` | `c39d4c5dc32eda38fd4042cd133f17e1b952c2cc` | repair | Preserve committed write/shell observation and delayed captured-root discovery; managed-root native proof passes. |
| `carry/effort` | `930feda163f3cfc557a94f1f2214cc1a0a5ec44e` | repair | Upstream CLI effort/fast/provider process overrides and resumed preference handling complement FX_EFFORT/ACP --effort. Preserve configured effort separately; command-line effort wins over environment, environment wins saved resume preference; upstream fast/provider overrides remain intact. Kept both new configured-provider provenance tests and carried effort tests. ReleaseSafe build passed; fresh --version 0.0.10 and ACP --help expose exact flag. CLI FX_EFFORT fixtures 2/2, 19 assertions pass. ACP fresh-binary proof 3/3, 26 assertions passed. |
| `carry/effort-catalog` | `e7bdf0926a6b0ae2363973ba9411fff25f7862c4` | repair | Upstream ProviderId now supports configured connections with display-name projection. JSON uses upstream providerDisplayName while retaining ordered reasoning_efforts and catalog row/count alignment. Exact-composition catalog gate passes. |
| `carry/exclusive-skill-roots` | `22926068b27c55fe3aa15dded12683a1b1dfe628` | unchanged | Skill runtime changes retain invocation-root policy boundaries; exclusive flag still disables workspace/global/compatibility roots while permitting ordered invocation roots. Global CLI model controls composed; upstream provides no equivalent exclusivity. |
| `carry/external-editor` | `aea9b2d4332391fa98023e0d69f2a970b238d517` | repair | Upstream added Ctrl-P replay handling and removed retired Ctrl-X constant; retain Ctrl-G editor and Ctrl-T upgrade, union control replay bytes, and concise editor documentation in rewritten README. Preserve new compaction test shard owner. Actual editor E2E and exact-composition gate pass. |
| `carry/fmx-distribution` | `d0bebd4d15183e7c2a49dddc204adaed134ca611` | unchanged | Explicit preserved alias of hosted-full-ci; fast-forwarded to same commit. |
| `carry/fmx-work-control` | `60dd85ee8049880a0a625b5e036bd0eb031bf7cf` | unchanged | Authenticated semantic work queue remains absent upstream; real socket lifecycle/queue smoke passes. |
| `carry/fxnk-version` | `39eb668060532f5edc5c638c693db0bf2aedf0b8` | unchanged | Upstream version advances embedded Fx to 0.0.10, fork probe remains independent and absent upstream. |
| `carry/hosted-full-ci` | `d0bebd4d15183e7c2a49dddc204adaed134ca611` | unchanged | Upstream workflow job changes retained, Integration-only push plus manual dispatch and constant cancellation group preserved. No product content retired. |
| `carry/invocation-skill-roots` | `4039dd8f4d934b04a1bbedfd3080dc9d5b90ff38` | unchanged | Upstream skill lifecycle changes preserve passed invocation policy and catalog; added bootstrap model override argument retained alongside test skill-root dependency injection. README simplified upstream prose retained with only invocation-specific instructions restored. Canonical ordered invocation roots remain absent upstream. |
| `carry/launch-control-continuity` | `892420011368d6350cb01eb066459e770ca1e177` | repair | Merged all 22 declared dependency heads. Preserved combined launch grammar and ownership, selected-profile configured provider registry, explicit identity and credential-store authority, upstream CLI model/effort/fast overrides, and retained project-instruction suppression. Reused resolutions checked against owning carries; production worker_runtime equals checked ACP lifecycle carry, and protocol transport code equals structured inference. |
| `carry/libfx-provider-authorization` | `5c7afd5da3467947057a7cf62e70c6c05ab7b7d9` | repair | Tagged provider allowlist, staged borrower lifetime, explicit store/account validation independent of global freshness cache. |
| `carry/local-gate-support` | `5a311259c7a5949c624e7035a0fb8c8dd0e4e518` | repair | Updated exact shared canary inventory from135 to141: selected configured-provider profile, retained instruction reconstruction, Codex store/account cache boundary, configured-provider allowlist, borrowed ACP preparation, and prepared compaction provenance. Imported retained-context test owner explicitly. |
| `carry/notification-sound-single-flight` | `3100a085c8eef2d972572a30c71020a7480635a8` | unchanged | Upstream sound.zig and notification hooks unchanged over interval. Existing process-owned SharedState single-flight player/reaper and unconditional bell remain necessary; upstream still spawns without carry's bound. |
| `carry/resume-bounds` | `83800fff9ca32baf14763d2e303e3851e87be989` | unchanged | Carry remains only a regression canary, as it already was at old frontier. Captured upstream layoutForTranscriptProjection validates against physical layout.rows and expands content_bottom; new retained-row publication changes complement it. No new production retirement claim. Exact native gate exercises the retained canary. |
| `carry/session-naming` | `6592afcff813ec2e106dd7b20a756953de41d55f` | repair | One interactive naming owner; new provider instruction lane, recovered title ownership, no ask/ACP requests. |
| `carry/state-auth-borrowing` | `12403c02ee9b1606803f929623c2f57d09712cd0` | repair | Composed new configured providers with process provider selection and selected-state startup. Empty FX_PROVIDER continues failing startup despite upstream ignore-empty behavior. Configured connection auth resolves only from selected profile, never borrowed authorization registry; saved credential borrowing remains read-only. Provider override propagated through borrowed and selected startup loaders. |
| `carry/state-system-prompts` | `760248255d072c552e3f1acda009e437818c758b` | unchanged | State prompt discovery remains explicit-state-only, case-sensitive exclusive SYSTEM/SYSTEM_APPEND with explicit invocation precedence; parser/ACP main and child paths retained. README keeps current upstream prose with only carry section. |
| `carry/structured-inference` | `edf03154e2266113cdd2fdcb5ecc510c290d39a4` | repair | Upstream CancelWatch preserves carried deadline and terminal/replay protocol; 94 focused native and 3 E2E tests pass. |
| `carry/system-prompt-files` | `8fd73733df89c03b84786f3746e687cd0a2234f5` | unchanged | Prompt replacement/ordered append file validation remains downstream; upstream compact README retained plus carried prompt-file section. New global provider/model parsing coexists with prompt arguments and ownership cleanup. No upstream replacement contract. |
| `carry/terminal-probe-determinism` | `dc606769b108b14734abd2e4d12f5df37d8a3bda` | unchanged | Upstream tmux helper adds separate title-response channel, v4 gateway URL and Escape-pair interrupt helper. Settled-writer wait and live-marker-only tape helpers remain absent upstream and carry additions unchanged. Full merged helper and render/replay blob deltas reviewed; exact pins updated without changing selected names or runtime-only timeout signatures. |

## Current notes

- Configured connections resolve only from selected profile definitions;
  borrowed built-in credentials cannot import another registry. Codex checks
  explicit store/account authority instead of trusting source-global freshness.
- Upstream prepared-compaction checkpoints now retain shape/credential
  provenance. Managed ADE child fixtures use current root-owned topology while
  preserving captured root attribution after delayed discovery/session change.
- Naming stays interactive-only with one carried owner and honors
  `session_titles=false`; provider system instructions use the current lane.
  Structured inference adopts upstream CancelWatch with its carried deadline.
- Integrated compiler repairs retain rich configured catalog entries, provider
  startup arguments, configured source display and exact broker shutdown rules.
  All repairs live on owning carries; no composition-only product patch remains.
- Native provider SDK proof covers NAPI, core Wasm, required Node 24 and Bun,
  store/account swap/refresh, timeout/cancel, HOME isolation and package imports.
  Structured proof passes 94 native tests and 3 E2E tests; managed ADE proof
  passes 43 focused tests. Complete gate covers the final composition.
- Gate temporary paths use `TMPDIR=/tmp` to avoid macOS Unix socket limits.
  A stale external-editor test hint was corrected from `ctrl o` to `ctrl+o`;
  actual guard behavior passes. Neither failure was quarantined or retried
  without a concrete cause/fix. AgentStart's unrelated temporary-path assertion
  uses canonical `TMPDIR=/private/tmp` to avoid `/var` symlink spelling drift.
- Style extraction follows the surviving visual_layout input-prefix producer;
  dead right_tag was removed. Palette values are unchanged. All six viewer
  sections/theme toggle were inspected in a real PTY; welcome captures were
  refreshed. PNG terminal background is termctrl's dark default even when Fx
  foreground tokens are light; this capture limitation is documented.
- Atomic publication moved only Main, Integration and the thirty declared
  carries. All other remote refs and the prior publication branch remain.
  Reconciliation and supervision checks pass. Hosted Full CI is nonblocking;
  Agentsource owns later failure reporting. No upstream fetch/chase was repeated.
- Root owns the deferred AgentStart full installer and coordinated app/service
  restart. This worker did not restart a live app or fleet service.
- Preserve `DELETEME/carry/launch-permission-mode` and all unrelated worktrees.
  Do not retire `/Users/arthack/src/fx/.git` or `/Users/arthack/src`.
  The old `/Volumes/Scratch/fx-maintain-20260904.J4a8X0/launch-control-continuity`
  dirty worktree remains outside this cycle. The old unexplained recovery seed
  failure remains historical; current full gates and diagnostic fixture pass.
- Cleanup removes only clean owned cycle worktrees after process checks;
  retained branches and evidence preserve the audit. Final cleanup receipt is
  `evidence/cleanup.log`. fmx remains deprecated and is not a consumer.

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

- 2026-09-16: Audited all 400 commits through `a8200bff`, repaired 18
  carries and retained 12 unchanged, retired none. Passed the 141-canary exact
  gate, atomically published and installed `e639de6a`, advanced AgentStart's
  pin/map/snapshot, and handed its full convergence/restart to root explicitly.

## Open before the next upstream absorb (2026-09-16)

- Root must record completion of the reserved AgentStart full installer and
  coordinated restart before declaring the consumer handoff fully complete.
- If the historical recovery seed failure recurs, use retained subprocess
  diagnostics rather than inventing a quarantine signature.
- Retire the old Fx store only after its owner resolves its dirty worktree.
