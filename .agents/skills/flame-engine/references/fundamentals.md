<page>
  <title>PositionComponent — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/components/position_component.html</url>
  <content># PositionComponent¶

Most visible objects in a game need a position, size, and rotation. `PositionComponent` provides these transform properties, making it the base class for nearly every visual element in Flame: sprites, animations, shapes, and your own custom components. It mirrors the concept of a [`Positioned`](https://api.flutter.dev/flutter/widgets/Positioned-class.html) widget in Flutter, but in a game-oriented coordinate system.

This class represents a positioned object on the screen, be it a floating rectangle, a rotating sprite, or anything else with position and size. It can also represent a group of positioned components if children are added to it.

The base of the `PositionComponent` is that it has a `position`, `size`, `scale`, `angle` and `anchor` which transforms how the component is rendered.

## Position¶

The `position` is just a `Vector2` which represents the position of the component’s anchor in relation to its parent; if the parent is a `FlameGame`, it is in relation to the viewport.

## Size¶

The `size` of the component when the zoom level of the camera is 1.0 (no zoom, default). The `size` is *not* in relation to the parent of the component.

## Scale¶

The `scale` is how much the component and its children should be scaled. Since it is represented by a `Vector2`, you can scale in a uniform way by changing `x` and `y` with the same amount, or in a non-uniform way, by changing `x` or `y` by different amounts.

## Angle¶

The `angle` is the rotation angle around the anchor, represented as a double in radians. It is relative to the parent’s angle.

## Native Angle¶

The `nativeAngle` is an angle in radians, measured clockwise, representing the default orientation of the component. It can be used to define the direction in which the component is facing when angle is zero.

It is especially helpful when making a sprite based component look at a specific target. If the original image of the sprite is not facing in the up/north direction, the calculated angle to make the component look at the target will need some offset to make it look correct. For such cases, `nativeAngle` can be used to let the component know what direction the original image is facing.

An example could be a bullet image pointing in the east direction. In this case `nativeAngle` can be set to pi/2 radians. Following are some common directions and their corresponding native angle values.

| Direction | Native Angle | In degrees |
| --- | --- | --- |
| Up/North | 0 | 0 |
| Down/South | pi or -pi | 180 or -180 |
| Left/West | -pi/2 | -90 |
| Right/East | pi/2 | 90 |

## Anchor¶

The `anchor` is where on the component that the position and rotation should be defined from (the default is `Anchor.topLeft`). So if you have the anchor set as `Anchor.center` the component’s position on the screen will be in the center of the component and if an `angle` is applied, it is rotated around the anchor, so in this case around the center of the component. You can think of it as the point within the component by which Flame “grabs” it.

When `position` or `absolutePosition` of a component is queried, the returned coordinates are that of the `anchor` of the component. In case you want to find the position of a specific anchor point of a component which is not actually the `anchor` of that component, you can use the `positionOfAnchor` and `absolutePositionOfAnchor` methods.

```
final comp = PositionComponent(
  size: Vector2.all(20),
  anchor: Anchor.center,
);

// Returns (0,0)
final p1 = component.position;

// Returns (10, 10)
final p2 = component.positionOfAnchor(Anchor.bottomRight);
```

A common pitfall when using `anchor` is confusing it as being the attachment point for children components. For example, setting `anchor` to `Anchor.center` for a parent component does not mean that the children components will be placed w.r.t the center of parent.

Note

Local origin for a child component is always the top-left corner of its parent component, irrespective of their `anchor` values.

## PositionComponent children¶

All children of the `PositionComponent` will be transformed in relation to the parent, which means that the `position`, `angle` and `scale` will be relative to the parent’s state. So if you, for example, wanted to position a child in the center of the parent you would do this:

```
@override
void onLoad() {
  final parent = PositionComponent(
    position: Vector2(100, 100),
    size: Vector2(100, 100),
  );
  final child = PositionComponent(
    position: parent.size / 2,
    anchor: Anchor.center,
  );
  parent.add(child);
}
```

Remember that most components that are rendered on the screen are `PositionComponent`s, so this pattern can be used in for example [SpriteComponent](https://docs.flame-engine.org/latest/flame/components/sprite_components.html#spritecomponent) and [SpriteAnimationComponent](https://docs.flame-engine.org/latest/flame/components/sprite_components.html#spriteanimationcomponent) too.

## Render PositionComponent¶

When implementing the `render` method for a component that extends `PositionComponent` remember to render from the top left corner (0.0). Your render method should not handle where on the screen your component should be rendered. To handle where and how your component should be rendered use the `position`, `angle` and `anchor` properties and Flame will automatically handle the rest for you.

If you want to know where on the screen the bounding box of the component is you can use the `toRect` method.

In the event that you want to change the direction of your component’s rendering, you can also use `flipHorizontally()` and `flipVertically()` to flip anything drawn to canvas during `render(Canvas canvas)`, around the anchor point. These methods are available on all `PositionComponent` objects, and are especially useful on `SpriteComponent` and `SpriteAnimationComponent`.

In case you want to flip a component around its center without having to change the anchor to `Anchor.center`, you can use `flipHorizontallyAroundCenter()` and `flipVerticallyAroundCenter()`.
</content>
</page>

<page>
  <title>Components — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/components/components.html</url>
  <content># Components¶

In game development, a component is a self-contained unit that encapsulates a specific piece of game behavior or visual. Flame uses the [Flame Component System](https://docs.flame-engine.org/latest/flame/game.html) (FCS) where every object in your game (players, enemies, backgrounds, UI elements) is a component. This makes games easier to build and maintain because each piece of logic lives in its own class and components can be freely composed into a tree, much like [Flutter’s widget tree](https://docs.flutter.dev/get-started/fundamentals/widgets).

- [Position Component](https://docs.flame-engine.org/latest/flame/components/position_component.html)
- [Sprite Components](https://docs.flame-engine.org/latest/flame/components/sprite_components.html)
- [Parallax Component](https://docs.flame-engine.org/latest/flame/components/parallax_component.html)
- [Shape Components](https://docs.flame-engine.org/latest/flame/components/shape_components.html)
- [Utility Components](https://docs.flame-engine.org/latest/flame/components/utility_components.html)

%%{init: { 'theme': 'dark' } }%% graph TD %% Config %% classDef default fill:#282828,stroke:#F6BE00; %% Nodes %% Component(Component) Misc(" TimerComponent ParticleComponent SpriteBatchComponent ") Effects("Effects<br/>(See the effects section)") Game(Game) FlameGame(FlameGame) PositionComponent(PositionComponent) Sprites(" SpriteComponent SpriteGroupComponent SpriteAnimationComponent SpriteAnimationGroupComponent ParallaxComponent IsoMetricTileMapComponent ") HudMarginComponent(HudMarginComponent) HudComponents(" HudButtonComponent JoystickComponent ") OtherPositionComponents(" ButtonComponent CustomPainterComponent ShapeComponent SpriteButtonComponent TextComponent TextBoxComponent NineTileBoxComponent ") %% Flow %% Component --> Misc Component --> Effects Component --> PositionComponent Component --> FlameGame Game --> FlameGame PositionComponent --> Sprites PositionComponent --> HudMarginComponent PositionComponent --> OtherPositionComponents HudMarginComponent --> HudComponents

This diagram might look intimidating, but don’t worry, it is not as complex as it looks.

## Component¶

All components inherit from the `Component` class and can have other `Component`s as children. This is the base of what we call the Flame Component System, or FCS for short.

Children can be added either with the `add(Component c)` method or directly in the constructor.

Example:

```
void main() {
  final component1 = Component(children: [Component(), Component()]);
  final component2 = Component();
  component2.add(Component());
  component2.addAll([Component(), Component()]);
}
```

The `Component()` here could of course be any subclass of `Component`.

Every `Component` has a few methods that you can optionally implement, which are used by the `FlameGame` class.

### Component lifecycle¶

%%{init: { 'theme': 'dark' } }%% graph TD %% Node Color %% classDef default fill:#282828,stroke:#F6BE00,stroke-width:2px; classDef lightYellow fill:#523F00,stroke-width:2px; classDef yellow fill:#F6BE00,color:#000000; classDef green fill:#00523F,stroke:#F6BE00,stroke-width:2px; %% Nodes %% x(Runs Each Tick) y(Runs On Add & Resize):::lightYellow z(Runs Once):::yellow w(Runs On Hot Reload):::green

%%{init: { 'theme': 'dark' } }%% graph LR %% Node Color %% classDef default fill:#282828,stroke:#F6BE00,stroke-width:2px; classDef lightYellow fill:#523F00,stroke-width:2px; classDef yellow fill:#F6BE00,color:#000000; classDef green fill:#00523F,stroke:#F6BE00,stroke-width:2px; %% Nodes %% A(onLoad):::yellow B(onGameResize):::lightYellow C(onMount):::lightYellow D(update) E(render) F(onRemove):::lightYellow G(onHotReload):::green %% Flow %% A-->B B-->C C-->D D-->E E-->D E-. If removed .->F F-. If re-parented .->B D-. If hot reloaded .->G G-.->D

The `onGameResize` method is called whenever the screen is resized, and also when this component gets added into the component tree, before the `onMount`.

The `onParentResize` method is similar: it is also called when the component is mounted into the component tree, and also whenever the parent of the current component changes its size.

The `onRemove` method can be overridden to run code before the component is removed from the game. It is only run once even if the component is removed both by using the parent’s remove method and the `Component` remove method.

The `onLoad` method can be overridden to run asynchronous initialization code for the component, like loading an image for example. This method is executed before `onGameResize` and `onMount`. This method is guaranteed to execute only once during the lifetime of the component, so you can think of it as an “asynchronous constructor”.

The `onMount` method runs every time the component is mounted into a game tree. This means that you should not initialize `late final` variables here, since this method might run several times throughout the component’s lifetime. This method will only run if the parent is already mounted. If the parent is not mounted yet, then this method will wait in a queue (this will have no effect on the rest of the game engine).

The `onChildrenChanged` method can be overridden if it’s needed to detect changes in a parent’s children. This method is called whenever a child is added to or removed from a parent (this includes if a child is changing its parent). Its parameters contain the target child and the type of change it went through (`added` or `removed`).

The `onHotReload` method is called on every component in the tree when Flutter’s hot reload is triggered (debug mode only). Override this method to reload assets, recalculate cached values, or perform other actions in response to code changes during development. The notification propagates automatically to all children that are loading or loaded, so you must call `super.onHotReload()` in your override:

```
class MyComponent extends Component {
  @override
  void onHotReload() {
    super.onHotReload();
    // Re-read values that may have changed in source code.
    _cachedValue = _computeExpensiveValue();
  }
}
```

A component’s lifecycle state can be checked by a series of getters:

- `isLoaded`: Returns a bool with the current loaded state.
- `loaded`: Returns a future that will complete once the component has finished loading.
- `isMounted`: Returns a bool with the current mounted state.
- `mounted`: Returns a future that will complete once the component has finished mounting.
- `isRemoved`: Returns a bool with the current removed state.
- `removed`: Returns a future that will complete once the component has been removed.

### Priority¶

In Flame every `Component` has the `int priority` property, which determines that component’s sorting order within its parent’s children. This is sometimes referred to as `z-index` in other languages and frameworks. The higher the `priority` is set to, the closer the component will appear on the screen, since it will be rendered on top of any components with lower priority that were rendered before it.

If you add two components and set one of their priorities to 1 for example, then that component will be rendered on top of the other component (if they overlap), because the default priority is 0.

All components take in `priority` as a named argument, so if you know the priority that you want your component at compile time, then you can pass it in to the constructor.

Example:

```
class MyGame extends FlameGame {
  @override
  void onLoad() {
    final myComponent = PositionComponent(priority: 5);
    add(myComponent);
  }
}
```

To update the priority of a component you have to set it to a new value, like `component.priority = 2`, and it will be updated in the current tick before the rendering stage.

In the following example we first initialize the component with priority 1, and then when the user taps the component we change its priority to 2:

```
class MyComponent extends PositionComponent with TapCallbacks {

  MyComponent() : super(priority: 1);

  @override
  void onTapDown(TapDownEvent event) {
    priority = 2;
  }
}
```

### Composability of components¶

Sometimes it is useful to wrap other components inside of your component. For example by grouping visual components through a hierarchy. You can do this by adding child components to any component, for example `PositionComponent`.

When you have child components on a component every time the parent is updated and rendered, all the children are rendered and updated with the same conditions.

Here’s an example where the visibility of two components is handled by a wrapper:

```
class GameOverPanel extends PositionComponent {
  bool visible = false;
  final Image spriteImage;

  GameOverPanel(this.spriteImage);

  @override
  void onLoad() {
    // GameOverText is a Component
    final gameOverText = GameOverText(spriteImage);
    // GameOverRestart is a SpriteComponent
    final gameOverButton = GameOverButton(spriteImage);

    add(gameOverText);
    add(gameOverButton);
  }

  @override
  void render(Canvas canvas) {
    if (visible) {
    } // If not visible none of the children will be rendered
  }
}
```

There are two methods for adding child components to your component. First, you have methods `add()`, `addAll()`, and `addToParent()`, which can be used at any time during the game. Traditionally, children will be created and added from the component’s `onLoad()` method, but it is also common to add new children during the course of the game.

The second method is to use the `children:` parameter in the component’s constructor. This approach more closely resembles the standard Flutter API:

```
class MyGame extends FlameGame {
  @override
  void onLoad() {
    add(
      PositionComponent(
        position: Vector2(30, 0),
        children: [
          HighScoreDisplay(),
          HitPointsDisplay(),
          FpsComponent(),
        ],
      ),
    );
  }
}
```

The two approaches can be combined freely: the children specified within the constructor will be added first, and then any additional child components after.

Note that the children added via either method are only guaranteed to be available eventually: after they are loaded and mounted. We can only assure that they will appear in the children list in the same order as they were scheduled for addition.

### Access to the World from a Component¶

If a component that has a `World` as an ancestor and requires access to that `World` object, one can use the `HasWorldReference` mixin.

Example:

```
class MyComponent extends Component with HasWorldReference<MyWorld>,
    TapCallbacks {
  @override
  void onTapDown(TapDownEvent info) {
    // world is of type MyWorld
    world.add(AnotherComponent());
  }
}
```

If you try to access `world` from a component that doesn’t have a `World` ancestor of the correct type an assertion error will be thrown.

### Ensuring a component has a given parent¶

When a component needs to be added to a specific parent type, the `ParentIsA` mixin can be used to enforce a strongly typed parent.

Example:

```
class MyComponent extends Component with ParentIsA<MyParentComponent> {
  @override
  void onLoad() {
    // parent is of type MyParentComponent
    print(parent.myValue);
  }
}
```

If you try to add `MyComponent` to a parent that is not `MyParentComponent`, an assertion error will be thrown.

### Ensuring a component has a given ancestor¶

When a component needs to have a specific ancestor type somewhere in the component tree, the `HasAncestor` mixin can be used to enforce that relationship.

The mixin exposes the `ancestor` field that will be of the given type.

Example:

```
class MyComponent extends Component with HasAncestor<MyAncestorComponent> {
  @override
  void onLoad() {
    // ancestor is of type MyAncestorComponent.
    print(ancestor.myValue);
  }
}
```

If you try to add `MyComponent` to a tree that does not contain `MyAncestorComponent`, an assertion error will be thrown.

### Component Keys¶

Components can have an identification key that allows them to be retrieved from the component tree, from any point of the tree.

To register a component with a key, simply pass a key to the `key` argument on the component’s constructor:

```
final myComponent = Component(
  key: ComponentKey.named('player'),
);
```

Then, to retrieve it in a different point of the component tree:

```
flameGame.findByKey(ComponentKey.named('player'));
```

There are two types of keys, `unique` and `named`. Unique keys are based on equality of the key instance, meaning that:

```
final key = ComponentKey.unique();
final key2 = key;
print(key == key2); // true
print(key == ComponentKey.unique()); // false
```

Named ones are based on the name that it receives, so:

```
final key1 = ComponentKey.named('player');
final key2 = ComponentKey.named('player');
print(key1 == key2); // true
```

When named keys are used, the `findByKeyName` helper can also be used to retrieve the component.

```
flameGame.findByKeyName('player');
```

### Querying child components¶

The children that have been added to a component live in a `QueryableOrderedSet` called `children`. To query for a specific type of components in the set, the `query<T>()` function can be used. By default `strictMode` is `false` in the children set, but if you set it to true, then the queries will have to be registered with `children.register` before a query can be used.

If you know at compile time that you later will run a query of a specific type it is recommended to register the query, no matter if the `strictMode` is set to `true` or `false`, since there are some performance benefits to gain from it. The `register` call is usually done in `onLoad`.

Example:

```
@override
void onLoad() {
  children.register<PositionComponent>();
}
```

In the example above a query is registered for `PositionComponent`s, and an example of how to query the registered component type can be seen below.

```
@override
void update(double dt) {
  final allPositionComponents = children.query<PositionComponent>();
}
```

### Querying components at a specific point on the screen¶

The method `componentsAtPoint()` allows you to check which components were rendered at some point on the screen. The returned value is an iterable of components, but you can also obtain the coordinates of the initial point in each component’s local coordinate space by providing a writable `List<Vector2>` as a second parameter.

The iterable retrieves the components in the front-to-back order, i.e. first the components in the front, followed by the components in the back.

This method can only return components that implement the method `containsLocalPoint()`. The `PositionComponent` (which is the base class for many components in Flame) provides such an implementation. However, if you’re defining a custom class that derives from `Component`, you’d have to implement the `containsLocalPoint()` method yourself.

Here is an example of how `componentsAtPoint()` can be used:

```
void onDragUpdate(DragUpdateInfo info) {
  game.componentsAtPoint(info.widget).forEach((component) {
    if (component is DropTarget) {
      component.highlight();
    }
  });
}
```

### Visibility of components¶

The recommended way to hide or show a component is usually to add or remove it from the tree using the `add` and `remove` methods.

However, adding and removing components from the tree will trigger lifecycle steps for that component (such as calling `onRemove` and `onMount`). It is also an asynchronous process and care needs to be taken to ensure the component has finished removing before it is added again if you are removing and adding a component in quick succession.

```
/// Example of handling the removal and adding of a child component
/// in quick succession
void show() async {
  // Need to await the [removed] future first, just in case the
  // component is still in the process of being removed.
  await myChildComponent.removed;
  add(myChildComponent);
}

void hide() {
  remove(myChildComponent);
}
```

These behaviors are not always desirable.

An alternative method to show and hide a component is to use the `HasVisibility` mixin, which may be used on any class that inherits from `Component`. This mixin introduces the `isVisible` property. Simply set `isVisible` to `false` to hide the component, and `true` to show it again, without removing it from the tree. This affects the visibility of the component and all its descendants (children).

```
/// Example that implements HasVisibility
class MyComponent extends PositionComponent with HasVisibility {}

/// Usage of the isVisible property
final myComponent = MyComponent();
add(myComponent);

myComponent.isVisible = false;
```

The mixin only affects whether the component is rendered, and will not affect other behaviors.

Note

Important! Even when the component is not visible, it is still in the tree and will continue to receive calls to ‘update’ and all other lifecycle events. It will still respond to input events, and will still interact with other components, such as collision detection for example.

The mixin works by preventing the `renderTree` method, therefore if `renderTree` is being overridden, a manual check for `isVisible` should be included to retain this functionality.

```
class MyComponent extends PositionComponent with HasVisibility {

  @override
  void renderTree(Canvas canvas) {
    // Check for visibility
    if (isVisible) {
      // Custom code here

      // Continue rendering the tree
      super.renderTree(canvas);
    }
  }
}
```

### Render Contexts¶

If you want a parent component to pass render-specific properties down to its children tree, you can override the `renderContext` property on the parent component. You can return a custom class that inherits from `RenderContext`, and then use `findRenderContext` on the children while rendering. Render Contexts are stored as a stack and propagated whenever the render tree is navigated for rendering.

For example:

```
class IntContext extends ComponentRenderContext {
  int value;

  IntContext(this.value);
}

class ParentWithContext extends Component {
  @override
  IntContext renderContext = IntContext(42);
}

class ChildReadsContext extends Component {
  @override
  void render(Canvas canvas) {
    final context = findRenderContext<IntContext>();
    // context.value available
  }
}
```

Each component will have access to the context of any parent that is above it in the component tree. If multiple components add the contexts matching the selected type `T`, the “closest” one will be returned (though typically you would create a unique context type for each component).

## Effects¶

Flame provides a set of effects that can be applied to a certain type of components. These effects can be used to animate some properties of your components, like position or dimensions. You can check the [list of available effects](https://docs.flame-engine.org/latest/flame/effects/effects.html).

Examples of the running effects can be found in the [effects examples directory](https://github.com/flame-engine/flame/tree/main/examples/lib/stories/effects).
</content>
</page>

<page>
  <title>Camera & World — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/camera.html</url>
  <content># Camera & World¶

In most games the world is larger than what fits on screen at once. The camera controls which portion of the game world is visible and how it is projected onto the player’s display, handling panning, zooming, and following characters. This is similar to how a [`Viewport`](https://api.flutter.dev/flutter/rendering/RenderViewport-class.html) in Flutter determines which part of a scrollable area is visible, but tailored for the free-form 2D coordinate space of a game.

Example of a simple game structure:

```
FlameGame
├── World
│   ├── Player
│   └── Enemy
└── CameraComponent
    ├── Viewfinder
    │   ├── HudButton
    │   └── FpsTextComponent
    └── Viewport
```

In order to understand how the `CameraComponent` works, imagine that your game world is an entity that exists *somewhere* independently from your application. Imagine that your game is merely a window through which you can look into that world. That you can close that window at any moment, and the game world would still be there. Or, on the contrary, you can open multiple windows that all look at the same world (or different worlds) at the same time.

With this mindset, we can now understand how the `CameraComponent` works.

First, there is the World class, which contains all components that are inside your game world. The `World` component can be mounted anywhere, for example at the root of your game class, like the built-in `World` is.

Then, a CameraComponent class that “looks at” the World. The `CameraComponent` has a Viewport and a Viewfinder inside of it, allowing both the flexibility of rendering the world at any place on the screen, and also controlling the viewing location and angle. The `CameraComponent` also contains a backdrop component which is statically rendered below the world.

## World¶

This component should be used to host all other components that comprise your game world. The main property of the `World` class is that it does not render through traditional means; instead it is rendered by one or more CameraComponents to “look at” the world. In the `FlameGame` class there is one `World` called `world` which is added by default and paired together with the default `CameraComponent` called `camera`.

A game can have multiple `World` instances that can be rendered either at the same time, or at different times. For example, if you have two worlds A and B and a single camera, then switching that camera’s target from A to B will instantaneously switch the view to world B without having to unmount A and then mount B.

Just like with most `Component`s, children can be added to `World` by using the `children` argument in its constructor, or by using the `add` or `addAll` methods.

For many games you want to extend the world and create your logic in there, such a game structure could look like this:

```
void main() {
  runApp(GameWidget(FlameGame(world: MyWorld())));
}

class MyWorld extends World {
  @override
  Future<void> onLoad() async {
    // Load all the assets that are needed in this world
    // and add components etc.
  }
}
```

## CameraComponent¶

This is a component through which a `World` is rendered. Multiple cameras can observe the same world at the same time.

There is a default `CameraComponent` called `camera` on the `FlameGame` class which is paired together with the default `world`, so you don’t need to create or add your own `CameraComponent` if your game doesn’t need to.

A `CameraComponent` has two other components inside: a Viewport and a Viewfinder. Those components are always children of a camera.

The `FlameGame` class has a `camera` field in its constructor, so you can set what type of default camera that you want, like this camera with a fixed resolution for example:

```
void main() {
  runApp(
    GameWidget(
      FlameGame(
        camera: CameraComponent.withFixedResolution(
          width: 800,
          height: 600,
        ),
        world: MyWorld(),
      ),
    ),
  );
}
```

There is also a static property `CameraComponent.currentCamera` and it returns the camera object that currently performs rendering. This is needed only for certain advanced use cases where the rendering of a component depends on the camera settings. For example, some components may decide to skip rendering themselves and their children if they are outside of the camera’s viewport.

### CameraComponent with fixed resolution¶

This named constructor will let you pretend that the user’s device has a fixed resolution of your choice. For example:

```
final camera = CameraComponent.withFixedResolution(
  world: myWorldComponent,
  width: 800,
  height: 600,
);
```

This will create a camera with a viewport centered in the middle of the screen, taking as much space as possible while still maintaining the 4:3 (800x600) aspect ratio, and showing a game world region of size 800 x 600.

A “fixed resolution” is very simple to work with, but it will underutilize the user’s available screen space, unless their device happens to have the same aspect ratio as your chosen dimensions.

## Viewport¶

The `Viewport` is a window through which the `World` is seen. That window has a certain size, shape, and position on the screen. There are multiple kinds of viewports available, and you can always implement your own.

The `Viewport` is a component, which means you can add other components to it. These child components will be affected by the viewport’s position, but not by its clip mask. Thus, if a viewport is a “window” into the game world, then its children are things that you can put on top of the window.

Adding elements to the viewport is a convenient way to implement “HUD” components.

The following viewports are available:

- `MaxViewport` (default): this viewport expands to the maximum size allowed by the game, i.e. it will be equal to the size of the game canvas.
- `FixedResolutionViewport`: keeps the resolution and aspect ratio fixed, with black bars on the sides if it doesn’t match the aspect ratio.
- `FixedSizeViewport`: a simple rectangular viewport with predefined size.
- `FixedAspectRatioViewport`: a rectangular viewport which expands to fit into the game canvas, but preserving its aspect ratio.
- `CircularViewport`: a viewport in the shape of a circle, fixed size.

If you add children to the `Viewport` they will appear as static HUDs in front of the world.

## Viewfinder¶

This part of the camera is responsible for knowing which location in the underlying game world we are currently looking at. The `Viewfinder` also controls the zoom level, and the rotation angle of the view.

The `anchor` property of the viewfinder allows you to designate which point inside the viewport serves as a “logical center” of the camera. For example, in side-scrolling action games it is common to have the camera focused on the main character who is displayed not in the center of the screen but closer to the lower-left corner. This off-center position would be the “logical center” of the camera, controlled by the viewfinder’s `anchor`.

If you add children to the `Viewfinder` they will appear in front of the world, but behind the viewport and with the same transformations as are applied to the world, so these components are not static.

You can also add behavioral components as children to the viewfinder, for example effects or other controllers. If you for example would add a `ScaleEffect` you would be able to achieve a smooth zoom in your game.

## Backdrop¶

To add static components behind the world you can add them to the `backdrop` component, or replace the `backdrop` component. This is for example useful if you want to have a static `ParallaxComponent` that shows behind a world that contains a player that can move around.

Example:

```
camera.backdrop.add(MyStaticBackground());
```

or

```
camera.backdrop = MyStaticBackground();
```

## Camera controls¶

There are several ways to modify a camera’s settings at runtime:

1. Use camera functions such as `follow()`, `moveBy()` and `moveTo()`. Under the hood, this approach uses the same effects/behaviors as in (2).
2. Apply effects and/or behaviors to the camera’s `Viewfinder` or `Viewport`. The effects and behaviors are special kinds of components whose purpose is to modify some property of a component over time.
3. Do it manually. You can always override the `CameraComponent.update()` method (or the same method on the viewfinder or viewport) and within it change the viewfinder’s position or zoom as you see fit. This approach may be viable in some circumstances, but in general it is not recommended.

The `CameraComponent` has several methods for controlling its behavior:

- `follow()` will force the camera to follow the provided target. Optionally you can limit the maximum speed of movement of the camera, or allow it to only move horizontally/vertically.
- `stop()` will undo the effect of the previous call and stop the camera at its current position.
- `moveBy()` can be used to move the camera by the specified offset. If the camera was already following another component or moving, those behaviors would be automatically cancelled.
- `moveTo()` can be used to move the camera to the designated point on the world map. If the camera was already following another component or moving towards another point, those behaviors would be automatically cancelled.
- `setBounds()` allows you to add limits to where the camera is allowed to go. These limits are in the form of a `Shape`, which is commonly a rectangle, but can also be any other shape.

### visibleWorldRect¶

The camera exposes property `visibleWorldRect`, which is a rect that describes the world’s region which is currently visible through the camera. This region can be used in order to avoid rendering components that are out of view, or updating objects that are far away from the player less frequently.

The `visibleWorldRect` is a cached property, and it updates automatically whenever the camera moves or the viewport changes its size.

### canSee¶

The `CameraComponent` has a method called `canSee` which can be used to check if a component is visible from the camera point of view. This is useful for example to cull components that are not in view.

```
if (!camera.canSee(component)) {
   component.removeFromParent(); // Cull the component
}
```

### Post processing¶

[Post processing](https://docs.flame-engine.org/latest/flame/rendering/post_processing.html) is a technique used in game development to apply visual effects to a component tree after it has been rendered. This can be added to the camera via the `postProcess` property.

```
camera.postProcess = PostProcessGroup(
  postProcesses: [
    PostProcessSequentialGroup(
      postProcesses: [
        FireflyPostProcess(),
        WaterPostProcess(),
      ],
    ),
    ForegroundFogPostProcess(),
  ],
);
```

Read more about this on [Post processing](https://docs.flame-engine.org/latest/flame/rendering/post_processing.html).
</content>
</page>

<page>
  <title>Game Widget — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/game_widget.html</url>
  <content># Game Widget¶

The `GameWidget` is the bridge between Flutter and Flame. Since Flame games are not Flutter widgets by themselves, the `GameWidget` wraps a `Game` instance and places it into the Flutter widget tree, just like any other [widget](https://docs.flutter.dev/get-started/fundamentals/widgets). This lets you combine a full-screen game with Flutter UI elements (navigation bars, overlays, dialogs) or embed a game as only part of your app’s layout.

class GameWidget<T extends Game>

extends StatefulWidget

The **GameWidget** is a Flutter widget which is used to insert a `Game` instance into the Flutter widget tree.

The `GameWidget` is sufficiently feature-rich to run as the root of your Flutter application. Thus, the simplest way to use `GameWidget` is like this:

```
void main() {
  runApp(
    GameWidget(game: MyGame()),
  );
}
```

At the same time, `GameWidget` is a regular Flutter widget, and can be inserted arbitrarily deep into the widget tree, including the possibility of having multiple `GameWidget`s within a single app.

The layout behavior of this widget is that it will expand to fill all available space. Thus, when used as a root widget it will make the app full-screen. Inside any other layout widget it will take as much space as possible.

In addition to hosting a `Game` instance, the `GameWidget` also provides some structural support, with the following features:

- `loadingBuilder` to display something while the game is loading;
- `errorBuilder` shown if the game throws an error;
- `backgroundBuilder` to draw some decoration behind the game;
- `overlayBuilderMap` to draw one or more widgets on top of the game.

It should be noted that `GameWidget` does not clip the content of its canvas, which means the game can potentially draw outside of its boundaries (not always, depending on which camera is used). If this is not desired, then consider wrapping the widget in Flutter’s [ClipRect](https://api.flutter.dev/flutter/widgets/ClipRect-class.html).

## Constructors¶

GameWidget({required this.game, this.textDirection, this.loadingBuilder, this.errorBuilder, this.backgroundBuilder, this.overlayBuilderMap, this.initialActiveOverlays, this.focusNode, this.autofocus = true, this.mouseCursor, this.addRepaintBoundary = true, this.behavior = HitTestBehavior.opaque, super.key})

Renders the provided `game` instance.

GameWidget.controlled({required this.gameFactory, this.textDirection, this.loadingBuilder, this.errorBuilder, this.backgroundBuilder, this.overlayBuilderMap, this.initialActiveOverlays, this.focusNode, this.autofocus = true, this.mouseCursor, this.addRepaintBoundary = true, this.behavior = HitTestBehavior.opaque, super.key})

A `GameWidget` which will create and own a `Game` instance, using the provided `gameFactory`.

This constructor can be useful when you want to put `GameWidget` into another widget, but would like to avoid the need to store the game’s instance yourself. For example:

```
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: GameWidget.controlled(
        gameFactory: MyGame.new,
      ),
    );
  }
}
```

## Properties¶

game : T?

The game instance which this widget will render, if it was provided with the default constructor. Otherwise, if the `GameWidget.controlled` constructor was used, this will always be `null`.

gameFactory : GameFactory<T>?

A function that creates a `Game` that this widget will render.

textDirection : TextDirection?

The text direction to be used in text elements in a game.

loadingBuilder : GameLoadingWidgetBuilder?

Builder to provide a widget which will be displayed while the game is loading. By default this is an empty `Container`.

errorBuilder : GameErrorWidgetBuilder?

If set, errors during the game loading will be caught and this widget will be shown. If not provided, errors are propagated normally.

backgroundBuilder : WidgetBuilder?

Builder to provide a widget tree to be built between the game elements and the background color provided via `Game.backgroundColor`.

overlayBuilderMap : Map<String, OverlayWidgetBuilder<T>>?

A collection of widgets that can be displayed over the game’s surface. These widgets can be turned on-and-off dynamically from within the game via the `Game.overlays` property.

```
void main() {
  runApp(
    GameWidget(
      game: MyGame(),
      overlayBuilderMap: {
        'PauseMenu': (context, game) {
          return Container(
            color: const Color(0xFF000000),
            child: Text('A pause menu'),
          );
        },
      },
    ),
  );
}
```

initialActiveOverlays : List<String>?

The list of overlays that will be shown when the game starts (but after it was loaded).

focusNode : FocusNode?

The [FocusNode](https://api.flutter.dev/flutter/widgets/FocusNode-class.html) to control the games focus to receive event inputs. If omitted, defaults to an internally controlled focus node.

autofocus : bool

Whether the `focusNode` requests focus once the game is mounted. Defaults to true.

mouseCursor : MouseCursor?

The shape of the mouse cursor when it is hovering over the game canvas. This property can be changed dynamically via `Game.mouseCursor`.

addRepaintBoundary : bool

Whether the game should assume the behavior of a [RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html), defaults to `true`.

behavior : HitTestBehavior

How the game widget behaves during hit testing.

- `HitTestBehavior.opaque` (default): the game absorbs all pointer events on its surface, preventing widgets behind it from receiving them.
- `HitTestBehavior.deferToChild`: the game only intercepts events at positions where a component with event callbacks (e.g. `TapCallbacks`) exists. Events at other positions pass through to widgets behind.
- `HitTestBehavior.translucent`: the game receives events where it has event-handling components, but always allows widgets behind it to be hit-tested as well.

## Hit Test Behavior¶

The `behavior` argument controls how the `GameWidget` participates in Flutter’s hit testing. This determines whether pointer events (taps, drags, etc.) are absorbed by the game or allowed to pass through to widgets underneath it in the widget tree.

There are three possible values from Flutter’s `HitTestBehavior`:

- **`HitTestBehavior.opaque`** (default): The game absorbs all pointer events on its entire surface, preventing any widgets behind it from receiving them. This is the classic behavior where the game acts as a solid layer.
- **`HitTestBehavior.deferToChild`**: The game only intercepts events at positions where a component with event callbacks (e.g. `TapCallbacks`) exists. Events at positions with no interactive components pass through to widgets behind the `GameWidget`. This is useful when layering a game on top of Flutter UI and you want the underlying widgets to remain interactive in areas the game doesn’t need to handle.
- **`HitTestBehavior.translucent`**: The game receives events where it has event-handling components, but always allows widgets behind it to be hit-tested as well. Both the game and the widgets behind it can receive the same event.

### Allowing taps to pass through¶

A common use case is placing a `GameWidget` on top of other Flutter widgets in a `Stack`. By default, the game will block all interaction with the widgets underneath. To let taps pass through to those widgets, set `behavior` to `HitTestBehavior.deferToChild`:

```
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Flutter widgets underneath
      Center(
        child: ElevatedButton(
          onPressed: () => print('Button tapped!'),
          child: const Text('Tap me'),
        ),
      ),
      // Game on top, letting taps pass through
      Positioned.fill(
        child: GameWidget(
          game: MyGame(),
          behavior: HitTestBehavior.deferToChild,
        ),
      ),
    ],
  );
}
```

In this setup, tapping an area with no interactive game components will reach the `ElevatedButton` behind the game. Tapping a game component that uses `TapCallbacks` will be handled by the game instead.

Note

When using `deferToChild` or `translucent`, `FlameGame` determines whether a position has an interactive component by traversing the component tree via `componentsAtPoint`, and treating any component that implements `PointerInputCallbacks` as interactive. Games that directly extend the low-level `Game` class report a hit on their entire surface by default; override `containsEventHandlerAt` to customize this.
</content>
</page>

<page>
  <title>FlameGame — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/game.html</url>
  <content># FlameGame¶

Every game needs a central object that owns the game loop, the continuous cycle of updating state and rendering frames that drives all real-time games. In Flame, `FlameGame` fills that role while also serving as the root of the component tree. If you are familiar with Flutter, think of `FlameGame` as the equivalent of `MaterialApp`: the top-level entry point that everything else hangs off of.

The base of almost all Flame games is the `FlameGame` class. It is the root of your component tree. We refer to this component-based system as the Flame Component System (FCS). Throughout the documentation, FCS is used to reference this system.

The `FlameGame` class implements a `Component` based `Game`. It has a tree of components and calls the `update` and `render` methods of all components that have been added to the game.

Components can be added to the `FlameGame` directly in the constructor with the named `children` argument, or from anywhere else with the `add`/`addAll` methods. Most of the time however, you want to add your children to a `World`, the default world exists under `FlameGame.world` and you add components to it just like you would to any other component.

A simple `FlameGame` implementation that adds two components, one in `onLoad` and one directly in the constructor can look like this:

```
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

/// A component that renders the crate sprite, with a 16 x 16 size.
class MyCrate extends SpriteComponent {
  MyCrate() : super(size: Vector2.all(16));

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('crate.png');
  }
}

class MyWorld extends World {
  @override
  Future<void> onLoad() async {
    await add(MyCrate());
  }
}

void main() {
  final myGame = FlameGame(world: MyWorld());
  runApp(
    GameWidget(game: myGame),
  );
}
```

## Custom World type¶

`FlameGame` has a generic type parameter `W` that defaults to `World`. By specifying a custom world type, the `world` getter on your game will return your specific world type directly, without needing to cast it.

This is useful when you have a custom `World` subclass and want to access its properties or methods from within your game class:

```
class MyWorld extends World {
  int score = 0;
}

class MyGame extends FlameGame<MyWorld> {
  MyGame() : super(world: MyWorld());

  void incrementScore() {
    // No cast needed, `world` is already typed as `MyWorld`.
    world.score++;
  }
}
```

When using this generic parameter, you **must** pass a matching world instance to the `super` constructor. If the generic type is specified but no world is provided, a runtime assertion error will be thrown.

Note

If you instantiate your game in a build method your game will be rebuilt every time the Flutter tree gets rebuilt, which usually is more often than you’d like. To avoid this, you can either create an instance of your game first and reference it within your widget structure or use the `GameWidget.controlled` constructor.

To remove components from the list on a `FlameGame` the `remove` or `removeAll` methods can be used. The first can be used if you just want to remove one component, and the second can be used when you want to remove a list of components. These methods exist on all `Component`s, including the `World`.

The `FlameGame` has a built-in `World` called `world` and a `CameraComponent` instance called `camera`, you can read more about those in the [Camera section](https://docs.flame-engine.org/latest/flame/camera.html).

## Game Loop¶

The `GameLoop` module is a simple abstraction of the game loop concept. Basically, most games are built upon two methods:

- The render method takes the canvas for drawing the current state of the game.
- The update method receives the delta time in seconds since the last update and allows you to move to the next state.

The `GameLoop` is used by all of Flame’s `Game` implementations.

## Resizing¶

Every time the game needs to be resized, for example when the orientation is changed, `FlameGame` will call all of the `Component`’s `onGameResize` methods and it will also pass this information to the camera and viewport.

The `FlameGame.camera` controls which point in the coordinate space that should be at the anchor of your viewfinder, [0,0] is in the center (`Anchor.center`) of the viewport by default.

## Lifecycle¶

The `FlameGame` lifecycle callbacks, `onLoad`, `render`, etc. are called in the following sequence:

%%{init: { 'theme': 'dark' } }%% graph TD %% Node Color %% classDef default fill:#282828,stroke:#F6BE00,stroke-width:2px; classDef lightYellow fill:#523F00,stroke-width:2px; classDef yellow fill:#F6BE00,color:#000000; classDef green fill:#00523F,stroke:#F6BE00,stroke-width:2px; %% Nodes %% x(Runs Each Tick) y(Runs On Add & Resize):::lightYellow z(Runs Once):::yellow w(Runs On Hot Reload):::green

%%{init: { 'theme': 'dark' } }%% graph LR %% Node Color %% classDef default fill:#282828,stroke:#F6BE00,stroke-width:2px; classDef lightYellow fill:#523F00,stroke-width:2px; classDef yellow fill:#F6BE00,color:#000000; classDef green fill:#00523F,stroke:#F6BE00,stroke-width:2px; %% Nodes %% A(onGameResize):::lightYellow B(onLoad):::yellow C(onMount):::yellow D(update) E(render) F(onRemove):::yellow G(onHotReload):::green %% Flow %% A-->B B-->C C-->D D-->E E-->D E-. If removed .->F F-. If re-parented .->A D-. If hot reloaded .->G G-.->D

When a `FlameGame` is first added to a `GameWidget` the lifecycle methods `onGameResize`, `onLoad` and `onMount` will be called in that order. Then `update` and `render` are called in sequence for every game tick. If the `FlameGame` is removed from the `GameWidget` then `onRemove` is called. If the `FlameGame` is added to a new `GameWidget` the sequence repeats from `onGameResize`.

Note

The order of `onGameResize` and `onLoad` are reversed from that of other `Component`s. This is to allow game element sizes to be calculated before resources are loaded or generated.

The `onRemove` callback can be used to clean up children and cached data:

```
  @override
  void onRemove() {
    // Optional based on your game needs.
    removeAll(children);
    processLifecycleEvents();
    Flame.images.clearCache();
    Flame.assets.clearCache();
    // Any other code that you want to run when the game is removed.
  }
```

Note

Clean-up of children and resources in a `FlameGame` is not done automatically and must be explicitly added to the `onRemove` call.

### onHotReload¶

When Flutter’s hot reload is triggered (debug mode only), the `GameWidget` calls `onHotReload` on the `FlameGame`, which automatically propagates the notification to every component in the tree that is loading or loaded. Override this method on any component to reload assets, refresh cached values, or react to source code changes during development:

```
class MyGame extends FlameGame {
  @override
  void onHotReload() {
    // Refresh game-level state affected by code changes.
    super.onHotReload();
  }
}
```

Note

`onHotReload` is only called in debug mode. Components that are still in the lifecycle queue (loading but not yet mounted) also receive the notification. Always call `super.onHotReload()` so the event continues to propagate to children.

### dispose()¶

As a convenience, `FlameGame` provides a `dispose()` method that handles all of the common cleanup in a single call:

```
  game.dispose();
```

This removes all children from the game (triggering `onRemove` on every component in the tree), processes all pending lifecycle events, and clears the `images` and `assets` caches.

The difference between `dispose()` and `onRemove` is that `dispose()` is a method you call explicitly to perform cleanup, while `onRemove` is a lifecycle callback that is invoked automatically when the game is removed from a `GameWidget`. You can use `dispose()` from within `onRemove`, or call it independently whenever you need to reset the game state.

## Debug mode¶

Flame’s `FlameGame` class provides a variable called `debugMode`, which by default is `false`. It can, however, be set to `true` to enable debug features for the components of the game. **Be aware** that the value of this variable is passed through to its components when they are added to the game, so if you change the `debugMode` at runtime, it will not affect already added components by default.

To read more about the `debugMode` on Flame, please refer to the [Debug Docs](https://docs.flame-engine.org/latest/flame/other/debug.html)

## Change background color¶

To change the background color of your `FlameGame` you have to override `backgroundColor()`.

In the following example, the background color is set to be fully transparent, so that you can see the widgets that are behind the `GameWidget`. The default is opaque black.

```
class MyGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0x00000000);
}
```

Note that the background color can’t change dynamically while the game is running, but you could just draw a background that covers the whole canvas if you would want it to change dynamically.

## SingleGameInstance mixin¶

An optional mixin `SingleGameInstance` can be applied to your game if you are making a single-game application. This is a common scenario when building games: there is a single full-screen `GameWidget` that hosts a single `Game` instance.

Adding this mixin provides performance advantages in certain scenarios. In particular, a component’s `onLoad` method is guaranteed to start when that component is added to its parent, even if the parent is not yet mounted itself. Consequently, `await`-ing on `parent.add(component)` is guaranteed to always finish loading the component.

Using this mixin is simple:

```
class MyGame extends FlameGame with SingleGameInstance {
  // ...
}
```

## Low-level Game API¶

%%{init: { 'theme': 'dark' } }%% graph TD %% Node Color %% classDef default fill:#282828,stroke:#F6BE00,stroke-width:2px; classDef yellow fill:#F6BE00,color:#000; %% Nodes %% z(Abstract Class):::yellow x(Normal Class)

%%{init: { 'theme': 'dark' } }%% graph BT %% Node Color %% classDef default fill:#282828,stroke:#F6BE00,stroke-width:2px; classDef yellow fill:#F6BE00,color:#000; %% Nodes %% B(Game):::yellow C(FlameGame) D(Component) E(Other Components) F(GameWidget) %% Flow %% F-- Wants -->B C-- Extends -->D E-- Extends -->D C-- With -->B

The abstract `Game` class is a low-level API that can be used when you want to implement the functionality of how the game engine should be structured. `Game` does not implement any `update` or `render` function for example.

The class also has the lifecycle methods `onLoad`, `onMount` and `onRemove` in it, which are called from the `GameWidget` (or another parent) when the game is loaded + mounted, or removed. `onLoad` is only called the first time the class is added to a parent, but `onMount` (which is called after `onLoad`) is called every time it is added to a new parent. `onRemove` is called when the class is removed from a parent.

Note

The `Game` class allows for more freedom of how to implement things, but you are also missing out on all of the built-in features in Flame if you use it.

An example of what a `Game` implementation could look like:

```
class MyGameSubClass extends Game {
  @override
  void render(Canvas canvas) {
    // ...
  }

  @override
  void update(double dt) {
    // ...
  }
}

void main() {
  final myGame = MyGameSubClass();
  runApp(
    GameWidget(
      game: myGame,
    )
  );
}
```

## Pause/Resuming/Stepping game execution¶

A Flame `Game` can be paused and resumed in two ways:

- With the use of the `pauseEngine` and `resumeEngine` methods.
- By changing the `paused` attribute.

When pausing a `Game`, the `GameLoop` is effectively paused, meaning that no updates or new renders will happen until it is resumed.

While the game is paused, it is possible to advance it frame by frame using the `stepEngine` method. It might not be very useful in the final game, but it can be very helpful for inspecting game state step by step during the development cycle.

### Backgrounding¶

The game will be automatically paused when the app is sent to the background, and resumed when it comes back to the foreground. This behavior can be disabled by setting `pauseWhenBackgrounded` to `false`.

```
class MyGame extends FlameGame {
  MyGame() {
    pauseWhenBackgrounded = false;
  }
}
```

This flag currently only works on Android and iOS.

## HasPerformanceTracker mixin¶

While optimizing a game, it can be useful to track the time it took for the game to update and render each frame. This data can help in detecting areas of the code that are running hot. It can also help in detecting visual areas of the game that are taking the most time to render.

To get the update and render times, just add the `HasPerformanceTracker` mixin to the game class.

```
class MyGame extends FlameGame with HasPerformanceTracker {
  // access `updateTime` and `renderTime` getters.
}
```
</content>
</page>