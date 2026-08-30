# Getting started

This repository is a game template. The included Tiny Tactics tic-tac-toe game is placeholder
content, not a product requirement. Treat it as disposable scaffolding and do not extend it as the
foundation of the next game.

Before building the real game:

1. Remove the tic-tac-toe rules, scene, demo-specific services/configuration, and their tests. Start
   with the paths currently named `tic_tac_toe` or `TicTacToe`, then remove any remaining references
   from the Flutter shell, Flame game root, `pubspec.yaml`, and documentation.
2. Remove the existing game assets rather than carrying them forward: audio, branding, fonts, icons,
   and any other files under `assets/`. Audit the native launcher and launch-screen resources too;
   replace or remove demo branding where it is still referenced.
3. Remove asset registrations, code, dependencies, and tests that became unused. Do not add
   compatibility shims just to preserve the placeholder.
4. Keep only the Flutter/Flame project structure and platform plumbing that the new game actually
   needs. Rename generic-looking demo concepts when they still describe tic-tac-toe behavior.
5. Update the README and checks so they describe and validate the new game, not Tiny Tactics.

The first meaningful implementation task is therefore a cleanup pass, followed by a fresh game
domain and asset set.
