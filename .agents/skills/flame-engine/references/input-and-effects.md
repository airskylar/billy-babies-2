<page>
  <title>Inputs — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/inputs/inputs.html</url>
  <content># Inputs¶

Games are interactive by nature, so handling player input is essential. Flame provides input handling that works on all platforms Flutter supports: touch on mobile, mouse and keyboard on desktop, and pointer events on the web. These APIs are designed as mixins that you add to your components, so each component can independently decide which input events it cares about. This is similar to how Flutter’s [GestureDetector](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html) works, but adapted for Flame’s component tree.

- [Tap Events](https://docs.flame-engine.org/latest/flame/inputs/tap_events.html)
- [Drag Events](https://docs.flame-engine.org/latest/flame/inputs/drag_events.html)
- [Scale Events](https://docs.flame-engine.org/latest/flame/inputs/scale_events.html)
- [Long Press Events](https://docs.flame-engine.org/latest/flame/inputs/long_press_events.html)
- [Gesture Input](https://docs.flame-engine.org/latest/flame/inputs/gesture_input.html)
- [Keyboard Input](https://docs.flame-engine.org/latest/flame/inputs/keyboard_input.html)
- [Other Inputs and Helpers](https://docs.flame-engine.org/latest/flame/inputs/other_inputs.html)
- [Pointer Events](https://docs.flame-engine.org/latest/flame/inputs/pointer_events.html)
- [Hardware Keyboard Detector](https://docs.flame-engine.org/latest/flame/inputs/hardware_keyboard_detector.html)
</content>
</page>

<page>
  <title>Long Press Events — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/inputs/long_press_events.html</url>
  <content># Long Press Events¶

**Long press events** occur when the user presses and holds a pointer (finger or mouse) on a component for a sustained period. This gesture is commonly used for context menus, drag-to-move behaviors, or any action that requires a deliberate, sustained touch.

For components that should respond to long press events, add the `LongPressCallbacks` mixin.

- This mixin adds four overridable methods to your component: `onLongPressStart`, `onLongPressMoveUpdate`, `onLongPressEnd`, and `onLongPressCancel`.
- By default, `isLongPressing` is tracked automatically and can be accessed by your component.
- The component must implement `containsLocalPoint()` (already implemented in `PositionComponent`, so most of the time you don’t need to do anything here). This method allows Flame to know whether the event occurred within the component or not. You can override it to `true` to receive all long press events regardless of position.

```
class MyComponent extends PositionComponent with LongPressCallbacks {
  MyComponent() : super(size: Vector2.all(32));

  @override
  void onLongPressStart(LongPressStartEvent event) {
    super.onLongPressStart(event); // handles internal updating of isLongPressing
    // Do something when the long press is recognized
  }

  @override
  void onLongPressEnd(LongPressEndEvent event) {
    super.onLongPressEnd(event); // handles internal updating of isLongPressing
    // Do something when the long press finishes
  }
}
```

## Long press anatomy¶

### onLongPressStart¶

The first event in a long press sequence. It fires once the pointer has been held down long enough to be recognized as a long press. By default, Flutter’s `LongPressGestureRecognizer` uses `kLongPressTimeout` (500ms) as a long press definition.

The `LongPressStartEvent` provides the position of the contact point in multiple coordinate systems: `devicePosition` (device coordinates), `canvasPosition` (game widget coordinates), and `localPosition` (component-local coordinates).

Any component that receives `onLongPressStart` will later receive either `onLongPressEnd` (on success) or `onLongPressCancel` (if cancelled). Move updates may also be delivered in between.

Calling `super.onLongPressStart(event)` sets `isLongPressing` to `true`.

### onLongPressMoveUpdate¶

Fires continuously as the user moves their finger during an active long press. This event is only delivered to components that received the initial `onLongPressStart`.

The `LongPressMoveUpdateEvent` is a `DisplacementEvent` that provides a frame-to-frame delta, just like `DragUpdateEvent`. That means you can use `localDelta` to move a component following the pointer (it correctly accounts for camera zoom and component transforms). The event also carries `offsetFromOrigin` for the total displacement since the gesture started.

### onLongPressEnd¶

Fires when the user lifts their pointer after a long press. The `LongPressEndEvent` includes the final position and the `velocity` of the pointer at the moment of release.

Calling `super.onLongPressEnd(event)` sets `isLongPressing` to `false`.

### onLongPressCancel¶

Fires if the gesture is interrupted before completing (e.g. by a competing gesture recognizer).

Calling `super.onLongPressCancel(event)` sets `isLongPressing` to `false`.

## Mixins¶

### LongPressCallbacks¶

The `LongPressCallbacks` mixin can be added to any `Component` for that component to start receiving long press events.

This mixin adds methods `onLongPressStart`, `onLongPressMoveUpdate`, `onLongPressEnd`, and `onLongPressCancel` to the component. Override them to implement behavior.

A component will only receive long press events that originate *within* that component, as judged by the `containsLocalPoint()` function. The commonly-used `PositionComponent` class provides such an implementation based on its `size` property.

The mixin also provides an `isLongPressing` property that tracks whether a long press gesture is currently active on the component. This is managed automatically when you call `super` in `onLongPressStart`, `onLongPressEnd`, and `onLongPressCancel`.

```
class LongPressSquare extends RectangleComponent with LongPressCallbacks {
  @override
  void onLongPressStart(LongPressStartEvent event) {
    super.onLongPressStart(event);
    paint.color = Colors.red;
  }

  @override
  void onLongPressMoveUpdate(LongPressMoveUpdateEvent event) {
    position += event.localDelta;
  }

  @override
  void onLongPressEnd(LongPressEndEvent event) {
    super.onLongPressEnd(event);
    paint.color = Colors.blue;
  }
}
```
</content>
</page>

<page>
  <title>Keyboard Input — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/inputs/keyboard_input.html</url>
  <content># Keyboard Input¶

This includes documentation for keyboard inputs.

For other input documents, see also:

- [Gesture Input](https://docs.flame-engine.org/latest/flame/inputs/gesture_input.html): for mouse and touch pointer gestures
- [Other Inputs](https://docs.flame-engine.org/latest/flame/inputs/other_inputs.html): For joysticks, game pads, etc.

## Intro¶

The keyboard API on flame relies on the [Flutter’s Focus widget](https://api.flutter.dev/flutter/widgets/Focus-class.html).

To customize focus behavior, see Controlling focus.

There are two ways a game can react to key strokes; at the game level and at a component level. For each we have a mixin that can me added to a `Game` or `Component` class.

### Receive keyboard events in a game level¶

To make a `Game` sub class sensitive to key stroke, mix it with `KeyboardEvents`.

After that, it will be possible to override an `onKeyEvent` method.

This method receives two parameters, first the [`KeyEvent`](https://api.flutter.dev/flutter/services/KeyEvent-class.html) that triggers the callback in the first place. The second is a set of the currently pressed [`LogicalKeyboardKey`](https://api.flutter.dev/flutter/services/LogicalKeyboardKey-class.html).

The return value is a [`KeyEventResult`](https://api.flutter.dev/flutter/widgets/KeyEventResult.html).

`KeyEventResult.handled` will tell the framework that the key stroke was resolved inside of Flame and skip any other keyboard handler widgets apart of `GameWidget`.

`KeyEventResult.ignored` will tell the framework to keep testing this event in any other keyboard handler widget apart of `GameWidget`. If the event is not resolved by any handler, the framework will trigger `SystemSoundType.alert`.

`KeyEventResult.skipRemainingHandlers` is very similar to `.ignored`, apart from the fact that will skip any other handler widget and will straight up play the alert sound.

Minimal example:

```
class MyGame extends FlameGame with KeyboardEvents {
  // ...
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isKeyDown = event is KeyDownEvent;

    final isSpace = keysPressed.contains(LogicalKeyboardKey.space);

    if (isSpace && isKeyDown) {
      if (keysPressed.contains(LogicalKeyboardKey.altLeft) ||
          keysPressed.contains(LogicalKeyboardKey.altRight)) {
        this.shootHarder();
      } else {
        this.shoot();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
```

### Receive keyboard events in a component level¶

To receive keyboard events directly in components, there is the mixin `KeyboardHandler`.

Similarly to `TapCallbacks` and `DragCallbacks`, `KeyboardHandler` can be mixed into any subclass of `Component`.

KeyboardHandlers must only be added to games that are mixed with `HasKeyboardHandlerComponents`.

> ⚠️ Note: If `HasKeyboardHandlerComponents` is used, you must remove `KeyboardEvents` from the game mixin list to avoid conflicts.

After applying `KeyboardHandler`, it will be possible to override an `onKeyEvent` method.

This method receives two parameters. First the [`KeyEvent`](https://api.flutter.dev/flutter/services/KeyEvent-class.html) that triggered the callback in the first place. The second is a set of the currently pressed [`LogicalKeyboardKey`](https://api.flutter.dev/flutter/services/LogicalKeyboardKey-class.html)s.

The returned value should be `true` to allow the continuous propagation of the key event among other components. To not allow any other component to receive the event, return `false`.

Flame also provides a default implementation called `KeyboardListenerComponent` which can be used to handle keyboard events. Like any other component, it can be added as a child to a `FlameGame` or another `Component`:

For example, imagine a `PositionComponent` which has methods to move on the X and Y axis, then the following code could be used to bind those methods to key events:

```
add(
  KeyboardListenerComponent(
    keyUp: {
      LogicalKeyboardKey.keyA: (keysPressed) { ... },
      LogicalKeyboardKey.keyD: (keysPressed) { ... },
      LogicalKeyboardKey.keyW: (keysPressed) { ... },
      LogicalKeyboardKey.keyS: (keysPressed) { ... },
    },
    keyDown: {
      LogicalKeyboardKey.keyA: (keysPressed) { ... },
      LogicalKeyboardKey.keyD: (keysPressed) { ... },
      LogicalKeyboardKey.keyW: (keysPressed) { ... },
      LogicalKeyboardKey.keyS: (keysPressed) { ... },
    },
  ),
);
```

### Controlling focus¶

On the widget level, it is possible to use the [`FocusNode`](https://api.flutter.dev/flutter/widgets/FocusNode-class.html) API to control whether the game is focused or not.

`GameWidget` has an optional `focusNode` parameter that allow its focus to be controlled externally.

By default `GameWidget` has its `autofocus` set to true, which means it will get focused once it is mounted. To override that behavior, set `autofocus` to false.

For a more complete example, see the [keyboard input example](https://github.com/flame-engine/flame/blob/main/examples/lib/stories/input/keyboard_example.dart).
</content>
</page>

<page>
  <title>Drag Events — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/inputs/drag_events.html</url>
  <content># Drag Events¶

**Drag events** occur when the user moves their finger across the screen of the device, or when they move the mouse while holding its button down.

Multiple drag events can occur at the same time, if the user is using multiple fingers. Such cases will be handled correctly by Flame, and you can even keep track of the events by using their `pointerId` property.

For those components that you want to respond to drags, add the `DragCallbacks` mixin.

- This mixin adds four overridable methods to your component: `onDragStart`, `onDragUpdate`, `onDragEnd`, and `onDragCancel`. By default, these methods do nothing; they need to be overridden in order to perform any function.
- In addition, the component must implement the `containsLocalPoint()` method (already implemented in `PositionComponent`, so most of the time you don’t need to do anything here). This method allows Flame to know whether the event occurred within the component or not.

```
class MyComponent extends PositionComponent with DragCallbacks {
  MyComponent() : super(size: Vector2(180, 120));

   @override
   void onDragStart(DragStartEvent event) {
     // Do something in response to a drag event
   }
}
```

## Demo¶

In this example you can use drag gestures to either drag star-like shapes across the screen, or to draw curves inside the magenta rectangle.

drag_events.dart

```
  1import 'dart:math';
  2
  3import 'package:flame/components.dart';
  4import 'package:flame/events.dart';
  5import 'package:flame/game.dart';
  6import 'package:flame/geometry.dart';
  7import 'package:flutter/rendering.dart';
  8
  9class DragEventsGame extends FlameGame {
 10  @override
 11  Future<void> onLoad() async {
 12    addAll([
 13      DragTarget(),
 14      Star(
 15        n: 5,
 16        radius1: 40,
 17        radius2: 20,
 18        sharpness: 0.2,
 19        color: const Color(0xffbae5ad),
 20        position: Vector2(70, 70),
 21      ),
 22      Star(
 23        n: 3,
 24        radius1: 50,
 25        radius2: 40,
 26        sharpness: 0.3,
 27        color: const Color(0xff6ecbe5),
 28        position: Vector2(70, 160),
 29      ),
 30      Star(
 31        n: 12,
 32        radius1: 10,
 33        radius2: 75,
 34        sharpness: 1.3,
 35        color: const Color(0xfff6df6a),
 36        position: Vector2(70, 270),
 37      ),
 38      Star(
 39        n: 10,
 40        radius1: 20,
 41        radius2: 17,
 42        sharpness: 0.85,
 43        color: const Color(0xfff82a4b),
 44        position: Vector2(110, 110),
 45      ),
 46    ]);
 47  }
 48}
 49
 50/// This component is the pink-ish rectangle in the center of the game window.
 51/// It uses the [DragCallbacks] mixin in order to receive drag events.
 52class DragTarget extends PositionComponent with DragCallbacks {
 53  DragTarget() : super(anchor: Anchor.center);
 54
 55  final _rectPaint = Paint()..color = const Color(0x88AC54BF);
 56
 57  /// We will store all current circles into this map, keyed by the `pointerId`
 58  /// of the event that created the circle.
 59  final Map<int, Trail> _trails = {};
 60
 61  @override
 62  void onGameResize(Vector2 size) {
 63    super.onGameResize(size);
 64    this.size = size - Vector2(100, 75);
 65    if (this.size.x < 100 || this.size.y < 100) {
 66      this.size = size * 0.9;
 67    }
 68    position = size / 2;
 69  }
 70
 71  @override
 72  void render(Canvas canvas) {
 73    canvas.drawRect(size.toRect(), _rectPaint);
 74  }
 75
 76  @override
 77  void onDragStart(DragStartEvent event) {
 78    super.onDragStart(event);
 79    final trail = Trail(event.localPosition);
 80    _trails[event.pointerId] = trail;
 81    add(trail);
 82  }
 83
 84  @override
 85  void onDragUpdate(DragUpdateEvent event) {
 86    _trails[event.pointerId]!.addPoint(event.localEndPosition);
 87  }
 88
 89  @override
 90  void onDragEnd(DragEndEvent event) {
 91    super.onDragEnd(event);
 92    _trails.remove(event.pointerId)!.end();
 93  }
 94
 95  @override
 96  void onDragCancel(DragCancelEvent event) {
 97    super.onDragCancel(event);
 98    _trails.remove(event.pointerId)!.cancel();
 99  }
100}
101
102class Trail extends Component {
103  Trail(Vector2 origin)
104    : _paths = [Path()..moveTo(origin.x, origin.y)],
105      _opacities = [1],
106      _lastPoint = origin.clone(),
107      _color = HSLColor.fromAHSL(
108        1,
109        random.nextDouble() * 360,
110        1,
111        0.8,
112      ).toColor();
113
114  final List<Path> _paths;
115  final List<double> _opacities;
116  Color _color;
117  late final _linePaint = Paint()..style = PaintingStyle.stroke;
118  late final _circlePaint = Paint()..color = _color;
119  bool _released = false;
120  double _timer = 0;
121  final _vanishInterval = 0.03;
122  final Vector2 _lastPoint;
123
124  static final random = Random();
125  static const lineWidth = 10.0;
126
127  @override
128  void render(Canvas canvas) {
129    assert(_paths.length == _opacities.length);
130    for (var i = 0; i < _paths.length; i++) {
131      final path = _paths[i];
132      final opacity = _opacities[i];
133      if (opacity > 0) {
134        _linePaint.color = _color.withValues(alpha: opacity);
135        _linePaint.strokeWidth = lineWidth * opacity;
136        canvas.drawPath(path, _linePaint);
137      }
138    }
139    canvas.drawCircle(
140      _lastPoint.toOffset(),
141      (lineWidth - 2) * _opacities.last + 2,
142      _circlePaint,
143    );
144  }
145
146  @override
147  void update(double dt) {
148    assert(_paths.length == _opacities.length);
149    _timer += dt;
150    while (_timer > _vanishInterval) {
151      _timer -= _vanishInterval;
152      for (var i = 0; i < _paths.length; i++) {
153        _opacities[i] -= 0.01;
154        if (_opacities[i] <= 0) {
155          _paths[i].reset();
156        }
157      }
158      if (!_released) {
159        _paths.add(Path()..moveTo(_lastPoint.x, _lastPoint.y));
160        _opacities.add(1);
161      }
162    }
163    if (_opacities.last < 0) {
164      removeFromParent();
165    }
166  }
167
168  void addPoint(Vector2 point) {
169    if (!point.x.isNaN) {
170      for (final path in _paths) {
171        path.lineTo(point.x, point.y);
172      }
173      _lastPoint.setFrom(point);
174    }
175  }
176
177  void end() => _released = true;
178
179  void cancel() {
180    _released = true;
181    _color = const Color(0xFFFFFFFF);
182  }
183}
184
185class Star extends PositionComponent with DragCallbacks {
186  Star({
187    required int n,
188    required double radius1,
189    required double radius2,
190    required double sharpness,
191    required this.color,
192    super.position,
193  }) {
194    _path = Path()..moveTo(radius1, 0);
195    for (var i = 0; i < n; i++) {
196      final p1 = Vector2(radius2, 0)..rotate(tau / n * (i + sharpness));
197      final p2 = Vector2(radius2, 0)..rotate(tau / n * (i + 1 - sharpness));
198      final p3 = Vector2(radius1, 0)..rotate(tau / n * (i + 1));
199      _path.cubicTo(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
200    }
201    _path.close();
202  }
203
204  final Color color;
205  final Paint _paint = Paint();
206  final Paint _borderPaint = Paint()
207    ..color = const Color(0xFFffffff)
208    ..style = PaintingStyle.stroke
209    ..strokeWidth = 3;
210  final _shadowPaint = Paint()
211    ..color = const Color(0xFF000000)
212    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
213  late final Path _path;
214
215  @override
216  bool containsLocalPoint(Vector2 point) {
217    return _path.contains(point.toOffset());
218  }
219
220  @override
221  void render(Canvas canvas) {
222    if (isDragged) {
223      _paint.color = color.withValues(alpha: 0.5);
224      canvas.drawPath(_path, _paint);
225      canvas.drawPath(_path, _borderPaint);
226    } else {
227      _paint.color = color.withValues(alpha: 1);
228      canvas.drawPath(_path, _shadowPaint);
229      canvas.drawPath(_path, _paint);
230    }
231  }
232
233  @override
234  void onDragStart(DragStartEvent event) {
235    super.onDragStart(event);
236    priority = 10;
237  }
238
239  @override
240  void onDragEnd(DragEndEvent event) {
241    super.onDragEnd(event);
242    priority = 0;
243  }
244
245  @override
246  void onDragUpdate(DragUpdateEvent event) {
247    position += event.localDelta;
248  }
249}
```

## Drag anatomy¶

### onDragStart¶

This is the first event that occurs in a drag sequence. Usually, the event will be delivered to the topmost component at the point of touch with the `DragCallbacks` mixin. However, by setting the flag `event.continuePropagation` to true, you can allow the event to propagate to the components below.

The `DragStartEvent` object associated with this event will contain the coordinate of the point where the event has originated. This point is available in multiple coordinate system: `devicePosition` is given in the coordinate system of the entire device, `canvasPosition` is in the coordinate system of the game widget, and `localPosition` provides the position in the component’s local coordinate system.

Any component that receives `onDragStart` will later be receiving `onDragUpdate` and `onDragEnd` events as well.

A drag only starts once the pointer has moved further than the platform’s touch slop from the point where it went down, so a tap with a slightly wobbling finger is still delivered as a tap and not as a drag. When the drag starts, the movement accumulated before that point is delivered in the first `onDragUpdate`.

### onDragUpdate¶

This event is fired continuously as user drags their finger across the screen. It will not fire if the user is holding their finger still.

The default implementation delivers this event to all the components that received the previous `onDragStart` with the same pointer id. If the point of touch is still within the component, then `event.localPosition` will give the position of that point in the local coordinate system. However, if the user moves their finger away from the component, the property `event.localPosition` will return a point whose coordinates are NaNs. Likewise, the `event.renderingTrace` in this case will be empty. However, the `canvasPosition` and `devicePosition` properties of the event will be valid.

In addition, the `DragUpdateEvent` will contain `delta`, the amount the finger has moved since the previous `onDragUpdate`, or since the `onDragStart` if this is the first drag-update after a drag-start.

The `event.timestamp` property measures the time elapsed since the beginning of the drag. It can be used, for example, to compute the speed of the movement.

### onDragEnd¶

This event is fired when the user lifts their finger and thus stops the drag gesture. There is no position associated with this event.

### onDragCancel¶

The precise semantics when this event occurs is not clear, so we provide a default implementation which simply converts this event into an `onDragEnd`.

## Mixins¶

### DragCallbacks¶

The `DragCallbacks` mixin can be added to any `Component` in order for that component to start receiving drag events.

This mixin adds methods `onDragStart`, `onDragUpdate`, `onDragEnd`, and `onDragCancel` to the component, which by default don’t do anything, but can be overridden to implement any real functionality.

Another crucial detail is that a component will only receive drag events that originate *within* that component, as judged by the `containsLocalPoint()` function. The commonly-used `PositionComponent` class provides such an implementation based on its `size` property. Thus, if your component derives from a `PositionComponent`, then make sure that you set its size correctly. If, however, your component derives from the bare `Component`, then the `containsLocalPoint()` method must be implemented manually.

If your component is a part of a larger hierarchy, then it will only receive drag events if its ancestors have all implemented the `containsLocalPoint` correctly.

### isDragged¶

The `DragCallbacks` mixin provides an `isDragged` getter that returns `true` while the component is actively being dragged. This is set to `true` at `onDragStart` and back to `false` at `onDragEnd`. It can be used, for example, to change the component’s visual appearance during a drag.

## Combining with ScaleCallbacks¶

A component can use both `DragCallbacks` and `ScaleCallbacks` at the same time. When both mixins are present, single-finger gestures produce drag events and two-finger gestures produce both drag and scale events. This is useful for components that should be draggable with one finger and pinch-to-zoom or rotatable with two fingers.

```
class InteractiveRectangle extends RectangleComponent
    with ScaleCallbacks, DragCallbacks {

  double _initialAngle = 0;

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
  }

  @override
  void onScaleStart(ScaleStartEvent event) {
    super.onScaleStart(event);
    _initialAngle = angle;
  }

  @override
  void onScaleUpdate(ScaleUpdateEvent event) {
    angle = _initialAngle + event.rotation;
  }
}
```
</content>
</page>

<page>
  <title>Scale Events — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/inputs/scale_events.html</url>
  <content># Scale Events¶

**Scale events** occur when the user moves two fingers in a pinch in, or in a pinch out move. Only one single scale gesture can occur at the same time.

For those components that you want to respond to scale events, add the `ScaleCallbacks` mixin.

- This mixin adds three overridable methods to your component: `onScaleStart`, `onScaleUpdate`, `onScaleEnd`. By default, these methods do nothing; they need to be overridden in order to perform any function.
- In addition, the component must implement the `containsLocalPoint()` method (already implemented in `PositionComponent`, so most of the time you don’t need to do anything here). This method allows Flame to know whether the event occurred within the component or not.

```
class MyComponent extends PositionComponent with ScaleCallbacks {
  MyComponent() : super(size: Vector2(180, 120));

   @override
   void onScaleStart(ScaleStartEvent event) {
     // Do something in response to a scale event
   }
}
```

## Scale anatomy¶

### onScaleStart¶

This is the first event that occurs in a scale sequence. Usually, the event will be delivered to the topmost component at the focal point (the point at the center of the line formed by the two fingers) with the `ScaleCallbacks` mixin. However, by setting the flag `event.continuePropagation` to true, you can allow the event to propagate to the components below.

The `ScaleStartEvent` object associated with this event will contain the coordinate of the first focal point recognized by the scale gesture recognizer. This point is available in multiple coordinate system: `devicePosition` is given in the coordinate system of the entire device, `canvasPosition` is in the coordinate system of the game widget, and `localPosition` provides the position in the component’s local coordinate system.

Any component that receives `onScaleStart` will later be receiving `onScaleUpdate` and `onScaleEnd` events as well.

### onScaleUpdate¶

This event is fired continuously as user drags their finger across the screen. It will not fire if the user is holding their finger still.

The default implementation delivers this event to all the components that received the previous `onScaleStart`. If the point of touch is still within the component, then `event.localPosition` will give the position of that point in the local coordinate system. However, if the user moves their finger away from the component, the property `event.localPosition` will return a point whose coordinates are NaNs. Likewise, the `event.renderingTrace` in this case will be empty. However, the `canvasPosition` and `devicePosition` properties of the event will be valid.

In addition, the `ScaleUpdateEvent` will contain `focalPointDelta` – the amount the focal point has moved since the previous `onScaleUpdate`, or since the `onScaleStart` if this is the first scale-update after a scale- start.

The `event.timestamp` property measures the time elapsed since the beginning of the scale. It can be used, for example, to compute the speed of the movement.

The `event.rotation` property measures the angle of rotation in radians, between the line formed from the two fingers at the start, and the line formed when this event is called.

The `event.scale` property measures the ratio of length between the line formed from the two fingers at the start, and the line formed when this event is called.

### onScaleEnd¶

This event is fired when the user lifts their finger and thus stops the scale gesture. There is no position associated with this event.

## Mixins¶

### ScaleCallbacks¶

The `ScaleCallbacks` mixin can be added to any `Component` in order for that component to start receiving scale events.

This mixin adds methods `onScaleStart`, `onScaleUpdate`, `onScaleEnd` to the component, which by default don’t do anything, but can be overridden to implement any real functionality.

Another crucial detail is that a component will only receive scale events that originate *within* that component, as judged by the `containsLocalPoint()` function. The commonly-used `PositionComponent` class provides such an implementation based on its `size` property. Thus, if your component derives from a `PositionComponent`, then make sure that you set its size correctly. If, however, your component derives from the bare `Component`, then the `containsLocalPoint()` method must be implemented manually.

If your component is a part of a larger hierarchy, then it will only receive scale events if its ancestors have all implemented the `containsLocalPoint` correctly.

### isScaling¶

The `ScaleCallbacks` mixin provides an `isScaling` getter that returns `true` while the component is actively being scaled. This is set to `true` at the start of `onScaleStart` and back to `false` at `onScaleEnd`. It can be used, for example, to change the component’s visual appearance during a scale gesture.

### scaleThreshold¶

Scale events are not fired immediately when two fingers touch the screen. Instead, a small movement threshold must be crossed first. By default, the fingers must spread or pinch by at least 5% (a scale factor of 1.05) before `onScaleStart` is called. This prevents accidental scale gestures when the user simply places two fingers without intending to scale.

The threshold can be changed by accessing the `MultiDragScaleDispatcher` from your game and setting `scaleThreshold` before any `ScaleCallbacks` component mounts:

```
class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    final dispatcher = MultiDragScaleDispatcher()..scaleThreshold = 1.02;
    registerKey(const MultiDragScaleDispatcherKey(), dispatcher);
    add(dispatcher);
  }
}
```

A lower value makes the recognizer more sensitive (reacts to smaller pinch movements), while a higher value requires a more deliberate gesture before scale events fire.

## Combining with DragCallbacks¶

A component can use both `ScaleCallbacks` and `DragCallbacks` at the same time. When both mixins are present, single-finger gestures produce drag events and two-finger gestures produce both scale and drag events. This is useful for components that should be draggable with one finger and pinch-to-zoom or rotatable with two fingers.

```
class InteractiveRectangle extends RectangleComponent
    with ScaleCallbacks, DragCallbacks {

  double _initialAngle = 0;

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
  }

  @override
  void onScaleStart(ScaleStartEvent event) {
    super.onScaleStart(event);
    _initialAngle = angle;
  }

  @override
  void onScaleUpdate(ScaleUpdateEvent event) {
    angle = _initialAngle + event.rotation;
  }
}
```
</content>
</page>

<page>
  <title>Tap Events — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/inputs/tap_events.html</url>
  <content># Tap Events¶

Note

This document describes the new events API. The old (legacy) approach, which is still supported, is described in [Gesture Input](https://docs.flame-engine.org/latest/flame/inputs/gesture_input.html).

**Tap events** are one of the most basic methods of interaction with a Flame game. These events occur when the user touches the screen with a finger, or clicks with a mouse, or taps with a stylus. A tap can be “long”, but the finger isn’t supposed to move during the gesture. Thus, touching the screen, then moving the finger, and then releasing is not a tap but a drag. Similarly, clicking a mouse button while the mouse is moving will also be registered as a drag.

Multiple tap events can occur at the same time, especially if the user has multiple fingers. Such cases will be handled correctly by Flame, and you can even keep track of the events by using their `pointerId` property.

For those components that you want to respond to taps, add the `TapCallbacks` mixin.

- This mixin adds four overridable methods to your component: `onTapDown`, `onTapUp`, `onTapCancel`, and `onLongTapDown`. By default, each of these methods does nothing, they need to be overridden in order to perform any function.
- In addition, the component must implement the `containsLocalPoint()` method (already implemented in `PositionComponent`, so most of the time you don’t need to do anything here). This method allows Flame to know whether the event occurred within the component or not.

```
class MyComponent extends PositionComponent with TapCallbacks {
  MyComponent() : super(size: Vector2(80, 60));

  @override
  void onTapUp(TapUpEvent event) {
    // Do something in response to a tap event
  }
}
```

## Tap anatomy¶

### onTapDown¶

Every tap begins with a “tap down” event, which you receive via the `void onTapDown(TapDownEvent)` handler. The event is delivered to the first component located at the point of touch that has the `TapCallbacks` mixin. Normally, the event then stops propagation. However, you can force the event to also be delivered to the components below by setting `event.continuePropagation` to true.

The `TapDownEvent` object that is passed to the event handler, contains the available information about the event. For example, `event.localPosition` will contain the coordinate of the event in the current component’s local coordinate system, whereas `event.canvasPosition` is in the coordinate system of the entire game canvas.

Every component that received an `onTapDown` event will eventually receive either `onTapUp` or `onTapCancel` with the same `pointerId`.

### onLongTapDown¶

If the user holds their finger down for some time, “long tap” will be triggered. This event invokes the `void onLongTapDown(TapDownEvent)` handler on those components that previously received the `onTapDown` event.

By default, the `.longTapDelay` is set to 300 milliseconds, what may be different of the system default. You can change this value by setting the `TapConfig.longTapDelay` value. It may also be useful for specific accessibility needs.

### onTapUp¶

This event indicates successful completion of the tap sequence. It is guaranteed to only be delivered to those components that previously received the `onTapDown` event with the same pointer id.

The `TapUpEvent` object passed to the event handler contains the information about the event, which includes the coordinate of the event (i.e. where the user was touching the screen right before lifting their finger), and the event’s `pointerId`.

Note that the device coordinates of the tap-up event will be the same (or very close) to the device coordinates of the corresponding tap-down event. However, the same cannot be said about the local coordinates. If the component that you’re tapping is moving (as they often tend to in games), then you may find that the local tap-up coordinates are quite different from the local tap-down coordinates.

In extreme case, when the component moves away from the point of touch, the `onTapUp` event will not be generated at all: it will be replaced with `onTapCancel`. Note, however, that in this case the `onTapCancel` will be generated at the moment the user lifts or moves their finger, not at the moment the component moves away from the point of touch.

### onTapCancel¶

This event occurs when the tap fails to materialize. Most often, this will happen if the user moves their finger, which converts the gesture from “tap” into “drag”. Less often, this may happen when the component being tapped moves away from under the user’s finger. Even more rarely, the `onTapCancel` occurs when another widget pops over the game widget, or when the device turns off, or similar situations.

The `TapCancelEvent` object contains only the `pointerId` of the previous `TapDownEvent` which is now being canceled. There is no position associated with a tap-cancel.

### Demo¶

Play with the demo below to see the tap events in action.

The blue-ish rectangle in the middle is the component that has the `TapCallbacks` mixin. Tapping this component would create circles at the points of touch. Specifically, `onTapDown` event starts making the circle. The thickness of the circle will be proportional to the duration of the tap: after `onTapUp` the circle’s stroke width will no longer grow. There will be a thin white stripe at the moment the `onLongTapDown` fires. Lastly, the circle will implode and disappear if you cause the `onTapCancel` event by moving the finger.

tap_events.dart

```
  1import 'dart:math';
  2
  3import 'package:flame/components.dart';
  4import 'package:flame/events.dart';
  5import 'package:flame/game.dart';
  6import 'package:flutter/rendering.dart';
  7
  8class TapEventsGame extends FlameGame {
  9  @override
 10  Future<void> onLoad() async {
 11    add(TapTarget());
 12  }
 13}
 14
 15/// This component is the tappable blue-ish rectangle in the center of the game.
 16/// It uses the [TapCallbacks] mixin to receive tap events.
 17class TapTarget extends PositionComponent with TapCallbacks {
 18  TapTarget() : super(anchor: Anchor.center);
 19
 20  final _paint = Paint()..color = const Color(0x448BA8FF);
 21
 22  /// We will store all current circles into this map, keyed by the `pointerId`
 23  /// of the event that created the circle.
 24  final Map<int, ExpandingCircle> _circles = {};
 25
 26  @override
 27  void onGameResize(Vector2 size) {
 28    super.onGameResize(size);
 29    this.size = size - Vector2(100, 75);
 30    if (this.size.x < 100 || this.size.y < 100) {
 31      this.size = size * 0.9;
 32    }
 33    position = size / 2;
 34  }
 35
 36  @override
 37  void render(Canvas canvas) {
 38    canvas.drawRect(size.toRect(), _paint);
 39  }
 40
 41  @override
 42  void onTapDown(TapDownEvent event) {
 43    final circle = ExpandingCircle(event.localPosition);
 44    _circles[event.pointerId] = circle;
 45    add(circle);
 46  }
 47
 48  @override
 49  void onLongTapDown(TapDownEvent event) {
 50    _circles[event.pointerId]!.accent();
 51  }
 52
 53  @override
 54  void onTapUp(TapUpEvent event) {
 55    _circles.remove(event.pointerId)!.release();
 56  }
 57
 58  @override
 59  void onTapCancel(TapCancelEvent event) {
 60    _circles.remove(event.pointerId)!.cancel();
 61  }
 62}
 63
 64class ExpandingCircle extends Component {
 65  ExpandingCircle(this._center)
 66    : _baseColor = HSLColor.fromAHSL(
 67        1,
 68        random.nextDouble() * 360,
 69        1,
 70        0.8,
 71      ).toColor();
 72
 73  final Color _baseColor;
 74  final Vector2 _center;
 75  double _outerRadius = 0;
 76  double _innerRadius = 0;
 77  bool _released = false;
 78  bool _cancelled = false;
 79  late final _paint = Paint()
 80    ..style = PaintingStyle.stroke
 81    ..color = _baseColor;
 82
 83  /// "Accent" is thin white circle generated by `onLongTapDown`. We use
 84  /// negative radius to indicate that the circle should not be drawn yet.
 85  double _accentRadius = -1e10;
 86  late final _accentPaint = Paint()
 87    ..style = PaintingStyle.stroke
 88    ..strokeWidth = 0
 89    ..color = const Color(0xFFFFFFFF);
 90
 91  /// At this radius the circle will disappear.
 92  static const maxRadius = 175;
 93  static final random = Random();
 94
 95  double get radius => (_innerRadius + _outerRadius) / 2;
 96
 97  void release() => _released = true;
 98  void cancel() => _cancelled = true;
 99  void accent() => _accentRadius = 0;
100
101  @override
102  void render(Canvas canvas) {
103    canvas.drawCircle(_center.toOffset(), radius, _paint);
104    if (_accentRadius >= 0) {
105      canvas.drawCircle(_center.toOffset(), _accentRadius, _accentPaint);
106    }
107  }
108
109  @override
110  void update(double dt) {
111    if (_cancelled) {
112      _innerRadius += dt * 100; // implosion
113    } else {
114      _outerRadius += dt * 20;
115      _innerRadius += dt * (_released ? 20 : 6);
116      _accentRadius += dt * 20;
117    }
118    if (radius >= maxRadius || _innerRadius > _outerRadius) {
119      removeFromParent();
120    } else {
121      final opacity = 1 - radius / maxRadius;
122      _paint.color = _baseColor.withValues(alpha: opacity);
123      _paint.strokeWidth = _outerRadius - _innerRadius;
124    }
125  }
126}
```

## Mixins¶

This section describes in more details several mixins needed for tap event handling.

### TapCallbacks¶

The `TapCallbacks` mixin can be added to any `Component` in order for that component to start receiving tap events.

This mixin adds methods `onTapDown`, `onLongTapDown`, `onTapUp`, and `onTapCancel` to the component, which by default don’t do anything, but can be overridden to implement any real functionality. There is no need to override all of them either: for example, you can override only `onTapUp` if you wish to respond to “real” taps only.

Another crucial detail is that a component will only receive tap events that occur *within* that component, as judged by the `containsLocalPoint()` function. The commonly-used `PositionComponent` class provides such an implementation based on its `size` property. Thus, if your component derives from a `PositionComponent`, then make sure that you set its size correctly. If, however, your component derives from the bare `Component`, then the `containsLocalPoint()` method must be implemented manually.

If your component is a part of a larger hierarchy, then it will only receive tap events if its parent has implemented the `containsLocalPoint` correctly.

```
class MyComponent extends Component with TapCallbacks {
  final _rect = const Rect.fromLTWH(0, 0, 100, 100);
  final _paint = Paint();
  bool _isPressed = false;

  @override
  bool containsLocalPoint(Vector2 point) => _rect.contains(point.toOffset());

  @override
  void onTapDown(TapDownEvent event) => _isPressed = true;

  @override
  void onTapUp(TapUpEvent event) => _isPressed = false;

  @override
  void onTapCancel(TapCancelEvent event) => _isPressed = false;

  @override
  void render(Canvas canvas) {
    _paint.color = _isPressed? Colors.red : Colors.white;
    canvas.drawRect(_rect, _paint);
  }
}
```

### SecondaryTapCallbacks¶

In addition to the primary tap events (i.e. left mouse button on desktop), Flame also supports secondary tap events (i.e. right mouse button on desktop). To receive these events, add the `SecondaryTapCallbacks` mixin to your `PositionComponent`.

```
class MyComponent extends PositionComponent with SecondaryTapCallbacks {
  @override
  void onSecondaryTapUp(SecondaryTapUpEvent event) {
    /// Do something
  }

  @override
  void onSecondaryTapCancel(SecondaryTapCancelEvent event) {
    /// Do something
  }

  @override
  void onSecondaryTapDown(SecondaryTapDownEvent event) {
    /// Do something
  }
```

You can extend both `TapCallbacks` and `SecondaryTapCallbacks` in the same component to receive both primary and secondary tap events.

### TertiaryTapCallbacks¶

Flame also supports tertiary tap events (i.e. middle mouse button on desktop). To receive these events, add the `TertiaryTapCallbacks` mixin to your `PositionComponent`.

```
class MyComponent extends PositionComponent with TertiaryTapCallbacks {
  @override
  void onTertiaryTapUp(TertiaryTapUpEvent event) {
    /// Do something
  }

  @override
  void onTertiaryTapCancel(TertiaryTapCancelEvent event) {
    /// Do something
  }

  @override
  void onTertiaryTapDown(TertiaryTapDownEvent event) {
    /// Do something
  }
```

You can combine `TapCallbacks`, `SecondaryTapCallbacks`, and `TertiaryTapCallbacks` in the same component to receive primary, secondary, and tertiary tap events independently.

### DoubleTapCallbacks¶

Flame also offers a mixin named `DoubleTapCallbacks` to receive a double-tap event from the component. To start receiving double tap events in a component, add the `DoubleTapCallbacks` mixin to your `PositionComponent`.

```
class MyComponent extends PositionComponent with DoubleTapCallbacks {
  @override
  void onDoubleTapUp(DoubleTapEvent event) {
    /// Do something
  }

  @override
  void onDoubleTapCancel(DoubleTapCancelEvent event) {
    /// Do something
  }

  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    /// Do something
  }
```

## Migration¶

If you have an existing game that uses `Tappable`/`Draggable` mixins, then this section will describe how to transition to the new API described in this document. Here’s what you need to do:

Take all of your components that uses these mixins, and replace them with `TapCallbacks`/`DragCallbacks`. The methods `onTapDown`, `onTapUp`, `onTapCancel` and `onLongTapDown` will need to be adjusted for the new API:

- The argument pair such as `(int pointerId, TapDownDetails details)` was replaced with a single event object `TapDownEvent event`.
- There is no return value anymore, but if you need to make a component to pass-through the taps to the components below, then set `event.continuePropagation` to true. This is only needed for `onTapDown` events; all other events will pass-through automatically.
- If your component needs to know the coordinates of the point of touch, use `event.localPosition` instead of computing it manually. Properties `event.canvasPosition` and `event.devicePosition` are also available.
- If the component is attached to a custom ancestor then make sure that ancestor also have the correct size or implement `containsLocalPoint()`.
</content>
</page>

<page>
  <title>Effects — Flame</title>
  <url>https://docs.flame-engine.org/latest/flame/effects/effects.html</url>
  <content># Effects¶

In game development, smoothly animating properties over time (moving a character, fading an element, scaling a power-up) is a constant need. Writing manual interpolation code in every `update` method is repetitive and error-prone. Effects provide a declarative way to describe these time-based changes: you attach an effect to a component, and it automatically handles the animation, then removes itself when finished.

An effect is a special component that can attach to another component in order to modify its properties or appearance.

For example, suppose you are making a game with collectible power-up items. You want these power-ups to generate randomly around the map and then de-spawn after some time. Obviously, you could make a sprite component for the power-up and then place that component on the map, but we could do even better!

Let’s add a `ScaleEffect` to grow the item from 0 to 100% when the power-up first appears. Add another infinitely repeating alternating `MoveEffect` in order to make the item move slightly up and down. Then add an `OpacityEffect` that will “blink” the item 3 times, this effect will have a built-in delay of 30 seconds, or however long you want your power-up to stay in place. Lastly, add a `RemoveEffect` that will automatically remove the item from the game tree after the specified time (you probably want to time it right after the end of the `OpacityEffect`).

As you can see, with a few simple effects we have turned a simple lifeless sprite into a much more interesting item. And what’s more important, it didn’t result in an increased code complexity: the effects, once added, will work automatically, and then self-remove from the game tree when finished.

## Overview¶

The function of an `Effect` is to effect a change over time in some component’s property. In order to achieve that, the `Effect` must know the initial value of the property, the final value, and how it should progress over time. The initial value is usually determined by an effect automatically, the final value is provided by the user explicitly, and progression over time is handled by [EffectControllers](https://docs.flame-engine.org/latest/flame/effects/effect_controllers.html).

### Effect¶

The base `Effect` class is not usable on its own (it is abstract), but it provides some common functionality inherited by all other effects. This includes:

- The ability to pause/resume the effect using `effect.pause()` and `effect.resume()`. You can check whether the effect is currently paused using `effect.isPaused`.
- Property `removeOnFinish` (which is true by default) will cause the effect component to be removed from the game tree and garbage-collected once the effect completes. Set this to false if you plan to reuse the effect after it is finished.
- Optional user-provided `onComplete`, which will be invoked when the effect has just completed its execution but before it is removed from the game.
- A `completed` future that completes when the effect finishes.
- The `reset()` method reverts the effect to its original state, allowing it to run once again.

There are multiple pre-built effects provided by Flame, and you can also create your own. The following effects are included:

- [`MoveByEffect`](https://docs.flame-engine.org/latest/flame/effects/move_effects.html#movebyeffect)
- [`MoveToEffect`](https://docs.flame-engine.org/latest/flame/effects/move_effects.html#movetoeffect)
- [`MoveAlongPathEffect`](https://docs.flame-engine.org/latest/flame/effects/move_effects.html#movealongpatheffect)
- [`RotateAroundEffect`](https://docs.flame-engine.org/latest/flame/effects/rotate_effects.html#rotatearoundeffect)
- [`RotateEffect.by`](https://docs.flame-engine.org/latest/flame/effects/rotate_effects.html#rotateeffect-by)
- [`RotateEffect.to`](https://docs.flame-engine.org/latest/flame/effects/rotate_effects.html#rotateeffect-to)
- [`ScaleEffect.by`](https://docs.flame-engine.org/latest/flame/effects/scale_effects.html#scaleeffect-by)
- [`ScaleEffect.to`](https://docs.flame-engine.org/latest/flame/effects/scale_effects.html#scaleeffect-to)
- [`SizeEffect.by`](https://docs.flame-engine.org/latest/flame/effects/size_effects.html#sizeeffect-by)
- [`SizeEffect.to`](https://docs.flame-engine.org/latest/flame/effects/size_effects.html#sizeeffect-to)
- [`AnchorByEffect`](https://docs.flame-engine.org/latest/flame/effects/anchor_effects.html#anchorbyeffect)
- [`AnchorToEffect`](https://docs.flame-engine.org/latest/flame/effects/anchor_effects.html#anchortoeffect)
- [`OpacityToEffect`](https://docs.flame-engine.org/latest/flame/effects/color_effects.html#opacitytoeffect)
- [`OpacityByEffect`](https://docs.flame-engine.org/latest/flame/effects/color_effects.html#opacitybyeffect)
- [`ColorEffect`](https://docs.flame-engine.org/latest/flame/effects/color_effects.html#coloreffect)
- [`SequenceEffect`](https://docs.flame-engine.org/latest/flame/effects/sequence_effect.html)
- [`CombinedEffect`](https://docs.flame-engine.org/latest/flame/effects/combined_effect.html)
- [`RemoveEffect`](https://docs.flame-engine.org/latest/flame/effects/remove_effect.html)
- [`FunctionEffect`](https://docs.flame-engine.org/latest/flame/effects/function_effect.html)

## Creating new effects¶

Although Flame provides a wide array of built-in effects, eventually you may find them to be insufficient. Luckily, creating new effects is very simple.

Each effect extends the base `Effect` class, possibly via one of the more specialized abstract subclasses such as `ComponentEffect<T>` or `Transform2DEffect`.

The `Effect` class’ constructor requires an `EffectController` instance as an argument. In most cases you may want to pass that controller from your own constructor. Luckily, the effect controller encapsulates much of the complexity of an effect’s implementation, so you don’t need to worry about re-creating that functionality.

Lastly, you will need to implement a single method `apply(double progress)` that will be called at each update tick while the effect is active. In this method you are supposed to make changes to the target of your effect.

In addition, you may want to implement callbacks `onStart()` and `onFinish()` if there are any actions that must be taken when the effect starts or ends.

When implementing the `apply()` method we recommend to use relative updates only. That is, change the target property by incrementing/decrementing its current value, rather than directly setting that property to a fixed value. This way multiple effects would be able to act on the same component without interfering with each other.

## Effects vs Decorators¶

While effects and decorators can sometimes achieve similar visual results (like changing opacity or color), they have different performance and visual characteristics:

- **Effects** are fast and generally change a property on a single component. When applied to a group, they affect each child individually.
- **Decorators** are more powerful but slower. They use `saveLayer` to flatten a whole component subtree into a single layer before applying an effect. This is essential for correctly rendering composite objects with transparency or complex filters.

See the [Decorators documentation](https://docs.flame-engine.org/latest/flame/rendering/decorators.html) for a more detailed comparison.

## See also¶

- [Examples of various effects](https://examples.flame-engine.org/).
</content>
</page>