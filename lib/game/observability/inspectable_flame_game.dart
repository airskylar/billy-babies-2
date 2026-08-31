import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'coreflame_debug_bridge.dart';
import 'runtime_inspection.dart';

abstract class InspectableFlameGame extends FlameGame
    implements RuntimeInspectionTarget, RuntimeInspectable {
  InspectableFlameGame({RuntimeEventJournal? inspectionJournal})
    : _journal = inspectionJournal ?? RuntimeEventJournal() {
    CoreflameDebugBridge.attach(this);
  }

  final RuntimeEventJournal _journal;
  EdgeInsets _safePadding = EdgeInsets.zero;
  AppLifecycleState? _appLifecycleState;
  Vector2? _viewportSize;
  int _revision = 0;
  int _frameNumber = 0;
  double _gameTimeSeconds = 0;
  bool _recordedGameLoaded = false;

  RuntimeInspectionAdapter get inspectionAdapter;

  @override
  String get inspectionId => 'game';

  int get revision => _revision;

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
    CoreflameDebugBridge.detach(this);
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
    final componentSnapshots = descendants(includeSelf: true)
        .whereType<RuntimeInspectable>()
        .map((inspectable) {
          final component = inspectable as Component;
          return _componentSnapshot(component, inspectable, detail);
        })
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
  RuntimeCommandResult dispatch(RuntimeCommandEnvelope command) {
    final previousRevision = _revision;
    if (command.expectedRevision case final expected?
        when expected != previousRevision) {
      return _commandResult(
        outcome: RuntimeCommandOutcome(
          accepted: false,
          code: 'staleRevision',
          message:
              'Expected revision $expected but current revision is '
              '$previousRevision',
        ),
        previousRevision: previousRevision,
      );
    }

    return _commandResult(
      outcome: inspectionAdapter.dispatch(command),
      previousRevision: previousRevision,
    );
  }

  void recordInspectionEvent(
    InspectionEventKind kind,
    Map<String, Object?> payload, {
    bool changesState = true,
  }) {
    if (changesState) {
      _revision += 1;
    }
    final event = _journal.add(
      revision: _revision,
      gameTimeSeconds: _gameTimeSeconds,
      kind: kind,
      payload: payload,
    );
    CoreflameDebugBridge.publish(event);
  }

  RuntimeCommandResult _commandResult({
    required RuntimeCommandOutcome outcome,
    required int previousRevision,
  }) {
    return RuntimeCommandResult(
      accepted: outcome.accepted,
      code: outcome.code,
      message: outcome.message,
      previousRevision: previousRevision,
      currentRevision: _revision,
      snapshot: snapshot(SnapshotDetail.semantic),
    );
  }

  ComponentSnapshot _componentSnapshot(
    Component component,
    RuntimeInspectable inspectable,
    SnapshotDetail detail,
  ) {
    final transform =
        detail == SnapshotDetail.visual && component is PositionComponent
        ? TransformSnapshot(
            x: component.position.x,
            y: component.position.y,
            width: component.size.x,
            height: component.size.y,
            scaleX: component.scale.x,
            scaleY: component.scale.y,
            angle: component.angle,
            anchor: component.anchor.toString(),
          )
        : null;
    return ComponentSnapshot(
      id: inspectable.inspectionId,
      type: component.runtimeType.toString(),
      loaded: component.isLoaded,
      mounted: component.isMounted,
      removed: component.isRemoved,
      priority: component.priority,
      parentId: switch (component.parent) {
        final RuntimeInspectable parent => parent.inspectionId,
        _ => null,
      },
      childIds: component.children
          .whereType<RuntimeInspectable>()
          .map((child) => child.inspectionId)
          .toList(growable: false),
      transform: transform,
      state: inspectable.inspectState(detail),
    );
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
