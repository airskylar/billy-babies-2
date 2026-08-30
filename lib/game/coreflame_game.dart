import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/cozy_tic_tac_toe_scene.dart';
import 'observability/coreflame_debug_bridge.dart';
import 'observability/coreflame_observability.dart';
import 'services/game_feedback.dart';
import 'services/game_platform_services.dart';
import 'theme/game_palette.dart';
import 'tic_tac_toe_match.dart';

class CoreflameGame extends FlameGame
    implements CoreflameDebugTarget, CoreflameInspectable {
  CoreflameGame({
    required this.platformServices,
    TicTacToeMatch? match,
    GameFeedback? feedback,
    CoreflameEventJournal? journal,
  }) : match = match ?? TicTacToeMatch(),
       feedback = feedback ?? GameFeedback(),
       _journal = journal ?? CoreflameEventJournal() {
    this.feedback.addObserver(_onFeedbackEvent);
    CoreflameDebugBridge.attach(this);
  }

  final TicTacToeMatch match;
  final GameFeedback feedback;
  final GamePlatformServices platformServices;
  final CoreflameEventJournal _journal;
  EdgeInsets _safePadding = EdgeInsets.zero;
  CozyTicTacToeScene? _scene;
  AppLifecycleState? _appLifecycleState;
  Vector2? _viewportSize;
  int _revision = 0;
  int _frameNumber = 0;
  double _gameTimeSeconds = 0;

  @override
  String get inspectionId => 'game';

  int get revision => _revision;

  set safePadding(EdgeInsets value) {
    if (_safePadding == value) return;
    final previous = _safePadding;
    _safePadding = value;
    if (_scene case final scene?) {
      scene.applySafeViewport(size, value);
    }
    _recordEvent(CoreflameEventKind.viewportChanged, {
      'from': _insetsJson(previous),
      'to': _insetsJson(value),
    });
  }

  @override
  Color backgroundColor() => GamePalette.cream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await feedback.preload();
    final scene = CozyTicTacToeScene(
      match: match,
      feedback: feedback,
      platformServices: platformServices,
      recordEvent: _recordEvent,
    );
    _scene = scene;
    await add(scene);
    scene.applySafeViewport(size, _safePadding);
    _recordEvent(CoreflameEventKind.gameLoaded, {
      'canvasWidth': canvasSize.x,
      'canvasHeight': canvasSize.y,
    });
    unawaited(feedback.startBackgroundMusic());
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
      _recordEvent(CoreflameEventKind.viewportChanged, {
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
      _recordEvent(CoreflameEventKind.lifecycleChanged, {
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
      _recordEvent(CoreflameEventKind.enginePaused, const {});
    }
  }

  @override
  void resumeEngine() {
    final wasPaused = paused;
    super.resumeEngine();
    if (wasPaused && !paused) {
      _recordEvent(CoreflameEventKind.engineResumed, const {});
    }
  }

  @override
  void stepEngine({double stepTime = 1 / 60}) {
    final canStep = paused;
    super.stepEngine(stepTime: stepTime);
    if (canStep) {
      _recordEvent(CoreflameEventKind.engineStepped, {'seconds': stepTime});
    }
  }

  @override
  void onRemove() {
    _recordEvent(CoreflameEventKind.gameRemoved, const {});
    CoreflameDebugBridge.detach(this);
    super.onRemove();
    unawaited(
      feedback.dispose().whenComplete(() {
        feedback.removeObserver(_onFeedbackEvent);
      }),
    );
  }

  @override
  CoreflameSnapshot snapshot(SnapshotDetail detail) {
    final componentSnapshots = descendants(includeSelf: true)
        .whereType<CoreflameInspectable>()
        .map((inspectable) {
          final component = inspectable as Component;
          return _componentSnapshot(component, inspectable, detail);
        })
        .toList(growable: false);

    return CoreflameSnapshot(
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
      match: match.snapshot,
      feedback: feedback.snapshot,
      scene: _scene?.snapshot(detail),
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
  CoreflameEventBatch eventBatchAfter(int sequence) =>
      _journal.batchAfter(sequence);

  @override
  CoreflameCommandResult dispatch(CoreflameCommandRequest request) {
    final previousRevision = _revision;
    if (request.expectedRevision case final expected?
        when expected != previousRevision) {
      return _commandResult(
        accepted: false,
        code: 'staleRevision',
        message:
            'Expected revision $expected but current revision is '
            '$previousRevision',
        previousRevision: previousRevision,
      );
    }

    final scene = _scene;
    if (scene == null || !scene.isMounted) {
      return _commandResult(
        accepted: false,
        code: 'gameNotReady',
        message: 'The Coreflame scene is not mounted',
        previousRevision: previousRevision,
      );
    }

    return switch (request.command) {
      PlayCellCommand(:final cell) => _dispatchPlayCell(
        scene,
        cell,
        previousRevision,
      ),
      StartNextRoundCommand() => _dispatchAction(
        previousRevision,
        scene.startNextRound,
        message: 'Started the next round',
      ),
      ResetMatchCommand() => _dispatchAction(
        previousRevision,
        scene.resetMatch,
        message: 'Reset the match',
      ),
      SetSettingsOpenCommand(:final open) => _dispatchChange(
        previousRevision,
        () => scene.setSettingsOpen(open, origin: CoreflameActionOrigin.agent),
        changedMessage: open ? 'Opened settings' : 'Closed settings',
      ),
      SetFeedbackSettingCommand(:final setting, :final enabled) =>
        _dispatchChange(
          previousRevision,
          () => scene.setFeedbackSetting(
            setting,
            enabled,
            origin: CoreflameActionOrigin.agent,
          ),
          changedMessage: 'Set ${setting.name} to $enabled',
        ),
    };
  }

  CoreflameCommandResult _dispatchPlayCell(
    CozyTicTacToeScene scene,
    int cell,
    int previousRevision,
  ) {
    if (cell < 0 || cell >= match.cells.length) {
      _recordEvent(CoreflameEventKind.moveRejected, {
        'cell': cell,
        'reason': 'outOfRange',
        'origin': CoreflameActionOrigin.agent.name,
      }, changesState: false);
      return _commandResult(
        accepted: false,
        code: 'outOfRange',
        message: 'Cell must be between 0 and 8',
        previousRevision: previousRevision,
      );
    }

    final outcome = scene.playCell(cell, origin: CoreflameActionOrigin.agent);
    return _commandResult(
      accepted: outcome == MoveOutcome.accepted,
      code: outcome.name,
      message: switch (outcome) {
        MoveOutcome.accepted => 'Played cell $cell',
        MoveOutcome.occupied => 'Cell $cell is already occupied',
        MoveOutcome.roundFinished => 'The round is already finished',
      },
      previousRevision: previousRevision,
    );
  }

  CoreflameCommandResult _dispatchAction(
    int previousRevision,
    void Function({CoreflameActionOrigin origin}) action, {
    required String message,
  }) {
    action(origin: CoreflameActionOrigin.agent);
    return _commandResult(
      accepted: true,
      code: 'applied',
      message: message,
      previousRevision: previousRevision,
    );
  }

  CoreflameCommandResult _dispatchChange(
    int previousRevision,
    bool Function() action, {
    required String changedMessage,
  }) {
    final changed = action();
    return _commandResult(
      accepted: true,
      code: changed ? 'applied' : 'noChange',
      message: changed
          ? changedMessage
          : 'State already had the requested value',
      previousRevision: previousRevision,
    );
  }

  CoreflameCommandResult _commandResult({
    required bool accepted,
    required String code,
    required String message,
    required int previousRevision,
  }) {
    return CoreflameCommandResult(
      accepted: accepted,
      code: code,
      message: message,
      previousRevision: previousRevision,
      currentRevision: _revision,
      snapshot: snapshot(SnapshotDetail.semantic),
    );
  }

  ComponentSnapshot _componentSnapshot(
    Component component,
    CoreflameInspectable inspectable,
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
        final CoreflameInspectable parent => parent.inspectionId,
        _ => null,
      },
      childIds: component.children
          .whereType<CoreflameInspectable>()
          .map((child) => child.inspectionId)
          .toList(growable: false),
      transform: transform,
      state: inspectable.inspectState(detail),
    );
  }

  void _onFeedbackEvent(GameFeedbackEvent event) {
    final failure = event.kind == GameFeedbackEventKind.failure;
    final changesState =
        event.kind == GameFeedbackEventKind.settingsLoaded ||
        event.kind == GameFeedbackEventKind.settingChanged;
    _recordEvent(
      failure
          ? CoreflameEventKind.feedbackFailure
          : CoreflameEventKind.feedbackStateChanged,
      {'feedbackEvent': event.kind.name, ...event.payload},
      changesState: changesState,
    );
  }

  void _recordEvent(
    CoreflameEventKind kind,
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
