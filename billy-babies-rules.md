# Billy Babies — Digital Card Game Rules

This document consolidates the agreed gameplay rules.

## Winning the game

Billy Babies is a two-player card game. Win two rounds to win the game, with a maximum of three rounds per match.

Each round has six emotion lanes and one Active Quality tug-of-war track. Players build emotion scores, move the quality track, and play cards that can remain on the table with persistent effects and magic stats.

## Deck building

Each player brings a custom deck of exactly 20 unique cards. Only one copy of any card is allowed, regardless of rarity. Players cannot change their deck between rounds of a match. Decks do not have to cover every emotion.

| Rarity | Maximum copies of the same card | Maximum cards of this rarity per deck |
| --- | ---: | --- |
| Common | 1 | No additional rarity cap |
| Uncommon | 1 | No additional rarity cap |
| Rare | 1 | 5 |
| Mythic | 1 | 2 |

## Starting a round

- Start the six emotion lanes with zero points for each player.
- Before the match, randomly select three distinct qualities from the shared quality pool. Reveal only the current round’s quality before dealing opening hands; keep later qualities hidden.
- Shuffle each player’s deck and give each player three cards.
- Start the shared Active Quality marker at zero, in the center of the track.
- Start with an empty table and zero table magic for each player.
- Reset each player's exhaustion count and empty-deck penalty count.
- Randomly select the starting player for round one. Alternate starting players in later rounds. Turns strictly alternate within each round.
- Each player begins the match with 200 wand magic. Carry existing wand magic into later rounds.
- At the start of every round, give the player going second 30 additional wand magic, subject to the 400 cap. In round one, the starting balances are therefore 200 and 230.

## Taking a turn

On your turn:

1. Play one card from your hand.
2. Discard one card from your hand.
3. Draw back up to three cards.

Three cards is the normal hand size. Failed draws can leave a player with fewer than three cards. The empty-deck rules below govern those exceptions.

With two or more cards, play one and discard one. With one card, play it and skip the discard. With no cards, skip both actions. In each case, attempt the normal refill afterward unless the round has ended. Canceled plays follow the replacement procedure below.

### Card activation and resolution

All applicable features activate together: emotion dice, points for the Active Quality, and card text. Declare targets and printed choices before the wand cancellation window.

After the window closes or the opponent passes, resolve in this order:

1. Roll emotion dice and add their results.
2. Apply matching Active Quality points.
3. Resolve card text.
4. Place the card on the table if it supplied quality points or has persistent text; otherwise discard it. Update table magic as cards enter or leave.
5. Add the card’s magic value to wand magic, up to the 400 cap.

A round-ending condition stops resolution immediately. In particular, reaching a quality endpoint ends the round before any remaining text, placement, or wand gain resolves.

## Emotion lanes

The six emotions are **joy, love, peaceful, shy, sad, and crazy**. Each has its own lane, with a separate score for each player.

Billy Baby cards specify how many dice they roll for each emotion, sometimes none, and how strong those dice are. All dice are six-sided. Greater strength increases the numbers on the faces rather than the number of sides.

Each face is equally likely:

| Strength | Six face values |
| --- | --- |
| Normal | 1, 1, 2, 2, 3, 6 |
| Strong | 1, 2, 3, 4, 4, 8 |
| Brutal | 3, 3, 4, 4, 5, 10 |

Roll the card's applicable emotion dice and add the results to the corresponding emotion scores.

Players can see who currently leads each lane during the round. Checkmarks are awarded only when the round ends:

- The player with the higher score in an emotion lane earns one checkmark.
- If an emotion lane is tied, neither player earns its checkmark.

A card played only for its dice goes to the discard pile after use. It does not contribute to table magic, but an uncanceled play still grants wand charge.

## Active Quality tug of war

The Active Quality changes each round. Its shared track runs from the center at zero to an endpoint 30 points toward either player.

Play a Billy Baby with the Active Quality to move the marker toward your side by the quality points listed on that card. Opposing quality plays move the same marker back toward the opponent's side.

A Billy Baby played for its quality stays on the table and contributes its magic stat to your table magic.

At round end, the player leading the Active Quality earns two checkmarks. If the marker is exactly at zero, neither player receives quality checkmarks.

If either player moves the marker to their endpoint, the round ends. Reaching the endpoint does **not** automatically win the round; determine the winner using checkmarks and tiebreakers.

## Cards on the table

Cards played for their quality and cards with persistent text remain on the table. Other cards go to the discard pile after resolving.

- Persistent text provides ongoing effects as described on the card.
- Each card on the table contributes its magic stat to its owner's table magic.
- There is no limit on the number of cards a player can have on the table.
- Card effects can remove an opponent's cards from the table.
- Unless an effect specifies another destination, a removed card goes to its owner’s discard pile.
- A card that leaves the table stops contributing table magic and persistent effects.
- Previously awarded emotion points remain when a card leaves the table.
- Reverse the quality points that the departing card contributed to the Active Quality track. For example, removing a card that moved the marker five points toward its owner moves it five points back toward the opponent. If this reaches or passes an endpoint, stop at the endpoint and end the round immediately.

## Magic

Players track two separate magic totals: wand charge and table magic.

| Total | How it is gained | What it is used for | Between rounds |
| --- | --- | --- | --- |
| Wand charge | At the wand-gain step, an uncanceled card adds its magic value, including dice-only plays | Canceling an opponent's played card | Carries over |
| Table magic | Sum of the magic stats of cards currently on your table | Card effects and round tiebreakers | Resets when the table clears |

Spending wand charge does not reduce table magic. Table magic decreases when contributing cards leave play.

### Magic wand

One wand charge costs 200 magic. A player can store up to 400 magic, enough for two uses.

Within six seconds of an opponent playing a card, you can spend 200 wand magic to cancel that card instantly. Hold all effects until the window closes or the opponent explicitly passes. Skip the window if the opponent has less than 200 wand magic. A pending quality play cannot end the round before this window is resolved.

A canceled card:

- Produces no emotion dice results, quality points, text effects, or magic gain.
- Goes to its owner's discard pile.
- Allows its owner to refill their hand and make another play.

Cancellation does not require the normal discard. Refill using the normal refill and exhaustion rules, then attempt another play if the round continues. Replacement plays can also be canceled. Take the turn’s normal discard only once, after a successful play, then refill. If a cancellation refill leaves the hand empty, skip the replacement play and discard and end the turn without another refill.

## Empty decks, penalties, and exhaustion

An empty deck means an empty **draw pile**, not an empty hand.

Drawing the final card from a draw pile does not itself trigger exhaustion or a penalty. Those occur when a player attempts to draw and cannot.

### Failed draws

At the start of each refill, establish one draw attempt for each card missing from the normal hand size of three. Resolve those attempts individually. Each attempt that cannot draw a card is a separate failed draw. If a player needs two cards and cannot draw either, that causes two penalties, unless the round ends first.

Each penalty:

- Selects a lane count of two, three, or four with equal probability.
- Selects that many distinct lanes uniformly from all six of that player’s lanes, including lanes at zero.
- Samples a single loss of two, three, or four points with equal probability and applies that same loss to every selected lane.
- Cannot reduce an emotion score below zero. Do not reroll zero-point lanes; their actual loss is zero.

Immediately after the second penalty from that empty draw pile, shuffle only the discard pile into a new draw pile. Leave cards in hand and on the table where they are. The penalty count starts over for the next empty draw pile.

Any still-pending attempts in the current refill use the newly shuffled pile. Even if the discard pile is empty, the reshuffle starts a new empty-pile cycle: reset the penalty count, and count a new exhaustion on its first failed draw.

Missed draws stay lost until the player's next refill. Reshuffling does not immediately replace those missed cards. Players can therefore continue with fewer than three cards in hand.

### Counting exhaustions

The first failed draw from an empty draw pile counts as one exhaustion for that player.

- Further failed draws from the same empty pile cause penalties but do not add exhaustions.
- After reshuffling, the player can exhaust the new draw pile and earn another exhaustion count.
- A player who reaches two exhaustions first continues playing while waiting for the other player to reach two.

When both players have reached at least two exhaustions, the round ends immediately, **before applying the triggering failed draw's penalty**.

For example, if one player already has two exhaustions and the other attempts their first failed draw from their second empty draw pile, the round ends at that moment. The triggering draw does not cause an emotion penalty.

## Ending and scoring a round

A round ends as soon as either condition is met:

1. The Active Quality marker reaches either player's endpoint at 30 points.
2. Both players have reached at least two exhaustions.

Determine the round winner in this order:

1. Award one checkmark for each emotion lane won and two for the Active Quality lead. The player with more checkmarks wins.
2. If checkmarks are tied, the player with more **table magic** wins.
3. If table magic is also tied, both players roll a standard six-sided die with faces 1, 2, 3, 4, 5, and 6 (not an emotion-strength die). The higher roll wins; reroll ties until there is a winner.

### Preparing the next round

Record the round winner. If that player has won two rounds, the match ends.

Otherwise, clear the board and return each player's cards to their full 20-card deck, then reshuffle. Reset emotion scores, the quality track, table magic, exhaustion counts, and penalty counts, and deal new three-card hands. Use a different Active Quality.

Wand charge carries over; add the new second player’s 30-magic bonus, up to 400. Alternate the starting player and reveal the next Active Quality before dealing. The match's round-win tally is retained, and the players keep the same deck composition.

## Card usage, fatigue, and underuse bonuses

A card counts as used when included in a deck for a completed match, whether or not it was drawn or played. Calculate adjusted magic before matchmaking and freeze it for the entire match. The same adjusted value applies to wand gain and table magic.

### Personal fatigue

Use the player’s last 20 completed matches. Apply no fatigue until the player has completed 20 matches. A card’s personal use rate is the percentage of those matches whose deck included it.

| Personal use rate | Magic reduction |
| --- | --- |
| Up to 50% | 0% |
| Above 50% through 75% | 5% |
| Above 75% | 10% |

Playing matches without a card allows recovery as those matches replace older matches containing it.

### Global underuse bonus

Recalculate global inclusion rates daily using completed player-decks from the previous seven days. A completed two-player match contributes two player-decks. Grant no underuse bonus if fewer than 1,000 player-decks are available in that window.

| Global inclusion rate | Magic bonus |
| --- | --- |
| Below 1% | 5% |
| At least 1% but below 3% | 2% |
| At least 3% | 0% |

### Adjusted magic

Adjusted magic = base magic × (1 − fatigue reduction + underuse bonus).

Round to the nearest integer, with halves rounded up. Adjustments range from 90% to 105% of base magic before rounding. Daily global updates and newly completed matches affect future matches only.
