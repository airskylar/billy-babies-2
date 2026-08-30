import 'dart:collection';

enum SnapshotDetail {
  semantic,
  visual;

  static SnapshotDetail parse(String? value) {
    return switch (value) {
      null || 'semantic' => SnapshotDetail.semantic,
      'visual' => SnapshotDetail.visual,
      _ => throw FormatException('Unknown snapshot detail: $value'),
    };
  }
}

enum CoreflameActionOrigin { pointer, agent, test, system }

class RectSnapshot {
  const RectSnapshot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  Map<String, Object?> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}

class TransformSnapshot {
  const TransformSnapshot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.scaleX,
    required this.scaleY,
    required this.angle,
    required this.anchor,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double scaleX;
  final double scaleY;
  final double angle;
  final String anchor;

  Map<String, Object?> toJson() => {
    'position': {'x': x, 'y': y},
    'size': {'width': width, 'height': height},
    'scale': {'x': scaleX, 'y': scaleY},
    'angle': angle,
    'anchor': anchor,
  };
}

class ComponentSnapshot {
  const ComponentSnapshot({
    required this.id,
    required this.type,
    required this.loaded,
    required this.mounted,
    required this.removed,
    required this.priority,
    required this.parentId,
    required this.childIds,
    required this.state,
    this.transform,
  });

  final String id;
  final String type;
  final bool loaded;
  final bool mounted;
  final bool removed;
  final int priority;
  final String? parentId;
  final List<String> childIds;
  final TransformSnapshot? transform;
  final Map<String, Object?> state;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'lifecycle': {'loaded': loaded, 'mounted': mounted, 'removed': removed},
    'priority': priority,
    'parentId': parentId,
    'childIds': childIds,
    if (transform case final value?) 'transform': value.toJson(),
    'state': state,
  };
}

abstract interface class CoreflameInspectable {
  String get inspectionId;

  Map<String, Object?> inspectState(SnapshotDetail detail);
}

class MatchSnapshot {
  const MatchSnapshot({
    required this.cells,
    required this.turn,
    required this.starter,
    required this.result,
    required this.winningCells,
    required this.xScore,
    required this.oScore,
    required this.draws,
  });

  final List<String?> cells;
  final String turn;
  final String starter;
  final String result;
  final List<int> winningCells;
  final int xScore;
  final int oScore;
  final int draws;

  int get moveCount => cells.where((cell) => cell != null).length;

  Map<String, Object?> toJson() => {
    'cells': cells,
    'turn': turn,
    'starter': starter,
    'result': result,
    'winningCells': winningCells,
    'scores': {'x': xScore, 'o': oScore, 'draws': draws},
    'moveCount': moveCount,
  };
}

class FeedbackFailureSnapshot {
  const FeedbackFailureSnapshot({
    required this.feature,
    required this.errorType,
    required this.message,
  });

  final String feature;
  final String errorType;
  final String message;

  Map<String, Object?> toJson() => {
    'feature': feature,
    'errorType': errorType,
    'message': message,
  };
}

class FeedbackSnapshot {
  const FeedbackSnapshot({
    required this.lifecycle,
    required this.backgroundMusic,
    required this.preferencesLoaded,
    required this.soundEnabled,
    required this.musicEnabled,
    required this.vibrationEnabled,
    this.lastFailure,
  });

  final String lifecycle;
  final String backgroundMusic;
  final bool preferencesLoaded;
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final FeedbackFailureSnapshot? lastFailure;

  Map<String, Object?> toJson() => {
    'lifecycle': lifecycle,
    'backgroundMusic': backgroundMusic,
    'preferencesLoaded': preferencesLoaded,
    'settings': {
      'soundEnabled': soundEnabled,
      'musicEnabled': musicEnabled,
      'vibrationEnabled': vibrationEnabled,
    },
    if (lastFailure case final value?) 'lastFailure': value.toJson(),
  };
}

class SceneLayoutSnapshot {
  const SceneLayoutSnapshot({
    required this.isLandscape,
    required this.panel,
    required this.board,
    required this.cells,
    required this.roundButton,
    required this.settingsButton,
    required this.settingsCard,
    required this.settingsCloseButton,
    required this.settingRows,
  });

  final bool isLandscape;
  final RectSnapshot panel;
  final RectSnapshot board;
  final List<RectSnapshot> cells;
  final RectSnapshot roundButton;
  final RectSnapshot settingsButton;
  final RectSnapshot settingsCard;
  final RectSnapshot settingsCloseButton;
  final List<RectSnapshot> settingRows;

  Map<String, Object?> toJson() => {
    'orientation': isLandscape ? 'landscape' : 'portrait',
    'panel': panel.toJson(),
    'board': board.toJson(),
    'cells': cells.map((cell) => cell.toJson()).toList(growable: false),
    'roundButton': roundButton.toJson(),
    'settingsButton': settingsButton.toJson(),
    'settingsCard': settingsCard.toJson(),
    'settingsCloseButton': settingsCloseButton.toJson(),
    'settingRows': settingRows
        .map((row) => row.toJson())
        .toList(growable: false),
  };
}

class SceneSnapshot {
  const SceneSnapshot({
    required this.overlay,
    required this.assetsLoaded,
    required this.animationsSettled,
    required this.lastPlacedCell,
    this.elapsedSeconds,
    this.markProgress,
    this.winningLineProgress,
    this.roundButtonPhase,
    this.roundButtonSink,
    this.roundButtonVelocity,
    this.layout,
  });

  final String overlay;
  final bool assetsLoaded;
  final bool animationsSettled;
  final int? lastPlacedCell;
  final double? elapsedSeconds;
  final List<double>? markProgress;
  final double? winningLineProgress;
  final String? roundButtonPhase;
  final double? roundButtonSink;
  final double? roundButtonVelocity;
  final SceneLayoutSnapshot? layout;

  Map<String, Object?> toJson() => {
    'overlay': overlay,
    'assetsLoaded': assetsLoaded,
    'animationsSettled': animationsSettled,
    'lastPlacedCell': lastPlacedCell,
    'elapsedSeconds': ?elapsedSeconds,
    'markProgress': ?markProgress,
    'winningLineProgress': ?winningLineProgress,
    'roundButtonPhase': ?roundButtonPhase,
    'roundButtonSink': ?roundButtonSink,
    'roundButtonVelocity': ?roundButtonVelocity,
    if (layout case final value?) 'layout': value.toJson(),
  };
}

class EngineSnapshot {
  const EngineSnapshot({
    required this.loaded,
    required this.mounted,
    required this.removed,
    required this.attached,
    required this.paused,
    required this.frameNumber,
    required this.gameTimeSeconds,
    required this.appLifecycle,
  });

  final bool loaded;
  final bool mounted;
  final bool removed;
  final bool attached;
  final bool paused;
  final int frameNumber;
  final double gameTimeSeconds;
  final String? appLifecycle;

  Map<String, Object?> toJson() => {
    'lifecycle': {
      'loaded': loaded,
      'mounted': mounted,
      'removed': removed,
      'attached': attached,
      'app': appLifecycle,
    },
    'paused': paused,
    'frameNumber': frameNumber,
    'gameTimeSeconds': gameTimeSeconds,
  };
}

class ViewportSnapshot {
  const ViewportSnapshot({
    required this.hasLayout,
    required this.width,
    required this.height,
    required this.safeTop,
    required this.safeRight,
    required this.safeBottom,
    required this.safeLeft,
  });

  final bool hasLayout;
  final double? width;
  final double? height;
  final double safeTop;
  final double safeRight;
  final double safeBottom;
  final double safeLeft;

  Map<String, Object?> toJson() => {
    'hasLayout': hasLayout,
    'size': {'width': width, 'height': height},
    'safeInsets': {
      'top': safeTop,
      'right': safeRight,
      'bottom': safeBottom,
      'left': safeLeft,
    },
  };
}

class CoreflameSnapshot {
  const CoreflameSnapshot({
    required this.revision,
    required this.detail,
    required this.engine,
    required this.viewport,
    required this.match,
    required this.feedback,
    required this.components,
    this.scene,
  });

  static const schemaVersion = 1;

  final int revision;
  final SnapshotDetail detail;
  final EngineSnapshot engine;
  final ViewportSnapshot viewport;
  final MatchSnapshot match;
  final FeedbackSnapshot feedback;
  final SceneSnapshot? scene;
  final List<ComponentSnapshot> components;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'revision': revision,
    'detail': detail.name,
    'engine': engine.toJson(),
    'viewport': viewport.toJson(),
    'match': match.toJson(),
    'feedback': feedback.toJson(),
    'scene': scene?.toJson(),
    'components': components
        .map((component) => component.toJson())
        .toList(growable: false),
  };
}

enum CoreflameEventKind {
  gameLoaded,
  gameRemoved,
  lifecycleChanged,
  viewportChanged,
  enginePaused,
  engineResumed,
  engineStepped,
  moveAccepted,
  moveRejected,
  roundStarted,
  matchReset,
  settingsOpened,
  settingsClosed,
  feedbackStateChanged,
  feedbackFailure,
}

class CoreflameEvent {
  CoreflameEvent({
    required this.sequence,
    required this.revision,
    required this.gameTimeSeconds,
    required this.kind,
    Map<String, Object?> payload = const {},
  }) : payload = Map.unmodifiable(payload);

  final int sequence;
  final int revision;
  final double gameTimeSeconds;
  final CoreflameEventKind kind;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'sequence': sequence,
    'revision': revision,
    'gameTimeSeconds': gameTimeSeconds,
    'kind': kind.name,
    'payload': payload,
  };
}

class CoreflameEventBatch {
  CoreflameEventBatch({
    required this.requestedAfter,
    required this.oldestAvailableSequence,
    required this.latestSequence,
    required this.truncated,
    required List<CoreflameEvent> events,
  }) : events = List.unmodifiable(events);

  final int requestedAfter;
  final int? oldestAvailableSequence;
  final int latestSequence;
  final bool truncated;
  final List<CoreflameEvent> events;

  Map<String, Object?> toJson() => {
    'schemaVersion': CoreflameSnapshot.schemaVersion,
    'requestedAfter': requestedAfter,
    'oldestAvailableSequence': oldestAvailableSequence,
    'latestSequence': latestSequence,
    'truncated': truncated,
    'events': events.map((event) => event.toJson()).toList(growable: false),
  };
}

class CoreflameEventJournal {
  CoreflameEventJournal({int capacity = 256})
    : capacity = capacity > 0
          ? capacity
          : throw ArgumentError.value(capacity, 'capacity', 'must be positive');

  final int capacity;
  final ListQueue<CoreflameEvent> _events = ListQueue();
  int _nextSequence = 1;

  int get latestSequence => _nextSequence - 1;

  int? get oldestAvailableSequence =>
      _events.isEmpty ? null : _events.first.sequence;

  CoreflameEvent add({
    required int revision,
    required double gameTimeSeconds,
    required CoreflameEventKind kind,
    Map<String, Object?> payload = const {},
  }) {
    final event = CoreflameEvent(
      sequence: _nextSequence,
      revision: revision,
      gameTimeSeconds: gameTimeSeconds,
      kind: kind,
      payload: payload,
    );
    _nextSequence += 1;
    _events.addLast(event);
    if (_events.length > capacity) {
      _events.removeFirst();
    }
    return event;
  }

  List<CoreflameEvent> after(int sequence) => _events
      .where((event) => event.sequence > sequence)
      .toList(growable: false);

  CoreflameEventBatch batchAfter(int sequence) {
    if (sequence < 0) {
      throw RangeError.range(sequence, 0, null, 'sequence');
    }
    final oldest = oldestAvailableSequence;
    return CoreflameEventBatch(
      requestedAfter: sequence,
      oldestAvailableSequence: oldest,
      latestSequence: latestSequence,
      truncated: oldest != null && sequence < oldest - 1,
      events: after(sequence),
    );
  }

  List<CoreflameEvent> get all => List.unmodifiable(_events);
}

enum FeedbackSetting { sound, music, vibration }

sealed class CoreflameCommand {
  const CoreflameCommand();

  String get name;
}

class PlayCellCommand extends CoreflameCommand {
  const PlayCellCommand(this.cell);

  final int cell;

  @override
  String get name => 'playCell';
}

class StartNextRoundCommand extends CoreflameCommand {
  const StartNextRoundCommand();

  @override
  String get name => 'startNextRound';
}

class ResetMatchCommand extends CoreflameCommand {
  const ResetMatchCommand();

  @override
  String get name => 'resetMatch';
}

class SetSettingsOpenCommand extends CoreflameCommand {
  const SetSettingsOpenCommand(this.open);

  final bool open;

  @override
  String get name => 'setSettingsOpen';
}

class SetFeedbackSettingCommand extends CoreflameCommand {
  const SetFeedbackSettingCommand({
    required this.setting,
    required this.enabled,
  });

  final FeedbackSetting setting;
  final bool enabled;

  @override
  String get name => 'setFeedbackSetting';
}

class CoreflameCommandRequest {
  const CoreflameCommandRequest({required this.command, this.expectedRevision});

  final CoreflameCommand command;
  final int? expectedRevision;

  static CoreflameCommandRequest parse(Map<String, String> parameters) {
    final commandName = parameters['command'];
    if (commandName == null) {
      throw const FormatException('Missing command parameter');
    }

    final expectedRevision = _optionalNonNegativeInt(
      parameters,
      'expected_revision',
    );
    final command = switch (commandName) {
      'playCell' => PlayCellCommand(_requiredInt(parameters, 'cell')),
      'startNextRound' => const StartNextRoundCommand(),
      'resetMatch' => const ResetMatchCommand(),
      'setSettingsOpen' => SetSettingsOpenCommand(
        _requiredBool(parameters, 'open'),
      ),
      'setFeedbackSetting' => SetFeedbackSettingCommand(
        setting: _requiredSetting(parameters),
        enabled: _requiredBool(parameters, 'enabled'),
      ),
      _ => throw FormatException('Unknown command: $commandName'),
    };

    final allowedKeys = switch (command) {
      PlayCellCommand() => {'command', 'expected_revision', 'cell'},
      StartNextRoundCommand() ||
      ResetMatchCommand() => {'command', 'expected_revision'},
      SetSettingsOpenCommand() => {'command', 'expected_revision', 'open'},
      SetFeedbackSettingCommand() => {
        'command',
        'expected_revision',
        'setting',
        'enabled',
      },
    };
    final unexpectedKeys = parameters.keys
        .where((key) => !allowedKeys.contains(key))
        .toList(growable: false);
    if (unexpectedKeys.isNotEmpty) {
      throw FormatException(
        'Unexpected command parameter(s): ${unexpectedKeys.join(', ')}',
      );
    }

    return CoreflameCommandRequest(
      command: command,
      expectedRevision: expectedRevision,
    );
  }

  static int _requiredInt(Map<String, String> parameters, String key) {
    final value = parameters[key];
    final parsed = value == null ? null : int.tryParse(value);
    if (parsed == null) {
      throw FormatException('Expected integer parameter: $key');
    }
    return parsed;
  }

  static int? _optionalNonNegativeInt(
    Map<String, String> parameters,
    String key,
  ) {
    final value = parameters[key];
    if (value == null) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) {
      throw FormatException('Expected non-negative integer parameter: $key');
    }
    return parsed;
  }

  static bool _requiredBool(Map<String, String> parameters, String key) {
    return switch (parameters[key]) {
      'true' => true,
      'false' => false,
      _ => throw FormatException('Expected boolean parameter: $key'),
    };
  }

  static FeedbackSetting _requiredSetting(Map<String, String> parameters) {
    return switch (parameters['setting']) {
      'sound' => FeedbackSetting.sound,
      'music' => FeedbackSetting.music,
      'vibration' => FeedbackSetting.vibration,
      _ => throw const FormatException(
        'Expected setting parameter: sound, music, or vibration',
      ),
    };
  }
}

class CoreflameCommandResult {
  const CoreflameCommandResult({
    required this.accepted,
    required this.code,
    required this.message,
    required this.previousRevision,
    required this.currentRevision,
    required this.snapshot,
  });

  final bool accepted;
  final String code;
  final String message;
  final int previousRevision;
  final int currentRevision;
  final CoreflameSnapshot snapshot;

  Map<String, Object?> toJson() => {
    'accepted': accepted,
    'code': code,
    'message': message,
    'previousRevision': previousRevision,
    'currentRevision': currentRevision,
    'snapshot': snapshot.toJson(),
  };
}
