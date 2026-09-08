# Billy Babies — Draft 1 Prototype Timing Supplement

**Version 0.1. Proposed for the 12 representative cards in the [Draft 1 card sheet](billy-babies-gen-1-draft-1-cards.md).** This supplement makes those examples resolvable for prototype checks. It does not edit or replace the [agreed game rules](billy-babies-rules.md), and its conventions are not yet adopted for the final game.

Use the agreed rules wherever this supplement does not address a detail. The first 12 cards introduce no extra plays or turns, no changed cancellation cost, and no changed round-ending conditions.

## 1. Declare the complete play

Move the played card out of the hand into a temporary resolving area. It is not yet on the table or in the discard pile. Declare its targets, printed choices, optional costs, and whether to perform optional actions before opening the normal wand window.

- For Balancini, declare both different emotions and an integer amount from 1 to 4. The source may currently have fewer points than that amount. At text resolution, move the smaller of the declared amount and the points then available.
- For Bobbin, declare the emotion, the hand card, the discard card, and whether to exchange. Both selected cards must have printed dice for that emotion. Bobbin cannot select itself.
- For Purrsie, declare the hand card to discard, a legal opposing table target, and whether to pay.
- For Mantini, declare the friendly sacrifice target, a legal opposing table target, and whether to sacrifice. Mantini cannot select itself because it has not entered the table.

The normal discard is chosen later, during its ordinary turn step. It is not one of the played card's printed choices and need not be committed during the wand window.

### Optional text without legal targets

For this prototype, a card with an optional targeted action may still be played for its dice, matching quality, and wand gain when that action has no legal targets. Declare that the optional action is skipped. Bobbin's exchange, Purrsie's paid removal, and Mantini's sacrifice are covered by this convention.

Recheck all targets required by a linked optional action immediately before starting it. If any are invalid, skip that action and pay no cost. A completed cost is not refunded because a later protection replacement redirects the removal. The compulsory end of a round always interrupts any remaining action.

## 2. Preserve the existing resolution steps

After a successful play's wand window, resolve its dice, matching quality, text, placement, and wand gain in the agreed order. Use the match-frozen adjusted magic value for wand gain, table magic, and magic-based target restrictions.

Evaluate conditional text when its instruction resolves, unless it explicitly watches another event. Dice have already affected emotion scores, but the current card does not yet contribute table magic or count toward table-card conditions.

Round-ending conditions take priority at every point where they can occur. In particular, quality movement or removal reversal that reaches an endpoint ends the round before later text, placement, wand gain, or queued rewards. Preserve all effects already completed before the ending.

## 3. Queue rewards; resolve replacements immediately

A replacement such as Tucktail's protection changes a pending removal before it happens. A reward such as Twirlina's gain happens after the action that caused it.

For v0.1:

1. When a qualifying event occurs, record eligible reward abilities and their event information. The source must be on the table at that moment, except for an explicit self-departure reward.
2. If the event occurs during a played card's resolution, finish that card through placement and wand gain before resolving recorded rewards. A reward cannot interrupt the card between its printed quality step and its text step.
3. If the event occurs during the normal discard, complete that discard and resolve its rewards before establishing refill draw attempts.
4. Process rewards in the order their qualifying events occurred. For abilities recorded from the same event, process the active player's abilities first, then the opponent's; within each player's group use the card sheet's slot IDs in ascending order.
5. A new reward caused by a resolving reward goes to the end of the queue. Finish the current reward before continuing. Check for a round ending after each operation that can cause one.

The slot-ID convention is a deterministic prototype ordering rule, not another player choice. It can be reconsidered after testing. Record IDs alongside cards during walkthroughs.

Normal watching abilities require the same table instance to remain present when their reward resolves. If the source left, skip that reward even if the card has since returned as a new instance. An explicit self-departure reward is the exception described below.

Mark a once-per-turn or once-per-round use when its eligible reward is recorded or its replacement is applied. A later skipped reward does not restore that use. These use limits follow the individual card across departures and returns for their stated turn or round; reset them when that turn or round ends.

### Events are distinct

- A point gain is not a point transfer.
- Twirlina requires at least one actual point to move between two of its owner's lanes. A zero-point transfer or a steal from the opponent does not qualify.
- A hand/discard exchange is neither a draw nor the normal discard.
- Putting a resolving card into discard, canceling it, or removing it from the table is not a normal discard.
- Only the successfully played card is used for Paperoo's emotion comparison. Earlier canceled attempts do not qualify.
- Printed dice profiles are card properties even when the card is now in the discard pile. An extra text-granted emotion point does not add an emotion to that profile.

Paperoo can watch the normal discard on the turn it enters, because that discard occurs after its placement. It does not retroactively watch cost discards or exchanges that occurred during its own resolution.

## 4. Resolve exchanges as exchanges

Bobbin's two selected cards exchange locations as one operation. Do not briefly treat the hand as gaining an extra card or trigger a draw attempt. Only grant its 2-point bonus after the exchange completes.

The exchange can create a recovery event for later cards that explicitly watch a discard card moving into hand. It creates no normal-discard event. The regular play-one/discard-one/refill sequence resumes after the played card and its rewards finish.

Purrsie's cost is different: it discards an additional hand card during text resolution. Take the turn's normal discard afterward if a card remains in hand, following the existing short-hand rules. Establish refill attempts from the actual hand size at the start of the refill.

## 5. Sacrifice and departure rewards

“Sacrifice” means remove a friendly table card as the explicit action or cost of your own card text. Mantini performs a sacrifice. Opposing removal, Tucktail replacing an opposing removal, normal discards, exchanges, canceled plays, and round cleanup do not.

When sacrificing a card:

1. Capture its magic value and current quality contribution for the resolving effect. Record any explicit self-departure ability and eligible other-card watchers.
2. Move it to its owner's discard pile, stop its ongoing effects, subtract its table magic, and reverse its quality contribution.
3. Check for an endpoint. If the round ends, discard pending rewards and stop the resolving action immediately.
4. If the round continues, finish the instruction that caused the sacrifice, including any opposing removal. Complete the played card's placement and wand gain, then resolve pending rewards as above.

Fluffernut's “when this card is sacrificed” ability uses its captured departure information and can resolve after it has left the table. Sporeboo's “another friendly card” ability cannot reward its own sacrifice and requires Sporeboo to remain on the table until its reward resolves.

For Mantini, the opposing target's permitted magic is compared with the sacrificed card's captured adjusted magic. The loss of the friendly card's table magic does not erase that comparison value.

## 6. Protection replaces one removal

Tucktail automatically replaces the first eligible opposing removal each round. It does not ask for a decision during the opponent's resolution.

- Check the original friendly target's adjusted magic and Tucktail's unused protection before removing anything.
- If eligible, mark Tucktail's use and substitute Tucktail for the original target. The original target stays on the table and does not briefly lose its effects, magic, or quality contribution.
- Remove Tucktail normally, including quality reversal and an immediate endpoint check. The removal remains caused by the opponent and grants no sacrifice rewards.
- Apply at most one protection replacement to a given removal. A second protector cannot redirect the substituted removal again.
- If future cards create several eligible protectors, use the one that entered the table earliest; break a simultaneous-entry tie by slot ID. This prevents an extra unannounced choice or a redirection loop.

The original effect's magic ceiling determines its initial legal target. A replacement is not a new target selection and does not reapply that ceiling to the protector. Purrsie's cost remains spent even if Tucktail redirects the removal.

Protection does not affect wand cancellation because a canceled card has not entered the table.

## 7. Scope of quality movement and future events

The 12 drafted cards move quality only through printed matches and the existing reversal on removal. Record each card's actual matching contribution when it is applied. A nonmatching persistent card contributes zero quality and reverses zero on departure.

Direct marker movement by text, including the proposed S13 and S14 shared slots, is still at brief stage. Before those cards are drafted, specify which source owns the movement, whether it causes a resolving card to stay, and how actual movement toward center reverses. No first-12 walkthrough relies on an unsettled text-movement rule.

No first-12 card has start-of-turn text, counters, temporary silence, or an opponent choice during resolution. Add explicit timing for such mechanics if later cards require them. Round cleanup does not activate departure or discard rewards.

The prototype uses the normal failed-draw penalties and exhaustion count. It never grants a missed card back merely because the discard pile reshuffled, and it stops before the triggering penalty when both players have reached two exhaustions.

**Revision record:** v0.1 establishes a proposed deterministic procedure for the first 12 cards. Revisit ordering and automatic protection choices after interaction checks and playtests, before adopting final rules.
