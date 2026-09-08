# Milestone 4 — Human-versus-computer playable duel

Status: implementation plan only; all tasks are pending.

[Prototype overview](../../../billy-babies-duel-prototype-plan.md) · [Previous](03-cards-and-decks.md) · [Next](05-verification-and-playtests.md)

## Outcome

A human selects a legal preset and plays a complete best-of-three match against the computer using the app alone. Every play, printed choice, wand response, discard, automatic effect, and round transition is understandable and uses the same rules engine.

UI/bot scaffolding can use milestone 2's fixtures during development. Completion requires milestone 3's full catalog and five decks. Use Coreflame's existing Flutter shell and Flame input/rendering boundary; read the Flame Engine skill and applicable Dart/runtime-inspection guidance before implementation.

## Ordered work

### 4.1 Establish the shared decision and observation boundary

- [ ] Provide a player-specific observation from authoritative state: own hand and permitted reveals, public board/resources/discards, current phase, and legal decisions. Keep privileged inspection data separate.
- [ ] Route human input, bot output, and semantic inspection actions through the same validation/mutation path. Tag action origin without changing rules behavior.
- [ ] Represent target/amount/emotion/order selections with typed data. Derive selection controls from each card's legal-choice requirements rather than duplicating a separate UI card list.
- [ ] Separate unsubmitted UI selection from the committed domain declaration. Confirm all printed choices before the wand window; normal discard remains a later decision.

### 4.2 Implement a random legal opponent first

- [ ] Cover declaration, optional skip, every completed card's choices, normal discard, wand cancel/pass, and automatic transitions. Random policy applies only to real decisions; it must not choose illegal skips or add actions.
- [ ] Use a dedicated policy seed; never consume the match's random stream while selecting candidates.
- [ ] Run headless legal matches across the five decks to expose unhandled decision types before adding strategy.
- [ ] Keep the policy as a test setting alongside the default heuristic opponent.

### 4.3 Implement a bounded heuristic opponent

- [ ] Enumerate or deterministically bound legal candidate choices using only the observation. Use expected dice values or independent sampled outcomes; candidate evaluation cannot access the live match RNG or hidden cards.
- [ ] Rank outcomes by expected round victory/checkmarks, close-lane gains, quality position, table-magic tiebreaker, engine value, useful retained cards, exhaustion pressure, and wand reserves. Treat weights as tunable test parameters with a bot version.
- [ ] Evaluate removal/sacrifice with protection, lost friendly support, queued rewards, and quality reversal. Score an endpoint using the resulting round result, not a generic endpoint bonus.
- [ ] Consider likely normal discards when choosing a play; re-evaluate the actual discard after resolution. Cover recovery targets and combinations without searching private future draws.
- [ ] Evaluate wand use from the opponent's visible declaration and public state. Consider the 200 cost, potential replacement play, current round stakes, and carried charge.
- [ ] Return a short debug reason and legal fallback if the evaluation budget is reached. A bounded search must still be able to select every required kind of decision.
- [ ] Test that changing unseen hand/order/future-quality information does not change the decision for the same observation/policy seed. Legitimate reveal effects may change the observation and therefore the decision.

### 4.4 Build setup and the board

- [ ] Add human/computer preset selection, readable strategy descriptions, start, and test settings for seed/policy. Display baseline-magic mode in test setup.
- [ ] Build the Flame board: opponent hand backs/count and table above, six named lanes plus signed quality track centrally, own table and hand below. Flutter owns shell/settings/safe areas; Flame owns board input and rendering.
- [ ] Keep wand charge and table magic visually separate. Show round wins, active player/phase, draw/discard counts, exhaustion, and penalty-cycle count.
- [ ] Build readable placeholder card faces with name, rarity, dice, qualities, magic, and persistence indicator. Tap for full text/detail; do not depend on finished creature art.
- [ ] Support table overflow with scrolling/compact cards and a detail view. Keep selection and labels usable on the smallest supported test viewport and larger safe-area layouts.

### 4.5 Build the complete turn interaction

- [ ] Select a card, choose legal targets/printed options, review, and confirm. Explain why a target or action is unavailable and allow backing out before declaration.
- [ ] Make the declared opponent card/choices visible as the six-second response begins. Display cancel cost, pass, countdown, and available charge. Avoid consuming the human's response time behind an introductory animation.
- [ ] Present dice and state changes in resolution order, including interrupted effects and quality reversals. Presentation reads completed domain events; it never recomputes results.
- [ ] Prompt for exactly the legal normal discard and automatically present refill/penalties. Explain cancellation replacement plays and short-hand turns rather than leaving apparently missing cards unexplained.
- [ ] Keep a concise recent-action log and inspectable public piles/table effects, including spent ability indicators. Hide private information from normal opponent views.
- [ ] Cover every completed card's selection flow, including any specifically permitted reveal/reorder interaction from the final timing supplement.

### 4.6 Handle lifecycle and results

- [ ] Schedule readable bot actions within controlled game time. Cancel scheduled work on pause, root disposal, restart, round completion, or superseded decisions; verify session/decision identity before applying.
- [ ] Preserve the remaining wand duration through background/resume. Test timeout and human response arriving together so exactly one outcome applies.
- [ ] At round result, show ending cause, all checkmarks, table-magic comparison, and actual tiebreak rolls if used. Make clear that reaching an endpoint did not itself award victory.
- [ ] Continue with the same decks, carried wand, next quality, alternate starter, and new hands. After two wins, show match result and rematch/setup actions.
- [ ] Define rematch as a fresh match/seed by default; expose repeating a recorded seed separately as a test action. No state or pending animation/bot callback leaks across matches.

## Verification

| Layer | Required evidence |
| --- | --- |
| Bot | Legal decisions across all effect families, hidden-information independence, bounded evaluation, favorable/unfavorable endpoint fixtures, wand and discard fixtures. |
| Domain integration | Human and bot decisions produce the same result as equivalent semantic commands. |
| Flame/input | Card/target selection, table scrolling, response buttons, and resize/safe-area behavior work through real pointer paths. |
| Flutter/lifecycle | Setup, pause/background, result/continue/rematch, and scenario restart dispose old state correctly. |
| Manual target test | A complete human-versus-heuristic match, including a wand response, normal discard, visible effect chain, and round transition. |

Use semantic snapshots for state assertions and atomic frame capture for visual evidence. Use pointer replay only for gesture/hit-test validation. Run focused tests and analysis as each interaction lands, then the full test suite and a debug build for the selected target at completion.

## Completion gate and handoff

- [ ] Every preset is selectable for either side; a human can finish a legal match without developer commands.
- [ ] The bot handles all choices fairly and cannot act on stale state or private future information.
- [ ] The board explains resources, cancellations, penalties, triggered effects, and round winners, including crowded tables.
- [ ] Required tests/build pass and a complete manual match is recorded. Any unavailable device check remains an explicit incomplete gate.

Suggested commits: `feat: add legal computer duel policies`, `feat: add duel setup and board`, `feat: add card choices and wand interaction`, and `feat: complete duel results and lifecycle`. Keep dependencies/buildability intact. Hand off the playable target, policy version, observed UX/rules issues, and captured match identifiers to milestone 5.
