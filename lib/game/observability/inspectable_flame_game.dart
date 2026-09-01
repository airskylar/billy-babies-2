import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'runtime_inspection_bridge.dart';
import 'runtime_inspection.dart';

final _inspectionCommandTransactionKey = Object();

abstract class InspectableFlameGame<W extends World> extends FlameGame<W>
    implements RuntimeInspectionTarget, RuntimeInspectable {
  InspectableFlameGame({
    super.children,
    super.world,
    super.camera,
    RuntimeEventJournal? inspectionJournal,
  }) : _journal = inspectionJournal ?? RuntimeEventJournal();

  final RuntimeEventJournal _journal;
  RuntimeInspectionSession? _inspectionSession;
  EdgeInsets _safePadding = EdgeInsets.zero;
  AppLifecycleState? _appLifecycleState;
  Vector2? _viewportSize;
  int _revision = 0;
  int _frameNumber = 0;
  double _gameTimeSeconds = 0;
  bool _recordedGameLoaded = false;
  Future<void> _commandTail = Future.value();

  RuntimeInspectionAdapter get inspectionAdapter;

  @override
  String get inspectionId => 'game';

  int get revision => _revision;

  RuntimeInspectionSession? get inspectionSession => _inspectionSession;

  EdgeInsets get safePadding => _safePadding;

  set safePadding(EdgeInsets value) {
    if (_safePadding == value) return;
    final previous = _safePadding;
    _safePadding = value;
    onSafePaddingChanged(value);
    recordInspectionEvent(RuntimeEventKind.viewportChanged, {
      'from': _insetsJson(previous),
      'to': _insetsJson(value),
    });
  }

  void onSafePaddingChanged(EdgeInsets value) {}

  @override
  void onMount() {
    super.onMount();
    _inspectionSession = RuntimeInspectionBridge.attach(this);
    if (_recordedGameLoaded) return;
    _recordedGameLoaded = true;
    recordInspectionEvent(RuntimeEventKind.gameLoaded, {
      'canvasWidth': canvasSize.x,
      'canvasHeight': canvasSize.y,
    });
  }

  @override
  void update(double dt) {
    _frameNumber += 1;
    _gameTimeSeconds += dt;
    super.update(dt);
  }

  @override
  void onGameResize(Vector2 size) {
    final previous = _viewportSize;
    _viewportSize = size.clone();
    super.onGameResize(size);
    if (previous == null || previous.x != size.x || previous.y != size.y) {
      recordInspectionEvent(RuntimeEventKind.viewportChanged, {
        'from': previous == null ? null : _sizeJson(previous),
        'to': _sizeJson(size),
      });
    }
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    final previous = _appLifecycleState;
    _appLifecycleState = state;
    super.lifecycleStateChange(state);
    if (previous != state) {
      recordInspectionEvent(RuntimeEventKind.lifecycleChanged, {
        'from': previous?.name,
        'to': state.name,
      });
    }
  }

  @override
  void pauseEngine() {
    final wasPaused = paused;
    super.pauseEngine();
    if (!wasPaused && paused) {
      recordInspectionEvent(RuntimeEventKind.enginePaused, const {});
    }
  }

  @override
  void resumeEngine() {
    final wasPaused = paused;
    super.resumeEngine();
    if (wasPaused && !paused) {
      recordInspectionEvent(RuntimeEventKind.engineResumed, const {});
    }
  }

  @override
  void stepEngine({double stepTime = 1 / 60}) {
    final canStep = paused;
    super.stepEngine(stepTime: stepTime);
    if (canStep) {
      recordInspectionEvent(RuntimeEventKind.engineStepped, {
        'seconds': stepTime,
      });
    }
  }

  @override
  void onRemove() {
    recordInspectionEvent(RuntimeEventKind.gameRemoved, const {});
    final session = _inspectionSession;
    _inspectionSession = null;
    if (session != null) {
      RuntimeInspectionBridge.detach(target: this, session: session);
    }
    super.onRemove();
  }

  @override
  RuntimeInspectionCapabilities capabilities() => RuntimeInspectionCapabilities(
    gameId: inspectionAdapter.gameId,
    gameSchemaVersion: inspectionAdapter.schemaVersion,
    commands: inspectionAdapter.commands,
  );

  @override
  RuntimeSnapshot snapshot(SnapshotDetail detail) {
    final componentSnapshots = _inspectableNodes()
        .map((node) => _componentSnapshot(node, detail))
        .toList(growable: false);

    return RuntimeSnapshot(
      revision: _revision,
      detail: detail,
      engine: EngineSnapshot(
        loaded: isLoaded,
        mounted: isMounted,
        removed: isRemoved,
        attached: isAttached,
        paused: paused,
        frameNumber: _frameNumber,
        gameTimeSeconds: _gameTimeSeconds,
        appLifecycle: _appLifecycleState?.name,
      ),
      viewport: ViewportSnapshot(
        hasLayout: hasLayout,
        width: hasLayout ? canvasSize.x : null,
        height: hasLayout ? canvasSize.y : null,
        safeTop: _safePadding.top,
        safeRight: _safePadding.right,
        safeBottom: _safePadding.bottom,
        safeLeft: _safePadding.left,
      ),
      game: GameInspectionSnapshot(
        id: inspectionAdapter.gameId,
        schemaVersion: inspectionAdapter.schemaVersion,
        state: inspectionAdapter.snapshot(detail),
      ),
      components: componentSnapshots,
    );
  }

  @override
  Map<String, Object?> inspectState(SnapshotDetail detail) => {
    'revision': _revision,
    'paused': paused,
    if (detail == SnapshotDetail.visual) ...{
      'frameNumber': _frameNumber,
      'gameTimeSeconds': _gameTimeSeconds,
    },
  };

  @override
  RuntimeEventBatch eventBatchAfter(int sequence) =>
      _journal.batchAfter(sequence);

  @override
  Future<RuntimeCommandResult> dispatch(
    RuntimeCommandEnvelope command, {
    RuntimeInspectionSession? initiatingSession,
  }) {
    if (initiatingSession != null &&
        !identical(initiatingSession.target, this)) {
      throw ArgumentError.value(
        initiatingSession,
        'initiatingSession',
        'must target this game',
      );
    }
    final commandSession = initiatingSession ?? _inspectionSession;
    // Recover the shared tail so one adapter error reaches only its caller and
    // cannot prevent later commands from entering the serialized queue.
    final transaction = _commandTail.then(
      (_) => _dispatchTransaction(command, initiatingSession: commandSession),
    );
    _commandTail = transaction.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return transaction;
  }

  Future<RuntimeCommandResult> _dispatchTransaction(
    RuntimeCommandEnvelope command, {
    required RuntimeInspectionSession? initiatingSession,
  }) async {
    final previousRevision = _revision;
    if (command.expectedRevision case final expected?
        when expected != previousRevision) {
      return _commandResult(
        outcome: RuntimeCommandOutcome(
          disposition: RuntimeCommandDisposition.rejected,
          code: 'staleRevision',
          message:
              'Expected revision $expected but current revision is '
              '$previousRevision',
        ),
        previousRevision: previousRevision,
      );
    }

    final transaction = _InspectionCommandTransaction(
      target: this,
      initiatingSession: initiatingSession,
    );
    // A zone follows the adapter's asynchronous call chain without claiming
    // unrelated game events that happen while the command Future is pending.
    final outcome = await runZoned(() async {
      final outcome = await inspectionAdapter.dispatch(command);
      if (outcome.disposition == RuntimeCommandDisposition.applied &&
          !transaction.recordedStateChangingEvent) {
        recordInspectionEvent(RuntimeEventKind.commandApplied, {
          'command': command.name,
          'code': outcome.code,
        });
      }
      return outcome;
    }, zoneValues: {_inspectionCommandTransactionKey: transaction});
    return _commandResult(outcome: outcome, previousRevision: previousRevision);
  }

  /// Records every event in the journal and reports whether it was also pushed.
  bool recordInspectionEvent(
    InspectionEventKind kind,
    Map<String, Object?> payload, {
    bool changesState = true,
  }) {
    final transaction = _currentCommandTransaction;
    if (changesState) {
      _revision += 1;
      transaction?.recordedStateChangingEvent = true;
    }
    final event = _journal.add(
      revision: _revision,
      gameTimeSeconds: _gameTimeSeconds,
      kind: kind,
      payload: payload,
    );
    final session = transaction?.initiatingSession ?? _inspectionSession;
    if (session != null) {
      return RuntimeInspectionBridge.publish(
        target: this,
        session: session,
        event: event,
      );
    }
    return false;
  }

  _InspectionCommandTransaction? get _currentCommandTransaction {
    final transaction = Zone.current[_inspectionCommandTransactionKey];
    return transaction is _InspectionCommandTransaction &&
            identical(transaction.target, this)
        ? transaction
        : null;
  }

  RuntimeCommandResult _commandResult({
    required RuntimeCommandOutcome outcome,
    required int previousRevision,
  }) {
    return RuntimeCommandResult(
      disposition: outcome.disposition,
      code: outcome.code,
      message: outcome.message,
      previousRevision: previousRevision,
      currentRevision: _revision,
      snapshot: snapshot(SnapshotDetail.semantic),
    );
  }

  List<_InspectableNode> _inspectableNodes() {
    final nodes = <_InspectableNode>[];

    void visit(Component component, _InspectableNode? parent) {
      var inspectableParent = parent;
      if (component case final RuntimeInspectable inspectable) {
        final node = _InspectableNode(
          component: component,
          inspectable: inspectable,
          parentId: parent?.inspectable.inspectionId,
        );
        parent?.childIds.add(inspectable.inspectionId);
        nodes.add(node);
        inspectableParent = node;
      }

      for (final child in component.children) {
        visit(child, inspectableParent);
      }
    }

    visit(this, null);
    return nodes;
  }

  ComponentSnapshot _componentSnapshot(
    _InspectableNode node,
    SnapshotDetail detail,
  ) {
    final component = node.component;
    final inspectable = node.inspectable;
    final transform =
        detail == SnapshotDetail.visual && component is PositionComponent
        ? _transformSnapshot(component)
        : null;
    return ComponentSnapshot(
      id: inspectable.inspectionId,
      type: component.runtimeType.toString(),
      loaded: component.isLoaded,
      mounted: component.isMounted,
      removed: component.isRemoved,
      priority: component.priority,
      parentId: node.parentId,
      childIds: List.unmodifiable(node.childIds),
      transform: transform,
      state: inspectable.inspectState(detail),
    );
  }

  TransformSnapshot _transformSnapshot(PositionComponent component) {
    final corners = _absoluteCorners(component);
    RectSnapshot? worldBounds;
    RectSnapshot? screenBounds;

    // Flame's absolute position helpers resolve PositionComponent ancestors,
    // but Worlds, Viewfinders, and Viewports establish additional render
    // spaces. Project those corners through the same primary-camera transforms
    // that render them so the snapshot keeps both world and hit-test geometry.
    final componentWorld = _ancestorOfType<World>(component);
    if (componentWorld != null) {
      worldBounds = _boundsSnapshot(corners);
      if (identical(camera.world, componentWorld)) {
        screenBounds = _projectedBounds(corners, camera.localToGlobal);
      }
    } else if (_isDescendantOf(component, camera.viewfinder)) {
      worldBounds = _boundsSnapshot(corners);
      screenBounds = _projectedBounds(corners, camera.localToGlobal);
    } else if (_isDescendantOf(component, camera.viewport) ||
        _isDescendantOf(component, camera.backdrop)) {
      screenBounds = _projectedBounds(corners, camera.viewport.localToGlobal);
    } else {
      screenBounds = _boundsSnapshot(corners);
    }

    return TransformSnapshot(
      x: component.position.x,
      y: component.position.y,
      width: component.size.x,
      height: component.size.y,
      scaleX: component.scale.x,
      scaleY: component.scale.y,
      angle: component.angle,
      anchor: component.anchor.toString(),
      worldBounds: worldBounds,
      screenBounds: screenBounds,
    );
  }

  List<Vector2> _absoluteCorners(PositionComponent component) => [
    component.absolutePositionOfAnchor(Anchor.topLeft),
    component.absolutePositionOfAnchor(Anchor.topRight),
    component.absolutePositionOfAnchor(Anchor.bottomRight),
    component.absolutePositionOfAnchor(Anchor.bottomLeft),
  ];

  RectSnapshot _projectedBounds(
    List<Vector2> corners,
    Vector2 Function(Vector2) project,
  ) => _boundsSnapshot(corners.map(project));

  RectSnapshot _boundsSnapshot(Iterable<Vector2> points) {
    final iterator = points.iterator..moveNext();
    var minX = iterator.current.x;
    var minY = iterator.current.y;
    var maxX = minX;
    var maxY = minY;
    while (iterator.moveNext()) {
      final point = iterator.current;
      minX = point.x < minX ? point.x : minX;
      minY = point.y < minY ? point.y : minY;
      maxX = point.x > maxX ? point.x : maxX;
      maxY = point.y > maxY ? point.y : maxY;
    }
    return RectSnapshot(
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  T? _ancestorOfType<T extends Component>(Component component) {
    var ancestor = component.parent;
    while (ancestor != null) {
      if (ancestor is T) return ancestor;
      ancestor = ancestor.parent;
    }
    return null;
  }

  bool _isDescendantOf(Component component, Component ancestor) {
    var candidate = component.parent;
    while (candidate != null) {
      if (identical(candidate, ancestor)) return true;
      candidate = candidate.parent;
    }
    return false;
  }

  Map<String, Object?> _insetsJson(EdgeInsets value) => {
    'top': value.top,
    'right': value.right,
    'bottom': value.bottom,
    'left': value.left,
  };

  Map<String, Object?> _sizeJson(Vector2 value) => {
    'width': value.x,
    'height': value.y,
  };
}

class _InspectableNode {
  _InspectableNode({
    required this.component,
    required this.inspectable,
    required this.parentId,
  });

  final Component component;
  final RuntimeInspectable inspectable;
  final String? parentId;
  final List<String> childIds = [];
}

class _InspectionCommandTransaction {
  _InspectionCommandTransaction({
    required this.target,
    required this.initiatingSession,
  });

  final RuntimeInspectionTarget target;
  final RuntimeInspectionSession? initiatingSession;
  bool recordedStateChangingEvent = false;
}
