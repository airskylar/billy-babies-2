import 'dart:collection';
import 'dart:convert';

import '../input/pointer_trace.dart';

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
  engineStepped,

  /// Host fallback for an applied command without a state-changing game event.
  commandApplied;

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
    required this.presentedFrameNumber,
    required this.gameTimeSeconds,
    required this.appLifecycle,
  });

  final bool loaded;
  final bool mounted;
  final bool removed;
  final bool attached;
  final bool paused;
  final int frameNumber;
  final int presentedFrameNumber;
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
    'presentedFrameNumber': presentedFrameNumber,
    'gameTimeSeconds': gameTimeSeconds,
  };
}

class InspectionCaptureRequest {
  const InspectionCaptureRequest({
    this.stepSeconds,
    this.detail = SnapshotDetail.visual,
    this.includePng = false,
    this.pixelRatio = 1,
  });

  final double? stepSeconds;
  final SnapshotDetail detail;
  final bool includePng;
  final double pixelRatio;
}

class InspectionCaptureResult {
  const InspectionCaptureResult({
    required this.snapshot,
    required this.presentedFrameNumber,
    this.pngBytes,
  });

  final RuntimeSnapshot snapshot;
  final int presentedFrameNumber;
  final List<int>? pngBytes;

  Map<String, Object?> toJson() => {
    'presentedFrameNumber': presentedFrameNumber,
    'snapshot': snapshot.toJson(),
    if (pngBytes case final bytes?) 'pngBase64': base64Encode(bytes),
  };
}

class PointerReplayResult {
  const PointerReplayResult({
    required this.eventsDispatched,
    required this.snapshot,
  });

  final int eventsDispatched;
  final RuntimeSnapshot snapshot;

  Map<String, Object?> toJson() => {
    'eventsDispatched': eventsDispatched,
    'snapshot': snapshot.toJson(),
  };
}

abstract interface class RuntimeInspectionSurface {
  Future<InspectionCaptureResult> capture(InspectionCaptureRequest request);

  Future<PointerReplayResult> replay(PointerTrace trace);

  void didPresentFrame(int frameNumber);
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

final class CommandArguments {
  CommandArguments(Map<String, String> values)
    : _values = Map.unmodifiable(values);

  final Map<String, String> _values;
  final Set<String> _consumed = {};

  String requireString(String name) {
    final value = _values[name];
    if (value == null) {
      throw FormatException('Expected string parameter: $name');
    }
    _consumed.add(name);
    return value;
  }

  int requireInt(String name) {
    final value = requireString(name);
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw FormatException('Expected integer parameter: $name');
    }
    return parsed;
  }

  double requireFiniteDouble(String name) {
    final value = requireString(name);
    final parsed = double.tryParse(value);
    if (parsed == null || !parsed.isFinite) {
      throw FormatException('Expected finite number parameter: $name');
    }
    return parsed;
  }

  bool requireBool(String name) => switch (requireString(name)) {
    'true' => true,
    'false' => false,
    _ => throw FormatException('Expected boolean parameter: $name'),
  };

  T requireEnum<T extends Enum>(
    String name,
    Iterable<T> values, {
    String Function(T value)? wireName,
  }) {
    final value = requireString(name);
    final encode = wireName ?? (candidate) => candidate.name;
    for (final candidate in values) {
      if (encode(candidate) == value) return candidate;
    }
    final expected = values.map(encode).join(', ');
    throw FormatException('Expected $name parameter: $expected');
  }

  void rejectUnknown() {
    final unexpected = _values.keys
        .where((key) => !_consumed.contains(key))
        .toList(growable: false);
    if (unexpected.isNotEmpty) {
      throw FormatException(
        'Unexpected command parameter(s): ${unexpected.join(', ')}',
      );
    }
  }
}

final class RuntimeCommandSpec<C> {
  const RuntimeCommandSpec({
    required this.descriptor,
    required this.decode,
    required this.encode,
  });

  final CommandDescriptor descriptor;
  final C Function(CommandArguments arguments) decode;
  final Map<String, String> Function(C command) encode;

  C decodeEnvelope(RuntimeCommandEnvelope envelope) {
    if (envelope.name != descriptor.name) {
      throw FormatException(
        'Expected command ${descriptor.name}, received ${envelope.name}',
      );
    }
    final arguments = CommandArguments(envelope.arguments);
    final command = decode(arguments);
    arguments.rejectUnknown();
    return command;
  }

  RuntimeCommandEnvelope envelope(C command, {int? expectedRevision}) =>
      RuntimeCommandEnvelope(
        name: descriptor.name,
        expectedRevision: expectedRevision,
        arguments: encode(command),
      );
}

abstract interface class RuntimeCommandRoute {
  CommandDescriptor get descriptor;

  Future<RuntimeCommandOutcome> dispatch(RuntimeCommandEnvelope envelope);
}

final class RuntimeCommandHandler<C> implements RuntimeCommandRoute {
  const RuntimeCommandHandler({required this.spec, required this.handle});

  final RuntimeCommandSpec<C> spec;
  final Future<RuntimeCommandOutcome> Function(C command) handle;

  @override
  CommandDescriptor get descriptor => spec.descriptor;

  @override
  Future<RuntimeCommandOutcome> dispatch(RuntimeCommandEnvelope envelope) =>
      handle(spec.decodeEnvelope(envelope));
}

final class RuntimeCommandRegistry {
  factory RuntimeCommandRegistry(Iterable<RuntimeCommandRoute> routes) {
    final routeList = routes.toList(growable: false);
    final routesByName = {
      for (final route in routeList) route.descriptor.name: route,
    };
    if (routesByName.length != routeList.length) {
      throw ArgumentError('Command names must be unique');
    }
    return RuntimeCommandRegistry._(Map.unmodifiable(routesByName));
  }

  const RuntimeCommandRegistry._(this._routes);

  final Map<String, RuntimeCommandRoute> _routes;

  List<CommandDescriptor> get descriptors =>
      _routes.values.map((route) => route.descriptor).toList(growable: false);

  Future<RuntimeCommandOutcome> dispatch(RuntimeCommandEnvelope envelope) {
    final route = _routes[envelope.name];
    if (route == null) {
      throw FormatException('Unknown command: ${envelope.name}');
    }
    return route.dispatch(envelope);
  }
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

enum RuntimeCommandDisposition {
  /// The command was not performed.
  rejected,

  /// The command was valid, but its requested postcondition already held.
  noChange,

  /// The command changed authoritative game state.
  applied,
}

class RuntimeCommandOutcome {
  const RuntimeCommandOutcome({
    required this.disposition,
    required this.code,
    required this.message,
  });

  final RuntimeCommandDisposition disposition;
  final String code;
  final String message;
}

class RuntimeCommandResult {
  const RuntimeCommandResult({
    required this.disposition,
    required this.code,
    required this.message,
    required this.previousRevision,
    required this.currentRevision,
    required this.snapshot,
  });

  final RuntimeCommandDisposition disposition;
  final String code;
  final String message;
  final int previousRevision;
  final int currentRevision;
  final RuntimeSnapshot snapshot;

  Map<String, Object?> toJson() => {
    'disposition': disposition.name,
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

  RuntimeCommandRegistry get commandRegistry;

  GameInspectionState snapshot(SnapshotDetail detail);
}

abstract interface class InspectionEventData {
  InspectionEventKind get kind;

  Map<String, Object?> get payload;

  bool get changesState;
}

typedef RuntimeEventRecorder = void Function(InspectionEventData event);
