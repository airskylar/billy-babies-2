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
dart run tool/coreflame_inspect.dart capabilities
dart run tool/coreflame_inspect.dart snapshot
dart run tool/coreflame_inspect.dart events --after 0
dart run tool/coreflame_inspect.dart tree          # Flame component tree
dart run tool/coreflame_inspect.dart widget-tree   # Flutter widget tree
```

The default snapshot is semantic. The generic envelope contains engine,
viewport, and stable component state; `game.state` contains the active game's
typed state. Request visual detail when an agent needs bounds, hit targets, or
animation progress:

```sh
dart run tool/coreflame_inspect.dart snapshot --detail visual
```

Agents can drive the same semantic actions as players. Passing the revision
from the latest snapshot prevents a stale observer from mutating newer state:

```sh
dart run tool/coreflame_inspect.dart dispatch playCell cell=4 \
  --expected-revision 12
dart run tool/coreflame_inspect.dart dispatch setSettingsOpen open=true
dart run tool/coreflame_inspect.dart pause
dart run tool/coreflame_inspect.dart step --seconds 0.0166667
```

Run `capabilities` to discover the active game ID, game-state schema version,
and strict command parameters; the CLI does not hard-code Tiny Tactics actions.
Run `dart run tool/coreflame_inspect.dart --help` for the transport commands.
The custom service extensions are debug-only. Snapshots carry a generic
`protocolVersion` and a separate `game.schemaVersion`; event batches report
their available sequence range and whether older history was truncated. The
template is pre-alpha, so `protocolVersion` remains 1 while this contract
evolves.
Commands execute serially and return only after their adapter work completes.
Each result reports a `disposition` of `rejected`, `noChange`, or `applied` and
includes the completed semantic snapshot. Expected revisions are checked when
the command reaches the front of the queue. State-changing events emitted in a
command's asynchronous call chain are attributed to that transaction. If an
applied command emits no such game event, the host records a generic
`commandApplied` fallback event; unrelated concurrent events cannot satisfy the
command's revision guarantee.

Every `capabilities`, `snapshot`, `events`, and `dispatch` response—and every
pushed Coreflame event—also carries a top-level `sessionId` identifying the
current game mount. If it changes, discard cached revisions and event cursors
before continuing. A command response retains the session that accepted it even
if the same game remounts or another game mount replaces it while the command is
running. Command-owned events are publishable only through that initiating
session, so they cannot be pushed as events from the replacement. Discard the
completed response when its `sessionId` is no longer current.

## Launch scenarios

Debug and profile builds include a searchable scenario launcher. On mobile,
swipe upward with three fingers. On desktop, use Control-Shift-P or
Command-Shift-P. Launching, restarting, or clearing a scenario creates a fresh
Flame game root so components, services, and transient input state do not leak
between runs.

Flutter widgets below `GameScreen` can open the same UI
programmatically:

```dart
await showScenarioLauncher(context);
```

The function is available when scenario launching is enabled for the build.

Start directly in a named scenario with a compilation variable:

```sh
flutter run --dart-define=STATE_LAUNCHER_SCENARIO=round.x-about-to-win
```

The launcher is excluded from release builds by default. Enable it explicitly
when producing an internal release build:

```sh
flutter run --release --dart-define=STATE_LAUNCHER_ENABLED=true
```

## Project shape

```text
lib/
├── main.dart                              Flutter app shell and launcher host
├── scenarios/
│   └── game_scenario.dart                 Scenario catalog and match factories
└── game/
    ├── coreflame_game.dart               Flame game root
    ├── tic_tac_toe_match.dart            Pure, testable game rules
    ├── components/
    │   └── cozy_tic_tac_toe_scene.dart   Rendering, layout, input, animation
    ├── observability/
    │   ├── runtime_inspection_bridge.dart
    │   │                                  Debug VM service extensions
    │   ├── inspectable_flame_game.dart   Reusable Flame inspection host
    │   ├── runtime_inspection.dart       Game-independent protocol kernel
    │   ├── tiny_tactics_inspection.dart  Demo state and command schema
    │   └── tiny_tactics_inspection_adapter.dart
    │                                      Demo snapshot/dispatch adapter
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
`lib/game/services/game_services_config.dart`.

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
- Replace `TicTacToeMatch` and `TinyTacticsInspectionAdapter` together when
  replacing the demo. A new game supplies its own `RuntimeInspectionAdapter`;
  `InspectableFlameGame`, the VM bridge, and the CLI remain unchanged.
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
