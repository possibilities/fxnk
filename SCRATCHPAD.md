# Maintenance scratchpad

This is current state for `/maintain`. The skill updates or removes stale
entries on every maintenance cycle and appends one compact history entry.

## Baseline

- Current maintenance: 2026-09-04. One-shot upstream snapshot
  `964c040491dcb40a4c6cc63ffdb0b89e9e85c9f4` is mirrored as Main. Thirty
  durable carries are published in installed Integration
  `e1b20262ba4b3392c8a848069e9c3fa0c69fd0a1`; the bound checkout is clean,
  and local and remote Integration agree exactly.
- Local development gate receipt:
  `~/.local/state/fxnk/local-gates/e1b20262ba4b3392c8a848069e9c3fa0c69fd0a1.json`.
  Contract digest:
  `15fe53413ea7c9bcaffcd2a1bd1eac7138d3dd501daf90023eeeebc6225100fb`.
  The 177-second gate passed 116 of 116 canaries, CLI 4/4, ADE 3/3,
  credential broker 4/4, voice 7/7, and quarantine 6/6.
- Installed SHA-256:
  `11d6d7d9ba28a786d409ee167a66870dbf5dce4f9fb73d405fed18b416bdb40b`.
  `/Users/arthack/.local/bin/fx --fxnk-version` reports
  `fxnk 0.5.0 (fx 0.0.7)`.
- AgentStart's exact Fx consumer handoff is
  `9da5d08d8a5f1e81eeffcc32d43c412d7c0298d6`; validation, installation,
  exact Fx pinning, current Smolmux contract, and retirement guards passed.
  Its subsequent source-root migration is published on `origin/main` at
  `062c47af7eca871304aa3efcbd3a5395830040e5`. fmx remains deprecated and is
  not a consumer.

## Audited-upstream frontier

- Complete through `ef03b480874a49a9cc508c39b7b98214c34178ee` on
  2026-08-31. The 2026-09-04 delivery intentionally captured the later
  upstream tip `964c040491dcb40a4c6cc63ffdb0b89e9e85c9f4` for one shot, but did
  not establish a complete feature-disposition audit for the 413 commits in
  `ef03b480874a49a9cc508c39b7b98214c34178ee..964c040491dcb40a4c6cc63ffdb0b89e9e85c9f4`.
  Do not advance this frontier from delivery evidence alone.
- Direct Codex operation beyond 64 sequential provider calls remains the
  upstream-owned reliability behavior at
  `dd409c27a7719e4dccaa30152c4e9087ec30edea`; no downstream carry exists.

## Carried state

Integration composes thirty durable published carry heads. Every head below is
an ancestor of published Integration:

- `carry/acp-capability-gates`
  `f8a16159fe6528f0ee0cfd990e0e165a5a71ad9c`
- `carry/acp-permission-policy`
  `452e44337adb70606274d6153b9bafe42d46215c`
- `carry/acp-project-instructions`
  `321ffbdcb46184348f3995e9de402f7c0ff3c212`
- `carry/acp-state-isolation`
  `eca5f1226935fb5c4ff1d66ec07659a7abb57ae7`
- `carry/acp-tool-selection`
  `dbdc2c9e260734db4563e57ba954e06e782c68ec`
- `carry/acp-voice-control`
  `d789ff4fd342fdcca0986f586c320c0762556338`
- `carry/ade-event-feed`
  `57a5d80b4c45732afd61a7b437dd7a5c4b36970d`
- `carry/agent-shape-sessions`
  `e550181438fff16f37d7af68f41288925fd6d042`
- `carry/codex-credential-authority`
  `6172d636b6e51dbfef012aacb98c324f26f2b9c8`
- `carry/edited-git-roots`
  `a0884d9aba3920d6c5a95bb8cf107b3a10706f93`
- `carry/effort` `536220ca7cc386a9522f286bea0b0e1004be2da2`
- `carry/effort-catalog`
  `d857e5efc4f00ca32edc2dc4fb10ac94a6f29686`
- `carry/exclusive-skill-roots`
  `09a1568582454d35bb04ed9f5b512983e49ddf9b`
- `carry/external-editor`
  `b03653d9290d30a9578e7f31dc2404272c6908c5`
- `carry/fmx-distribution`
  `21304eaa2dcb80eb84eb95fc77ee2a04d760ee00`
- `carry/fmx-work-control`
  `bf27c29ec6a93a81d5cdb528afeb1abafb744de8`
- `carry/fxnk-version`
  `a17bd8d7c0f76a3b43c319567a1bb21c247b5614`
- `carry/hosted-full-ci`
  `21304eaa2dcb80eb84eb95fc77ee2a04d760ee00`
- `carry/invocation-skill-roots`
  `0a64bd78a3daf9375574ec190789604e6e3990e8`
- `carry/launch-control-continuity`
  `b3787068fad2a66d1d214f245016c1369c1d812a`
- `carry/libfx-provider-authorization`
  `0c21937745e3ac920be8bc3da1e768d296dfb16b`
- `carry/local-gate-support`
  `f188270a801147274d1a22fdbdc462ed80204eb4`
- `carry/notification-sound-single-flight`
  `77c5b37764042bb67eb415f08bfbe3416e52a2a6`
- `carry/resume-bounds`
  `0a990d31f4cb09e78a348996a3da413d549a9d32`
- `carry/session-naming`
  `8babb0d4c533ac174bd80f7a995278f4ac29d26d`
- `carry/state-auth-borrowing`
  `ae1db4a23c0b3ddbad83ba90963468fd8521acd5`
- `carry/state-system-prompts`
  `1b6a6b575d3a10e593e393ec5beee5fc4626ed7f`
- `carry/structured-inference`
  `5f6e13a75a9b66d992464d7bcdfa7db38d8c9890`
- `carry/system-prompt-files`
  `09f577292c3e84184c6e7e903a7d200dee8f473a`
- `carry/terminal-probe-determinism`
  `fcf04e3a94fc6076018fa1ecd2237f1b0ccf0d12`

All thirty heads are exact published refs and ancestors of Integration. The
2026-09-04 reconciliation matched Main, Integration, and every carry to the
declared graph while leaving unrelated fork heads unchanged.

## Current notes

- Exact branch reconciliation against captured upstream `964c040` passes for
  Main, Integration, and all thirty carry refs. Supervision is configured and
  verified with trunk `integration` and mirror `main`. Style extraction from
  installed Integration `e1b20262` reports no drift.
- AgentVoice independently passed its complete non-Cove voice and credential
  broker regression on the installed Integration: WebRTC connected, five RTP
  packets decoded, and 3.6 seconds of audible output were observed. The broker
  wire contract is unchanged for its current consumer.
- Hosted Full CI receipt
  `~/.local/state/fxnk/full-ci/e1b20262ba4b3392c8a848069e9c3fa0c69fd0a1.json`
  records run <https://github.com/possibilities/fx/actions/runs/33914543924>.
  It is nonblocking and failed composition checks: all E2E shards immediately
  lack `codex-credential-broker.test.ts`; all native architectures share nine
  failures and one CLI-catalog crash. Board item
  “repair Fx hosted Full CI composition failures” owns a future one-shot fix.
- The model-capability design at
  `~/handoffs/2026-09-04-fx-model-capability-exposure-design.md` is not part of
  this mandate and has no promised start. It is only input to a separately
  invoked future one-shot run against a newly captured upstream SHA.
- Source-clone migration is committed in this Workshop at `ed2471b`. The
  replacement Fx clone preserves all 961 old-store refs under
  `refs/legacy/src-fx/*`, 204 maintenance-repository refs under
  `refs/legacy/src-fx-maintain-20260830/*`, and all 467 rerere entries. Rerere
  is enabled with autoupdate in the replacement clone.
- Do not retire `/Users/arthack/src/fx/.git` or `/Users/arthack/src` yet.
  `/Volumes/Scratch/fx-maintain-20260904.J4a8X0/launch-control-continuity`
  remains an old-store worktree with 25 dirty paths and must be handled by its
  owner before retirement.
- The copied rerere cache still contains a known corrupt resolution for
  `src/core/agent/worker_runtime.zig`: it stacks two return types on
  `admitPromptObserved`. Never accept that resolution as proof; clear or
  bypass it and re-derive the merge by hand.

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

## Open before the next upstream absorb (2026-09-04)

- Disposition the 413 upstream commits after the audited `ef03b480` frontier;
  the successful one-shot delivery at `964c040` is not a substitute for that
  audit.
- Repair Hosted Full CI composition failures from run `33914543924` only in a
  separately invoked maintenance run with a newly captured upstream SHA.
- Replay helpers from this cycle are under `scripts/resolvers/`.
- `tests/e2e/acp.test.ts` is run by no gate step; it sat unparseable through a
  whole cycle. Consider a parse-only step.
- Pending test on `carry/acp-tool-selection`: under `--tool terminal:exec` an
  admitted one-shot run still stalls past admission.
- Retire the old Fx store only after the owner resolves the 25 dirty paths in
  `/Volumes/Scratch/fx-maintain-20260904.J4a8X0/launch-control-continuity`.
