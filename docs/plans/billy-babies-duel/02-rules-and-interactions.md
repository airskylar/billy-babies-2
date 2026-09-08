# Milestone 2 — Rules engine and 12-card interaction harness

Status: implementation plan only; all tasks are pending.

[Prototype overview](../../../billy-babies-duel-prototype-plan.md) · [Previous](01-foundation.md) · [Next](03-cards-and-decks.md)

## Outcome

A deterministic, pure Dart rules engine resolves the agreed match rules and all 12 drafted cards. Tests and Coreflame scenarios can drive every decision without a finished board. The interaction harness is explicitly separate from legal 20-card match setup.

Requires milestone 1's shell and prototype contract. The authoritative inputs are the [agreed rules](../../../billy-babies-rules.md), [12 card drafts and walkthroughs](../../../billy-babies-gen-1-draft-1-cards.md), and [timing supplement](../../../billy-babies-gen-1-draft-1-timing.md). Follow the Dart and runtime-inspection rules. Do not invent the remaining 38 card definitions in this milestone.

## Ordered work

### 2.1 Define state, decisions, and deterministic inputs

- [ ] Model player IDs, six emotions, dice strengths, qualities, rarity, card identity, and closed turn phases using typed domains.
- [ ] Separate immutable card definitions, a player's owned card identity, and table-instance identity. The same slot can exist in both players' decks; departure/reentry creates a new table instance without resetting card-level turn/round use limits.
- [ ] Model hand, draw pile, discard, table, and resolving zone; round wins; frozen magic values; reversible quality contributions; exhaustion cycles; and pending rewards.
- [ ] Define strict player decisions for declaring a card/choices, wand pass/cancel, normal discard, and continuing a round. Generate legal choices from current state and reject wrong-player, wrong-phase, stale, or invalid-target submissions before mutation.
- [ ] Inject a seeded game random source and controlled time. Keep bot/presentation randomness independent. Emit typed domain events with sufficient random outcomes and action information for milestone 5's replay collector.
- [ ] Provide controlled fixture construction in test/debug scenarios without weakening production deck validation.

### 2.2 Implement setup, scoring, and basic resolution

- [ ] Validate exactly 20 unique card IDs, no more than 5 Rare and 2 Mythic, and catalog membership at normal match setup.
- [ ] Select three distinct qualities, select the first starter, freeze adjusted magic, shuffle full decks, reveal the current quality before dealing three, and apply starting wand values/second-player bonus.
- [ ] Implement exact emotion die faces and scores. Resolve uncanceled plays as dice → matching quality → text → placement → wand gain.
- [ ] Derive table magic from present cards. Keep persistent/matching-quality cards on the table and otherwise discard during placement. Track actual per-instance quality movement for reversal.
- [ ] Check for a round ending immediately after operations that can cause one. Stop all remaining work, including placement, wand gain, rewards, and refill, when the round ends.
- [ ] Score six emotion checkmarks, two quality checkmarks, table-magic ties, then standard-d6 rerolls. Rebuild the same decks for the next round, reset round state, alternate starter, carry wand charge, and finish after two round wins.

### 2.3 Implement the complete turn and wand loop

- [ ] Move a declared card into the resolving zone and validate all printed choices before opening a wand window. Choose the normal discard later.
- [ ] Hold all effects for six controlled seconds or until pass/cancel. Skip the window below 200 opposing wand magic. Resolve timeout/pass/cancel as one serialized decision so the card cannot resolve twice.
- [ ] On cancellation, spend 200 wand magic, discard the canceled card with no effects/costs/gain, and establish a refill. If the round continues and hand is nonempty, return to declaration on the same turn.
- [ ] Allow repeated cancellation of replacement plays. Take the normal discard only after success and only if a card remains; then refill.
- [ ] Handle ordinary turns beginning with two, one, or zero cards. An empty cancellation refill ends the turn without another refill. Do not use the ordinary empty-hand path to refill it twice.
- [ ] Reject response commands after a window closes. Test exact deadline behavior with injected time and document the ordering convention for a response at the deadline.

### 2.4 Implement failed draws and exhaustion

- [ ] Fix the number of attempts at refill start to the number missing from three. Drawing the last card is a success, not a failed draw.
- [ ] On the first failed attempt in an empty-pile cycle, increment exhaustion. If both players now have at least two, end immediately before that attempt's penalty.
- [ ] For each failed attempt that continues, sample a uniform lane count of 2–4, distinct uniformly chosen lanes, and one uniform loss of 2–4 applied to all chosen lanes, floored at zero.
- [ ] After the second penalty, reshuffle only discard and reset the cycle even if the discard is empty. Remaining established attempts use that pile; missed draws are not retried.
- [ ] Test multiple failures within one refill, pending attempts after reshuffle, empty reshuffles, and one player continuing beyond two exhaustions while waiting for the other.

### 2.5 Implement the 12 effects and timing

| Cards | Required behavior |
| --- | --- |
| Balancini / Twirlina | Declared bounded transfer; reward only actual positive movement; queue and enforce once-per-turn use. |
| Bumbini / Blushimi / Cuddlump | Evaluate conditional gains at text resolution, after dice and before current-card placement. |
| Bobbin / Paperoo | Atomic optional hand/discard exchange, valid shared printed emotion, no draw/normal-discard event; reward the later normal discard using only the successful play. |
| Purrsie / Mantini | Declare optional cost and target together; revalidate before paying; resolve discard/sacrifice cost and bounded removal in order. |
| Fluffernut / Sporeboo | Capture sacrifice departure information; distinguish self-departure from live watcher rewards; interrupt everything on endpoint reversal. |
| Tucktail | Automatic first eligible opposing removal replacement, at most one redirect; no sacrifice event; preserve original target and paid costs. |

- [ ] Use the card-sheet numbers/text exactly. Match-frozen adjusted magic governs removal thresholds and captured sacrifice values.
- [ ] Queue rewards in event order, active player first then opponent, then slot ID. Drain after the played card's wand step or after normal discard and before establishing refill attempts.
- [ ] Mark usage when the reward is recorded/replacement applied. Skip rewards from departed instances without refunding use; permit explicitly captured self-departure rewards.
- [ ] Ensure exchanges, normal discards, cost discards, placement discards, cancellations, removals, and cleanup remain different events. Round cleanup does not trigger departure rewards.

### 2.6 Expose and prove the harness

- [ ] Add strict game commands and snapshots alongside each implemented decision; derive them from the domain, using the existing command registry and revision/session protections.
- [ ] Add the six published walkthrough scenarios: transfer reward, recovery/normal discard, sacrifice/removal/rewards, endpoint interruption, protection, and cancellation of setup actions.
- [ ] Cover invariants after transitions: card conservation, nonnegative scores, wand bounds, valid zones, table-magic derivation, no actions after completion, and deterministic replay of a scripted sequence.
- [ ] Run focused domain and adapter tests, analysis, retained architecture checks, and a launcher smoke test. Use scripted dice for exact assertions and seeded sequences for broader checks; avoid flaky statistical tests.

## Expected changes

Fresh modules under `lib/game/domain/`, the initial typed catalog under `lib/game/content/`, expanded `lib/game/inspection/` and `lib/game/scenarios/`, and focused tests under matching `test/game/` areas. UI remains a harness; shared runtime protocol code should require no game-specific changes.

## Completion gate and handoff

- [ ] All agreed core rules and the 12 exact effects pass deterministic checks, including both kinds of round ending and full match progression using test fixtures.
- [ ] All six source walkthroughs are reproducible through scenarios and tests.
- [ ] Only the controlled harness can use partial fixtures; normal setup continues to require legal decks.
- [ ] Milestones 3 and 4 have a stable card/effect interface, legal-decision interface, player-observation boundary, controlled clock, and domain event stream.

Suggested commit sequence: `feat: add duel domain and match lifecycle`, `feat: resolve duel turns and exhaustion`, and `feat: add draft card interactions and scenarios`. Keep each commit coherent and passing; boundaries may move if the engine must land together. No full playable-pool claim is made yet.
