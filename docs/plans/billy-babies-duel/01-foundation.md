# Milestone 1 — Prototype contract and starter replacement

Status: implementation plan only; all tasks are pending.

[Prototype overview](../../../billy-babies-duel-prototype-plan.md) · [Next milestone](02-rules-and-interactions.md)

## Outcome

Coreflame launches a minimal Billy Babies Duel shell on a supported mobile test target. The Tiny Tactics implementation and branding are gone, reusable inspection still works, and the prototype's rules/configuration boundaries are recorded. This milestone does not produce a playable duel.

## Entry conditions and scope

Read [initialization guidance](../../../.agents/getting-started.md), [Dart rules](../../../.agents/rules/dart-code-quality.md), and [inspection rules](../../../.agents/rules/runtime-inspection.md) before implementation. Check the current worktree and preserve unrelated changes. Use the existing checkout without creating or switching branches.

Retain Flutter/Flame, safe-area/lifecycle handling, inspection surface and VM bridge, pointer replay, useful motion utilities, and the scenario-launcher pattern. Remove the concrete demo and platform-service behavior that the offline prototype does not need. No dependency upgrades, new artwork pipeline, or backend work are planned.

## Ordered work

### 1.1 Record the implementation contract

- [ ] Create a concise prototype contract alongside these plans, linking the agreed rules, card sheet, timing supplement, and roster versions. Record the initial content/rules identifiers used in debug snapshots and later replays.
- [ ] Record defaults: offline human versus computer, baseline magic, the six provisional qualities, five eventual presets, and landscape-first presentation.
- [ ] Record the proposed visibility convention: public tables/discards/resources/counts, private hands and unrevealed draw order, hidden future qualities. Explicit reveal effects grant only their stated information to the relevant player.
- [ ] Record pause behavior: game time, the wand window, and bot scheduling freeze on pause/background; restarting creates a fresh game session. Keep these prototype conventions distinct from final adopted rules.
- [ ] Inspect available devices and select an existing simulator/emulator for smoke checks. Record the target and viewport used; do not add desktop/web projects to work around an unavailable mobile target.

### 1.2 Inventory the replacement boundary

- [ ] Use entity/impact inspection for the existing game root and `CoreflameApp` wiring. Identify demo imports, scenario factories, service IDs, preferences, feedback, theme, and corresponding tests before removal.
- [ ] Inventory `assets/`, `pubspec.yaml` registrations, native launcher/launch-screen resources, and demo references in README/checks. Distinguish game assets from required platform build files.
- [ ] Classify runtime modules and dependencies by actual use after replacement. Remove unused demo/platform-service plumbing coherently with its tests and configuration; retain generic facilities still needed by the prototype.
- [ ] Record the current checks and existing failures before changes, so a pre-existing problem is not attributed to the replacement.

### 1.3 Replace the game and shell wiring as one coherent change

- [ ] Remove the old `lib/game/` and matching game tests according to the sentinel guidance. Build fresh Billy Babies code rather than renaming the tic-tac-toe domain.
- [ ] Add a minimal game root based on `InspectableFlameGame`, a simple named scene, and a game-specific inspection adapter. Expose an honest setup/not-started state with a game ID and schema version.
- [ ] Replace the concrete imports and construction in `lib/app/coreflame_app.dart`. Continue using the existing inspection surface and safe-padding propagation.
- [ ] Replace the demo scenario catalog with a minimal shell scenario. Launch/restart/clear must replace the entire root and discard old state.
- [ ] Remove demo sign-in, achievements, score submission, save payloads, and feedback wiring. Avoid initializing unused mobile service plugins for this offline prototype.
- [ ] Preserve disposal and lifecycle handling. The empty shell must survive background/resume and repeated scenario restarts.

### 1.4 Clean assets, configuration, and documentation

- [ ] Remove demo audio, fonts, icons, branding, and their registrations. Use platform/default text and simple geometric placeholders for the initial shell.
- [ ] Replace or remove native demo branding while retaining valid launcher and launch-screen resources. Use a neutral prototype icon if one is required for the build.
- [ ] Remove dependencies made unused by the cleanup and update the lockfile through the normal package tooling; do not opportunistically upgrade retained packages.
- [ ] Rewrite README setup and inspection examples around Billy Babies. Clearly say the shell is not yet playable.
- [ ] Retire `.getting-started` only after its required replacement/cleanup is complete.

### 1.5 Verify the foundation

- [ ] Update shell and scenario tests for the new root, including safe-area changes, disposal, and fresh state on restart.
- [ ] Keep architecture checks proving runtime modules do not import the active game. Run retained runtime tests and `flutter analyze`.
- [ ] Launch the target build; discover `capabilities`, inspect `snapshot`, and confirm the new game ID, schema, and scenario session changes.
- [ ] Inspect one captured frame for placeholder branding and layout. Confirm no removed asset is requested and no platform sign-in is initiated.
- [ ] Search active source/configuration for obsolete demo references; historical Git content is outside this cleanup.

## Expected changes

Primary areas: `lib/app/coreflame_app.dart`, fresh `lib/game/` root/scene/inspection/scenarios, matching `test/app/` and `test/game/`, unused runtime service modules if applicable, `assets/`, native resource references, `pubspec.yaml`/lockfile, `.getting-started`, and README. Exact file splits should follow actual responsibilities rather than creating empty directories for future milestones.

## Completion gate and handoff

- [ ] Billy Babies launches and is discoverable through Coreflame inspection on the selected supported target.
- [ ] No active Tiny Tactics implementation, demo assets, or service behavior remains.
- [ ] Updated shell/scenario tests, retained runtime tests, and analysis pass; unavailable checks are explicitly recorded.
- [ ] The prototype contract, chosen target, and remaining limitations are documented.

Commit the verified foundation as `feat: establish Billy Babies Duel prototype shell`. If cleanup and replacement cannot build independently, keep them in the same commit. Hand off the root/adapter pattern, version identifiers, and prototype contract to milestones 2 and 3. Do not describe this gate as a playable match.
