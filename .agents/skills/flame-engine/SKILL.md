---
name: flame-engine
description: Build and debug Flutter/Dart games using the Flame engine and its official bridge packages, with version-aware guidance for components, lifecycle, rendering, input, cameras, collisions, testing, and performance.
---

# Flame Engine

Use this skill for work involving `flame`, `FlameGame`, `GameWidget`, the Flame Component System, worlds and cameras, sprites and animations, effects, input, collision detection, rendering, game tests, performance, or official `flame_*` bridge packages.

The files under `references/` are focused snapshots fetched from the official Flame documentation and repository with `sitefetch` on 2026-08-30. Use them as a fast, searchable starting point, but treat the project’s resolved dependency version and version-specific API reference as authoritative.

## Inspect the project first

- Read `pubspec.yaml` and `pubspec.lock` to identify the exact `flame` and bridge-package versions, Flutter/Dart constraints, and declared Flutter assets. Do not silently upgrade dependencies to match the latest docs.
- Locate the Flutter/Flame boundary (`GameWidget`), the game class, `World`, camera, components, overlays, and tests before changing architecture. Keep Flutter widget state and the Flame component tree conceptually separate.
- Follow the repository’s existing naming, asset, state-management, and testing conventions. Prefer Flame and Flutter primitives already used by the project over new abstractions.
- When an API is uncertain or the snapshot does not match the lockfile, consult the matching generated API reference and the upstream source/examples before coding.

## Core model

- `GameWidget` hosts a `Game` inside Flutter. Use it for Flutter composition such as loading/error/background builders, focus, layout, and overlays. Put gameplay behavior in the game/component tree unless the feature is intentionally Flutter UI.
- Use `FlameGame` as the normal root for FCS games. Put world entities under `World`; use the built-in `game.world` and `game.camera` unless multiple worlds, cameras, or custom routing require otherwise.
- Treat component additions and removals as lifecycle-scheduled operations. Use `onLoad` for asynchronous, once-per-component initialization such as asset loading; `onMount` may run again after re-parenting; `onRemove` is the cleanup boundary. Await `loaded`, `mounted`, or `game.ready()` when correctness depends on descendants being ready.
- For ordinary components, `onLoad` is a one-time asynchronous constructor-like phase, followed by resize/mount work; the game-level lifecycle has its own resize-first ordering. Do not assume Flutter widget lifecycle semantics apply to Flame components.
- `PositionComponent` values are parent-local: reason about `position`, `size`, `scale`, `angle`, and `anchor` together. Keep world objects under a world, HUD elements under `camera.viewport`, and camera-transformed UI/effects under `camera.viewfinder`.
- Use component composition and `priority` for ownership and draw order. Use typed relationship mixins such as `ParentIsA` or `HasWorldReference` when they make an invariant explicit instead of repeatedly searching or casting.

## Feature guidance

### Assets and rendering

- Declare files in Flutter’s asset configuration before loading them. Load images, sprites, and animations asynchronously during load; reuse decoded images and shared animation data rather than decoding on every frame.
- Choose the narrowest built-in visual component: `SpriteComponent` for one sprite, `SpriteAnimationComponent` for one animation, `SpriteAnimationGroupComponent` for state-driven animations, and sprite batches/atlases for many repeated textures.
- In a custom `render(Canvas)`, make canvas transforms and `Paint` ownership explicit. Use `save`/`restore` around temporary canvas state and preserve inherited/child rendering when the component’s design requires it.
- Use Flame text components/renderers for in-game text and Flutter widgets for app UI. Avoid rebuilding Flutter widgets every frame to animate game-world visuals.

### Input

- Add event mixins to the component that owns the interaction (`TapCallbacks`, `DragCallbacks`, `LongPressCallbacks`, and related APIs). Give `PositionComponent`s a meaningful `size` or override `containsLocalPoint()` so hit testing reflects the actual target.
- Prefer event-local coordinates and deltas when components can be transformed. Local deltas account for parent transforms and camera zoom more reliably than manually converting screen coordinates.
- Preserve callback lifecycle behavior. In particular, call the documented `super` implementations when they maintain mixin state such as `isLongPressing`.
- For keyboard input, choose either game-level `KeyboardEvents` or component-level `KeyboardHandler` with `HasKeyboardHandlerComponents`; do not combine the conflicting approaches. Confirm `GameWidget` focus and `autofocus` behavior for desktop/web tasks.
- Use Flutter gesture widgets only at an intentional Flutter/Flame boundary. Do not duplicate a component’s hit testing in a surrounding `GestureDetector` without deciding which layer owns the gesture.

### Camera and world layout

- Use camera APIs such as `follow`, `moveTo`, `moveBy`, bounds, and viewfinder/viewport effects before manually mutating camera state each frame.
- Choose fixed resolution deliberately: it simplifies world coordinates but can introduce letterboxing and changes how much of the world is visible across aspect ratios.
- Put static HUD children in the viewport, world-transformed children in the viewfinder, and static background content in the camera backdrop. Make coordinate-space conversions explicit when mapping input or UI to world positions.

### Effects and animation

- Effects are components that change target properties over time. Add them to the target, select an appropriate controller/duration, and define completion/removal behavior for the gameplay state.
- Give each mutable property one clear owner. Do not manually update a property in `update` while an effect or animation is also expected to control it unless the interaction is intentional and tested.
- Use sequences and combined effects for choreography; use decorators or custom rendering when the requirement is a visual post-process rather than a component-property change.

### Collision and physics

- Add `HasCollisionDetection` at the smallest intended tree scope (the game or a specific world), add `CollisionCallbacks` to responders, and add `ShapeHitbox` children that match the gameplay geometry.
- Collision callbacks may be delivered to both participants and to hitboxes that implement the callbacks. Type-check `other`, keep responses idempotent, and avoid applying the same damage/state transition twice.
- Built-in Flame collision detection is discrete and can tunnel when objects move quickly or `dt` is large. Use conservative movement/steps or choose `flame_forge2d` when rigid-body physics, contacts, joints, or continuous-physics behavior is the actual requirement.
- Use passive hitboxes and broad-phase/culling options only when their semantics match the game and profiling shows collision work is material.
- In Forge2D, use `Forge2DGame`, `Forge2DWorld`, and top-level `BodyComponent`s in the physics world. Keep bodies out of nested component hierarchies, and account for Forge2D’s default zoom and Flame’s screen-coordinate convention.

### State and bridge packages

- Keep domain/gameplay state in testable Dart objects or components. Use `flame_bloc` or another bridge only when the project already uses that state system or the integration is a clear boundary.
- Treat `flame_tiled`, `flame_audio`, `flame_forge2d`, and other bridges as separate package APIs: verify the package version, asset setup, initialization, cache lifetime, and cleanup independently.
- For repeated sound effects, use the package’s caching/pooling facilities when appropriate. For tile maps, validate TMX/tileset assets and platform texture limits. For any bridge, prefer the package’s documented example over invented glue code.

## Performance, debugging, and tests

- Keep `update` and `render` allocation-light: reuse vectors, paints, images, and other stable values; avoid per-frame widget rebuilds and asset decoding.
- Reduce unnecessary collision participation and use camera visibility/culling where it is correct. Consider `ComponentPool` for high-churn components only after measuring; reset internal reusable state on mount without overwriting caller-configured spawn values.
- Use `debugMode` and hitbox rendering to investigate spatial/input bugs, then verify that debug-only behavior is not part of the shipped path. Clear game and bridge caches deliberately when games are removed or restarted.
- Use `testWithFlameGame` for component/game behavior, `await game.ready()` before assertions that require loading/mounting, and `game.update(dt)` for deterministic time advancement. Use widget tests for `GameWidget`, overlays, focus, and Flutter composition; use golden tests for stable rendering.
- For a change or bug fix, add a focused regression test for the lifecycle, coordinate, callback, collision, or rendering transition at issue. Avoid sleeps; make time, assets, and randomness deterministic where possible.
- Finish with the repository-appropriate formatter, analyzer, and targeted tests. Run broader Flutter tests when the change crosses widget, platform, or package boundaries.

## Reference routing

Read only the reference relevant to the current task. [references/source-index.md](references/source-index.md) records the fetched URLs and coverage.

- [Fundamentals](references/fundamentals.md): `FlameGame`, `GameWidget`, components/lifecycle, `PositionComponent`, worlds, cameras, and viewports.
- [Rendering](references/rendering.md): images, sprites, animations, shapes, particles, and text rendering.
- [Input and effects](references/input-and-effects.md): taps, drags, long presses, scale/keyboard input, and effects.
- [Collision](references/collision.md): hitboxes, collision callbacks, collision scopes, ray casting, and tunneling considerations.
- [Performance and testing](references/performance-and-testing.md): frame allocations, collision cost, pooling, Flame game tests, widget tests, and golden tests.
- [Bridge details](references/bridge-details.md): Forge2D, Tiled, audio, and `flame_bloc` usage.
- [Integrations and source](references/integrations-and-source.md): the official repository’s feature/bridge overview and source links.
