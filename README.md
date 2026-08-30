# Coreflame

A small Android and iOS game template built with Flutter and Flame. The included demo is
**Tiny Tactics**, a cute local two-player tic-tac-toe game with responsive
layouts, animated marks, scorekeeping, haptic and audio feedback, and a win
celebration. The included `blossom.mp3` loops as lifecycle-aware background
music. A built-in settings modal lets players independently toggle sound
effects, music, and Pulsar vibration.

The repository intentionally includes only the `android/` and `ios/` Flutter
platform projects. The iOS deployment target is iOS 14 or newer, matching the
minimum required by `games_services`.

## Run it

```sh
cd ~/dev/flutter/coreflame
flutter pub get
flutter run -d <android-or-ios-device>
```

Use `flutter devices` to find an Android emulator, iOS simulator, or connected
phone.

## Inspect a running game

Debug builds expose a versioned, JSON-friendly view of Flutter/Flame state over
the Dart VM service. Copy the VM service URL printed by `flutter run`, then use
the repository CLI from another terminal:

```sh
export COREFLAME_VM_SERVICE_URL=http://127.0.0.1:12345/example=/
dart run tool/coreflame_inspect.dart snapshot
dart run tool/coreflame_inspect.dart events --after 0
dart run tool/coreflame_inspect.dart tree          # Flame component tree
dart run tool/coreflame_inspect.dart widget-tree   # Flutter widget tree
```

The default snapshot is semantic: match state, feedback state, lifecycle,
viewport, and stable component IDs without render-only geometry. Request visual
detail when an agent needs bounds and hit targets:

```sh
dart run tool/coreflame_inspect.dart snapshot --detail visual
```

Agents can drive the same semantic actions as players. Passing the revision
from the latest snapshot prevents a stale observer from mutating newer state:

```sh
dart run tool/coreflame_inspect.dart dispatch play-cell \
  --cell 4 --expected-revision 12
dart run tool/coreflame_inspect.dart dispatch open-settings
dart run tool/coreflame_inspect.dart pause
dart run tool/coreflame_inspect.dart step --seconds 0.0166667
```

Run `dart run tool/coreflame_inspect.dart --help` for every command. The custom
service extensions are debug-only. Snapshots carry a `schemaVersion`; event
batches report their available sequence range and whether older history was
truncated. Commands return their resulting snapshot so automation can observe
each transition directly.

## Project shape

```text
lib/
├── main.dart                              Flutter app shell
└── game/
    ├── coreflame_game.dart               Flame game root
    ├── tic_tac_toe_match.dart            Pure, testable game rules
    ├── components/
    │   └── cozy_tic_tac_toe_scene.dart   Rendering, layout, input, animation
    ├── observability/
    │   ├── coreflame_debug_bridge.dart   Debug VM service extensions
    │   └── coreflame_observability.dart  Snapshots, events, and commands
    ├── services/
    │   ├── game_feedback.dart             Pulsar haptics and Flame audio
    │   ├── game_platform_services.dart    Typed, platform-neutral contract
    │   ├── mobile_game_platform_services.dart
    │   │                                  Game Center / Play Games adapter
    │   └── fake_game_platform_services.dart
    │                                      Deterministic in-memory fake
    └── theme/
        └── game_palette.dart              Shared colors
tool/
└── coreflame_inspect.dart                 Agent-facing inspection CLI
```

Flutter owns the application shell and safe-area handling. Flame owns the game
loop, canvas rendering, resizing, and pointer input. The match rules are kept
free of Flutter and Flame types so they stay quick to unit test and easy to
replace when using this project as a base for another game.

## Platform game services

`MobileGamePlatformServices` normalizes Apple Game Center and Google Play Games
through `games_services`. It provides authentication, logical achievement and
leaderboard IDs, platform UI, versioned cloud-save documents, server
credentials, and typed errors. Reviews use `in_app_review`. The Flutter screen
owns authentication and disposal; Flame only receives the platform-neutral
`GamePlatformServices` contract.

Game services are disabled by default. Enable and configure them with
`--dart-define` values:

- `GAME_SERVICES_ENABLED=true`
- `ANDROID_ACHIEVEMENT_FIRST_WIN` and `IOS_ACHIEVEMENT_FIRST_WIN`
- `ANDROID_LEADERBOARD_MATCH_WINS` and `IOS_LEADERBOARD_MATCH_WINS`
- `GAME_SERVICES_CLOUD_SAVES=true` when cloud saves are configured
- `GOOGLE_GAMES_SERVER_CLIENT_ID` when an Android backend needs an auth code
- `APP_STORE_ID` when the iOS app opens its public review page

The demo unlocks `first_win` and submits `match_wins` after a winning round.
Add or replace the authoritative logical IDs in
`lib/game/services/game_platform_services.dart`, then map them in
`lib/game/services/coreflame_game_services_config.dart`.

Build-time IDs do not replace native store setup:

- Android: configure Play Games Services and OAuth in Play Console, place its
  generated resources in `android/app/src/main/res/values/games-ids.xml`, and
  add the Play Games app ID metadata to the `<application>` in
  `android/app/src/main/AndroidManifest.xml`.
- iOS: configure the game in App Store Connect and add the Game Center
  capability to Runner. Cloud saves additionally need an iCloud container and
  the iCloud Documents capability.

Cloud-save conflicts are resolved by Game Center or Play Games before the
Flutter plugin returns a document. The facade records this honestly as
`GameSaveConflictBehavior.platformResolved`; it does not invent conflict
candidates or cross-platform account merging. Use a backend provider when the
game requires either behavior.

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
- Replace the sample game-service IDs and versioned save payload with the
  domain types for your game.

## Checks

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator
```
