# Coreflame

A small 2D game template built with Flutter and Flame. The included demo is
**Tiny Tactics**, a cute local two-player tic-tac-toe game with responsive
layouts, animated marks, scorekeeping, haptic and audio feedback, and a win
celebration. The included `blossom.mp3` loops as lifecycle-aware background
music. A built-in settings modal lets players independently toggle sound
effects, music, and Pulsar vibration.

## Run it

```sh
cd ~/dev/flutter/coreflame
flutter pub get
flutter run
```

Use `flutter devices` if you want to choose a specific phone, desktop, or web
target.

## Project shape

```text
lib/
├── main.dart                              Flutter app shell
└── game/
    ├── coreflame_game.dart               Flame game root
    ├── tic_tac_toe_match.dart            Pure, testable game rules
    ├── components/
    │   └── cozy_tic_tac_toe_scene.dart   Rendering, layout, input, animation
    ├── services/
    │   └── game_feedback.dart             Pulsar haptics and Flame audio
    └── theme/
        └── game_palette.dart              Shared colors
```

Flutter owns the application shell and safe-area handling. Flame owns the game
loop, canvas rendering, resizing, and pointer input. The match rules are kept
free of Flutter and Flame types so they stay quick to unit test and easy to
replace when using this project as a base for another game.

## Make it yours

- Change the visual theme in `lib/game/theme/game_palette.dart`.
- Replace move sounds in `assets/audio/` or change their mapping in
  `lib/game/services/game_feedback.dart`.
- Replace `assets/audio/blossom.mp3` to swap the looping background track; its
  volume is configured in `GameFeedback`.
- Replace interface icons in `assets/icons/`; the round button uses a MingCute
  refresh SVG and the settings modal uses a MingCute settings SVG through Flame
  SVG.
- Replace `assets/fonts/gluten_variable.ttf` to change the registered `Gluten`
  typeface used by both Flutter widgets and Flame-rendered text.
- Add components or split scenes under `lib/game/components/`.
- Replace `TicTacToeMatch` while keeping `CoreflameGame` and the Flutter shell.
- Add sprite or audio folders under `assets/`, then register them in
  `pubspec.yaml`.

## Checks

```sh
flutter analyze
flutter test
flutter build web
```
