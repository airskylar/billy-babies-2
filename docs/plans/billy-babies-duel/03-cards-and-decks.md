# Milestone 3 — Complete card pool and five preset decks

Status: implementation and card-design plan only; no new card text or deck lists have been drafted here.

[Prototype overview](../../../billy-babies-duel-prototype-plan.md) · [Previous](02-rules-and-interactions.md) · [Next](04-playable-duel.md)

## Outcome

All 50 assigned Gen 1 cards have exact, versioned gameplay definitions and executable effects. Five legal 20-card presets express the three primary strategies and two hybrids. Included effects have settled prototype timing; balance remains a playtest question.

Card writing can begin after milestone 1's contract; executable definitions depend on milestone 2's domain/effect model. Use the [card sheet](../../../billy-babies-gen-1-draft-1-cards.md), [strategy](../../../billy-babies-gen-1-draft-1-strategy.md), [effect candidates](../../../billy-babies-effects.md), [Gen 1 roster](../../../billy-babies-gen-1.md), and [timing supplement](../../../billy-babies-gen-1-draft-1-timing.md). Preserve names, appearance, generation, and rarity. Gen 2 stays outside the playable set.

## Ordered work

### 3.1 Create a traceable content workflow

- [ ] Preserve E/D/T/S slot IDs and record which definitions are complete versus briefs. Do not expose briefs as playable cards.
- [ ] Keep the Markdown card sheet as the design specification and one typed catalog as runtime authority. Add a validation/export comparison at the boundary so printed stats/text cannot silently drift from the executable catalog; do not parse prose during gameplay.
- [ ] Give each completed card exact dice, qualities/values, base magic, effect text, choices, cost, targets, persistence, timing, limits, and revision notes. Keep role/partners/tradeoff notes in the design sheet.
- [ ] Retain the provisional six-quality pool, two qualities per card, and starting numerical ranges as design baselines. Explain deliberate exceptions; do not silently treat provisional numbers as balance findings.
- [ ] Inventory new mechanics required by the briefs and batch cards by reusable behavior. Add only the typed handlers the completed designs require.

### 3.2 Finish the remaining 24 strategy cards

| Batch | Slots / Billies | Design work to complete |
| --- | --- | --- |
| Emotion shifting | E05–E12: Duufin, Leemo, Doodiri, Dabbadoo, Hareloom, Dazzip, Arabesk, Pillowbit | Alternative transfers; bounded rewards; chosen-pair support; dice consolation; lead conversion; lane protection. |
| Discard/recovery | D05–D12: Fidgetail, Cubibi, Noodletoes, Scuppup, Glissip, Gillyrest, Snailody, Jotjot | Hand selection and recovery alternatives; separate recovery/normal-discard rewards; scoring coverage; bounded wand disruption. |
| Table/sacrifice | T05–T12: Liliwen, Glowgrub, Hiveling, Cloudnest, Thallumi, Lilynook, Nukkeli, Snappaw | Alternative sacrifice targets/actions; entry and departure rewards; penalty cushion; recovery and removal. |

- [ ] Complete each batch's text/stats before implementing its handlers and interaction checks. Check synergy across batches after each addition.
- [ ] Define zero/partial-result behavior, optional skips, target invalidation, and once-per-turn/round lifetimes explicitly. Avoid adding extra plays or turns.
- [ ] Give each strategy multiple usable enablers and answers so its engine does not depend on one exact card.
- [ ] Keep simple scorers as references. Judge transfers, recovery, and sacrifice by their actual strategic costs as well as immediate points.

### 3.3 Finish the 14 shared cards

| Batch | Slots | Purpose |
| --- | --- | --- |
| Scoring | S01–S06 | Fill emotion/profile gaps and offer flexible choices across strategies. |
| Interaction | S07–S10 | Bounded lane disruption, quality-card removal, wand drain, and protection distinct from Tucktail. |
| Hand selection | S11–S12 | Precisely limited viewing/reordering/exchange without inventing draw attempts or extra plays. |
| Quality management | S13–S14 | Buy time or finish a favorable round through explicitly owned text movement. |

- [ ] Use observed support gaps from the strategy batches to set shared-card numbers and restrictions.
- [ ] Check cumulative protection/loss-reduction behavior and prevent replacement loops.
- [ ] For viewing/reordering, specify who sees which cards, what happens with fewer cards available, and when ordering choices occur. Any choice after reveal needs explicit timing relative to pre-wand declarations; do not silently bypass that rule.
- [ ] For dice changes, specify the selected die/tie procedure and whether choices precede the wand window. A reroll replacing a scored die adjusts by the difference rather than awarding both results.

### 3.4 Extend timing before shipping dependent cards

- [ ] Specify source ownership and signed actual movement for S13/S14, whether text movement causes table retention, and exactly what reverses when the source leaves. Include movement stopped at zero and movement interrupted at an endpoint.
- [ ] Specify table-entry, recovery, and successful-play event eligibility/order for new watchers, including whether the new source can watch its own event.
- [ ] Specify start-of-turn behavior only if a completed card uses it; keep temporary silence, complex counters, and opponent choices deferred unless the design demonstrably needs them.
- [ ] Add numerical walkthroughs and regression fixtures for each new convention. Keep the supplement explicitly provisional and version it with the card changes.
- [ ] Surface any conflict requiring a change to agreed game rules rather than embedding an undocumented exception in code. Resolve included timing before declaring this milestone complete.

### 3.5 Construct the five presets

- [ ] Create one shifting, one discard/recovery, one table/sacrifice, one shifting/discard, and one discard/sacrifice deck. Each list references catalog IDs and contains exactly 20 unique cards with at most 5 Rare and 2 Mythic.
- [ ] For each primary strategy, document at least 22 credible candidates, including shared/cross-strategy options, and show how the final list satisfies rarity limits. A strategy tag alone does not establish support.
- [ ] For each preset, record its plan, principal interactions, weak points, emotion coverage, quality coverage, and several plausible cuts/swaps. Explain what each hybrid gives up to combine strategies.
- [ ] Check useful decisions when the signature card is missing, canceled, normally discarded, or removed. Do not tailor the shared quality pool to the matchup.
- [ ] Store preset membership once and derive setup choices/deck details from it. Freeze catalog/deck versions at match start.

### 3.6 Validate the completed pool

- [ ] Validate 50 unique slots and the existing 16 Common / 19 Uncommon / 11 Rare / 4 Mythic allocation, along with exact roster identities. If a selection policy changes, document the rationale instead of changing approved rarity.
- [ ] Ensure every selectable card has exact text/stats, valid quality/dice data, supported choice types, and an executable effect. Ensure every preset references only complete catalog entries.
- [ ] Add meaningful effect tests for new behavior and representative combinations: multiple watchers, costs plus protection, recovery of a departed source, entry rewards, penalty cushions, and text quality reversal.
- [ ] Exercise adjusted-magic thresholds at both ends of the permitted range, particularly around 40 magic; ordinary matches remain baseline mode.
- [ ] Test recovery combinations for repeatable loops and delayed exhaustion. A test action limit reports unresolved/stalled behavior, not a new win condition.

## Completion gate and handoff

- [ ] All 50 cards are specified, executable, and traceable to the updated sheet and timing version.
- [ ] All five decks are legal; each primary strategy has documented alternatives and useful support beyond one key card.
- [ ] No included mechanic has unresolved timing or an unbounded effect-resolution loop.
- [ ] Content validation and focused rules/effect tests pass. The catalog exposes all choices and public descriptions needed by the board, bot, and inspector.

Suggested commits: one coherent content/handler/test change per strategy batch, one for shared effects/timing, and `feat: add five prototype deck presets`. Keep card text, executable behavior, and their tests together. Hand off the catalog/deck versions and any balance concerns to milestone 4; do not call the set balanced before playtesting.
