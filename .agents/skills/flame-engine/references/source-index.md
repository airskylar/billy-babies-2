# Flame Engine reference index

These snapshots were fetched with the `sitefetch` CLI on 2026-08-30 from the official Flame documentation and repository. Each snapshot preserves the page title, source URL, and extracted Markdown. The live `latest` URLs are useful for checking updates; resolve against the project’s locked package version when it differs.

## Official source and orientation

- [Flame repository](https://github.com/flame-engine/flame/) — feature overview, bridge-package list, examples, tutorials, and API links. Snapshot: [integrations-and-source.md](integrations-and-source.md).
- [Flame latest documentation](https://docs.flame-engine.org/latest/) — documentation entry point.
- [Flame API reference](https://pub.dev/documentation/flame/latest/) — generated Dart API reference; use a matching package-version URL when needed.

## Snapshot coverage

| Topic | Local snapshot | Fetched pages |
| --- | --- | --- |
| Fundamentals | [fundamentals.md](fundamentals.md) | [FlameGame](https://docs.flame-engine.org/latest/flame/game.html), [Game Widget](https://docs.flame-engine.org/latest/flame/game_widget.html), [Components](https://docs.flame-engine.org/latest/flame/components/components.html), [PositionComponent](https://docs.flame-engine.org/latest/flame/components/position_component.html), [Camera & World](https://docs.flame-engine.org/latest/flame/camera.html) |
| Rendering | [rendering.md](rendering.md) | [Sprite Components](https://docs.flame-engine.org/latest/flame/components/sprite_components.html), [Images](https://docs.flame-engine.org/latest/flame/rendering/images.html), [Text Rendering](https://docs.flame-engine.org/latest/flame/rendering/text_rendering.html), [Particles](https://docs.flame-engine.org/latest/flame/rendering/particles.html), [Shape Components](https://docs.flame-engine.org/latest/flame/components/shape_components.html) |
| Input and effects | [input-and-effects.md](input-and-effects.md) | [Inputs](https://docs.flame-engine.org/latest/flame/inputs/inputs.html), [Tap Events](https://docs.flame-engine.org/latest/flame/inputs/tap_events.html), [Drag Events](https://docs.flame-engine.org/latest/flame/inputs/drag_events.html), [Long Press Events](https://docs.flame-engine.org/latest/flame/inputs/long_press_events.html), [Scale Events](https://docs.flame-engine.org/latest/flame/inputs/scale_events.html), [Keyboard Input](https://docs.flame-engine.org/latest/flame/inputs/keyboard_input.html), [Effects](https://docs.flame-engine.org/latest/flame/effects/effects.html) |
| Collision | [collision.md](collision.md) | [Collision Detection](https://docs.flame-engine.org/latest/flame/collision_detection.html) |
| Performance and testing | [performance-and-testing.md](performance-and-testing.md) | [Performance](https://docs.flame-engine.org/latest/flame/other/performance.html), [Writing tests](https://docs.flame-engine.org/latest/development/testing_guide.html) |
| Bridge packages | [bridge-details.md](bridge-details.md) | [Forge2D](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html), [Tiled](https://docs.flame-engine.org/latest/bridge_packages/flame_tiled/tiled.html), [Audio](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio.html), [Background music](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/bgm.html), [AudioPool](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html), [flame_bloc](https://docs.flame-engine.org/latest/bridge_packages/flame_bloc/bloc.html), [flame_bloc components](https://docs.flame-engine.org/latest/bridge_packages/flame_bloc/bloc_components.html) |
| Bridge/package orientation | [integrations-and-source.md](integrations-and-source.md) | [flame_forge2d](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/flame_forge2d.html), [flame_tiled](https://docs.flame-engine.org/latest/bridge_packages/flame_tiled/flame_tiled.html), [flame_audio](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/flame_audio.html), [flame_bloc](https://docs.flame-engine.org/latest/bridge_packages/flame_bloc/flame_bloc.html), [Flame repository](https://github.com/flame-engine/flame/) |

Some bridge landing pages can redirect to an older-version notice while their detailed pages remain usable. Treat that as a signal to check the package version and generated API reference rather than assuming the landing page describes the installed release.
