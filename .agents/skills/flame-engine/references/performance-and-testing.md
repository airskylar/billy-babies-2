<page>
  <title>Performance — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/other/performance.html</url>
  <content># Performance¶

Just like any other game engine, Flame tries to be as efficient as possible without making the API too complex. But given its general purpose nature, Flame cannot make any assumption about the type of game being made. This means game developers will always have some room for performance optimizations based on how their game functions.

On the other hand, depending on the underlying hardware, there will always be some hard limit on what can be achieved with Flame. But apart from the hardware limits, there are some common pitfalls that Flame users can run into, which can be easily avoided by following some simple steps. This section tries to cover some optimization tricks and ways to avoid the common performance pitfalls.

Note

Disclaimer: Each Flame project is very different from the others. As a result, solution described here cannot guarantee to always produce a significant improvement in performance.

## Object creation per frame¶

Creating objects of a class is very common in any kind of project/game. But object creation is a somewhat involved operation. Depending on the frequency and amount of objects that are being created, the application can experience some slow down.

In games, this is something to be very careful of because games generally have a game loop that updates as fast as possible, where each update is called a frame. Depending on the hardware, a game can be updating 30, 60, 120 or even higher frames per second. This means if a new object is created in a frame, the game will end up creating as many number of objects as the frame count per second.

Flame users generally tend to run into this problem when they override the `update` and `render` method of a `Component`. For example, in the following innocent looking code, a new `Vector2` and a new `Paint` object is spawned every frame. But the data inside the objects is essentially the same across all frames. Now imagine if there are 100 instances of `MyComponent` in a game running at 60 FPS. That would essentially mean 6000 (100 * 60) new instances of `Vector2` and `Paint` each will be created every second.

Note

It is like buying a new computer every time you want to send an email or buying a new pen every time you want to write something. Sure it gets the job done, but it is not very economically smart.

```
class MyComponent extends PositionComponent {
  @override
  void update(double dt) {
    position += Vector2(10, 20) * dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint());
  }
}
```

A better way of doing things would be something like as shown below. This code stores the required `Vector2` and `Paint` objects as class members and reuses them across all the update and render calls.

```
class MyComponent extends PositionComponent {
  final _direction = Vector2(10, 20);
  final _paint = Paint();

  @override
  void update(double dt) {
    position.setValues(
      position.x + _direction.x * dt,
      position.y + _direction.y * dt,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }
}
```

Note

To summarize, avoid creating unnecessary objects in every frame. Even a seemingly small object can affect the performance if spawned in high volume.

## Unwanted collision checks¶

Flame has a built-in collision detection system which can detect when any two `Hitbox`es intersect with each other. In an ideal case, this system runs on every frame and checks for collision. It is also smart enough to filter out only the possible collisions before performing the actual intersection checks.

Despite this, it is safe to assume that the cost of collision detection will increase as the number of hitboxes increases. But in many games, the developers are not always interested in detecting collision between every possible pair. For example, consider a simple game where players can fire a `Bullet` component that has a hitbox. In such a game it is likely that the developers are not interested in detecting collision between any two bullets, but Flame will still perform those collision checks.

To avoid this, you can set the `collisionType` for bullet component to `CollisionType.passive`. Doing so will cause Flame to completely skip any kind of collision check between all the passive hitboxes.

Note

This does not mean bullet component in all games must always have a passive hitbox. It is up to the developers to decide which hitboxes can be made passive based on the rules of the game. For example, the Rogue Shooter game in Flame’s examples uses passive hitbox for enemies instead of the bullets.

## Object Pooling¶

As mentioned in the “Object creation per frame” section, creating and destroying objects frequently can impact performance. For components that are spawned and removed repeatedly (like bullets, particles, or enemies), object pooling is an effective optimization technique.

Object pooling reuses objects instead of constantly creating and destroying them. Flame provides the `ComponentPool` class to make object pooling easy and efficient.

### ComponentPool¶

The `ComponentPool` class manages a pool of reusable components. It automatically handles the component lifecycle: when a pooled component is removed from its parent, it is returned to the pool for reuse.

**Creating a pool:**

```
class MyGame extends FlameGame {
  late final ComponentPool<Bullet> bulletPool;

  @override
  Future<void> onLoad() async {
    bulletPool = ComponentPool<Bullet>(
      factory: () => Bullet(),
      maxSize: 50,      // Maximum number of bullets to keep in the pool
      initialSize: 10,  // Pre-create 10 bullets for immediate use
    );
  }
}
```

**Acquiring components from the pool:**

When you need a component, use `acquire()` to get one from the pool. If the pool is empty, a new component will be created automatically using the factory function.

```
void spawnBullet(Vector2 position, Vector2 velocity) {
  final bullet = bulletPool.acquire();
  bullet.position.setFrom(position);
  bullet.velocity.setFrom(velocity);
  world.add(bullet);
}
```

**Returning components to the pool:**

Components are returned to the pool **automatically** when they are removed from the game tree. Simply call `removeFromParent()` on the component. There is no manual release step.

```
class Bullet extends SpriteComponent with CollisionCallbacks {
  Vector2 velocity = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);

    // Remove bullet if it goes off screen. Automatically returned to pool.
    if (position.x < -100 || position.x > game.size.x + 100) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    // Return to pool on collision. No manual release needed.
    removeFromParent();
  }

  @override
  void onMount() {
    super.onMount();
    // Reset visual/internal state here so the component is clean when reused.
    // Caller-configured state (position, velocity) should NOT be reset here
    // because it is set between acquire() and add().
  }
}
```

### Pool Management¶

**Checking available components:**

You can check how many components are currently available in the pool:

```
print('Available bullets: ${bulletPool.availableCount}');
```

**Clearing the pool:**

If you need to free up memory or reset the pool, you can clear all available components:

```
bulletPool.clear();
```

Note

Clearing only affects components currently in the pool. Components that are in use (acquired but not yet released) are not affected.

### Best Practices¶

1. **No special mixin needed**: Any `Component` subclass can be pooled. Just pass a factory function to `ComponentPool` and you’re ready to go.
2. **Use `onMount` to reset internal state**: Reset visual or internal properties (e.g. animation frame, bounce phase) in `onMount()`. Do not reset caller-configured state (like position or velocity) there, since those are set between `acquire()` and `add()`.
3. **Just call `removeFromParent()`**: Components are returned to the pool automatically when removed. There is no manual release method to call.
4. **Set appropriate pool sizes**: Set `maxSize` based on your game’s needs. Too small and you’ll create new objects frequently; too large and you’ll waste memory.
5. **Use `initialSize` for warm-up**: Set `initialSize` to pre-create commonly used components, reducing frame drops during gameplay.
6. **Pool behavior is LIFO**: The pool uses a stack (Last In, First Out) internally, meaning the most recently returned component will be the next one acquired.
</content>
</page>

<page>
  <title>Writing tests — Flame</title>
  <url>https://docs.flame-engine.org/latest/development/testing_guide.html</url>
  <content># Writing tests¶

- All new functionality must be tested, if at all possible. When fixing a bug, tests must be added to ensure that this bug would not reappear in the future.
- Run `melos run coverage` to execute all tests in the “coverage” mode. The results will be saved in the `coverage/index.html` file, which can be opened in a browser. Try to achieve 100% coverage for any new functionality added.
- Every source file should have a corresponding test file, with the `_test` suffix. For example, if you’re making a `SpookyEffect` and the source file is `src/effects/spooky_effect.dart`, then the test file should be `test/effects/spooky_effect_test.dart` mirroring the source directory.
- The test file should contain a `main()` function with a single `group()` whose name matches the name of the class being tested. If the source file contains multiple public classes, then each of them should have its own group. For example:

```
void main() {
  group('SpookyEffect', () {
    // tests here
  });
}
```
- For a larger class, multiple groups can be created inside the top-level group, allowing to navigate the test suite easier. The names of the nested groups should be capitalized.
- The names of the individual tests should normally start with a lowercase.
- Often, you would need to define multiple helper classes to run the tests. Such classes should be private (start with an underscore), and placed at the end of the file. The reason for this is that whenever some test breaks, the first thing one needs to do is to go into the test file and run all the tests. Having the `main()` function at the top of the file makes this process much easier.

## Types of tests¶

### Simple tests¶

```
test('the name of the test', () {
  expect(...);
});
```

This is the simplest kind of test available, and also the fastest. Use these tests for checking some classes/methods that can function in isolation from the rest of the Flame framework.

### FlameGame tests¶

It is very common to want to have a `FlameGame` instance inside a test, so that you can add some components to it and verify various behaviors. The following approach is recommended:

```
testWithFlameGame('the name of the test', (game) async {
  game.add(...);
  await game.ready();

  expect(...);
});
```

Here the `game` instance that is passed to the test body is a fully initialized game that behaves as if it was mounted to a `GameWidget`. The `game.ready()` method waits until all the scheduled components are loaded and mounted to the component tree.

The time within the `game` can be advanced with `game.update(dt)`.

If you need to have a custom game inside this test (say, a game with some mixin), then use

```
testWithGame<_MyGame>(
  'the name of the test',
  _MyGame.new,
  (game) async {
    // test body...
  },
);
```

### Widget tests¶

Sometimes having a “naked” `FlameGame` is insufficient, and you want to have access to the Flutter infrastructure as well. That is, to have a game mounted into a real `GameWidget` embedded into an actual Flutter framework. In such cases, use

```
testWidgets('test name', (tester) async {
  final game = _MyGame();
  await tester.pumpWidget(GameWidget(game: game));
  await tester.pump();
  await tester.pump();

  // At this point the game is fully initialized, and you can run your checks
  // against it.
  expect(...);

  // Equivalent to game.update(0)
  await tester.pump();

  // Advances in-game time by 20 milliseconds
  await tester.pump(const Duration(milliseconds: 20));
});
```

There are some additional methods available on the `tester` controller, for example in order to simulate taps, or drags, or key presses.

### Golden tests¶

These tests verify that things render as intended. The process of creating a golden test is simple:

1. Write the test, using the following template:

```
testGolden(
  'the name of the test',
  (game) async {
     // Set up the game by adding the necessary components
     // You can add `expect()` checks here too, if you want to
  },
  size: Vector2(300, 200),
  goldenFile: '.../_goldens/my_test_file.png',
);
```

Here the `size` parameter determines the size of the game canvas and of the output image. The `goldenFile` parameter is the name of the file where you want to store the “golden” results. This should be a relative path to the `test/_goldens` directory, starting from your test file.
2. Run

```
flutter test --update-goldens
```

this would create the golden file for the first time. Open the file to verify that it renders exactly as you intended. If not, then delete the file and go back to step 1.
3. Subsequent runs of `flutter test` will check whether the output of the golden test matches the saved golden file. If not, Flutter will save the image-diff files into the `failures/` directory where your test is located.

Note

Avoid using text in your golden tests – it does not render reliably across different platforms, due to font discrepancies and differences in anti-aliasing algorithms.

### Random tests¶

These are the tests that use a random number generator in order to construct a randomized input and then check its correctness. Use as follows:

```
testRandom('test name', (Random random) {
  // Use [random] to generate random input
});
```

You can add `repeatCount: 1000` parameter to run this test the specified number of times, each one with a different seed. It is useful to run a high `repeatCount` when developing the test, to ensure that it doesn’t break. However, when submitting the test to the main repository, avoid repeatCounts higher than 10.

If the test breaks at some particular seed, then that seed will be shown in the test output. Add it as the `seed: NNN` parameter to your test, and you’ll be able to run it for the same seed as long as you need until the test is fixed. Do not leave the `seed:` parameter when submitting your code, as it defeats the purpose of having the test randomized.
</content>
</page>