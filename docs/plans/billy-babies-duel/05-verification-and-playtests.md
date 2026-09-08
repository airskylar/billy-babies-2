# Milestone 5 — Replays, verification, and playtesting

Status: implementation and test-session plan only; no playtests have been run.

[Prototype overview](../../../billy-babies-duel-prototype-plan.md) · [Previous](04-playable-duel.md)

## Outcome

Suspicious interactions can be captured and reproduced, automated runs expose rule failures, and human-versus-computer sessions provide specific evidence about the five decks and the game's clarity. This milestone validates a testing prototype; it does not certify balance.

Requires milestone 4's playable duel and the exact content/rules/bot versions under test. Inspection/events and deterministic inputs must already exist from milestones 1–4; extend them as state is introduced rather than postponing observability until this milestone.

## Ordered work

### 5.1 Finish the inspection contract

- [ ] Audit semantic snapshots for phase/player, pending declaration and response, round tally, six emotion scores, quality, resources, zones/counts, table instances/contributions, use limits, exhaustion cycles, rewards, and legal decisions.
- [ ] Keep geometry and continuously changing animation detail in visual snapshots. Document any privileged debug visibility; the bot must use its restricted observation instead.
- [ ] Discover all game actions through one typed command registry. Cover seeded setup, complete declarations/choices, wand response, normal discard, and next-round continuation, including new card-specific decision phases if finalized timing requires them.
- [ ] Verify session/revision rejection and event attribution for human, computer, timer, and inspection origins. A stale action must not partially apply.
- [ ] Test pause/step/capture and fresh-root scenarios. Update game schema version for incompatible changes; keep the generic runtime/CLI game-independent and synchronize README/help where applicable.

### 5.2 Add complete replay capture and import

- [ ] Define a versioned, strict replay document containing match ID, rules/content/deck/bot versions, frozen magic configuration, seed, player/deck assignments, accepted decisions, automatic deadline outcomes or time advances, random outcomes, and round/match results.
- [ ] Include the exact content/deck snapshot or an immutable resolvable content version so later card edits do not silently change the replay. Validate IDs/schema/versions before replaying.
- [ ] Record the full match independently of Coreflame's bounded event journal. Exclude VM service URLs, credentials, and unrelated personal data. Store exports locally and make privileged card information explicit when included for debugging.
- [ ] Replay accepted bot decisions rather than rerunning the current heuristic. Use recorded randomness and time events to reproduce the match; keep original seeds for provenance and comparison.
- [ ] Check the reconstructed state after meaningful transitions and report the first divergence with sequence/phase/action context. Reject corrupt or incompatible input clearly; do not silently repair it or introduce a compatibility layer.
- [ ] Support export after a failure/unfinished match as well as completion. Demonstrate one ordinary match and one controlled edge case round-trip into equivalent states/events.

### 5.3 Build the scenario and regression matrix

| Scenario group | Cases to prove |
| --- | --- |
| Cancellation | Zero/one/two affordable uses; pass/timeout; repeated replacement cancellations; empty refill ends turn; canceled costs never paid. |
| Quality endings | Printed endpoint; text endpoint; removal reversal; sacrifice interruption; endpoint player loses on checkmarks; center tie. |
| Effect timing | Published six walkthroughs; multiple watchers; departed/reentered source; optional invalid targets; protection replacement; legitimate reveal/reorder. |
| Exhaustion | Last successful draw; each failed attempt; second-penalty reshuffle; empty discard; remaining refill attempts; second player's second exhaustion ends before penalty. |
| Scoring/reset | Tied lanes/quality; table-magic tie; repeated standard-d6 ties; wand carryover/cap/second-player bonus; starter alternation and distinct qualities. |
| UI/lifecycle | Crowded tables; short/empty hand; small/large safe areas; pause during wand window; bot restart race; real target gestures. |

- [ ] Assign stable scenario IDs and deterministic random inputs. Reuse scenario factories for tests and the launcher instead of maintaining duplicate expected setups.
- [ ] Add adjustment-sensitive scenarios for frozen magic/rounding and removal ceilings, while leaving ordinary baseline tests unchanged.
- [ ] Keep scripted scenario results separate from sampled match outcomes. Promote each discovered rules bug to the smallest meaningful regression test before fixing it.

### 5.4 Run automated coverage sweeps

- [ ] Add a headless runner accepting seed range, deck pairing, policy, side/starter assignment, content version, and action budget. Produce counts of completed, failed, and unfinished runs plus replay references.
- [ ] Start with random-legal policies for transition coverage, then heuristic-versus-random and heuristic mirrors for practical behavior. Cover all five presets, including mirrors and both side assignments.
- [ ] Use an initial engineering sweep of 100 seeds per distinct pairing and 20 per mirror, with both side assignments; treat these counts as adjustable coverage targets, not statistical balance requirements.
- [ ] Check invariants during each run: legal phase transitions, card conservation, resource bounds, deterministic outcomes, and no pending actions after round/match completion.
- [ ] Flag crashes, rejected bot decisions, repeated states, and action-budget overruns with exportable evidence. Label budget exhaustion as unfinished; never award a fabricated win or force a new round-ending rule.
- [ ] Investigate the first distinct failure, fix it with a focused test, and rerun the affected cases before broadening. Record configuration changes so comparisons remain interpretable.

### 5.5 Conduct human-versus-computer sessions

- [ ] Start with a guided full match using each of the three primary presets. Verify the human can explain their play/discard/wand choices and the result without inspection tooling.
- [ ] Schedule the ten distinct preset pairings: shifting–discard, shifting–table, shifting–shifting/discard, shifting–discard/sacrifice, discard–table, discard–shifting/discard, discard–discard/sacrifice, table–shifting/discard, table–discard/sacrifice, and shifting/discard–discard/sacrifice. Generate executable pairing membership from the preset catalog.
- [ ] Run each pairing twice as a controlled exploratory pass: exchange human/computer deck assignments and swap the first-round starter. Record seeds and qualities; hold the quality sequence constant within a comparison if the controlled setup supports it. Later starters still alternate normally.
- [ ] Keep those 20 controlled matches separate from the initial guided matches, ordinary random-start matches, mirror tests, and automated sweeps. Since deck/controller/starter assignments change together, do not use the paired outcomes to claim an isolated causal advantage.
- [ ] A human must actually play these sessions. Automated matches cannot satisfy this gate. If sessions are not yet completed, report the count and provide the ready build/session instructions rather than inventing feedback.
- [ ] After every match, ask for the most interesting decision, most confusing interaction, and least useful card. Record observations before proposing numerical changes.

### 5.6 Evaluate and hand off the prototype

- [ ] Produce a compact playtest report with tested build/content/policy versions, target device, match counts by category, reproduced failures, and unresolved issues.
- [ ] Record turns/duration, ending cause, checks/tiebreakers, wand uses, exhaustion, important trigger totals, frequently played/discarded cards, and human notes. Derive summaries from match logs where possible.
- [ ] Separate engine bugs, bot weaknesses, usability problems, and card-balance hypotheses. Compare strategic behavior rather than relying only on aggregate wins or total points.
- [ ] Identify specific follow-up changes supported by evidence. Keep unrelated new mechanics, Gen 2, and broad rebalance outside this milestone; meaningful balance revisions need a new version and another comparable test pass.
- [ ] Run final formatting, analysis, full tests, and selected-platform debug build. Verify the installation and a final smoke match after the last relevant change. Record unavailable checks honestly.

## Completion gate

- [ ] A full match and a failing/edge-case sequence can be exported and replayed deterministically, with incompatible inputs rejected.
- [ ] Inspection and scenario contracts are complete, documented, and tested.
- [ ] Automated sweeps complete without unresolved correctness failures; unfinished runs have been investigated and explained.
- [ ] All five presets can finish matches. The human session matrix is completed and recorded, or this milestone remains explicitly open for those sessions.
- [ ] A reviewed playtest report distinguishes verified behavior from balance hypotheses and lists reproducible remaining limitations.
- [ ] Final checks and the selected target build pass. The intended changes are committed and the worktree is clean before any applicable repository integration workflow.

Suggested commits: `feat: add versioned duel replay export`, `test: add duel scenario and simulation coverage`, and `docs: record prototype playtest findings`. Do not commit generated bulk logs or sensitive session data; retain only intentional sanitized fixtures/reports. The handoff is a playable, inspectable prototype and evidence for the next design iteration.
