<page>
  <title>Sprite Components — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/components/sprite_components.html</url>
  <content># Sprite Components¶

Sprites are 2D images (or regions of images) that represent the visual appearance of game objects. They are the most common way to display characters, items, backgrounds, and other visuals in 2D games. Flame provides several sprite-based components that make it easy to load images, play animations, and switch between visual states, all while benefiting from the transform properties inherited from `PositionComponent`.

## SpriteComponent¶

The most commonly used implementation of `PositionComponent` is `SpriteComponent`, and it can be created with a `Sprite`:

```
import 'package:flame/components/component.dart';

class MyGame extends FlameGame {
  late final SpriteComponent player;

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load('player.png');
    final size = Vector2.all(128.0);
    final player = SpriteComponent(size: size, sprite: sprite);

    // Vector2(0.0, 0.0) by default, can also be set in the constructor
    player.position = Vector2(10, 20);

    // 0 by default, can also be set in the constructor
    player.angle = 0;

    // Adds the component
    add(player);
  }
}
```

## SpriteAnimationComponent¶

This class is used to represent a Component that has sprites that run in a single cyclic animation.

This will create a simple three frame animation using 3 different images:

```
@override
Future<void> onLoad() async {
  final sprites = [0, 1, 2]
      .map((i) => Sprite.load('player_$i.png'));
  final animation = SpriteAnimation.spriteList(
    await Future.wait(sprites),
    stepTime: 0.01,
  );
  this.player = SpriteAnimationComponent(
    animation: animation,
    size: Vector2.all(64.0),
  );
}
```

If you have a sprite sheet, you can use the `sequenced` constructor from the `SpriteAnimationData` class (check more details on [Images > Animation](https://docs.flame-engine.org/latest/flame/rendering/images.html#animation)):

```
@override
Future<void> onLoad() async {
  final size = Vector2.all(64.0);
  final data = SpriteAnimationData.sequenced(
    textureSize: size,
    amount: 2,
    stepTime: 0.1,
  );
  this.player = SpriteAnimationComponent.fromFrameData(
    await images.load('player.png'),
    data,
  );
}
```

All animation components internally maintain a `SpriteAnimationTicker` which ticks the `SpriteAnimation`. This allows multiple components to share the same animation object.

Example:

```
final sprites = [/*Your sprite list here*/];
final animation = SpriteAnimation.spriteList(sprites, stepTime: 0.01);

final animationTicker = SpriteAnimationTicker(animation);

// or alternatively, you can ask the animation object to create one for you.

final animationTicker = animation.createTicker(); // creates a new ticker

animationTicker.update(dt);
```

To listen when the animation is done (when it reaches the last frame and is not looping) you can use `animationTicker.completed`.

Example:

```
await animationTicker.completed;

doSomething();

// or alternatively

animationTicker.completed.whenComplete(doSomething);
```

Additionally, `SpriteAnimationTicker` also has the following optional event callbacks: `onStart`, `onFrame`, and `onComplete`. To listen to these events, you can do the following:

```
final animationTicker = SpriteAnimationTicker(animation)
  ..onStart = () {
    // Do something on start.
  };

final animationTicker = SpriteAnimationTicker(animation)
  ..onComplete = () {
    // Do something on completion.
  };

final animationTicker = SpriteAnimationTicker(animation)
  ..onFrame = (index) {
    if (index == 1) {
      // Do something for the second frame.
    }
  };
```

To reset the animation to the first frame when the component is removed, you can set `resetOnRemove` to `true`:

```
SpriteAnimationComponent(
  animation: animation,
  size: Vector2.all(64.0),
  resetOnRemove: true,
);
```

## SpriteAnimationGroupComponent¶

`SpriteAnimationGroupComponent` is a simple wrapper around `SpriteAnimationComponent` which enables your component to hold several animations and change the current playing animation at runtime. Since this component is just a wrapper, the event listeners can be implemented as described in SpriteAnimationComponent.

Its use is very similar to the `SpriteAnimationComponent` but instead of being initialized with a single animation, this component receives a Map of a generic type `T` as key and a `SpriteAnimation` as value, and the current animation.

Example:

```
enum RobotState {
  idle,
  running,
}

final running = await loadSpriteAnimation(/* omitted */);
final idle = await loadSpriteAnimation(/* omitted */);

final robot = SpriteAnimationGroupComponent<RobotState>(
  animations: {
    RobotState.running: running,
    RobotState.idle: idle,
  },
  current: RobotState.idle,
);

// Changes current animation to "running"
robot.current = RobotState.running;
```

As this component works with multiple `SpriteAnimation`s, naturally it needs an equal number of animation tickers to make all those animations tick. Use `animationsTickers` getter to access a map containing tickers for each animation state. This can be useful if you want to register callbacks for `onStart`, `onComplete` and `onFrame`.

Example:

```
enum RobotState { idle, running, jump }

final running = await loadSpriteAnimation(/* omitted */);
final idle = await loadSpriteAnimation(/* omitted */);

final robot = SpriteAnimationGroupComponent<RobotState>(
  animations: {
    RobotState.running: running,
    RobotState.idle: idle,
  },
  current: RobotState.idle,
);

robot.animationTickers?[RobotState.running]?.onStart = () {
  // Do something on start of running animation.
};

robot.animationTickers?[RobotState.jump]?.onStart = () {
  // Do something on start of jump animation.
};

robot.animationTickers?[RobotState.jump]?.onComplete = () {
  // Do something on complete of jump animation.
};

robot.animationTickers?[RobotState.idle]?.onFrame = (currentIndex) {
  // Do something based on current frame index of idle animation.
};
```

## SpriteGroupComponent¶

`SpriteGroupComponent` is pretty similar to its animation counterpart, but especially for sprites.

Example:

```
class PlayerComponent extends SpriteGroupComponent<ButtonState>
    with HasGameReference<SpriteGroupExample>, TapCallbacks {
  @override
  Future<void> onLoad() async {
    final pressedSprite = await game.loadSprite(/* omitted */);
    final unpressedSprite = await game.loadSprite(/* omitted */);

    sprites = {
      ButtonState.pressed: pressedSprite,
      ButtonState.unpressed: unpressedSprite,
    };

    current = ButtonState.unpressed;
  }

  // tap methods handler omitted...
}
```

## IconComponent¶

`IconComponent` renders a Flutter `IconData` (such as `Icons.star`) as a Flame component. The icon is rasterized to an image once during `onLoad()` and then drawn each frame using `canvas.drawImageRect()` with the component’s `Paint`. Because the icon is rendered as a cached image rather than as text, all paint-based effects work out of the box, including `tint()`, `setOpacity()`, `ColorEffect`, `OpacityEffect`, `GlowEffect`, and custom `ColorFilter`s.

### Basic usage¶

```
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    final star = IconComponent(
      icon: Icons.star,
      iconSize: 64,
      position: Vector2(100, 100),
    );
    add(star);
  }
}
```

### Tinting and effects¶

The icon is rasterized in white, which allows you to tint it to any color using `HasPaint` methods:

```
// Tint the icon gold
final star = IconComponent(
  icon: Icons.star,
  iconSize: 64,
  position: Vector2(100, 100),
)..tint(const Color(0xFFFFD700));

// Set opacity
star.setOpacity(0.5);

// Or use a custom paint
final icon = IconComponent(
  icon: Icons.favorite,
  iconSize: 48,
  paint: Paint()..colorFilter = const ColorFilter.mode(
    Color(0xFFFF0000),
    BlendMode.srcATop,
  ),
);
```

### Constructor parameters¶

- `icon`: The `IconData` to render (e.g., `Icons.star`, `Icons.favorite`).
- `iconSize`: The resolution at which the icon is rasterized (default `64`). This is independent of the component’s display `size`.
- `size`: The display size of the component. Defaults to `Vector2.all(iconSize)` if not provided.
- `paint`: Optional `Paint` for rendering effects.
- All standard `PositionComponent` parameters (`position`, `scale`, `angle`, `anchor`, etc.).

### Changing the icon at runtime¶

Both the `icon` and `iconSize` properties can be changed after creation. The component will automatically re-rasterize the icon on the next frame:

```
final iconComponent = IconComponent(
  icon: Icons.play_arrow,
  iconSize: 64,
);

// Later, swap the icon
iconComponent.icon = Icons.pause;

// Or change the rasterization resolution
iconComponent.iconSize = 128;
```
</content>
</page>

<page>
  <title>Particles — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/rendering/particles.html</url>
  <content># Particles¶

Flame offers a basic, yet robust and extendable particle system. The core concept of this system is the `Particle` class, which is very similar in its behavior to the `ParticleSystemComponent`.

The most basic usage of a `Particle` with `FlameGame` would look as in the following:

```
import 'package:flame/components.dart';

// ...

game.add(
  // Wrapping a Particle with ParticleSystemComponent
  // which maps Component lifecycle hooks to Particle ones
  // and embeds a trigger for removing the component.
  ParticleSystemComponent(
    particle: CircleParticle(),
  ),
);
```

When using `Particle` with a custom `Game` implementation, please ensure that both the `update` and `render` methods are called during each game loop tick.

Main approaches to implement desired particle effects:

- Composition of existing behaviors.
- Use behavior chaining (just a syntactic sugar of the first one).
- Using `ComputedParticle`.

Composition works in a similar fashion to those of Flutter widgets by defining the effect from top to bottom. Chaining allows to express the same composition trees more fluently by defining behaviors from bottom to top. Computed particles in their turn fully delegate implementation of the behavior to your code. Any of the approaches could be used in conjunction with existing behaviors where needed.

```
Random rnd = Random();

Vector2 randomVector2() => (Vector2.random(rnd) - Vector2.random(rnd)) * 200;

// Composition.
//
// Defining a particle effect as a set of nested behaviors from top to bottom,
// one within another:
//
// ParticleSystemComponent
//   > ComposedParticle
//     > AcceleratedParticle
//       > CircleParticle
game.add(
  ParticleSystemComponent(
    particle: Particle.generate(
      count: 10,
      generator: (i) => AcceleratedParticle(
        acceleration: randomVector2(),
        child: CircleParticle(
          paint: Paint()..color = Colors.red,
        ),
      ),
    ),
  ),
);

// Chaining.
//
// Expresses the same behavior as above, but with a more fluent API.
// Only Particles with SingleChildParticle mixin can be used as chainable behaviors.
game.add(
  ParticleSystemComponent(
    particle: Particle.generate(
      count: 10,
      generator: (i) => pt.CircleParticle(paint: Paint()..color = Colors.red)
    )
  )
);

// Computed Particle.
//
// All the behaviors are defined explicitly. Offers greater flexibility
// compared to built-in behaviors.
game.add(
  ParticleSystemComponent(
      particle: Particle.generate(
        count: 10,
        generator: (i) {
          Vector2 position = Vector2.zero();
          Vector2 speed = Vector2.zero();
          final acceleration = randomVector2();
          final paint = Paint()..color = Colors.red;

          return ComputedParticle(
            renderer: (canvas, _) {
              speed += acceleration;
              position += speed;
              canvas.drawCircle(Offset(position.x, position.y), 1, paint);
            }
        );
      }
    )
  )
);
```

See more [examples of how to use built-in particles in various combinations](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/rendering/particles_example.dart).

## Lifecycle¶

A behavior common to all `Particle`s is that all of them accept a `lifespan` argument. This value is used to make the `ParticleSystemComponent` remove itself once its internal `Particle` has reached the end of its life. Time within the `Particle` itself is tracked using the Flame `Timer` class. It can be configured with a `double`, represented in seconds (with microsecond precision) by passing it into the corresponding `Particle` constructor.

```
Particle(lifespan: .2); // will live for 200ms.
Particle(lifespan: 4); // will live for 4s.
```

It is also possible to reset a `Particle`’s lifespan by using the `setLifespan` method, which also accepts a `double` of seconds.

```
final particle = Particle(lifespan: 2);

// ... after some time.
particle.setLifespan(2) // will live for another 2s.
```

During its lifetime, a `Particle` tracks the time it was alive and exposes it through the `progress` getter, which returns a value between `0.0` and `1.0`. This value can be used in a similar fashion as the `value` property of the `AnimationController` class in Flutter.

```
final particle = Particle(lifespan: 2.0);

game.add(ParticleSystemComponent(particle: particle));

// Will print values from 0 to 1 with step of .1: 0, 0.1, 0.2 ... 0.9, 1.0.
Timer.periodic(duration * .1, () => print(particle.progress));
```

The `lifespan` is passed down to all the descendants of a given `Particle`, if it supports any of the nesting behaviors.

## Built-in particles¶

Flame ships with a few built-in `Particle` behaviors:

- The `TranslatedParticle` translates its `child` by given `Vector2`
- The `MovingParticle` moves its `child` between two predefined `Vector2`, supports `Curve`
- The `AcceleratedParticle` allows basic physics based effects, like gravitation or speed dampening
- The `CircleParticle` renders circles of all shapes and sizes
- The `SpriteParticle` renders Flame `Sprite` within a `Particle` effect
- The `ImageParticle` renders *dart:ui* `Image` within a `Particle` effect
- The `ComponentParticle` renders Flame `Component` within a `Particle` effect
- The `FlareParticle` renders Flare animation within a `Particle` effect

See more [examples of how to use built-in Particle behaviors together](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/rendering/particles_example.dart). All the implementations are available in the [particles folder on the Flame repository.](https://github.com/flame-engine/flame/tree/main/packages/flame/lib/src/particles)

## TranslatedParticle¶

Simply translates the underlying `Particle` to a specified `Vector2` within the rendering `Canvas`. Does not change or alter its position, consider using `MovingParticle` or `AcceleratedParticle` where change of position is required. Same effect could be achieved by translating the `Canvas` layer.

```
game.add(
  ParticleSystemComponent(
    particle: TranslatedParticle(
      // Will translate the child Particle effect to the center of game canvas.
      offset: game.size / 2,
      child: Particle(),
    ),
  ),
);
```

## MovingParticle¶

Moves the child `Particle` between the `from` and `to` `Vector2`s during its lifespan. Supports `Curve` via `CurvedParticle`.

```
game.add(
  ParticleSystemComponent(
    particle: MovingParticle(
      // Will move from corner to corner of the game canvas.
      from: Vector2.zero(),
      to: game.size,
      child: CircleParticle(
        radius: 2.0,
        paint: Paint()..color = Colors.red,
      ),
    ),
  ),
);
```

## AcceleratedParticle¶

A basic physics particle which allows you to specify its initial `position`, `speed` and `acceleration` and lets the `update` cycle do the rest. All three are specified as `Vector2`s, which you can think of as vectors. It works especially well for physics-based “bursts”, but it is not limited to that. Unit of the `Vector2` value is *logical px/s*. So a speed of `Vector2(0, 100)` will move a child `Particle` by 100 logical pixels of the device every second of game time.

```
final rnd = Random();
Vector2 randomVector2() => (Vector2.random(rnd) - Vector2.random(rnd)) * 100;

game.add(
  ParticleSystemComponent(
    particle: AcceleratedParticle(
      // Will fire off in the center of game canvas
      position: game.canvasSize/2,
      // With random initial speed of Vector2(-100..100, 0..-100)
      speed: Vector2(rnd.nextDouble() * 200 - 100, -rnd.nextDouble() * 100),
      // Accelerating downwards, simulating "gravity"
      // speed: Vector2(0, 100),
      child: CircleParticle(
        radius: 2.0,
        paint: Paint()..color = Colors.red,
      ),
    ),
  ),
);
```

## CircleParticle¶

A `Particle` which renders a circle with given `Paint` at the zero offset of passed `Canvas`. Use in conjunction with `TranslatedParticle`, `MovingParticle` or `AcceleratedParticle` in order to achieve desired positioning.

```
game.add(
  ParticleSystemComponent(
    particle: CircleParticle(
      radius: game.size.x / 2,
      paint: Paint()..color = Colors.red.withValues(alpha: .5),
    ),
  ),
);
```

## SpriteParticle¶

Allows you to embed a `Sprite` into your particle effects.

```
game.add(
  ParticleSystemComponent(
    particle: SpriteParticle(
      sprite: Sprite('sprite.png'),
      size: Vector2(64, 64),
    ),
  ),
);
```

## ImageParticle¶

Renders given `dart:ui` image within the particle tree.

```
// During game initialization
await Flame.images.loadAll(const [
  'image.png',
]);

// ...

// Somewhere during the game loop
final image = await Flame.images.load('image.png');

game.add(
  ParticleSystemComponent(
    particle: ImageParticle(
      size: Vector2.all(24),
      image: image,
    );
  ),
);
```

## ScalingParticle¶

Scales the child `Particle` between `1` and `to` during its lifespan.

```
game.add(
  ParticleSystemComponent(
    particle: ScalingParticle(
      lifespan: 2,
      to: 0,
      curve: Curves.easeIn,
      child: CircleParticle(
        radius: 2.0,
        paint: Paint()..color = Colors.red,
      )
    );
  ),
);
```

## SpriteAnimationParticle¶

A `Particle` which embeds a `SpriteAnimation`. By default, aligns the `SpriteAnimation`’s `stepTime` so that it’s fully played during the `Particle` lifespan. It’s possible to override this behavior with the `alignAnimationTime` argument.

```
final spriteSheet = SpriteSheet(
  image: yourSpriteSheetImage,
  srcSize: Vector2.all(16.0),
);

game.add(
  ParticleSystemComponent(
    particle: SpriteAnimationParticle(
      animation: spriteSheet.createAnimation(0, stepTime: 0.1),
    );
  ),
);
```

## ComponentParticle¶

This `Particle` allows you to embed a `Component` within the particle effects. The `Component` could have its own `update` lifecycle and could be reused across different effect trees. If the only thing you need is to add some dynamics to an instance of a certain `Component`, please consider adding it to the `game` directly, without the `Particle` in the middle.

```
final longLivingRect = RectComponent();

game.add(
  ParticleSystemComponent(
    particle: ComponentParticle(
      component: longLivingRect
    );
  ),
);

class RectComponent extends Component {
  void render(Canvas c) {
    c.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 100, height: 100),
      Paint()..color = Colors.red
    );
  }

  void update(double dt) {
    /// Will be called by parent [Particle]
  }
}
```

## ComputedParticle¶

A `Particle` which could help you when:

- Default behavior is not enough
- Complex effects optimization
- Custom easings

When created, it delegates all the rendering to a supplied `ParticleRenderDelegate` which is called on each frame to perform necessary computations and render something to the `Canvas`.

```
game.add(
  ParticleSystemComponent(
    // Renders a circle which gradually changes its color and size during the
    // particle lifespan.
    particle: ComputedParticle(
      renderer: (canvas, particle) => canvas.drawCircle(
        Offset.zero,
        particle.progress * 10,
        Paint()
          ..color = Color.lerp(
            Colors.red,
            Colors.blue,
            particle.progress,
          ),
      ),
    ),
  ),
)
```

## Nesting behavior¶

Flame’s implementation of particles follows the same pattern of extreme composition as Flutter widgets. That is achieved by encapsulating small pieces of behavior in every particle and then nesting these behaviors together to achieve the desired visual effect.

Two entities that allow `Particle`s to nest each other are: `SingleChildParticle` mixin and `ComposedParticle` class.

A `SingleChildParticle` may help you with creating `Particles` with a custom behavior. For example, randomly positioning its child during each frame:

The `SingleChildParticle` may help you with creating `Particles` with a custom behavior.

For example, randomly positioning it’s child during each frame:

```
var rnd = Random();

class GlitchParticle extends Particle with SingleChildParticle {
  Particle child;

  GlitchParticle({
    required this.child,
    super.lifespan,
  });

  @override
  render(Canvas canvas)  {
    canvas.save();
    canvas.translate(rnd.nextDouble() * 100, rnd.nextDouble() * 100);

    // Will also render the child
    super.render();

    canvas.restore();
  }
}
```

The `ComposedParticle` could be used either as a standalone or within an existing `Particle` tree.
</content>
</page>

<page>
  <title>Images — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/rendering/images.html</url>
  <content># Images¶

To start off you must have an appropriate folder structure and add the files to the `pubspec.yaml` file, like this:

```
flutter:
  assets:
    - assets/images/player.png
    - assets/images/enemy.png
```

Images can be in any format supported by Flutter, which include: JPEG, WebP, PNG, GIF, animated GIF, animated WebP, BMP, and WBMP. Other formats would require additional libraries. For example, SVG images can be loaded via the `flame_svg` library.

## Loading images¶

Flame bundles an utility class called `Images` that allows you to easily load and cache images from the assets directory into memory.

Flutter has a handful of types related to images, and converting everything properly from a local asset to an `Image` that can be drawn on Canvas is a bit convoluted. This class allows you to obtain an `Image` that can be drawn on the `Canvas` using the `drawImageRect` method.

It automatically caches any image loaded by filename, so you can safely call it many times.

The methods for loading and clearing the cache are: `load`, `loadAll`, `clear` and `clearCache`. They return `Future`s for loading the images. These futures must be awaited for before the images can be used in any way. If you do not want to await these futures right away, you can initiate multiple `load()` operations and then await for all of them at once using `Images.ready()` method.

To synchronously retrieve a previously cached image, the `fromCache` method can be used. If an image with that key was not previously loaded, it will throw an exception.

To add an already loaded image to the cache, the `add` method can be used and you can set the key that the image should have in the cache. You can retrieve all the keys in the cache using the `keys` getter.

You can also use `ImageExtension.fromPixels()` to dynamically create an image during the game.

For `clear` and `clearCache`, do note that `dispose` is called for each removed image from the cache, so make sure that you don’t use the image afterwards.

### Standalone usage¶

It can manually be used by instantiating it:

```
import 'package:flame/cache.dart';
final imagesLoader = Images();
Image image = await imagesLoader.load('yourImage.png');
```

But Flame also offers two ways of using this class without instantiating it yourself.

### Flame.images¶

There is a singleton, provided by the `Flame` class, that can be used as a global image cache.

Example:

```
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

// inside an async context
Image image = await Flame.images.load('player.png');

final playerSprite = Sprite(image);
```

### Game.images¶

The `Game` class offers some utility methods for handling images loading too. It bundles an instance of the `Images` class, that can be used to load image assets to be used during the game. The game will automatically free the cache when the game widget is removed from the widget tree.

The `onLoad` method from the `Game` class is a great place for the initial assets to be loaded.

Example:

```
class MyGame extends Game {

  Sprite player;

  @override
  Future<void> onLoad() async {
    // Note that you could also use Sprite.load for this.
    final playerImage = await images.load('player.png');
    player = Sprite(playerImage);
  }
}
```

Loaded assets can also be retrieved while the game is running by `images.fromCache`, for example:

```
class MyGame extends Game {

  // attributes omitted

  @override
  Future<void> onLoad() async {
    // other loads omitted
    await images.load('bullet.png');
  }

  void shoot() {
    // This is just an example, in your game you probably don't want to
    // instantiate new [Sprite] objects every time you shoot.
    final bulletSprite = Sprite(images.fromCache('bullet.png'));
    _bullets.add(bulletSprite);
  }
}
```

## Loading images over the network¶

The Flame core package doesn’t offer a built in method to loading images from the network.

The reason for that is that Flutter/Dart does not have a built in http client, which requires a package to be used and since there are a couple of packages available out there, we refrain from forcing the user to use a specific package.

With that said, it is quite simple to load images from the network once a http client package is chosen by the user. The following snippet shows how an `Image` can be fetched from the web using the [http](https://pub.dev/packages/http) package.

```
import 'package:http/http.dart' as http;
import 'package:flutter/painting.dart';

final response = await http.get('https://url.com/image.png');
final image = await decodeImageFromList(response.bytes);
```

Note

Check [`flame_network_assets`](https://pub.dev/packages/flame_network_assets) for a ready to use network assets solution that provides a built in cache.

## Sprite¶

Flame offers a `Sprite` class that represents an image, or a region of an image.

You can create a `Sprite` by providing it an `Image` and coordinates that defines the piece of the image that that sprite represents.

For example, this will create a sprite representing the whole image of the file passed:

```
final image = await images.load('player.png');
Sprite player = Sprite(image);
```

You can also specify the coordinates in the original image where the sprite is located. This allows you to use sprite sheets and reduce the number of images in memory, for example:

```
final image = await images.load('player.png');
final playerFrame = Sprite(
  image,
  srcPosition: Vector2(32.0, 0),
  srcSize: Vector2(16.0, 16.0),
);
```

The default values are `(0.0, 0.0)` for `srcPosition` and `null` for `srcSize` (meaning it will use the full width/height of the source image).

The `Sprite` class has a render method, that allows you to render the sprite onto a `Canvas`:

```
final image = await images.load('block.png');
Sprite block = Sprite(image);

// in your render method
block.render(canvas, 16.0, 16.0); //canvas, width, height
```

You must pass the size to the render method, and the image will be resized accordingly.

All render methods from the `Sprite` class can receive a `Paint` instance as the optional named parameter `overridePaint` that parameter will override the current `Sprite` paint instance for that render call.

`Sprite`s can also be used as widgets, to do so just use `SpriteWidget` class. Here is a complete [example using sprite as widgets](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/widgets/sprite_widget_example.dart).

### Sprite Bleeding¶

In some cases when rendering sprites next to each other, when the edges of the sprites are touching, you may see a rendering artifact called “ghost lines” between them.

This happens especially when the sprites are positioned in coordinates that are not whole numbers, or when scaling is applied to the canvas.

Those lines appear because floating-point numbers aren’t 100% accurate in computer science. Due to rounding errors, even though the sprites are supposed to be touching, they are not rendered that way.

One way to avoid this is to use a technique called “bleeding”, which consists of adding a very small margin to the edges of the sprites, so that when they are rendered, they will overlap a bit and thus avoid rendering the ghost lines.

Flame provides a way to do this by using the `bleed` parameter in the `Sprite` render method. This is a double value that represents the amount of bleeding to be applied to the edges of the sprite.

For example, if you do:

```
final image = await images.load('player.png');
final playerFrame = Sprite(
  image,
  srcPosition: Vector2(32.0, 0),
  srcSize: Vector2(16.0, 16.0),
);
playerFrame.render(canvas, 16.0, 16.0, bleed: 1.0);
```

The sprite will be rendered with a bleed amount of 1.0, meaning that it will have a value of 1 pixels added to each edge of the sprite.

For users of the `SpriteComponent`, using the bleeding feature is also quite simple, it is just a matter of passing a value to the `bleed` attribute in the component constructor:

```
final sprite = Sprite(...);

final spriteComponent = SpriteComponent(
  sprite: sprite,
  size: Vector2.all(16.0),
  bleed: 1.0, // bleed value
);
```

Note that the amount of the bleed value depends on the size of the sprite, so a bleed value of 1.0 might not make much difference for a sprite of 100x100.

### Sprite Rasterization¶

Rasterizing a sprite is the process of extracting the selected area of the image from that sprite, storing it in memory, and returning a new Sprite that contains that rasterized image.

That can be used for a variety of reasons, one of the most useful ones is to avoid texture leaking when using a sprite sheet.

Texture leaking can happen for the same reason as in the issue explained above (floating point rounding errors), and it causes parts outside of a sprite selection to also be rendered.

Extracting the sprite selection and rasterizing it before rendering is a way to avoid this issue, since it then renders an image that only contains the selected area.

Example of using a `RasterSpriteComponent`:

```
final sprite = await Sprite.load('flame.png');
final rasterSpriteComponent = RasterSpriteComponent(
  sprite: sprite,
  size: Vector2.all(16.0),
);
```

When using the `RasterSpriteComponent`, it will automatically rasterize the sprite when it is loaded.

If you need to rasterize a sprite manually, you can use the `Sprite.rasterize` method:

```
final image = await images.load('player.png');
final playerFrame = Sprite(
  image,
  srcPosition: Vector2(32.0, 0),
  srcSize: Vector2(16.0, 16.0),
);

final rasterizedSprite = await playerFrame.rasterize();
```

By default, the `rasterize` method will use `Flame.images` to cache the rasterized image, auto generating a key based on the sprite’s source position and size. If you want to use a custom key for the rasterized image, or use a different cache object, you can pass it as an optional parameter:

```
final rasterizedSprite = await playerFrame.rasterize(
  cacheKey: 'custom_key_for_rasterized_image',
  images: Images(),
);
```

## SpriteBatch¶

If you have a sprite sheet (also called an image atlas, which is an image with smaller images inside), and would like to render it effectively - `SpriteBatch` handles that job for you.

Give it the filename of the image, and then add rectangles which describes various part of the image, in addition to transforms (position, scale and rotation) and optional colors.

You render it with a `Canvas` and an optional `Paint`, `BlendMode` and `CullRect`.

A `SpriteBatchComponent` is also available for your convenience.

See how to use it in the [SpriteBatch examples](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/sprites/sprite_batch_example.dart)

## ImageComposition¶

In some cases you may want to merge multiple images into a single image; this is called [Compositing](https://en.wikipedia.org/wiki/Compositing). This can be useful for example when working with the SpriteBatch API to optimize your drawing calls.

For such use cases Flame comes with the `ImageComposition` class. This allows you to add multiple images, each at their own position, onto a new image:

```
final composition = ImageComposition()
  ..add(image1, Vector2(0, 0))
  ..add(image2, Vector2(64, 0));
  ..add(image3,
    Vector2(128, 0),
    source: Rect.fromLTWH(32, 32, 64, 64),
  );

Image image = await composition.compose();
Image imageSync = composition.composeSync();
```

As you can see, two versions of composing image are available. Use `ImageComposition.compose()` for the async approach. Or use the new `ImageComposition.composeSync()` function to rasterize the image into GPU context using the benefits of the `Picture.toImageSync` function.

**Note:** Composing images is expensive, we do not recommend you run this every tick as it affect the performance badly. Instead we recommend to have your compositions pre-rendered so you can just reuse the output image.

## Animation¶

The Animation class helps you create a cyclic animation of sprites.

You can create it by passing a list of equally sized sprites and the stepTime (that is, how many seconds it takes to move to the next frame):

```
final a = SpriteAnimationTicker(SpriteAnimation.spriteList(sprites, stepTime: 0.02));
```

After the animation is created, you need to call its `update` method and render the current frame’s sprite on your game instance.

Example:

```
class MyGame extends Game {
  SpriteAnimationTicker a;

  MyGame() {
    a = SpriteAnimationTicker(SpriteAnimation(...));
  }

  void update(double dt) {
    a.update(dt);
  }

  void render(Canvas c) {
    a.getSprite().render(c);
  }
}
```

A better alternative to generate a list of sprites is to use the `fromFrameData` constructor:

```
const amountOfFrames = 8;
final a = SpriteAnimation.fromFrameData(
    imageInstance,
    SpriteAnimationFrame.sequenced(
      amount: amountOfFrames,
      textureSize: Vector2(16.0, 16.0),
      stepTime: 0.1,
    ),
);
```

This constructor makes creating an `Animation` very easy when using sprite sheets.

In the constructor you pass an image instance and the frame data, which contains some parameters that can be used to describe the animation. Check the documentation on the constructors available on the `SpriteAnimationFrameData` class to see all the parameters.

If you use Aseprite for your animations, Flame does provide some support for Aseprite animation’s JSON data. To use this feature you will need to export the Sprite Sheet’s JSON data, and use something like the following snippet:

```
final image = await images.load('chopper.png');
final jsonData = await assets.readJson('chopper.json');
final animation = SpriteAnimation.fromAsepriteData(image, jsonData);
```

**Note:** trimmed sprite sheets are not supported by flame, so if you export your sprite sheet this way, it will have the trimmed size, not the sprite original size.

Animations, after created, have an update and render method; the latter renders the current frame, and the former ticks the internal clock to update the frames.

Animations are normally used inside `SpriteAnimationComponent`s, but custom components with several Animations can be created as well.

To learn more, check out the full example code of [using animations as widgets](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/widgets/sprite_animation_widget_example.dart).

## SpriteSheet¶

Sprite sheets are big images with several frames of the same sprite on it and is a very good way to organize and store your animations. Flame provides a very simple utility class to deal with SpriteSheets, using which you can load your sprite sheet image and extract animations from it as well. Following is a simple example of how to use it:

```
import 'package:flame/sprite.dart';

final spriteSheet = SpriteSheet(
  image: imageInstance,
  srcSize: Vector2.all(16.0),
);

final animation = spriteSheet.createAnimation(0, stepTime: 0.1);
```

Now you can use the animation directly or use it in an animation component.

You can also create a custom animation by retrieving individual `SpriteAnimationFrameData` using either `SpriteSheet.createFrameData` or `SpriteSheet.createFrameDataFromId`:

```
final animation = SpriteAnimation.fromFrameData(
  imageInstance,
  SpriteAnimationData([
    spriteSheet.createFrameDataFromId(1, stepTime: 0.1), // by id
    spriteSheet.createFrameData(2, 3, stepTime: 0.3), // row, column
    spriteSheet.createFrameDataFromId(4, stepTime: 0.1), // by id
  ]),
);
```

If you don’t need any kind of animation and instead only want an instance of a `Sprite` on the `SpriteSheet` you can use the `getSprite` or `getSpriteById` methods:

```
spriteSheet.getSpriteById(2); // by id
spriteSheet.getSprite(0, 0); // row, column
```

See a full example of the [`SpriteSheet` class](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/sprites/sprite_sheet_example.dart) for more details on how to work with it.

## HasAutoBatchedChildren¶

Flame introduces automatic sprite batching for improved rendering performance via the `HasAutoBatchedChildren` mixin. This mixin enables groups of sprite components to be rendered in a single draw call per atlas, significantly reducing rendering overhead and improving performance, especially when managing many similar sprites.

### Purpose¶

The `HasAutoBatchedChildren` mixin is designed for scenarios where you have a group of sprite or animation components (such as enemies, bullets, or particles) that share the same atlas image. By batching their rendering, Flame minimizes the number of draw calls, which is a major performance bottleneck in graphics applications.

### When to Use¶

Use this mixin when you have many `SpriteComponent` or `SpriteAnimationComponent` children that:

- Use the same atlas image
- Have uniform scale
- Do not require custom decorators or snapshot caching
- Do not have complex paint effects

This is ideal for groups of similar objects, such as enemy waves or particle systems.

### How to Use¶

To enable batching, simply add the mixin to your group component:

```
import 'package:flame/components.dart';
import 'package:flame/src/components/mixins/has_auto_batched_children.dart';

class EnemyGroup extends PositionComponent with HasAutoBatchedChildren {
  // Add SpriteComponent or SpriteAnimationComponent children
}
```

You can toggle batching at runtime:

```
final group = EnemyGroup();
group.batchingEnabled = false; // falls back to individual rendering
```

The mixin works by intercepting per-child rendering (`renderChild`) and post-children rendering hooks (`afterChildrenRendered`), accumulating eligible children for batch rendering and flushing batches at priority boundaries to preserve correct render order.

### Example¶

```
class BulletGroup extends PositionComponent with HasAutoBatchedChildren {
  // Add SpriteComponent children representing bullets
}

// Add bullets to the group
bulletGroup.add(BulletSpriteComponent(...));
```

#### Rogue Shooter Example¶

See the [Rogue Shooter game example](https://examples.flame-engine.org/#/Sample_Games_Rogue_Shooter) for a real-world usage of this mixin.
</content>
</page>

<page>
  <title>ShapeComponents — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/components/shape_components.html</url>
  <content># ShapeComponents¶

Geometric shapes are useful in many game scenarios: debug visualizations, procedurally generated graphics, UI elements, or simple game objects that don’t need sprite art. Flame’s shape components let you render polygons, rectangles, and circles as first-class components with all the transform properties of `PositionComponent`. They also serve as the foundation for the [collision detection hitboxes](https://docs.flame-engine.org/latest/flame/collision_detection.html#shapehitbox).

A `ShapeComponent` is the base class for representing a scalable geometrical shape. The shapes have different ways of defining how they look, but they all have a size and angle that can be modified and the shape definition will scale or rotate the shape accordingly.

These shapes are meant as a tool for using geometrical shapes in a more general way than together with the collision detection system, where you want to use the [ShapeHitbox](https://docs.flame-engine.org/latest/flame/collision_detection.html#shapehitbox)es.

## PolygonComponent¶

A `PolygonComponent` is created by giving it a list of points in the constructor, called vertices. This list will be transformed into a polygon with a size, which can still be scaled and rotated.

For example, this would create a square going from (50, 50) to (100, 100), with its center in (75, 75):

```
void main() {
  PolygonComponent([
    Vector2(100, 100),
    Vector2(100, 50),
    Vector2(50, 50),
    Vector2(50, 100),
  ]);
}
```

A `PolygonComponent` can also be created with a list of relative vertices, which are points defined in relation to the given size, most often the size of the intended parent.

For example you could create a diamond-shaped polygon like this:

```
void main() {
  PolygonComponent.relative(
    [
      Vector2(0.0, -1.0), // Middle of top wall
      Vector2(1.0, 0.0), // Middle of right wall
      Vector2(0.0, 1.0), // Middle of bottom wall
      Vector2(-1.0, 0.0), // Middle of left wall
    ],
    size: Vector2.all(100),
  );
}
```

The vertices in the example define percentages of the length from the center to the edge of the screen in both x and y axis, so for our first item in our list (`Vector2(0.0, -1.0)`) we are pointing on the middle of the top wall of the bounding box, since the coordinate system here is defined from the center of the polygon.

In the image you can see how the polygon shape formed by the purple arrows is defined by the red arrows.

## RectangleComponent¶

A `RectangleComponent` is created very similarly to how a `PositionComponent` is created, since it also has a bounding rectangle.

Something like this for example:

```
void main() {
  RectangleComponent(
    position: Vector2(10.0, 15.0),
    size: Vector2.all(10),
    angle: pi/2,
    anchor: Anchor.center,
  );
}
```

Dart also already has an excellent way to create rectangles and that class is called `Rect`, you can create a Flame `RectangleComponent` from a `Rect` by using the `RectangleComponent.fromRect` factory, and just like when setting the vertices of the `PolygonComponent`, your rectangle will be sized according to the `Rect` if you use this constructor.

The following would create a `RectangleComponent` with its top left corner in `(10, 10)` and a size of `(100, 50)`.

```
void main() {
  RectangleComponent.fromRect(
    Rect.fromLTWH(10, 10, 100, 50),
  );
}
```

You can also create a `RectangleComponent` by defining a relation to the intended parent’s size, you can use the default constructor to build your rectangle from a position, size and angle. The `relation` is a vector defined in relation to the parent size, for example a `relation` that is `Vector2(0.5, 0.8)` would create a rectangle that is 50% of the width of the parent’s size and 80% of its height.

In the example below a `RectangleComponent` of size `(25.0, 30.0)` positioned at `(100, 100)` would be created.

```
void main() {
  RectangleComponent.relative(
    Vector2(0.5, 1.0),
    position: Vector2.all(100),
    size: Vector2(50, 30),
  );
}
```

Since a square is a simplified version of a rectangle, there is also a constructor for creating a square `RectangleComponent`, the only difference is that the `size` argument is a `double` instead of a `Vector2`.

```
void main() {
  RectangleComponent.square(
    position: Vector2.all(100),
    size: 200,
  );
}
```

## CircleComponent¶

If you know your circle’s position and/or how long the radius is going to be from the start you can use the optional arguments `radius` and `position` to set those.

The following would create a `CircleComponent` with its center in `(100, 100)` with a radius of 5, and therefore a size of `Vector2(10, 10)`.

```
void main() {
  CircleComponent(radius: 5, position: Vector2.all(100), anchor: Anchor.center);
}
```

When creating a `CircleComponent` with the `relative` constructor you can define how long the radius is in comparison to the shortest edge of the bounding box defined by `size`.

The following example would result in a `CircleComponent` that defines a circle with a radius of 40 (a diameter of 80).

```
void main() {
  CircleComponent.relative(0.8, size: Vector2.all(100));
}
```
</content>
</page>

<page>
  <title>Text Rendering — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/rendering/text_rendering.html</url>
  <content># Text Rendering¶

Flame has some dedicated classes to help you render text.

## Text Components¶

The simplest way to render text with Flame is to leverage one of the provided text-rendering components:

- `TextComponent` for rendering a single line of text
- `TextBoxComponent` for bounding multi-line text within a sized box, including the possibility of a typing effect. You can use the `newLineNotifier` to be notified when a new line is added. Use the `onComplete` callback to execute a function when the text is completely printed.
- `ScrollTextBoxComponent` enhances the functionality of `TextBoxComponent` by adding vertical scrolling capability when the text exceeds the boundaries of the enclosing box.

All components are showcased in [this example](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/rendering/text_example.dart).

### TextComponent¶

`TextComponent` is a simple component that renders a single line of text.

Simple usage:

```
class MyGame extends FlameGame {
  @override
  void onLoad() {
    add(
      TextComponent(
        text: 'Hello, Flame',
        position: Vector2.all(16.0),
      ),
    );
  }
}
```

In order to configure aspects of the rendering like font family, size, color, etc, you need to provide (or amend) a `TextRenderer` with such information; while you can read more details about this interface below, the simplest implementation you can use is the `TextPaint`, which takes a Flutter `TextStyle`:

```
final regular = TextPaint(
  style: TextStyle(
    fontSize: 48.0,
    color: BasicPalette.white.color,
  ),
);

class MyGame extends FlameGame {
  @override
  void onLoad() {
    add(
      TextComponent(
        text: 'Hello, Flame',
        textRenderer: regular,
        anchor: Anchor.topCenter,
        position: Vector2(size.width / 2, 32.0),
      ),
    );
  }
}
```

You can find all the options under [TextComponent’s API](https://pub.dev/documentation/flame/latest/components/TextComponent-class.html).

### TextBoxComponent¶

`TextBoxComponent` is very similar to `TextComponent`, but as its name suggest it is used to render text inside a bounding box, creating line breaks according to the provided box size.

You can decide if the box should grow as the text is written or if it should be static by the `growingBox` variable in the `TextBoxConfig`. A static box could either have a fixed size (setting the `size` property of the `TextBoxComponent`), or to automatically shrink to fit the text content.

In addition, the `align` property allows you to control the horizontal and vertical alignment of the text content. For example, setting `align` to `Anchor.center` will center the text within its bounding box both vertically and horizontally.

If you want to change the margins of the box use the `margins` variable in the `TextBoxConfig`.

Finally, if you want to simulate a “typing” effect, by showing each character of the string one by one as if being typed in real-time, you can provide the `boxConfig.timePerChar` parameter.

To control the typing effect, call `skip` to show the entire text at once, and `resetAnimation` to reset the typing effect back to the beginning without having to recreate the component. Do note that `skip` sets `boxConfig.timePerChar` to `0` so when attempting to replay the typing effect after calling `skip`, make sure to re-set the `boxConfig.timePerChar` right before or after calling `resetAnimation`.

Example usage:

```
class MyTextBox extends TextBoxComponent {
  MyTextBox(String text) : super(
    text: text,
    textRenderer: tiny,
    boxConfig: TextBoxConfig(timePerChar: 0.05),
  );

  final bgPaint = Paint()..color = Color(0xFFFF00FF);
  final borderPaint = Paint()..color = Color(0xFF000000)..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    Rect rect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(rect.deflate(boxConfig.margin), borderPaint);
    super.render(canvas);
  }
}
```

You can find all the options under [TextBoxComponent’s API](https://pub.dev/documentation/flame/latest/components/TextBoxComponent-class.html).

### ScrollTextBoxComponent¶

The `ScrollTextBoxComponent` is an advanced version of the `TextBoxComponent`, designed for displaying scrollable text within a defined area. This component is particularly useful for creating interfaces where large amounts of text need to be presented in a constrained space, such as dialogues or information panels.

Note that the `align` property of `TextBoxComponent` is not available.

Example usage:

```
class MyScrollableText extends ScrollTextBoxComponent {
  MyScrollableText(Vector2 frameSize, String text) : super(
    size: frameSize,
    text: text,
    textRenderer: regular,
    boxConfig: TextBoxConfig(timePerChar: 0.05),
  );
}
```

### TextElementComponent¶

If you want to render an arbitrary TextElement, ranging from a single InlineTextElement to a formatted DocumentRoot, you can use the `TextElementComponent`.

A simple example is to create a DocumentRoot to render a sequence of block elements (think of an HTML “div”) containing rich text:

```
  final document = DocumentRoot([
    HeaderNode.simple('1984', level: 1),
    ParagraphNode.simple(
      'Anything could be true. The so-called laws of nature were nonsense.',
    ),
    // ...
  ]);
  final element = TextElementComponent.fromDocument(
    document: document,
    position: Vector2(100, 50),
    size: Vector2(400, 200),
  );
```

Note that the size can be specified in two ways; either via:

- the size property common to all `PositionComponents`; or
- the width/height included within the `DocumentStyle` applied.

An example applying a style to the document (which can include the size but other parameters as well):

```
  final style = DocumentStyle(
    width: 400,
    height: 200,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    background: BackgroundStyle(
      color: const Color(0xFF4E322E),
      borderColor: const Color(0xFF000000),
      borderWidth: 2.0,
    ),
  );
  final document = DocumentRoot([ ... ]);
  final element = TextElementComponent.fromDocument(
    document: document,
    style: style,
    position: Vector2(100, 50),
  );
```

See a more elaborate [example of rich-text, formatted text blocks rendering](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/rendering/rich_text_example.dart).

For more details about the underlying mechanics of the text rendering pipeline, see “Text Elements, Text Nodes, and Text Styles” below.

### Flame Markdown¶

In order to more easily create rich-text-based DocumentRoots, from simple strings with bold/italics to complete structured documents, Flame provides the `flame_markdown` bridge package that connects the `markdown` library with Flame’s text rendering infrastructure.

Just use the `FlameMarkdown` helper class and the `toDocument` method to convert a markdown string into a DocumentRoot (which can then be used to create a `TextElementComponent`):

```
import 'package:flame/text.dart';
import 'package:flame_markdown/flame_markdown.dart';

// ...
final component = await TextElementComponent.fromDocument(
  document: FlameMarkdown.toDocument(
    '# Header\n'
    '\n'
    'This is a **bold** text, and this is *italic*.\n'
    '\n'
    'This is a second paragraph.\n',
  ),
  style: ...,
  position: ...,
  size: ...,
);
```

## Infrastructure¶

If you are not using the Flame Component System, want to understand the infrastructure behind text rendering, want to customize fonts and styles used, or want to create your own custom renderers, this section is for you.

- `TextRenderer`: renderers know “how” to render text; in essence they contain the style information to render any string
- `TextElement`: an element is formatted, “laid-out” piece of text, include the string (“what”) and the style (“how”)

The following diagram showcases the class and inheritance structure of the text rendering pipeline:

%%{init: { 'theme': 'dark' } }%% classDiagram %% renderers note for TextRenderer "This just the style (how). It knows how to take a text string and create a TextElement. `render` is just a helper to `format(text).render(...)`. Same for `getLineMetrics`." class TextRenderer { TextElement format(String text) LineMetrics getLineMetrics(String text) void render(Canvas canvas, String text, ...) } class TextPaint class SpriteFontRenderer class DebugTextRenderer %% elements class TextElement { LineMetrics metrics render(Canvas canvas, ...) } class TextPainterTextElement TextRenderer --> TextPaint TextRenderer --> SpriteFontRenderer TextRenderer --> DebugTextRenderer TextRenderer *-- TextElement TextPaint *-- TextPainterTextElement SpriteFontRenderer *-- SpriteFontTextElement note for TextElement "This is the text (what) and the style (how); laid out and ready to render." TextElement --> TextPainterTextElement TextElement --> SpriteFontTextElement TextElement --> Others

### TextRenderer¶

`TextRenderer` is the abstract class used by Flame to render text. Implementations of `TextRenderer` must include the information about the “how” the text is rendered. Font style, size, color, etc. It should be able to combine that information with a given string of text, via the `format` method, to generate a `TextElement`.

Flame provides two concrete implementations:

- `TextPaint`: most used, uses Flutter `TextPainter` to render regular text
- `SpriteFontRenderer`: uses a `SpriteFont` (a sprite sheet-based font) to render bitmap text
- `DebugTextRenderer`: only intended to be used for Golden Tests

But you can also provide your own if you want to extend to other customized forms of text rendering.

The main job of a `TextRenderer` is to format a string of text into a `TextElement`, that then can be rendered onto the screen:

```
final textElement = textRenderer.format("Flame is awesome")
textElement.render(...)
```

However the renderer provides a helper method to directly create the element and render it:

```
textRenderer.render(
  canvas,
  'Flame is awesome',
  Vector2(10, 10),
  anchor: Anchor.topCenter,
);
```

#### TextPaint¶

`TextPaint` is the built-in implementation of text rendering in Flame. It is based on top of Flutter’s `TextPainter` class (hence the name), and it can be configured by the style class `TextStyle`, which contains all typographical information required to render text; i.e., font size and color, font family, etc.

Outside of the style you can also optionally provide one extra parameter which is the `textDirection` (but that is typically already set to `ltr` or left-to-right).

Example usage:

```
const TextPaint textPaint = TextPaint(
  style: TextStyle(
    fontSize: 48.0,
    fontFamily: 'Awesome Font',
  ),
);
```

Note: there are several packages that contain the class `TextStyle`. We export the right one (from Flutter) via the `text` module:

```
import 'package:flame/text.dart';
```

But if you want to import it explicitly, make sure that you import it from `package:flutter/painting.dart` (or from material or widgets). If you also need to import `dart:ui`, you might need to hide its version of `TextStyle`, since that module contains a different class with the same name:

```
import 'package:flutter/painting.dart';
import 'dart:ui' hide TextStyle;
```

Following are some common properties of `TextStyle`(see the [full list of `TextStyle` properties](https://api.flutter.dev/flutter/painting/TextStyle-class.html)):

- `fontFamily`: a commonly available font, like Arial (default), or a custom font added in your pubspec (see [how to add a custom font](https://docs.flutter.dev/cookbook/design/fonts)).
- `fontSize`: font size, in pts (default `24.0`).
- `height`: height of text line, as a multiple of font size (default `null`).
- `color`: the color, as a `ui.Color` (default white).

For more information regarding colors and how to create them, see the [Colors and Palette](https://docs.flame-engine.org/latest/flame/rendering/palette.html) guide.

#### SpriteFontRenderer¶

The other renderer option provided out of the box is `SpriteFontRenderer`, which allows you to provide a `SpriteFont` based off of a sprite sheet. TODO

#### DebugTextRenderer¶

This renderer is intended to be used for Golden Tests. Rendering normal font-based text in Golden Tests is unreliable due to differences in font definitions across platforms and different algorithms used for anti-aliasing. This renderer will render text as if each word was a solid rectangle, making it possible to test the layout, positioning and sizing of the elements without having to rely on font-based rendering.

## Inline Text Elements¶

A `TextElement` is a “pre-compiled”, formatted and laid-out piece of text with a specific styling applied, ready to be rendered at any given position.

A `InlineTextElement` implements the `TextElement` interface and must implement their two methods, one that teaches how to translate it around and another on how to draw it to the canvas:

```
  void translate(double dx, double dy);
  void draw(Canvas canvas);
```

These methods are intended to be overwritten by the implementations of `InlineTextElement`, and probably will not be called directly by users; because a convenient `render` method is provided:

```
  void render(
    Canvas canvas,
    Vector2 position, {
    Anchor anchor = Anchor.topLeft,
  })
```

That allows the element to be rendered at a specific position, using a given anchor.

The interface also mandates (and provides) a getter for the `LineMetrics` object associated with that `InlineTextElement`, which allows you (and the `render` implementation) to access sizing information related to the element (width, height, ascend, etc).

```
  LineMetrics get metrics;
```

## Text Elements, Text Nodes, and Text Styles¶

While normal renderers always work with a `InlineTextElement` directly, there is a bigger underlying infrastructure that can be used to render more rich or formatter text.

Text Elements are a superset of Inline Text Elements that represent an arbitrary rendering block within a rich-text document. Essentially, they are concrete and “physical”: they are objects that are ready to be rendered on a canvas.

This property distinguishes them from Text Nodes, which are structured pieces of text, and from Text Styles (called `FlameTextStyle` in code to make it easier to work alongside Flutter’s `TextStyle`), which are descriptors for how arbitrary pieces of text ought to be rendered.

So, in the most general case, a user would use a `TextNode` to describe a desired piece of rich text; define a `FlameTextStyle` to apply to it; and use that to generate a `TextElement`. Depending on the type of rendering, the `TextElement` generated will be an `InlineTextElement`, which brings us back to the normal flow of the rendering pipeline. The unique property of the Inline-Text-type element is that it exposes a LineMetrics that can be used for advanced rendering; while the other elements only expose a simpler `draw` method which is unaware of sizing and positioning.

However, the other types of Text Elements, Text Nodes, and Text Styles must be used if the intent is to create an entire document (multiple blocks or paragraphs), enriched with formatted text. In order to render an arbitrary TextElement, you can alternatively use the `TextElementComponent` (see above).

See [examples of such usage](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/rendering/rich_text_example.dart).

### Text Nodes and the Document Root¶

A `DocumentRoot` is not a `TextNode` (inheritance-wise) in itself but represents a grouping of `BlockNodes` that layout a “page” or “document” of rich text laid out in multiple blocks or paragraphs. It represents the entire document and can receive a global Style.

The first step to define your rich-text document is to create a Node, which will likely be a `DocumentRoot`.

It will first contain the top-most list of Block Nodes that can define headers, paragraphs or columns.

Then each of those blocks can contain other blocks or the Inline Text Nodes, either Plain Text Nodes or some rich-text with specific formatting.

Note that the hierarchy defined by the node structure is also used for styling purposes as per defined in the `FlameTextStyle` class.

The actual nodes all inherit from `TextNode` and are broken down by the following diagram:

%%{init: { 'theme': 'dark' } }%% graph TD %% Config %% classDef default fill:#282828,stroke:#F6BE00; %% Nodes %% TextNode(" <big><strong>TextNode</strong></big> Can be thought of as an HTML DOM node; each subclass can be thought of as a specific tag. ") BlockNode(" <big><strong>BlockNode</strong></big> #quot;div#quot; ") InlineTextNode(" <big><strong>InlineTextNode</strong></big> #quot;span#quot; ") ColumnNode(" <big><strong>ColumnNode</strong></big> column-arranged group of other Block Nodes ") TextBlockNode(" <big><strong>TextBlockNode</strong></big> a #quot;div#quot; with an InlineTextNode as a direct child ") HeaderNode(" <big><strong>HeaderNode</strong></big> #quot;h1#quot; / #quot;h2#quot; / etc ") ParagraphNode(" <big><strong>ParagraphNode</strong></big> #quot;p#quot; ") GroupTextNode(" <big><strong>GroupTextNode</strong></big> groups other TextNodes in a single line ") PlainTextNode(" <big><strong>PlainTextNode</strong></big> just plain text, unformatted ") ItalicTextNode(" <big><strong>ItalicTextNode</strong></big> #quot;i#quot; / #quot;em#quot; ") BoldTextNode(" <big><strong>BoldTextNode</strong></big> #quot;b#quot; / #quot;strong#quot; ") TextNode ----> BlockNode TextNode --------> InlineTextNode BlockNode --> ColumnNode BlockNode --> TextBlockNode TextBlockNode --> HeaderNode TextBlockNode --> ParagraphNode InlineTextNode --> GroupTextNode InlineTextNode --> PlainTextNode InlineTextNode --> BoldTextNode InlineTextNode --> ItalicTextNode

### (Flame) Text Styles¶

Text Styles can be applied to nodes to generate elements. They all inherit from `FlameTextStyle` abstract class (which is named as is to avoid confusion with Flutter’s `TextStyle`).

They follow a tree-like structure, always having `DocumentStyle` as the root; this structure is leveraged to apply cascading style to the analogous Node structure. In fact, they are pretty similar to, and can be thought of as, CSS definitions.

The full inheritance chain can be seen on the following diagram:

%%{init: { 'theme': 'dark' } }%% classDiagram %% Nodes %% class FlameTextStyle { copyWith() merge() } note for FlameTextStyle "Root for all styles. Not to be confused with Flutter's TextStyle." class DocumentStyle { <<for the entire Document Root>> size padding background [BackgroundStyle] specific styles [for blocks & inline] } class BlockStyle { <<for Block Nodes>> margin, padding background [BackgroundStyle] text [InlineTextStyle] } class BackgroundStyle { <<for Block or Document>> color border } class InlineTextStyle { <<for any nodes>> font, color } FlameTextStyle <|-- DocumentStyle FlameTextStyle <|-- BlockStyle FlameTextStyle <|-- BackgroundStyle FlameTextStyle <|-- InlineTextStyle

### Text Elements¶

Finally, we have the elements, that represent a combination of a node (“what”) with a style (“how”), and therefore represent a pre-compiled, laid-out piece of rich text to be rendered on the Canvas.

Inline Text Elements specifically can alternatively be thought of as a combination of a `TextRenderer` (simplified “how”) and a string (single line of “what”).

That is because an `InlineTextStyle` can be converted to a specific `TextRenderer` via the `asTextRenderer` method, which is then used to lay out each line of text into a unique `InlineTextElement`.

When using the renderer directly, the entire layout process is skipped, and a single `TextPainterTextElement` or `SpriteFontTextElement` is returned.

As you can see, both definitions of an Element are, essentially, equivalent, all things considered. But it still leaves us with two paths for rendering text. Which one to pick? How to solve this conundrum?

When in doubt, the following guidelines can help you picking the best path for you:

- for the simplest way to render text, use `TextPaint` (basic renderer implementation)
  - you can use the FCS provided component `TextComponent` for that.

- for rendering Sprite Fonts, you must use `SpriteFontRenderer` (a renderer implementation that accepts a `SpriteFont`);
- for rendering multiple lines of text, with automatic line breaks, you have two options:
  - use the FCS `TextBoxComponent`, which uses any text renderer to draw each line of text as an Element, and does its own layout and line breaking;
  - use the Text Node & Style system to create your pre-laid-out Elements. Note: there is no current FCS component for it.

- finally, in order to have formatted (or rich) text, you must use Text Nodes & Styles.
</content>
</page>