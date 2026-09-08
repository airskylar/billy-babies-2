# iPhone testing handoff plan

## Goal

Run commit `f59131f` on a real iPhone in Debug mode, then verify signing,
safe-area handling, landscape layout, scenario replacement, and Coreflame
inspection. Do not begin gameplay implementation until this smoke test passes.

## 1. Sync the foundation

From the repository root:

```sh
git fetch origin
git log --oneline --decorate -10
git status --short --branch
```

Confirm commit `f59131f` is present. If it is not reachable from the other
computer, stop and request that the commit be pushed or transferred. Do not
overwrite local work.

Then run:

```sh
flutter pub get
flutter doctor -v
```

The previous computer had Flutter 3.47.2 but only Command Line Tools, not full
Xcode. A full Xcode installation is required.

## 2. Configure Xcode

Install or update Xcode from Apple, then run:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcodebuild -version
xcrun simctl list devices
```

Open the project once:

```sh
open ios/Runner.xcworkspace
```

This project uses Flutter’s Swift Package Manager integration and does not
contain a `Podfile`. Do not add one or run `pod install` unless Flutter
explicitly reports that CocoaPods is required.

In Xcode:

1. Select the `Runner` target.
2. Open Signing & Capabilities.
3. Select the user’s Apple Developer team.
4. Enable automatic signing.
5. Change `com.example.coreflame` to a unique bundle ID if necessary.
6. Keep machine-specific signing changes uncommitted unless they are
   intentionally part of the project configuration.

## 3. Register the iPhone

For a physical iPhone:

1. Connect it by USB.
2. Unlock it and accept “Trust This Computer.”
3. Enable Developer Mode under Settings → Privacy & Security → Developer Mode.
4. Restart the phone if requested.
5. In Xcode, open Window → Devices and Simulators and confirm the phone is
   available.
6. Ensure the phone runs iOS 14 or newer.

Then verify Flutter sees it:

```sh
flutter devices
```

Record the iPhone’s device ID.

## 4. Build and launch

Run:

```sh
flutter run -d <iphone-device-id> \
  --dart-define=STATE_LAUNCHER_SCENARIO=shell.default
```

If signing fails, fix the Xcode team or bundle ID configuration. Do not modify
game code to solve provisioning problems.

If Flutter still reports “Application not configured for iOS” after full Xcode
setup, stop before regenerating the platform project. Capture:

```sh
flutter doctor -v
flutter devices -v
flutter build ios --debug -v
```

and report the exact output.

## 5. Verify the foundation manually

On the iPhone:

- Confirm the app launches as “Billy Babies Duel.”
- Rotate to landscape and check that the shell is not clipped by the notch or
  home indicator.
- Confirm the placeholder panel and quality-track mark render.
- Open the scenario launcher with the three-finger upward gesture.
- Launch, restart, and clear “Duel shell.”
- Confirm each replacement visibly creates a fresh shell.
- Confirm there are no sign-in, achievement, audio, haptic, or asset-loading
  errors.

This is intentionally not a playable duel yet.

## 6. Verify runtime inspection

Copy the VM service URL printed by `flutter run`, then run:

```sh
export COREFLAME_VM_SERVICE_URL='<vm-service-url>'

dart run tool/coreflame_inspect.dart capabilities
dart run tool/coreflame_inspect.dart snapshot
dart run tool/coreflame_inspect.dart snapshot --detail visual
dart run tool/coreflame_inspect.dart pause
dart run tool/coreflame_inspect.dart capture \
  --step 0.0166667 \
  --out /tmp/billy-babies-iphone.png
```

Expected values:

- Game ID: `billyBabiesDuel`
- Game schema: `1`
- State: `setupNotStarted`
- Scenario ID: `shell.default`
- No game-specific commands yet
- A new `sessionId` after restart or clear

Record the iPhone model, iOS version, viewport/orientation, Flutter/Xcode
versions, and captured frame path.

## Completion criteria

The handoff is complete only when:

```sh
flutter analyze
flutter test
```

pass, the app runs on the physical iPhone, the inspection snapshot matches the
expected contract, and `git status --short` contains no unintended changes.
