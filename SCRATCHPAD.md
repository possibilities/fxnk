# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Current maintenance: 2026-08-31. The complete upstream audit, nine carry
  repairs, exact atomic publication, direct installation, final branch
  reconciliation, and the exact fmx and AgentStart consumer handoffs are
  complete. Hosted Full CI is running as nonblocking observability for the
  delivered Integration SHA.
- Upstream base and Main mirror:
  `ef03b480874a49a9cc508c39b7b98214c34178ee`
- Published and installed Integration:
  `beadc01a82891ef22bfa6cd3bc88f12edcec9176`
- Local development gate: exact-SHA receipt
  `~/.local/state/fxnk/local-gates/beadc01a82891ef22bfa6cd3bc88f12edcec9176.json`;
  contract `1cd051437c5f5f29cf398cd7ac95c1c5ee1f67a1224fd06a3bed70868a3b7e49`;
  recorded replay completed in 35 seconds with 61 of 61 canaries.
  `ship-gate.sh` printed
  `SHIP beadc01a82891ef22bfa6cd3bc88f12edcec9176`.
- Installed SHA-256:
  `62eeb7e014153845f474928b84ea03a95a06fd3cc7cd2f7a06096265ce8ea9b0`.
  The receipt, clean bound checkout, published ref, installed `fx`, and fmx's
  installed `fmx-fx` all match; both binaries report
  `fxnk 0.5.0 (fx 0.0.7)`, and Fx auto-upgrade is disabled.
- Both quarantine files recorded `pass` with zero failures and no signatures.
  Semantic review accepted subagent-manager blob
  `0e747981a4efd7c6d33296f83deed2cb59d47273` and render-replay blob
  `f09bf04a887405faad341f1bdea32e1bee455892`; the shared tmux-helper pin
  remains `a7ace9b57f359a8f845dad045edef6c5a3cc5626`.

## Audited-upstream frontier

- Complete through `ef03b480874a49a9cc508c39b7b98214c34178ee` on
  2026-08-31. The aggregate audit range
  `bb2dc7d557642c7e1c2e89176ca7721281dfb08c..ef03b480874a49a9cc508c39b7b98214c34178ee`
  covered fifteen upstream commits: the interactive MCP menu and its rendering
  contracts, consolidated MCP catalog pagination, reduced duplicate tool-result
  state, and stabilized PGSO terminal fixtures.
- Upstream disposition for the current twenty-five carries: 0 retired, 9
  repaired, 16 unchanged. The repaired carry heads were
  `carry/acp-state-isolation`, `carry/acp-tool-selection`,
  `carry/ade-event-feed`, `carry/edited-git-roots`,
  `carry/launch-control-continuity`, `carry/libfx-provider-authorization`,
  `carry/local-gate-support`, `carry/session-naming`, and
  `carry/state-system-prompts`. The unchanged carry heads were
  `carry/acp-capability-gates`, `carry/acp-permission-policy`,
  `carry/acp-project-instructions`, `carry/effort`, `carry/effort-catalog`,
  `carry/exclusive-skill-roots`, `carry/external-editor`,
  `carry/fmx-distribution`, `carry/fmx-work-control`, `carry/fxnk-version`,
  `carry/hosted-full-ci`, `carry/invocation-skill-roots`,
  `carry/notification-sound-single-flight`, `carry/resume-bounds`,
  `carry/system-prompt-files`, and `carry/terminal-probe-determinism`.
- No upstream replacement satisfies a remaining carry contract. Direct Codex
  operation beyond 64 sequential provider calls remains the one upstream-owned
  reliability behavior, at `dd409c27a7719e4dccaa30152c4e9087ec30edea`,
  and has no downstream carry. The delivered Integration baseline is
  `beadc01a82891ef22bfa6cd3bc88f12edcec9176`.

## Carried state

Integration composes twenty-five durable published carry heads. Every head below
is an ancestor of published Integration:

- `carry/acp-capability-gates`
  `3d92d036630c353c3c36e21f8e4df39aa4787439`
- `carry/acp-permission-policy`
  `2953553dd971cda86797ee0f626742d542245bfd`
- `carry/acp-project-instructions`
  `959777943d3a7d11c8d24efa1517459b600c7c16`
- `carry/acp-state-isolation`
  `0aabb3bb89c266bf6713ab86593e7ae1c52e8262`
- `carry/acp-tool-selection`
  `0ab8b7452645e64955d4889ccfb3a089136ff0d0`
- `carry/ade-event-feed`
  `5b5c85d8563cf2f74e4d4811cee8e82c6f6b5cb9`
- `carry/edited-git-roots`
  `6c594717725f37a4f6cce82981e30e66645113f2`
- `carry/effort` `7622b065c6b1eb5fee731345f32295cf2e616e0e`
- `carry/effort-catalog`
  `73b228766c967280164531f5a0dd5b703d5df423`
- `carry/exclusive-skill-roots`
  `c905bbc0797f1f88ddfca12f1dde807f9a7172eb`
- `carry/external-editor`
  `449a923b4689b6b002fc42ee36ecf99a23bab3a1`
- `carry/fmx-distribution`
  `2d825a6a30b984356a06ba0ce18cbc689131fcec`
- `carry/fmx-work-control`
  `4cfcef710cfbfbebd50a5a3c66876bff0bb1874a`
- `carry/fxnk-version`
  `4c9d931bc7d8d457460ff7dd4965df0599e27dfa`
- `carry/hosted-full-ci`
  `b21b2de296cfd04e30c54b75a5585d7a64342fb8`
- `carry/invocation-skill-roots`
  `9f4149dca38ea3545751fb416bed35f84368b1fd`
- `carry/launch-control-continuity`
  `7ebe1b3885a5d698b8a811b07a004e2158e8b609`
- `carry/libfx-provider-authorization`
  `66af3a4d51425bdacefeae4922da330d0f511308`
- `carry/local-gate-support`
  `17d131b57fc63fd01fdebc4b86d9841450190c0c`
- `carry/notification-sound-single-flight`
  `af2b516a586e68b3a7753b255b6d26a986f80598`
- `carry/resume-bounds`
  `215c4d8ff84c72fd7814677936009b0f3ab49e50`
- `carry/session-naming`
  `8b9ab4501cd888c299c006dd45d8da88d449b980`
- `carry/state-system-prompts`
  `18e8901917e412c2d27448002f739a6c29942e25`
- `carry/system-prompt-files`
  `19a8e2ef78ac9163852a0ef5e8a9be191fadc588`
- `carry/terminal-probe-determinism`
  `21b453509b59a3722dc67365ca8c45fc4e8b76b6`

All twenty-five carry heads are based on current Main or their declared
dependency. Hosted Full CI is the common base of every other carry, directly
or through its declared dependency chain. Session naming and edited-root
recovery depend on the ADE feed. Native-tool selection depends on the shared
capability gate. Launch-control continuity depends on every prompt, skill,
context, permission, tool, and state launch-control carry. State system prompts
depends on launch continuity and local gate support, and libfx authorization
depends on local gate support. Local gate support contains the complete product
composition.
- Direct Codex usage beyond 64 sequential provider calls remains satisfied by
  upstream commit `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream
  carry exists for it.

## Current notes

- 2026-09-03, this cycle in progress: two carries are being added together,
  `carry/codex-credential-authority` and `carry/acp-voice-control`, and the
  cycle absorbed a third upstream advance to `090c4582` to do it. Every carry
  was replayed onto that mirror with content verified file-set identical.
- Two agents worked in `~/code/fxnk` at once and the boundary slipped.
  Commit `0041272` is carry 2's Features commit with one paragraph belonging to
  carry 1 folded into it by a mistaken `--amend`; both paragraphs are correct
  and present, only the boundary is wrong, and it was left alone deliberately
  rather than rewrite history under a live writer.
- Rerere holds a corrupt resolution for `src/core/agent/worker_runtime.zig`.
  Replaying it stacks two return types on `admitPromptObserved` and cannot
  compile. Merges touching that file were resolved by hand with rerere off this
  cycle; the next maintainer should clear that entry from `.git/rr-cache`
  rather than trust it.
- `tests/e2e/acp.test.ts` had stopped parsing entirely at Integration
  `11e8d5cc`: an earlier replay fused two subagent tests into one `test(` call
  with two name strings. The gate never runs that file, so a whole cycle
  passed without noticing. It is repaired on `carry/acp-tool-selection`.

- 2026-09-02, by operator decision: the AgentWorkplace program is abandoned and
  its Fx-only additions are retired. Four behaviors left the fork - durable
  launch admission with final receipts, launch-time `--name` conversation
  naming, the private launch provider in both schema 1 and schema 2, and
  process-only `--permission-mode auto`. The upgrade-relaunch `--record`
  plumbing went with them, not as a retirement but because upstream
  internalized terminal recording.
- The retirement could not ship on the old mirror, so the cycle absorbed two
  upstream advances. The first, to `b8dd29f9`, produced Integration `081a3563`,
  which the ship gate then refused because `origin/main` had moved again. The
  second, to `49fc251a`, is what shipped: `SHIP 11e8d5cc`. Receipt:
  `~/.local/state/fxnk/local-gates/11e8d5cc417f0bacb63dc8a57bec98cb352a7b09.json`.
  Nothing was installed.
- The mirror is exact again. Local `main` and `fork/main` are both `49fc251a`,
  and `carry/hosted-full-ci` is `6835a182`; upstream did not touch the Full CI
  workflow across either advance, so the carried diff is byte-identical.
- `carry/launch-permission-mode` keeps its ref at `ed0b75e4`, leaves the
  composition and the inventory, and is marked locally as
  `DELETEME/launch-permission-mode`; no fork branch was deleted.
- The replay silently dropped the ADE feed's shutdown emission.
  `LifecycleAppRuntime.prepareStopped` and `ade_events.deinit()` sat directly
  beneath `subagents.deinit`, which upstream deleted with the subagent stores,
  so the resolution took upstream's side whole and fx exited without
  `FxStopped`. Restored on `carry/ade-event-feed` at `922284d9`. A carry whose
  lines sit adjacent to code upstream deletes is where a replay loses contract,
  and only the E2E fixture caught it.
- Upstream absorbed one carry outright. It adopted
  `layoutForTranscriptProjection` and its three call sites verbatim, so
  `carry/resume-bounds` now carries only the canary that proves the contract.
- Four carries were found carrying `carry/launch-control-continuity`'s
  upgrade-relaunch argv composition, one of them still rebuilding the retired
  `--record` flag. Each took upstream's path; the contract stays in its own
  carry, re-derived onto upstream's revision-carrying relaunch.
- `carry/libfx-provider-authorization` was re-specced by operator ruling.
  Upstream's libfx kernel made `createFxAgent()` refuse `env` outright and take
  flat `apiKey` and `model`, which the carry's `env.AI_GATEWAY_API_KEY`
  shorthand contradicted. The tagged `auth` entry, the Codex session store,
  account pinning, catalog loading and the WebAssembly Gateway-only guard all
  survive; `auth` is translated into upstream's flat options before its guard
  runs, so upstream's own loader tests pass untouched.
- Three canaries were re-specified rather than repaired, because upstream's
  behavior changed under them: a manual queue review is now refused while
  steering is pending, an empty managed skill root now produces its own
  diagnostic, and a partially built ACP server state must declare it has no
  host tools.
- Two quarantine blob pins moved after review. Upstream renamed the setup hub
  to the provider picker, changing one expectation in the render-replay
  fixture, and removed the post-tool decision prompt from the tmux helpers.
  Neither touches the tolerated session-exit timeout signature.
- Two carries had the retired code in their trees while none of the retired
  commits was an ancestor. `carry/local-gate-support` sat on the Phase 1A
  composition, and `carry/state-auth-borrowing` descended from `54a2a9a9`, a
  squashed recomposition of the whole downstream stack. Ancestry checks alone
  do not prove a carry clean; scan the tree.
- `carry/state-auth-borrowing` now sits on `carry/acp-state-isolation` and
  declares its four canaries on `carry/local-gate-support`, because its
  dependency has no `tests/fxnk/runner.zig`. `carry/structured-inference`
  declares its fifteen there for the same reason.
- The canary inventory is 89, down from 134. The ADE E2E fixture is three
  tests, down from four: the fourth covered the retired `--name` flag.
- Backup refs are under `refs/awp-retire-backup/` for the pre-retirement heads
  and `refs/awp-b8dd-backup/` for the `081a3563` heads. Do not prune or gc
  `~/src/fx` while they matter.

- Fx now exposes one authenticated semantic work-control endpoint per opted-in
  interactive main Agent. Snapshot, queue, steer-with-safe-fallback,
  cooperative interrupt, queued-item update/delete, and queue resume use Fx's
  native admission order and return authoritative post-operation state. The
  surface does not control permissions, questions, sessions, subagents,
  settings, or queue reordering, and remains independent of ADE.
- fmx `10b7c878615814b07ab7ae3955786a501a188a57` retains the eleven-tool
  stdio MCP surface and advances its exact Fx source pin to Integration
  `beadc01a`. Its exact isolated gate passed 407 tests with 18 intentional
  skips plus both PTY E2Es. The source installer and `fmx doctor` passed; the
  installed Fx SHA-256 is the same as the Workshop binary, and the Companion
  is `0.7.0+fmx.2ffb1c1e425f`.
- AgentStart `e6128efb42b8a2209b89c9b47aa610f8887af4df` advances the exact
  Integration pin, its check-plan assertion, and the fleet pin map. Full
  validation and convergence passed; both Fx binaries report
  `fxnk 0.5.0 (fx 0.0.7)` and are byte-identical, `fmx doctor` passes, and the
  installed Collab manifest is the expected policy-qualified form of
  agentguidance's source template. Cass declined a nonessential refresh for
  low disk headroom while its healthy lexical index still covered all 3,042
  known conversations; no user data was removed or compacted.
- Focused, unrecorded, and recorded proof completed with all 61 downstream
  canaries, the focused CLI and ADE integration paths, the clean three-case
  selected-profile MCP rerun, both terminal quarantine probes, and fresh-binary
  checks passing.
- Post-install reconciliation check/apply/check kept Main, Integration, and
  all twenty-five declared carries exact, preserved 142 unrelated fork heads,
  and found no `DELETEME/*` ref. It ran from a clean exact-ref checkout so the
  unrelated active `fx-fmx-work-control-20260829` worktree and the checkout
  with 817 intentional staged deletions remained untouched. The bound checkout
  is clean on Integration. Style extraction reports no drift.
- MCP Add, Remove, and logout now resolve and mutate the selected `--state-dir`
  profile instead of ambient `HOME`. Two residual UI follow-ups remain
  deliberate future work: make MCP menu action eligibility status-aware and
  render the selected profile path instead of the literal `~/.fx/mcp.json`.
- The gate reads its contract from the path it is invoked through:
  `local-gate.sh` sets `root` from its own location. Invoke the canonical
  `~/code/fxnk/scripts/local-gate.sh` while that checkout is clean on `main`,
  or prove a different Workshop worktree's four contract files byte-identical
  to `main`; a branch label alone does not establish the receipt contract.
- Hosted Full CI blob `a512d762b94e9b964f2983c545be1bf2cf7f8de3`
  admits only Integration pushes and manual dispatch and uses one constant
  cancelling concurrency group. Run `33357494147` is the sole run created by
  this publication, for exact Integration `beadc01a`, and remains in progress
  as nonblocking observability. Publication and final reconciliation created
  zero carry runs.
- The watcher refreshed
  `~/.local/state/fxnk/full-ci/pending.json`; it is not overdue and retains
  four historical obligations. Run `33284331921` for `559bbd62` is a real
  cross-platform failure in the workspace launch-modifier CLI test; its
  repaired paths are green in `4cd9c45a`. The `c83be4d7` split-HOME defects
  and `ec1cbc3a` canary-runner defects are also repaired, while `0deb9806`
  never received a run. These receipts remain historical evidence under the
  watcher's retention policy rather than shipping authority.

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
