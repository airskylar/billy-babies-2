# Billy Babies Duel prototype contract

This contract fixes the inputs and conventions for the offline prototype. It is
an implementation baseline, not an amendment to the agreed rules.

## Versioned inputs

| Input | Identifier | Authority |
| --- | --- | --- |
| [Agreed rules](../../../billy-babies-rules.md) | `billy-babies-rules@sha256:1939319a77465159f2d2bd09a725b991d6add01cc3699800a041053b0c5f8103` | Match, turn, scoring, cancellation, exhaustion, and magic rules. |
| [Draft 1 card sheet](../../../billy-babies-gen-1-draft-1-cards.md) | `gen-1-draft-1-cards@0.1+sha256:cd98d8f933941b668699b17b290f9ba9c18c19641f916064e4d64c6e4a315982` | First 50 slots, 12 drafted cards, and provisional numerical baseline. |
| [Draft 1 timing supplement](../../../billy-babies-gen-1-draft-1-timing.md) | `draft-1-timing@0.1+sha256:17d170cf2043c81473aae01ce87868fc65c0bb082be75586dfaf9a806e96854f` | Proposed resolution conventions for the first 12 drafted cards. |
| [Approved Gen 1 roster](../../../billy-babies-gen-1.md) | `gen-1-roster@sha256:3bd4b2aeab0b88937b4e2ac9332d1613d8be4d99a44da3552b777c2ac159d01f` | Names, rarities, generation, and visual descriptions. |
| [Draft 1 strategy](../../../billy-babies-gen-1-draft-1-strategy.md) | `gen-1-draft-1-strategy@sha256:5e916d9f6ad531566463fbe60b15235001af607bd8c4b4436f7beb71cd99b102` | Five intended preset directions and playtest goals. |

Debug snapshots use game ID `billyBabiesDuel`, game schema version `1`, and
contract version `1`. Later replay artifacts must carry these source identifiers
and increment the relevant version when an input changes.

## Prototype defaults

- Play is offline, one human against one computer.
- Ordinary tests use the card sheet's baseline magic values without fatigue or
  usage-history adjustment.
- The provisional quality pool is brave, clever, curious, gentle, loyal, and
  playful. A match selects three distinct qualities.
- The eventual presets are emotion shifting, discard/recovery, table/sacrifice,
  shifting/discard hybrid, and discard/sacrifice hybrid.
- Presentation is landscape-first and remains responsive to safe areas and
  viewport changes.

## Information visibility

Tables, discard piles, scores, wand and table magic, pile sizes, exhaustion,
and other resource counts are public. Hands, unrevealed draw order, and future
qualities are private. An explicit reveal effect grants only the information it
states, only to the relevant player. Debug inspection may expose privileged
state, but the computer policy must operate on a player-visible observation.

This convention is provisional until playtests establish whether the agreed
rules need a formal visibility section.

## Time, pause, and restart

Game time, an open six-second wand window, and pending computer scheduling all
freeze while locally paused or backgrounded. Resume continues from the same
remaining game-time duration. Restarting or clearing a scenario discards the
entire game root and creates a fresh inspection session; no pending task or
transient state survives.

These are prototype runtime conventions, not final adopted gameplay rules.

## Mobile smoke target

No supported mobile target is installed or connected in the current environment
as of 2026-09-08. `flutter devices` reports only macOS and Chrome,
`flutter emulators` reports no emulator sources, and `xcrun simctl` is
unavailable. No desktop or web platform project will be added as a workaround.
An Android debug build is also unavailable because `ANDROID_HOME` has no SDK,
and the installed Flutter tool reports this checkout as not configured for an
iOS simulator build.
The first available iOS simulator or Android emulator should be selected and its
landscape viewport recorded before layout tuning or the Milestone 1 mobile
runtime gate is declared complete.
