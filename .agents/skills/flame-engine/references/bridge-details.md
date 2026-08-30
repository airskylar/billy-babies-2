<page>
  <title>Tiled — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_tiled/tiled.html</url>
  <content># Tiled¶

[Tiled](https://www.mapeditor.org/) is a great tool to design levels and maps. From [Tiled](https://www.mapeditor.org/)’s documentation:

> Tiled is a 2D level editor that helps you develop the content of your game. Its primary feature is to edit tile maps of various forms, but it also supports free image placement as well as powerful ways to annotate your level with extra information used by the game. Tiled focuses on general flexibility while trying to stay intuitive.
>
>
>
> In terms of tile maps, it supports straight rectangular tile layers, but also projected isometric, staggered isometric and staggered hexagonal layers. A tileset can be either a single image containing many tiles, or it can be a collection of individual images. In order to support certain depth faking techniques, tiles and layers can be offset by a custom distance and their rendering order can be configured.

Flame provides a package ([flame_tiled](https://github.com/flame-engine/flame/tree/main/packages/flame_tiled)) that bundles a [dart](https://pub.dev/packages/tiled) package which allows you to parse TMX (XML) files and access the tiles, objects, and everything in there.

The [dart](https://pub.dev/packages/tiled) package provides a simple `Tiled` class and [flame_tiled](https://github.com/flame-engine/flame/tree/main/packages/flame_tiled) provides a component wrapper `TiledComponent`, for the map rendering, which renders the tiles on the screen and supports rotations and flips.

## Tiled Editor¶

You can choose to download the [Tiled](https://www.mapeditor.org/) map editor and create interactive maps that can be loaded into your game. At its core, the [Tiled](https://www.mapeditor.org/) map editor creates a TMX file that can be parsed and used within your game.
</content>
</page>

<page>
  <title>Components — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_bloc/bloc_components.html</url>
  <content># Components¶

## FlameBlocProvider¶

FlameBlocProvider is a Component which creates and provides a bloc to its children.
 The bloc will only live while this component is alive. It is used as a dependency injection (DI) widget so that a single instance of a bloc can be provided to multiple Components within a subtree.

FlameBlocProvider should be used to create new blocs which will be made available to the rest of the subtree.

```
FlameBlocProvider<BlocA, BlocAState>(
  create: () => BlocA(),
  children: [...]
);
```

FlameBlocProvider can be used to provide an existing bloc to a new portion of the Component tree.

```
FlameBlocProvider<BlocA, BlocAState>.value(
  value: blocA,
  children: [...],
);
```

## FlameMultiBlocProvider¶

Similar to FlameBlocProvider, but provides multiples blocs down to the component tree

```
FlameMultiBlocProvider(
  providers: [
    FlameBlocProvider<BlocA, BlocAState>(
      create: () => BlocA(),
    ),
    FlameBlocProvider<BlocB, BlocBState>.value(
      create: () => BlocB(),
    ),
    ],
  children: [...],
)
```

## FlameBlocListener¶

FlameBlocListener is Component which can listen to changes in a Bloc state. It invokes the `onNewState` in response to state changes in the bloc. For fine-grained control over when the `onNewState` function is called an optional `listenWhen` can be provided. `listenWhen` takes the previous bloc state and current bloc state and returns a boolean. If `listenWhen` returns true, `onNewState` will be called with `state`. If `listenWhen` returns false, `onNewState` will not be called with `state`.

alternatively you can use `FlameBlocListenable` mixin to listen state changes on Component.

```
FlameBlocListener<GameStatsBloc, GameStatsState>(
  listenWhen: (previousState, newState) {
      // return true/false to determine whether or not
      // to call listener with state
  },
  onNewState: (state) {
          // do stuff here based on state
  },
)
```

## FlameBlocListenable¶

FlameBlocListenable is an alternative to FlameBlocListener to listen state changes.

```
class ComponentA extends Component
    with FlameBlocListenable<BlocA, BlocAState> {

  @override
  bool listenWhen(PlayerState previousState, PlayerState newState) {
    // return true/false to determine whether or not
    // to call listener with state
  }

  @override
  void onNewState(PlayerState state) {
    super.onNewState(state);
    // do stuff here based on state
  }
}
```

## FlameBlocReader¶

FlameBlocReader is mixin that allows you to read the current state of bloc on Component. It is Useful for components that needs to only read a bloc current state or to trigger an event on it. You can have only one reader on Component

```
class InventoryReader extends Component
    with FlameBlocReader<InventoryCubit, InventoryState> {}

    /// inside game

    final component = InventoryReader();
    // reading current state
    var state = component.bloc
```
</content>
</page>

<page>
  <title>AudioPool — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html</url>
  <content># AudioPool¶

An AudioPool is a provider of AudioPlayers that are pre-loaded with local assets to minimize audio playback delays. This is particularly useful in fast-paced games where sound effects need to trigger quickly and potentially overlap with each other.

A single AudioPool always plays the same sound, usually a quick sound effect that might need to be played repeatedly or simultaneously, such as:

- Shooting sounds in a space shooter
- Jump sounds in a platformer
- Explosion effects
- Collecting coins or items
- Enemy hit sounds

## How It Works¶

AudioPool works by creating and pre-loading a pool of AudioPlayer instances that are all configured to play the same sound. When you need to play the sound:

1. The pool gives you an available player from its collection
2. If no player is available, a new player is created on demand
3. When a sound finishes playing or is stopped manually, the player is returned to the pool for reuse, unless the pool already has reached its maximum size limit, in which case the player is released

This approach significantly reduces latency compared to creating new AudioPlayer instances on demand, while also managing memory by limiting the maximum size of the pool.

## Creating an AudioPool¶

There are multiple ways to create an AudioPool:

### Using FlameAudio Helper¶

The simplest approach is to use the helper method in `FlameAudio`, which conveniently uses Flame’s global audio cache:

```
import 'package:flame_audio/flame_audio.dart';

Future<void> loadSounds() async {
  // Create a pool with minimum 1 player and maximum 2 players
  // This automatically uses Flame's global audio cache
  AudioPool explosionSoundPool = await FlameAudio.createPool(
    'explosion.mp3',
    minPlayers: 1,
    maxPlayers: 2,
  );
}
```

### Creating Directly with Source¶

You can also create an AudioPool by directly using the static factory methods:

```
import 'package:audioplayers/audioplayers.dart';
import 'package:flame_audio/flame_audio.dart';

Future<void> loadSounds() async {
  // Create a pool with a specific Source
  AudioPool explosionSoundPool = await AudioPool.create(
    source: AssetSource('explosion.mp3'),
    minPlayers: 1,
    maxPlayers: 2,
    audioCache: FlameAudio.audioCache, // Optional
  );
}
```

### Creating from Asset Path¶

For convenience, you can create an AudioPool from just the asset path:

```
import 'package:flame_audio/flame_audio.dart';

Future<void> loadSounds() async {
  AudioPool explosionSoundPool = await AudioPool.createFromAsset(
    path: 'explosion.mp3',
    minPlayers: 1,
    maxPlayers: 2,
    audioCache: FlameAudio.audioCache, // Optional
  );
}
```

The parameters are:

- `source` or `path`: The audio source to play (either as a Source object or asset path)
- `minPlayers`: The initial number of AudioPlayers to create and preload (default: 1)
- `maxPlayers`: The maximum number of AudioPlayers that can be kept in the pool
- `audioCache`: Optional AudioCache instance to use
- `audioContext`: Optional audio context to be used by all players in the pool

## Using an AudioPool¶

Once you’ve created an AudioPool, you can start playing sounds:

```
// Play the sound with default volume (1.0)
final stopFunction = await audioPool.start();

// Play the sound with custom volume
final stopFunction = await audioPool.start(volume: 0.5);

// Later, you can stop the sound if needed
await stopFunction();
```

The `start()` method returns a `StopFunction` that you can call to stop the sound before it completes naturally.

## Managing the Pool¶

AudioPool provides a `dispose()` method to release resources when you no longer need the pool:

```
// When you're done with the pool
await audioPool.dispose();
```

## Example Usage¶

Here’s a complete example showing how to use AudioPools in a Flame game:

```
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';

class MyGame extends FlameGame {
  late AudioPool laserSound;
  late AudioPool explosionSound;

  @override
  Future<void> onLoad() async {
    // Load sound effects into audio pools
    laserSound = await FlameAudio.createPool(
      'laser.mp3',
      minPlayers: 3,
      maxPlayers: 6,
    );

    explosionSound = await FlameAudio.createPool(
      'explosion.mp3',
      minPlayers: 2,
      maxPlayers: 4,
    );
  }

  void fireLaser() async {
    // Play the laser sound effect - can be called rapidly
    final stop = await laserSound.start();

    // If you need to stop the sound early:
    // await stop();
  }

  void enemyDestroyed() async {
    // Play explosion sound effect
    await explosionSound.start(volume: 0.7);
  }

  @override
  Future<void> onRemove() async {
    await super.onRemove();

    // Clean up resources when the game component is removed
    await laserSound.dispose();
    await explosionSound.dispose();
  }
}
```

You can also find the interactive example in [Flame Basic](https://examples.flame-engine.org/)
</content>
</page>

<page>
  <title>Forge2D — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html</url>
  <content># Forge2D¶

Blue Fire maintains a ported version of the Box2D physics engine and our version is called Forge2D.

If you want to use Forge2D specifically for Flame you should use our bridge library [flame_forge2d](https://github.com/flame-engine/flame/tree/main/packages/flame_forge2d) and if you just want to use it in a Dart project you can use the [forge2d](https://github.com/flame-engine/forge2d) library directly.

To use it in your game you just need to add `flame_forge2d` to your `pubspec.yaml`, as can be seen in the [Forge2D [example](https://github.com/flame-engine/flame/tree/main/packages/flame_forge2d/example) and the pub. dev [installation instructions](https://pub.dev/packages/flame_forge2d)]([https://pub.dev/packages/flame_forge2d](https://pub.dev/packages/flame_forge2d)).

## Forge2DGame¶

If you are going to use Forge2D in your project it can be a good idea to use the Forge2D-specific `FlameGame` class, `Forge2DGame`.

It is called `Forge2DGame` and supports both the special Forge2D components called `BodyComponents` as well as normal Flame components.

`Forge2DGame` has a built-in `CameraComponent` and has a zoom level set to 10 by default, so your components will be a lot bigger than in a normal Flame game. This is due to the speed limit in the `Forge2D` world, which you would hit very quickly if you are using it with `zoom = 1.0`. You can easily change the zoom level either by calling `super(zoom: yourZoom)` in your constructor or doing `game.cameraComponent.viewfinder.zoom = yourZoom;` at a later stage.

If you are previously familiar with Box2D it can be good to know that the whole concept of the Box2d world is mapped to `world` in the `Forge2DGame` component and every `Body` that you want to use as a component should be wrapped in a `BodyComponent`, and added to the `world` in your `Forge2DGame`.

You can have have non-physics-related components in your `Forge2DGame` world’s component list along with your physical entities. When the update is called, it will use the Forge2D physics engine to properly update every `BodyComponent` and other components in the game will be updated according to the normal `FlameGame` way.

In `Forge2DGame` the gravity is flipped compared to `Forge2D` to keep the same coordinate system as in Flame, so a positive y-axis in the gravity like `Vector2(0, 10)` would be pulling bodies downwards, meanwhile, a negative y-axis would pull them upwards. The gravity can be set directly in the constructor of the `Forge2DGame`.

A simple `Forge2DGame` implementation example can be seen in the [examples folder](https://github.com/flame-engine/flame/tree/main/packages/flame_forge2d/example).

## Forge2DWorld¶

The `Forge2DWorld` is a the world that all your [`BodyComponent`]s live in. In the `Forge2DGame` there is a `Forge2DWorld` instance called `world` by default, which is where you should add your `BodyComponent`s.

If you want to swap between worlds you can create your own `Forge2DWorld` instance and assign it to the `Forge2DGame` instance’s `world` property, `game.world = Forge2DWorld()`.

If you would like to re-use a world later and have it keep its physics state you have to make sure that the bodies aren’t destroyed when the world is removed from the game. You can do this by setting `world.destroyOnRemove` to false, like `game.world.destroyOnRemove = false;`.

## BodyComponent¶

The `BodyComponent` is a wrapper for the `Forge2D` body, which is the body that the physics engine is interacting with. To create a `BodyComponent` you can either:

- override `createBody()` and create and return your created body;
- use the default `createBody()` implementation by passing a `BodyDef` instance (and optionally a list of `FixtureDef` instances) to the BodyComponent’s constructor;
- use the default `createBody()` implementation and assign a `BodyDef` instance to `this.bodyDef`, and optionally a list of `FixtureDef` instances to `this.fixtureDefs`.

The `BodyComponent` is by default having `renderBody = true`, since otherwise, it wouldn’t show anything after you have created a `Body` and added the `BodyComponent` to the game. If you want to turn it off you can just set (or override) `renderBody` to false.

Just like any other Flame component you can add children to the `BodyComponent`, which can be very useful if you want to add for example animations or other components on top of your body.

The body that you create should be defined according to Flame’s coordinate system, not according to the coordinate system of Forge2D (where the Y-axis is flipped).

:exclamation: In Forge2D you shouldn’t add any bodies as children to other components, since Forge2D doesn’t have a concept of nested bodies. So bodies should live on the top level in the physics world, `Forge2DGame.world`. So instead of `add(Weapon()))`, `world.add(Weapon())` should be used (as below), and the `Player` should also of course initially be added to the world.

```
class Weapon extends BodyComponent  {
  @override
  void onLoad() {
    ...
  }
}

class Player extends BodyComponent  {
  @override
  void onLoad() {
    world.add(Weapon());
  }
}
```

Later you might want to add bullets coming from your weapon, these are added to the world in the same sense, but if they are going to be moving very fast, make sure that you set `isBullet = true` to avoid some tunneling problems.

## Contact callbacks¶

`Forge2DGame` provides a simple out-of-the-box solution to propagate contact events.

Contact events occur whenever two `Fixture`s meet each other. These events allow listening when these `Fixture`s begin to come in contact (`beginContact`) and cease being in contact (`endContact`).

There are multiple ways to listen to these events. One common way is to use the `ContactCallbacks` class as a mixin in the `BodyComponent` where you are interested in these events.

```
class Ball extends BodyComponent with ContactCallbacks {
  ...
  void beginContact(Object other, Contact contact) {
    if (other is Wall) {
      // Do something here.
    }
  }
  ...
}
```

For the above to work, the `Ball`’s `body.userData` or contacting `fixture.userData` must be set to a `ContactCallback`. And if `Wall` is a `BodyComponent` it’s `body.userData` or contacting `fixture.userData` must be set to `Wall`.

If `userData` is `null` the contact events are ignored, it is `null` by default.

A convenient way of setting `userData` is to assign it when creating the body. For example:

```
class Ball extends BodyComponent with ContactCallbacks {
  ...

  @override
  Body createBody() {
    ...
    final bodyDef = BodyDef(
      userData: this,
    );
    ...
  }

}
```

Every time `Ball` and `Wall` begin to come in contact `beginContact` will be called, and once the fixtures cease being in contact, `endContact` will be called.

An implementation example can be seen in the [Flame Forge2D example](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/bridge_libraries/flame_forge2d/utils/balls.dart).
</content>
</page>

<page>
  <title>Audio — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio.html</url>
  <content># Audio¶

Playing audio is essential for most games, so we made it simple!

First you have to add [flame_audio](https://github.com/flame-engine/flame_audio) to your dependency list in your `pubspec.yaml` file:

```
dependencies:
  flame_audio: VERSION
```

The latest version can be found on [pub.dev](https://pub.dev/packages/flame_audio/install).

After installing the `flame_audio` package, you can add audio files in the assets section of your `pubspec.yaml` file. Make sure that the audio files exists in the paths that you provide.

The default directory for `FlameAudio` is `assets/audio` (which can be changed by providing your own instance of `AudioCache`).

For the examples below, your `pubspec.yaml` file needs to contain something like this:

```
flutter:
  assets:
    - assets/audio/explosion.mp3
    - assets/audio/music.mp3
```

Then you have the following methods at your disposal:

```
import 'package:flame_audio/flame_audio.dart';

// For shorter reused audio clips, like sound effects
FlameAudio.play('explosion.mp3');

// For looping an audio file
FlameAudio.loop('music.mp3');

// For playing a longer audio file
FlameAudio.playLongAudio('music.mp3');

// For looping a longer audio file
FlameAudio.loopLongAudio('music.mp3');

// For background music that should be paused/played when the pausing/resuming
// the game
FlameAudio.bgm.play('music.mp3');
```

The difference between the `play/loop` and `playLongAudio/loopLongAudio` is that `play/loop` makes use of optimized features that allow sounds to be looped without gaps between their iterations, and almost no drop on the game frame rate will happen. You should whenever possible, prefer the former methods.

`playLongAudio/loopLongAudio` allows for audios of any length to be played, but they do create frame rate drop, and the looped audio will have a small gap between iterations.

You can use [the `Bgm` class](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/bgm.html) (via `FlameAudio.bgm`) to play looping background music tracks. The `Bgm` class lets Flame automatically manage the pausing and resuming of background music tracks when the game is sent to background or comes back to the foreground.

You can use [the `AudioPool` class](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio_pool.html) if you want to fire quick sound effects in a very efficient manner. `AudioPool` will keep a pool of `AudioPlayer`s preloaded with a given sound, and allow you to play them very fast in quick succession.

Some file formats that work across devices and that we recommend are: MP3, OGG and WAV.

This bridge library (flame_audio) uses [audioplayers](https://github.com/bluefireteam/audioplayers) in order to allow for playing multiple sounds simultaneously (crucial in a game). You can check the link for a more in-depth explanation.

Both on `play` and `loop` you can pass an additional optional double parameter, the `volume` (defaults to `1.0`).

Both the `play` and `loop` methods return an instance of an `AudioPlayer` from the [audioplayers](https://github.com/bluefireteam/audioplayers) lib, that allows you to stop, pause and configure other parameters.

In fact you can always use `AudioPlayer`s directly to gain full control over how your audio is played – the `FlameAudio` class is just a wrapper for common functionality.

## Caching¶

You can pre-load your assets. Audios need to be stored in the memory the first time they are requested; therefore, the first time you play each mp3 you might get a delay. In order to pre-load your audios, just use:

```
await FlameAudio.audioCache.load('explosion.mp3');
```

You can load all your audios in the beginning in your game’s `onLoad` method so that they always play smoothly. To load multiple audio files, use the `loadAll` method:

```
await FlameAudio.audioCache.loadAll(['explosion.mp3', 'music.mp3']);
```

Finally, you can use the `clear` method to remove a file that has been loaded into the cache:

```
FlameAudio.audioCache.clear('explosion.mp3');
```

There is also a `clearCache` method, that clears the whole cache.

This might be useful if, for instance, your game has multiple levels and each has a different set of sounds and music.
</content>
</page>

<page>
  <title>Looping Background Music — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_audio/bgm.html</url>
  <content># Looping Background Music¶

With the `Bgm` class, you can manage looping of background music tracks with regards to application (or game) lifecycle state changes.

When the application is terminated, or sent to background, `Bgm` will automatically pause the currently playing music track. Similarly, when the application is resumed, `Bgm` will resume the background music. Manually pausing and resuming your tracks is also supported.

For this class to function properly, the observer must be registered by calling the following:

```
FlameAudio.bgm.initialize();
```

**IMPORTANT Note:** The `initialize` function must be called at a point in time where an instance of the `WidgetsBinding` class already exists. Best practice is to put this call inside of your game’s `onLoad` method`.

In cases where you’re done with background music but still want to keep the application/game running, use the `dispose` function to remove the observer.

```
FlameAudio.bgm.dispose();
```

To play a looping background music track, run:

```
import 'package:flame_audio/flame_audio.dart';

FlameAudio.bgm.play('adventure-track.mp3');
```

You must have an appropriate folder structure and add the files to the `pubspec.yaml` file, as explained in [Flame Audio documentation](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio.html).

## Caching music files¶

The `Bgm` class will use the static instance of `FlameAudio` for storing cached music files by default.

So in order to pre-load music, you can use the same recommendations from the [Flame Audio documentation](https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio.html).

You can optionally create your own `Bgm` instances with different backing `AudioCache`s, if you so desire.

## Methods¶

### Play¶

The `play` function takes in a `String` that should be a path that points to the location of the music file to be played (following the Flame Audio folder structure requirements).

You can pass an additional optional `double` parameter which is the `volume` (defaults to `1.0`).

Examples:

```
FlameAudio.bgm.play('music/boss-fight/level-382.mp3');
```

```
FlameAudio.bgm.play('music/world-map.mp3', volume: .25);
```

### Stop¶

To stop a currently playing background music track, just call `stop`.

```
FlameAudio.bgm.stop();
```

### Pause and Resume¶

To manually pause and resume background music you can use the `pause` and `resume` functions.

`FlameAudio.bgm` automatically handles pausing and resuming the currently playing background music track. Manually `pausing` prevents the app/game from auto-resuming when focus is given back to the app/game.

```
FlameAudio.bgm.pause();
```

```
FlameAudio.bgm.resume();
```
</content>
</page>

<page>
  <title>flame_bloc — Flame</title>
  <url>https://docs.flame-engine.org/latest/bridge_packages/flame_bloc/bloc.html</url>
  <content># flame_bloc¶

`flame_bloc` is a bridge library for using [Bloc](https://bloclibrary.dev/) in your Flame game. `flame_bloc` offers a simple and natural (as in similar to flutter_bloc) way to use blocs and cubits inside a FlameGame. Bloc offers way to make game state changes predictable by regulating when a game state change can occur and offers a single way to change game state throughout an entire Game.

To use it in your game you just need to add `flame_bloc` to your pubspec.yaml, as can be seen in the [Flame Bloc example](https://github.com/flame-engine/flame/tree/main/packages/flame_bloc/example) and in the pub.dev [installation instructions](https://pub.dev/packages/flame_bloc).

## How to use¶

Lets assume we have a bloc that handles player inventory, first we need to make it available to our components.

We can do that by using `FlameBlocProvider` component:

```
class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await add(
      FlameBlocProvider<PlayerInventoryBloc, PlayerInventoryState>(
        create: () => PlayerInventoryBloc(),
        children: [
          Player(),
          // ...
        ],
      ),
    );
  }
}
```

With the above changes, the `Player` component will now have access to our bloc.

If more than one bloc needs to be provided, `FlameMultiBlocProvider` can be used in a similar fashion:

```
class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await add(
      FlameMultiBlocProvider(
        providers: [
          FlameBlocProvider<PlayerInventoryBloc, PlayerInventoryState>(
            create: () => PlayerInventoryBloc(),
          ),
          FlameBlocProvider<PlayerStatsBloc, PlayerStatsState>(
            create: () => PlayerStatsBloc(),
          ),
        ],
        children: [
          Player(),
          // ...
        ],
      ),
    );
  }
}
```

Listening to states changes at the component level can be done with two approaches:

By using `FlameBlocListener` component:

```
class Player extends PositionComponent {
  @override
  Future<void> onLoad() async {
    await add(
      FlameBlocListener<PlayerInventoryBloc, PlayerInventoryState>(
        listener: (state) {
          updateGear(state);
        },
      ),
    );
  }
}
```

Or by using `FlameBlocListenable` mixin:

```
class Player extends PositionComponent
    with FlameBlocListenable<PlayerInventoryBloc, PlayerInventoryState> {

  @override
  void onNewState(state) {
    updateGear(state);
  }
}
```

If all your component need is to simply access a bloc, the `FlameBlocReader` mixin can be applied to a component:

```
class Player extends PositionComponent
    with FlameBlocReader<PlayerStatsBloc, PlayerStatsState> {

  void takeHit() {
    bloc.add(const PlayerDamaged());
  }
}
```

Note that one limitation of the mixin is that it can access only a single bloc.

## Full Example¶

You can check an example [here](https://github.com/flame-engine/flame/tree/main/packages/flame_bloc/example).
</content>
</page>