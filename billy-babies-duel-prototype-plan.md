# Billy Babies Duel — Prototype Plan

Status: proposed implementation plan, September 8, 2026. No gameplay implementation or card-design changes are included in this document.

## Detailed milestone plans

1. [Prototype contract and starter replacement](docs/plans/billy-babies-duel/01-foundation.md)
2. [Rules engine and 12-card interaction harness](docs/plans/billy-babies-duel/02-rules-and-interactions.md)
3. [Complete card pool and five preset decks](docs/plans/billy-babies-duel/03-cards-and-decks.md)
4. [Human-versus-computer playable duel](docs/plans/billy-babies-duel/04-playable-duel.md)
5. [Replays, verification, and playtesting](docs/plans/billy-babies-duel/05-verification-and-playtests.md)

Finish milestone 1 first. Milestone 3's card writing can proceed while milestone 2 is implemented; executable content depends on milestone 2's domain contracts. Milestone 4 can begin with interaction scenarios, but its completion requires milestones 2 and 3. Build inspection and replay foundations as state is introduced; milestone 5 completes and verifies them against the playable game. These dependencies describe work order, not authorization to start implementation or delegate work.

## Goal

Build an offline, single-player Billy Babies Duel prototype in Coreflame. A human plays complete best-of-three matches against a computer opponent to test the rules, card interactions, deck strategies, and clarity of decisions.

The target prototype uses the first 50 Gen 1 cards and five preset, legal 20-card decks. Start with the 12 fully drafted cards as a controlled interaction test harness; that harness is not a legal match mode. Complete the remaining card designs before treating the 50-card pool as playable. Use readable placeholder card faces so artwork does not delay rules testing.

## Sources and their authority

| Source | Use in this prototype |
| --- | --- |
| [Agreed game rules](billy-babies-rules.md) | Authoritative match, turn, scoring, cancellation, exhaustion, and magic rules. |
| [Draft 1 card sheet v0.1](billy-babies-gen-1-draft-1-cards.md) | 50 assigned slots, 12 complete card drafts, 38 briefs, and provisional numerical baseline. |
| [Draft 1 timing supplement v0.1](billy-babies-gen-1-draft-1-timing.md) | Proposed prototype conventions for resolving the first 12 cards. Version extensions separately as more cards require them. |
| [Draft 1 strategy](billy-babies-gen-1-draft-1-strategy.md) | Three primary strategies, two hybrids, deck-design goals, and playtest questions. |
| [Effect ideas](billy-babies-effects.md) | Candidates for finishing briefs; not automatically implemented or adopted rules. |
| [Gen 1 roster](billy-babies-gen-1.md) | Approved names, rarity, generation, and visual descriptions. Preserve these when assigning gameplay. |
| [Gen 2 roster](billy-babies-gen-2.md) | Future content reference; outside this prototype's playable pool. |
| [Coreflame README](README.md), [initialization guidance](.agents/getting-started.md), [runtime inspection rules](.agents/rules/runtime-inspection.md), [Dart quality rules](.agents/rules/dart-code-quality.md) | Framework boundaries, replacement of the demo, semantic testing, and implementation conventions. |

The repository currently contains Tiny Tactics and an active `.getting-started` sentinel. Flame is locked to 1.38.2. Android and iOS are the existing platform targets. Preserve the resolved framework versions unless an implementation need warrants a separately considered change.

## Prototype scope and defaults

- One local human and one computer; no account, matchmaking, multiplayer networking, collection economy, or backend.
- Five selectable presets: emotion shifting, discard/recovery, table/sacrifice, shifting/discard hybrid, and discard/sacrifice hybrid. Either side can use any preset, including a mirror matchup.
- Exactly 20 unique cards per deck, at most 5 Rare and 2 Mythic cards, with deck composition fixed throughout the match.
- Use Draft 1's proposed shared quality pool: brave, clever, curious, gentle, loyal, playful. Select three distinct qualities once per match and reveal only the current one before dealing.
- Use base magic for ordinary prototype tests, with no usage-history tracking or global statistics. Label this as a baseline test configuration. Add explicit adjusted-magic scenarios to test rounding and the 90%–105% range; do not silently apply fatigue to repeated local playtests.
- Start on an available iOS simulator or Android emulator. Use a landscape-first duel board for readability, responsive to safe areas and viewport changes. Confirm the preferred playtest device before tuning final dimensions.
- Keep normal six-second wand windows. Provide explicit pass and debug pause/step controls; no general human turn timer. Freeze gameplay deadlines and bot scheduling while the local game is paused or backgrounded.
- Defer a custom deck editor, finished creature art, elaborate effects, music, cloud saves, achievements, and Gen 2. Presets and a card detail viewer are enough to test the game initially.

These are prototype recommendations, not amendments to the agreed rules.

## Player experience

1. **Set up a duel.** Choose your preset and the computer's preset. Start with a random seed; expose seed entry and bot mode in test settings.
2. **See the round.** Reveal the Active Quality, starting player, wand balances, and three-card hand. Show round wins and who acts next.
3. **Declare a play.** Select a card, inspect its full text, choose required targets and printed choices, then confirm. Highlight legal targets and explain unavailable choices. Optional targeted text can be skipped under the timing supplement.
4. **Respond with the wand.** Display the opponent's declared card and choices before any effects resolve. If eligible, offer “Cancel · 200 magic” and “Pass” with a six-second countdown. Skip this phase below 200 wand magic.
5. **Follow resolution.** Briefly show dice results, lane changes, quality movement, text effects, placement, and wand gain in rules order. On cancellation, explain the refill and replacement play. After a successful play, prompt for the normal discard and refill automatically.
6. **Understand the outcome.** At round end, identify the ending condition, each awarded checkmark, and any table-magic or standard-d6 tiebreaker. Continue to the next round or show the match result with a rematch option.

Board layout: opponent hand backs/count and table at the top, six named emotion lanes and the shared quality track in the center, and the human table/three-card hand below. Keep wand charge, table magic, pile counts, exhaustion, and penalty-cycle counts distinct. Use text and symbols as well as colors. Since table size is unlimited, provide scrolling or a compact table tray with a readable detail view. Include a recent-action log to explain automatic triggers and removals.

Proposed visibility convention: table cards, discard piles, scores, and resource/pile counts are public; hands, draw-pile order, and unrevealed qualities are hidden from the opponent. Document this convention with the prototype timing notes before implementation. Privileged debug inspection must remain separate from the bot's information.

## Coreflame implementation shape

| Area | Responsibility |
| --- | --- |
| `lib/app/` | Flutter shell, safe areas, lifecycle, setup/settings, and scenario launcher composition. |
| `lib/game/domain/` | Pure Dart card definitions, deck validation, match state, legal choices, resolution, scoring, and injected randomness/time. |
| `lib/game/content/` | Typed, versioned card catalog and preset deck references. Preserve card-sheet slot IDs and roster identities. |
| `lib/game/ai/` | Computer policies operating on a player-visible observation and legal decisions. |
| `lib/game/scene/` and `lib/game/game_root.dart` | Flame board, cards, pointer input, responsive layout, feedback, and presentation of domain events. |
| `lib/game/inspection/` | Billy Babies state schema, typed events, command registry, and `RuntimeInspectionAdapter`. |
| `lib/game/scenarios/` | Deterministic interaction and round-boundary fixtures for the existing launcher. |
| `lib/runtime/` | Retained game-independent inspection, input, and motion infrastructure. |

Use a fresh Billy Babies game root derived from `InspectableFlameGame`. Replace the concrete Tiny Tactics wiring in `CoreflameApp`; keep the existing inspection surface and fresh-root scenario restart pattern. Runtime code must not import Billy Babies types.

One domain state owner accepts validated decisions from the human UI, computer, and inspection adapter. Use explicit phases such as declaration, wand response, resolution, normal discard, refill, round result, and match result. Cancellation returns through refill to a replacement declaration on the same turn. Reject decisions that do not belong to the current phase/player.

Represent effects with a small set of typed operations and explicit handlers for the actual card pool. Do not parse English card text during gameplay or build a general scripting system. Store printed profiles, table-instance identity, per-card usage limits, and each instance's actual reversible quality contribution. Derive legal choices, table magic, and visible state from authoritative data rather than maintaining parallel lists or totals that can drift.

Keep rendering observational. Domain events drive animations; animation completion must not decide game outcomes. Advance the wand deadline through controlled game time, with injected time in domain tests. Use separate randomness for game outcomes and bot tie-breaking so changing bot evaluation does not consume future dice or shuffle results.

## Computer opponent

Implement two local policies using the same legal-action interface:

- **Random legal policy:** chooses valid plays, printed choices, discards, and eligible wand responses. Useful for broad rules coverage and comparison.
- **Heuristic policy (default):** evaluates legal plays and target combinations using expected dice outcomes, likely lane checkmarks, quality position, table engines, hand retention, exhaustion pressure, and wand reserves. Use bounded evaluation so complex choices do not freeze the UI.

The heuristic should prefer taking or preserving contested lanes over adding surplus to a lane already comfortably won. Evaluate sacrifice/removal with the loss of table magic, future triggers, protection, and quality reversal included. An endpoint is desirable only if the resulting round score is favorable; reaching it is not an automatic victory.

Evaluate play and likely discard together, then choose the actual normal discard when that phase arrives using the information revealed by resolution. Decide whether to spend 200 wand magic based on the declared play's threat and the value of retaining cancellation for replacement plays or later rounds. Cover optional-action skips, short hands, repeated cancellations, and all printed choices in the finalized pool.

The bot sees its own hand and legitimately revealed information, including cards explicitly revealed to it by a card effect. It cannot inspect the human hand, unrevealed draw-pile order, future qualities, or the match RNG state. Candidate evaluation must not mutate the live match. Add a test showing that changing unseen information leaves its decision unchanged when its observation and policy seed are unchanged.

Expose a short decision reason in debug mode, such as “contests two close lanes” or “saves wand for a stronger threat.” Add a small presentation delay to make computer actions readable; resolve within the legal response window and cancel pending bot work on pause, restart, or game removal. Validate the current match/decision identity before applying a scheduled action.

## Milestones and acceptance gates

### 1. Lock the prototype contract and replace the starter

- Record the selected sources, provisional visibility/timing conventions, baseline magic mode, and content version.
- Remove Tiny Tactics game code and matching tests, demo assets, branding, service identifiers, and unused registrations/dependencies according to `.agents/getting-started.md`.
- Audit native launcher/launch-screen branding. Keep only platform plumbing needed for the offline prototype; remove demo authentication and achievement behavior.
- Wire a minimal Billy Babies root, inspection adapter, and scenario catalog. Update README instructions and retire the sentinel after initialization is complete.

**Gate:** The new shell launches on a supported simulator/emulator, inspection discovers Billy Babies, and retained runtime/architecture tests pass. No demo gameplay or assets remain referenced.

### 2. Implement the rules and 12-card interaction harness

- Implement deck validation, seeded setup, card zones, explicit turn phases, wand cancellation/replacement plays, emotion dice, quality tracking/reversal, table magic, failed draws, exhaustion, round scoring, and match progression.
- Encode E01–E04, D01–D04, and T01–T04 exactly as drafted. Implement the v0.1 trigger queue, protection replacement, target revalidation, and usage-limit lifetimes.
- Convert all six card-sheet walkthroughs into deterministic tests/scenarios, including the sacrifice endpoint that interrupts remaining resolution.
- Provide semantic commands as these decisions are implemented, so rules can be exercised before the board is polished.

**Gate:** The 12-card interactions and core boundary tests pass without rendering. These fixtures remain clearly labeled controlled scenarios; no reduced deck is presented as a legal duel.

### 3. Complete the 50-card pool and five decks

- Finish the remaining 24 strategy briefs, then the 14 shared briefs, preserving approved names and rarities. Assign exact dice, qualities, magic, choices, text, and persistence with version notes.
- Before including S13 Ollu or S14 Granuloo, specify ownership of text-driven quality movement, table retention, and reversal of movement toward center. Extend timing only for mechanics actually needed, including any new start-of-turn or dice behavior.
- Add alternative enablers and rewards for each strategy and assess recovery combinations for exhaustion-delaying loops.
- Build the three primary and two hybrid presets from the completed pool. Verify at least 22 credible candidates per primary strategy and document meaningful alternative inclusions/cuts, following the design strategy.
- Validate catalog IDs, roster rarities, exact 20-card singleton deck sizes, rarity caps, and effect-handler coverage. Derive selectable card membership from the catalog. Do not silently turn unfinished briefs into blank-effect cards.

**Gate:** All 50 cards have complete executable definitions and focused effect checks; five legal decks exist with no unresolved included timing mechanics. This content work can proceed alongside milestone 2 once the prototype contract is recorded.

### 4. Deliver the first human-versus-computer duel

- Implement both computer policies, observation boundaries, deterministic scheduling, and debug decision reasons.
- Build setup, board, card detail/target selection, wand response, discard/refill feedback, round results, match results, and rematch.
- Hook every human and computer decision into the shared domain path. Preserve hidden information in ordinary play.
- Implement compact table browsing and clear labels for all resources and resolution interruptions.

**Gate:** A human can complete a full legal best-of-three match against the heuristic bot without using developer commands. Either side can cancel, lose, win, and continue between rounds correctly. Pausing, backgrounding, and restarting do not apply stale actions.

### 5. Make failures reproducible and run the playtests

- Expose semantic state: phase, active player, pending declaration/response, round wins, emotion scores, quality, wand charge, table cards/contributions, pile counts, exhaustion cycles, queued effects, and legal decisions. Keep geometry/countdown animation detail in visual snapshots.
- Register proposed game commands such as starting a seeded match, declaring a play with choices, responding to a wand window, choosing a normal discard, and continuing a round. Final parameter shapes must be typed and discoverable through `capabilities`.
- Preserve session/revision checks and action origins. Update README examples, CLI help where needed, and snapshot/event/command tests together; keep the generic CLI game-independent.
- Capture content/rules/bot versions, seed, deck IDs, player assignments, decisions, random outcomes, and round results in a local replay artifact. A bounded runtime journal alone is not a complete replay record; collect the full match stream separately for export. Exclude VM service URLs and credentials.
- Add scenarios for full/empty hands, cancellation chains, protection, quality reversal endings, repeated exhaustion, ties, and next-round carryover. Use semantic inspection first and atomic frame capture/pointer replay for visual or hit-testing checks.
- Run scripted and bot-versus-bot sweeps for crashes, illegal actions, repeated states, and unusually long matches. A test runner's action budget reports an incomplete/stalled test; it must not invent a new gameplay round ending.
- Play full human-versus-computer matches with the three primary decks first. Then test all ten distinct pairings of the five presets twice, swapping sides/starting assignments in controlled tests. Keep these 20 exploratory matches separate from ordinary random-start matches, mirror matches, and controlled interaction checks.

**Gate:** Failures can be replayed with the same versioned content, decisions, and random outcomes. All five presets can finish matches, and observed problems are recorded with evidence rather than inferred from a small win-rate sample.

## Required verification

Test the rules most likely to look plausible while being wrong:

- Exact Normal/Strong/Brutal face tables, all six emotions, frozen adjusted magic and half-up rounding, 400 wand cap, and second-player bonuses.
- Targets and choices declared before the six-second window; no canceled effects or costs; replacement plays cancelable; one normal discard after success; empty cancellation refill ends the turn without a second refill.
- Endpoints interrupt text, placement, wand gain, rewards, and further actions. Endpoint ownership need not match the round winner. Emotion ties award nothing; quality lead awards two; tied checkmarks use table magic then standard d6 rerolls.
- Drawing the last card is not exhaustion. Refill attempts are fixed at refill start. Each failed attempt has its own penalty; each penalty uses distinct uniformly sampled lanes and one shared loss value, floored at zero. The second penalty reshuffles only discard, does not replace missed draws, and resets the cycle even with an empty discard pile.
- Both players reaching two exhaustions ends the round before the triggering penalty. One player reaching two alone does not end it.
- Exchanges, cost discards, normal discards, canceled plays, sacrifices, opposing removals, and round cleanup produce distinct events. No recursive protection; no watcher reward from zero transferred points; departed/reentered instances do not inherit queued watcher eligibility.
- Round reset rebuilds the same full decks, alternates the starter, retains wand charge and round wins, and reveals the next distinct quality at the correct time.
- Cards are conserved across hand/draw/discard/table/resolving zones; scores stay nonnegative; legal actions never bypass the current phase; the bot has no hidden-information access.

Run focused pure-Dart/domain, bot, inspection, Flame component, and Flutter shell tests during implementation. At prototype completion run formatting, `flutter analyze`, `flutter test`, and a debug build for the selected test platform (`flutter build ios --simulator` or `flutter build apk --debug`). Verify visual readability, safe areas, crowded tables, and real input on that target. Report unavailable platform checks explicitly.

## What the prototype should teach us

After each playtest, record the most interesting decision, most confusing interaction, and least useful card. Track round duration/turn count, ending reason, checkmarks, wand uses, canceled cards, exhaustion, and key recurring rewards. Compare human observations with bot behavior; a weak bot is not evidence that a deck is balanced or overpowered.

Completion means we can choose any of the five presets, play a complete match against the computer, understand each result, and reproduce a suspicious interaction. Balance changes and expansion beyond 50 cards follow that evidence.

Implement milestones as focused changes, verify them, and create local Conventional Commits on the existing checkout without creating or switching branches. Follow repository integration guidance only when the intended implementation is committed, clean, verified, and ready for manual testing.
