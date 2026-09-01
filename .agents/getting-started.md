# Getting started

This repository is a game template. The included Tiny Tactics tic-tac-toe game is placeholder
content, not a product requirement. Treat it as disposable scaffolding and do not extend it as the
foundation of the next game.

Before building the real game:

1. Remove `lib/game/` and the matching `test/game/` tests. They contain the complete Tiny Tactics
   game: its rules, Flame root and scene, feedback, inspection adapter, scenarios, theme, and
   platform-service identifiers/configuration. Remove the concrete game wiring from
   `lib/app/coreflame_app.dart` before connecting the replacement game.
2. Remove the existing game assets rather than carrying them forward: audio, branding, fonts, icons,
   and any other files under `assets/`. Audit the native launcher and launch-screen resources too;
   replace or remove demo branding where it is still referenced.
3. Remove asset registrations, code, dependencies, and tests that became unused. Do not add
   compatibility shims just to preserve the placeholder.
4. Keep only the Flutter/Flame project structure and platform plumbing that the new game actually
   needs. Reusable inspection and platform adapters live under `lib/runtime/`; keep them
   game-independent and remove any that the replacement does not need.
5. Update the README and checks so they describe and validate the new game, not Tiny Tactics.

The first meaningful implementation task is therefore a cleanup pass, followed by a fresh game
domain and asset set.
