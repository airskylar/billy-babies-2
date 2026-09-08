# Billy Babies Duel

An offline, single-player digital card-game prototype built with Flutter and
Flame. The current Milestone 1 build is a non-playable foundation shell: it
establishes the Billy Babies game root, scenario lifecycle, and inspection
contract before duel rules and cards are added.

The repository contains Android and iOS platform projects. It intentionally
does not add desktop or web targets as substitutes for mobile testing.

## Run the shell

```sh
flutter pub get
flutter devices
flutter run -d <android-or-ios-device>
```

The shell is landscape-first but responds to safe areas and viewport changes.
There are no sign-in, cloud-save, achievement, leaderboard, review, audio, or
haptic integrations in this offline prototype.

## Inspect a debug build

Copy the VM service URL printed by `flutter run`, then use the repository CLI
from another terminal. Treat that URL as ephemeral local access data.

```sh
export COREFLAME_VM_SERVICE_URL=http://127.0.0.1:12345/example=/
dart run tool/coreflame_inspect.dart capabilities
dart run tool/coreflame_inspect.dart snapshot
dart run tool/coreflame_inspect.dart events --after 0
dart run tool/coreflame_inspect.dart tree
dart run tool/coreflame_inspect.dart widget-tree
```

Milestone 1 exposes game ID `billyBabiesDuel`, game schema version `1`, and an
honest `setupNotStarted` state. `capabilities` currently lists no game-specific
commands because there are no legal duel decisions yet. The generic pause,
resume, step, capture, and pointer-replay controls remain available:

```sh
dart run tool/coreflame_inspect.dart pause
dart run tool/coreflame_inspect.dart step --seconds 0.0166667
dart run tool/coreflame_inspect.dart capture --step 0.0166667 --out frame.png
```

Every capabilities, snapshot, events, and dispatch response has a top-level
`sessionId`. Launching, restarting, or clearing a scenario replaces the entire
game root, so discard cached revisions and event cursors when that ID changes.
Run `dart run tool/coreflame_inspect.dart --help` for the complete CLI contract.

## Launch the foundation scenario

Debug and profile builds include a searchable scenario launcher. Swipe upward
with three fingers on mobile. Launching, restarting, and clearing all create a
fresh game root.

```sh
flutter run \
  --dart-define=STATE_LAUNCHER_SCENARIO=shell.default \
  -d <android-or-ios-device>
```

Flutter widgets below `GameScreen` can open the same launcher with
`showScenarioLauncher(context)`. The launcher is omitted from release builds by
default; `--dart-define=STATE_LAUNCHER_ENABLED=true` enables it for an internal
release build.

## Project shape

```text
lib/
├── app/coreflame_app.dart                 Flutter shell and scenario lifecycle
├── game/
│   ├── domain/prototype_session.dart      Pure not-started prototype state
│   ├── inspection/                        Billy Babies snapshot adapter
│   ├── scenarios/catalog.dart             Foundation scenario catalog
│   ├── scene/scene.dart                   Flame placeholder shell
│   ├── game_root.dart                     Inspectable Billy Babies root
│   └── prototype_contract.dart            Runtime version identifiers
└── runtime/
    ├── input/                              Validated pointer traces
    ├── inspection/                         Game-independent inspection runtime
    └── motion/                             Reusable motion primitives
```

Flutter owns the application shell and safe-area handling. Flame owns the game
loop, rendering, resizing, and pointer input. Rules added in later milestones
belong in pure Dart under `lib/game/domain/`. Reusable code under `lib/runtime/`
must not import the active game; an architecture test enforces that boundary.

The source versions and provisional visibility/pause conventions are fixed in
the [prototype contract](docs/plans/billy-babies-duel/prototype-contract.md).

## Checks

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build apk --debug
# or, on a configured macOS/iOS toolchain:
flutter build ios --simulator
```
