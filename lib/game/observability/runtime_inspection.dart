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

abstract interface class InspectionEventKind {
  String get wireName;
}

enum RuntimeEventKind implements InspectionEventKind {
  gameLoaded,
  gameRemoved,
  lifecycleChanged,
  viewportChanged,
  enginePaused,
  engineResumed,
  engineStepped;

  @override
  String get wireName => name;
}

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
    this.worldBounds,
    this.screenBounds,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double scaleX;
  final double scaleY;
  final double angle;
  final String anchor;

  /// Axis-aligned bounds after resolving the component's world transforms.
  final RectSnapshot? worldBounds;

  /// Axis-aligned bounds after resolving the primary camera or viewport.
  final RectSnapshot? screenBounds;

  Map<String, Object?> toJson() => {
    'position': {'x': x, 'y': y},
    'size': {'width': width, 'height': height},
    'scale': {'x': scaleX, 'y': scaleY},
    'angle': angle,
    'anchor': anchor,
    if (worldBounds case final value?) 'worldBounds': value.toJson(),
    if (screenBounds case final value?) 'screenBounds': value.toJson(),
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

abstract interface class RuntimeInspectable {
  String get inspectionId;

  Map<String, Object?> inspectState(SnapshotDetail detail);
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

abstract interface class GameInspectionState {
  Map<String, Object?> toJson();
}

class GameInspectionSnapshot {
  const GameInspectionSnapshot({
    required this.id,
    required this.schemaVersion,
    required this.state,
  });

  final String id;
  final int schemaVersion;
  final GameInspectionState state;

  Map<String, Object?> toJson() => {
    'id': id,
    'schemaVersion': schemaVersion,
    'state': state.toJson(),
  };
}

class RuntimeSnapshot {
  const RuntimeSnapshot({
    required this.revision,
    required this.detail,
    required this.engine,
    required this.viewport,
    required this.game,
    required this.components,
  });

  static const protocolVersion = 1;

  final int revision;
  final SnapshotDetail detail;
  final EngineSnapshot engine;
  final ViewportSnapshot viewport;
  final GameInspectionSnapshot game;
  final List<ComponentSnapshot> components;

  Map<String, Object?> toJson() => {
    'protocolVersion': protocolVersion,
    'revision': revision,
    'detail': detail.name,
    'engine': engine.toJson(),
    'viewport': viewport.toJson(),
    'game': game.toJson(),
    'components': components
        .map((component) => component.toJson())
        .toList(growable: false),
  };
}

class RuntimeEvent {
  RuntimeEvent({
    required this.sequence,
    required this.revision,
    required this.gameTimeSeconds,
    required this.kind,
    Map<String, Object?> payload = const {},
  }) : payload = Map.unmodifiable(payload);

  final int sequence;
  final int revision;
  final double gameTimeSeconds;
  final InspectionEventKind kind;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'sequence': sequence,
    'revision': revision,
    'gameTimeSeconds': gameTimeSeconds,
    'kind': kind.wireName,
    'payload': payload,
  };
}

class RuntimeEventBatch {
  RuntimeEventBatch({
    required this.requestedAfter,
    required this.oldestAvailableSequence,
    required this.latestSequence,
    required this.truncated,
    required List<RuntimeEvent> events,
  }) : events = List.unmodifiable(events);

  final int requestedAfter;
  final int? oldestAvailableSequence;
  final int latestSequence;
  final bool truncated;
  final List<RuntimeEvent> events;

  Map<String, Object?> toJson() => {
    'protocolVersion': RuntimeSnapshot.protocolVersion,
    'requestedAfter': requestedAfter,
    'oldestAvailableSequence': oldestAvailableSequence,
    'latestSequence': latestSequence,
    'truncated': truncated,
    'events': events.map((event) => event.toJson()).toList(growable: false),
  };
}

class RuntimeEventJournal {
  RuntimeEventJournal({int capacity = 256})
    : capacity = capacity > 0
          ? capacity
          : throw ArgumentError.value(capacity, 'capacity', 'must be positive');

  final int capacity;
  final ListQueue<RuntimeEvent> _events = ListQueue();
  int _nextSequence = 1;

  int get latestSequence => _nextSequence - 1;

  int? get oldestAvailableSequence =>
      _events.isEmpty ? null : _events.first.sequence;

  RuntimeEvent add({
    required int revision,
    required double gameTimeSeconds,
    required InspectionEventKind kind,
    Map<String, Object?> payload = const {},
  }) {
    final event = RuntimeEvent(
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

  List<RuntimeEvent> after(int sequence) => _events
      .where((event) => event.sequence > sequence)
      .toList(growable: false);

  RuntimeEventBatch batchAfter(int sequence) {
    if (sequence < 0) {
      throw RangeError.range(sequence, 0, null, 'sequence');
    }
    final oldest = oldestAvailableSequence;
    return RuntimeEventBatch(
      requestedAfter: sequence,
      oldestAvailableSequence: oldest,
      latestSequence: latestSequence,
      truncated: oldest != null && sequence < oldest - 1,
      events: after(sequence),
    );
  }

  List<RuntimeEvent> get all => List.unmodifiable(_events);
}

enum CommandParameterType { string, integer, number, boolean }

class CommandParameterDescriptor {
  const CommandParameterDescriptor({
    required this.name,
    required this.type,
    required this.required,
    required this.description,
  });

  final String name;
  final CommandParameterType type;
  final bool required;
  final String description;

  Map<String, Object?> toJson() => {
    'name': name,
    'type': type.name,
    'required': required,
    'description': description,
  };
}

class CommandDescriptor {
  const CommandDescriptor({
    required this.name,
    required this.description,
    this.parameters = const [],
  });

  final String name;
  final String description;
  final List<CommandParameterDescriptor> parameters;

  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'parameters': parameters
        .map((parameter) => parameter.toJson())
        .toList(growable: false),
  };
}

class RuntimeInspectionCapabilities {
  RuntimeInspectionCapabilities({
    required this.gameId,
    required this.gameSchemaVersion,
    required List<CommandDescriptor> commands,
  }) : commands = List.unmodifiable(commands);

  final String gameId;
  final int gameSchemaVersion;
  final List<CommandDescriptor> commands;

  Map<String, Object?> toJson() => {
    'protocolVersion': RuntimeSnapshot.protocolVersion,
    'game': {'id': gameId, 'schemaVersion': gameSchemaVersion},
    'commands': commands
        .map((command) => command.toJson())
        .toList(growable: false),
  };
}

class RuntimeCommandEnvelope {
  RuntimeCommandEnvelope({
    required this.name,
    this.expectedRevision,
    Map<String, String> arguments = const {},
  }) : arguments = Map.unmodifiable(arguments) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (expectedRevision case final revision? when revision < 0) {
      throw ArgumentError.value(
        revision,
        'expectedRevision',
        'must not be negative',
      );
    }
  }

  final String name;
  final int? expectedRevision;
  final Map<String, String> arguments;

  static RuntimeCommandEnvelope parse(Map<String, String> parameters) {
    final name = parameters['command'];
    if (name == null || name.isEmpty) {
      throw const FormatException('Missing command parameter');
    }

    final rawRevision = parameters['expected_revision'];
    final expectedRevision = rawRevision == null
        ? null
        : int.tryParse(rawRevision);
    if (rawRevision != null &&
        (expectedRevision == null || expectedRevision < 0)) {
      throw const FormatException(
        'Expected expected_revision to be a non-negative integer',
      );
    }

    return RuntimeCommandEnvelope(
      name: name,
      expectedRevision: expectedRevision,
      arguments: Map.fromEntries(
        parameters.entries.where(
          (entry) => entry.key != 'command' && entry.key != 'expected_revision',
        ),
      ),
    );
  }
}

class RuntimeCommandOutcome {
  const RuntimeCommandOutcome({
    required this.accepted,
    required this.code,
    required this.message,
  });

  final bool accepted;
  final String code;
  final String message;
}

class RuntimeCommandResult {
  const RuntimeCommandResult({
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
  final RuntimeSnapshot snapshot;

  Map<String, Object?> toJson() => {
    'accepted': accepted,
    'code': code,
    'message': message,
    'previousRevision': previousRevision,
    'currentRevision': currentRevision,
    'snapshot': snapshot.toJson(),
  };
}

abstract interface class RuntimeInspectionAdapter {
  String get gameId;

  int get schemaVersion;

  List<CommandDescriptor> get commands;

  GameInspectionState snapshot(SnapshotDetail detail);

  RuntimeCommandOutcome dispatch(RuntimeCommandEnvelope command);
}

typedef RuntimeEventRecorder =
    void Function(
      InspectionEventKind kind,
      Map<String, Object?> payload, {
      bool changesState,
    });
