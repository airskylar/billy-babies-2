<page>
  <title>flame_bloc — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_bloc/flame_bloc.html</url>
  <content>**Warning:** you are currently viewing the docs for an older version  of Flame.

Please [click here](https://docs.flame-engine.org/) to go see the documentation for the latest released version.
</content>
</page>

<page>
  <title>flame_tiled — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_tiled/flame_tiled.html</url>
  <content># flame_tiled¶

**flame_tiled** is the bridge package that connects the flame game engine to [Tiled](https://www.mapeditor.org/) maps by parsing TMX (XML) files and accessing the tiles, objects, and everything in there.

To use this,

1. Create your own map by using [Tiled](https://www.mapeditor.org/).
2. Create a `TiledComponent` and add it to the component tree as follows:

```
final component = await TiledComponent.load(
  'my_map.tmx',
  Vector2.all(32),
);

add(component);
```

## TiledComponent¶

Tiled is a free and open source, full-featured level and map editor for your platformer or RPG game. Currently we have an “in progress” implementation of a Tiled component. This API uses the lib [tiled.dart](https://github.com/flame-engine/tiled.dart) to parse map files and render visible layers using the performant `SpriteBatch` for each layer.

Supported map types include: Orthogonal, Isometric, Hexagonal, and Staggered.

| Orthogonal | Hexagonal | Isomorphic |
| --- | --- | --- |
|  |  |  |

An example of how to use the API can be found [here](https://github.com/flame-engine/flame/tree/main/packages/flame_tiled/example).

### TileStack¶

Once a `TiledComponent` is loaded, you can select any column of (x,y) tiles in a `tileStack` to then add animation. Removing the stack will not remove the tiles from the map.

> **Note**: This currently only supports position based effects.

```
void onLoad() {
  final stack = map.tileMap.tileStack(4, 0, named: {'floor_under'});
  stack.add(
    SequenceEffect(
      [
        MoveEffect.by(
          Vector2(5, 0),
          NoiseEffectController(duration: 1, frequency: 20),
        ),
        MoveEffect.by(Vector2.zero(), LinearEffectController(2)),
      ],
      repeatCount: 3,
    )
      ..onComplete = () => stack.removeFromParent(),
  );
  map.add(stack);
}
```

### TileAtlas¶

When a tilemap has multiple images (from multiple tilesets) `TiledComponent` uses a `TileAtlas` to pack all those image into a single big image (a.k.a atlas). This helps in rendering the whole map in a single draw call. But is there a limit on how big this atlas can be based on the target platform and hardware. As it is not possible to query this max size from Flame or Flutter as of now, `TiledComponent` limits the atlas to `4096x4096` for web and `8192x8192` for all other platforms.

These limits should work well for most cases. But in case you are sure that your target platform can support bigger atlas and want to override the limits used by `TiledComponent` you can do so by passing in the `atlasMaxX` and `atlasMaxX` values to `TiledComponent.load`.

NOTE: This is not recommended as such huge sizes might not work with all hardware. Instead consider resizing the original tileset images so that when packed they fit with the limits.

```
final component = await TiledComponent.load(
  'my_map.tmx',
  Vector2.all(32),
  atlasMaxX: 9216,
  atlasMaxY: 9216,
);

add(component);
```

## Limitations¶

### Flip¶

[Tiled](https://www.mapeditor.org/) has a feature that allows you to flip a tile horizontally or vertically, or even rotate it.

`flame_tiled` supports this but if you are using a large texture and have flipped tiles there will be a drop in performance. If you want to ignore any flips in your tilemap you can set the `ignoreFlip` to false in the constructor.

**Note**: A large texture in this context means one with multiple tilesets (or a huge tileset) where the sum of their dimensions are in the thousands.

```
final component = await TiledComponent.load(
  'my_map.tmx',
  Vector2.all(32),
  ignoreFlip: true,
);
```

### Clearing images cache¶

If you have called `Flame.images.clearCache()` you also need to call `TiledAtlas.clearCache()` to remove disposed images from the tiled cache. It might be useful if your next game map have completely different tiles than the previous.

## Troubleshooting¶

### My game shows “lines” and artifacts between the map tiles¶

This is caused by the imprecision found in float-pointing numbers in computer science.

Check this [Article](https://verygood.ventures/blog/solving-super-dashs-rendering-challenges-eliminating-ghost-lines-for-a-seamless-gaming-experience) to learn more about the issue and how it can be solved.
</content>
</page>

<page>
  <title>flame_forge2d — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/flame_forge2d.html</url>
  <content># flame_forge2d¶

- [Overview](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html)
  - [Forge2DGame](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html#forge2dgame)
  - [Forge2DWorld](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html#forge2dworld)
  - [BodyComponent](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html#bodycomponent)
  - [Contact callbacks](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html#contact-callbacks)

- [Joints](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html)
  - [Built-in joints](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#built-in-joints)
    - [`ConstantVolumeJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#constantvolumejoint)
    - [`DistanceJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#distancejoint)
    - [`FrictionJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#frictionjoint)
    - [`GearJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#gearjoint)
    - [`MotorJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#motorjoint)
    - [`MouseJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#mousejoint)
    - [`PrismaticJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#prismaticjoint)
      - [Prismatic Joint Limit](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#prismatic-joint-limit)
      - [Prismatic Joint Motor](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#prismatic-joint-motor)

    - [`PulleyJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#pulleyjoint)
    - [`RevoluteJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#revolutejoint)
      - [Revolute Joint Limit](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#revolute-joint-limit)
      - [Revolute Joint Motor](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#revolute-joint-motor)

    - [`RopeJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#ropejoint)
    - [`WeldJoint`](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#weldjoint)
      - [Breakable Bodies and WeldJoint](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/joints.html#breakable-bodies-and-weldjoint)
</content>
</page>

<page>
  <title>flame_audio — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_audio/flame_audio.html</url>
  <content># flame_audio¶

- [General audio](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio.html)
  - [Caching](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio.html#caching)

- [Background music](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/bgm.html)
  - [Caching music files](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/bgm.html#caching-music-files)
  - [Methods](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/bgm.html#methods)
    - [Play](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/bgm.html#play)
    - [Stop](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/bgm.html#stop)
    - [Pause and Resume](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/bgm.html#pause-and-resume)

- [AudioPool](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html)
  - [How It Works](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html#how-it-works)
  - [Creating an AudioPool](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html#creating-an-audiopool)
    - [Using FlameAudio Helper](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html#using-flameaudio-helper)
    - [Creating Directly with Source](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html#creating-directly-with-source)
    - [Creating from Asset Path](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html#creating-from-asset-path)

  - [Using an AudioPool](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html#using-an-audiopool)
  - [Managing the Pool](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html#managing-the-pool)
  - [Example Usage](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html#example-usage)
</content>
</page>

<page>
  <title>GitHub - flame-engine/flame: A Flutter based game engine.</title>
  <url>https://github.com/flame-engine/flame/</url>
  <content>A Flutter-based game engine.

---

## Documentation

The full documentation for Flame can be found on [docs.flame-engine.org](https://docs.flame-engine.org/).

To change the version of the documentation, use the version selector noted with `version:` in the top of the page.

**Note**: The documentation that resides in the main branch is newer than the released documentation on the docs website.

Other useful links:

- [The official Flame site](https://flame-engine.org/).
- [Examples](https://examples.flame-engine.org/) of most features which can be tried out from your browser.
  - To access the code for each example, press the `< >` button in the top right corner.

- [Tutorials](https://docs.flame-engine.org/main/tutorials/tutorials.html) - Some simple tutorials to get started.
- [API Reference](https://pub.dev/documentation/flame/latest/) - The generated dartdoc API reference.
- [awesome-flame](https://github.com/flame-engine/awesome-flame) - A curated list of Tutorials, Games, Libraries and Articles.

## Help

There is a Flame community on [Blue Fire's Discord server](https://discord.gg/5unKpdQD78) where you can ask any of your Flame related questions.

If you are more comfortable with StackOverflow, you can also create a question there. Add the [Flame tag](https://stackoverflow.com/questions/tagged/flame), to make sure that anyone following the tag can help out.

## Features

The goal of the Flame Engine is to provide a complete set of out-of-the-way solutions for common problems that games developed with Flutter might share.

Some of the key features provided are:

- A game loop.
- A component/object system (FCS).
- Effects and particles.
- Collision detection.
- Gesture and input handling.
- Images, animations, sprites, and sprite sheets.
- General utilities to make development easier.

On top of those features, you can augment Flame with bridge packages. Through these libraries, you will be able to access bindings to other packages, including custom Flame components and helpers, in order to make integrations seamless.

Flame officially provides bridge libraries to the following packages:

- [flame_audio](https://github.com/flame-engine/flame/tree/main/packages/flame_audio) for [AudioPlayers](https://github.com/bluefireteam/audioplayers): Play multiple audio files simultaneously.
- [flame_bloc](https://github.com/flame-engine/flame/tree/main/packages/flame_bloc) for [Bloc](https://github.com/felangel/bloc): A predictable state management library.
- [flame_fire_atlas](https://github.com/flame-engine/flame/tree/main/packages/flame_fire_atlas) for [FireAtlas](https://github.com/flame-engine/fire-atlas): Create texture atlases for games.
- [flame_forge2d](https://github.com/flame-engine/flame/tree/main/packages/flame_forge2d) for [Forge2D](https://github.com/flame-engine/forge2d): A Box2D physics engine.
- [flame_gamepads](https://github.com/flame-engine/flame/tree/main/packages/flame_gamepads) - Support gamepad input in your game (bridge package for [gamepads](https://github.com/flame-engine/gamepads))
- [flame_isolate](https://github.com/flame-engine/flame/tree/main/packages/flame_isolate) - Makes it easy to use [Flutter Isolates](https://api.flutter.dev/flutter/dart-isolate/Isolate-class.html) in a Flame game.
- [flame_lint](https://github.com/flame-engine/flame/tree/main/packages/flame_lint) - Our set of linting (`analysis_options.yaml`) rules.
- [flame_lottie](https://github.com/flame-engine/flame/tree/main/packages/flame_lottie) - Support for [Lottie](https://airbnb.design/lottie/) animation in Flame.
- [flame_network_assets](https://github.com/flame-engine/flame/tree/main/packages/flame_network_assets) - Helpers to load game assets from network.
- [flame_rive](https://github.com/flame-engine/flame/tree/main/packages/flame_rive) for [Rive](https://rive.app/): Create interactive animations.
- [flame_svg](https://github.com/flame-engine/flame/tree/main/packages/flame_svg) for [flutter_svg](https://github.com/dnfield/flutter_svg): Draw SVG files in Flutter.
- [flame_texturepacker](https://github.com/flame-engine/flame/tree/main/packages/flame_texturepacker): Load and use sprite sheets generated with [TexturePacker](https://www.codeandweb.com/texturepacker)
- [flame_tiled](https://github.com/flame-engine/flame/tree/main/packages/flame_tiled) for [Tiled](https://www.mapeditor.org/): 2D tile map level editor.

## Sponsors

The Flame Engine's top sponsors:

Do you or your company want to sponsor Flame? Check out our [OpenCollective page](https://opencollective.com/blue-fire), which is also mentioned in the section below, or contact us on [Discord](https://discord.gg/pxrBmy4).

## Support

The simplest way to show us your support is by giving the project a star! ⭐

You can also support us monetarily by donating through OpenCollective:

Through GitHub Sponsors:

Or by becoming a patron on Patreon:

You can also show on your repository that your game is made with Flame by using one of the following badges:

```
[![Powered by Flame](https://img.shields.io/badge/Powered%20by-%F0%9F%94%A5-272727.svg)](https://flame-engine.org)
[![Powered by Flame](https://img.shields.io/badge/Powered%20by-%F0%9F%94%A5-272727.svg?style=flat-square)](https://flame-engine.org)
[![Powered by Flame](https://img.shields.io/badge/Powered%20by-%F0%9F%94%A5-272727.svg?style=for-the-badge)](https://flame-engine.org)
```

## Contributing

Have you found a bug or have a suggestion of how to enhance Flame? Open an issue and we will take a look at it as soon as possible.

Do you want to contribute with a PR? PRs are always welcome, just make sure to create it from the correct branch (main) and follow the [checklist](https://github.com/flame-engine/flame/blob/main/.github/pull_request_template.md) which will appear when you open the PR.

Also, before you start, make sure to read our [Contributing Guide](https://github.com/flame-engine/flame/blob/main/CONTRIBUTING.md).

For bigger changes, or if in doubt, make sure to talk about your contribution to the team. Either via an issue, GitHub discussion, or reach out to the team either using the [Discord server](https://discord.gg/pxrBmy4).

## Credits

- The [Blue Fire team](https://github.com/orgs/bluefireteam/people), who are continuously working on maintaining and improving Flame and its ecosystem.
- All the friendly contributors and people who are helping out in the community.
</content>
</page>