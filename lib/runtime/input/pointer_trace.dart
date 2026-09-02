import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';

enum PointerTraceCoordinateSpace { surface, normalized }

enum PointerTracePhase { down, move, up, cancel }

final class PointerTraceEvent {
  const PointerTraceEvent({
    required this.timeMicros,
    required this.pointer,
    required this.phase,
    required this.x,
    required this.y,
    this.kind = PointerDeviceKind.touch,
    this.buttons = kPrimaryButton,
  });

  final int timeMicros;
  final int pointer;
  final PointerTracePhase phase;
  final double x;
  final double y;
  final PointerDeviceKind kind;
  final int buttons;

  factory PointerTraceEvent.fromJson(Map<String, Object?> json) {
    _rejectUnknown(json, const {
      'timeMicros',
      'pointer',
      'phase',
      'x',
      'y',
      'kind',
      'buttons',
    });
    return PointerTraceEvent(
      timeMicros: _requiredInt(json, 'timeMicros'),
      pointer: _requiredInt(json, 'pointer'),
      phase: _requiredEnum(json, 'phase', PointerTracePhase.values),
      x: _requiredDouble(json, 'x'),
      y: _requiredDouble(json, 'y'),
      kind:
          _optionalEnum(json, 'kind', PointerDeviceKind.values) ??
          PointerDeviceKind.touch,
      buttons: _optionalInt(json, 'buttons') ?? kPrimaryButton,
    );
  }

  Map<String, Object?> toJson() => {
    'timeMicros': timeMicros,
    'pointer': pointer,
    'phase': phase.name,
    'x': x,
    'y': y,
    'kind': kind.name,
    'buttons': buttons,
  };
}

final class PointerTrace {
  PointerTrace({
    required List<PointerTraceEvent> events,
    this.coordinateSpace = PointerTraceCoordinateSpace.surface,
    this.protocolVersion = 1,
  }) : events = List.unmodifiable(events) {
    if (protocolVersion != 1) {
      throw FormatException(
        'Unsupported pointer trace protocol version: $protocolVersion',
      );
    }
    _validate();
  }

  final int protocolVersion;
  final PointerTraceCoordinateSpace coordinateSpace;
  final List<PointerTraceEvent> events;

  factory PointerTrace.fromJson(Map<String, Object?> json) {
    _rejectUnknown(json, const {
      'protocolVersion',
      'coordinateSpace',
      'events',
    });
    final rawEvents = json['events'];
    if (rawEvents is! List<Object?>) {
      throw const FormatException('Expected pointer trace events list');
    }
    return PointerTrace(
      protocolVersion: _requiredInt(json, 'protocolVersion'),
      coordinateSpace: _requiredEnum(
        json,
        'coordinateSpace',
        PointerTraceCoordinateSpace.values,
      ),
      events: rawEvents
          .map((event) {
            if (event is! Map<Object?, Object?>) {
              throw const FormatException(
                'Expected pointer trace event object',
              );
            }
            return PointerTraceEvent.fromJson(event.cast<String, Object?>());
          })
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() => {
    'protocolVersion': protocolVersion,
    'coordinateSpace': coordinateSpace.name,
    'events': events.map((event) => event.toJson()).toList(growable: false),
  };

  void _validate() {
    final activePointers = <int>{};
    var previousTime = 0;
    for (final event in events) {
      if (event.timeMicros < previousTime) {
        throw const FormatException(
          'Pointer trace timestamps must be non-decreasing',
        );
      }
      if (event.timeMicros < 0 || event.pointer < 0) {
        throw const FormatException(
          'Pointer trace timestamps and pointer IDs must not be negative',
        );
      }
      if (!event.x.isFinite || !event.y.isFinite) {
        throw const FormatException('Pointer trace coordinates must be finite');
      }
      if (coordinateSpace == PointerTraceCoordinateSpace.normalized &&
          (event.x < 0 || event.x > 1 || event.y < 0 || event.y > 1)) {
        throw const FormatException(
          'Normalized pointer trace coordinates must be between 0 and 1',
        );
      }
      switch (event.phase) {
        case PointerTracePhase.down:
          if (!activePointers.add(event.pointer)) {
            throw FormatException('Pointer ${event.pointer} is already active');
          }
        case PointerTracePhase.move:
          if (!activePointers.contains(event.pointer)) {
            throw FormatException(
              'Pointer ${event.pointer} moved before going down',
            );
          }
        case PointerTracePhase.up || PointerTracePhase.cancel:
          if (!activePointers.remove(event.pointer)) {
            throw FormatException(
              'Pointer ${event.pointer} ended before going down',
            );
          }
      }
      previousTime = event.timeMicros;
    }
    if (activePointers.isNotEmpty) {
      throw FormatException(
        'Pointer trace left active pointer(s): ${activePointers.join(', ')}',
      );
    }
  }
}

abstract interface class PointerTraceTarget {
  Size get surfaceSize;

  Offset localToGlobal(Offset position);

  void dispatchPointerEvent(PointerEvent event);

  Future<void> elapse(Duration duration);
}

final class PointerTracePlayer {
  const PointerTracePlayer();

  Future<int> play(PointerTrace trace, PointerTraceTarget target) async {
    var previousTime = 0;
    for (final event in trace.events) {
      final deltaMicros = event.timeMicros - previousTime;
      if (deltaMicros > 0) {
        await target.elapse(Duration(microseconds: deltaMicros));
      }
      final localPosition = switch (trace.coordinateSpace) {
        PointerTraceCoordinateSpace.surface => Offset(event.x, event.y),
        PointerTraceCoordinateSpace.normalized => Offset(
          event.x * target.surfaceSize.width,
          event.y * target.surfaceSize.height,
        ),
      };
      final position = target.localToGlobal(localPosition);
      final timeStamp = Duration(microseconds: event.timeMicros);
      target.dispatchPointerEvent(switch (event.phase) {
        PointerTracePhase.down => PointerDownEvent(
          timeStamp: timeStamp,
          pointer: event.pointer,
          position: position,
          kind: event.kind,
          buttons: event.buttons,
        ),
        PointerTracePhase.move => PointerMoveEvent(
          timeStamp: timeStamp,
          pointer: event.pointer,
          position: position,
          kind: event.kind,
          buttons: event.buttons,
        ),
        PointerTracePhase.up => PointerUpEvent(
          timeStamp: timeStamp,
          pointer: event.pointer,
          position: position,
          kind: event.kind,
        ),
        PointerTracePhase.cancel => PointerCancelEvent(
          timeStamp: timeStamp,
          pointer: event.pointer,
          position: position,
          kind: event.kind,
        ),
      });
      previousTime = event.timeMicros;
    }
    return trace.events.length;
  }
}

void _rejectUnknown(Map<String, Object?> json, Set<String> allowed) {
  final unknown = json.keys.where((key) => !allowed.contains(key)).toList();
  if (unknown.isNotEmpty) {
    throw FormatException('Unexpected field(s): ${unknown.join(', ')}');
  }
}

int _requiredInt(Map<String, Object?> json, String name) {
  final value = json[name];
  if (value is! int) throw FormatException('Expected integer field: $name');
  return value;
}

int? _optionalInt(Map<String, Object?> json, String name) {
  final value = json[name];
  if (value == null) return null;
  if (value is! int) throw FormatException('Expected integer field: $name');
  return value;
}

double _requiredDouble(Map<String, Object?> json, String name) {
  final value = json[name];
  if (value is! num) throw FormatException('Expected number field: $name');
  return value.toDouble();
}

T _requiredEnum<T extends Enum>(
  Map<String, Object?> json,
  String name,
  Iterable<T> values,
) {
  final value = _optionalEnum(json, name, values);
  if (value == null) throw FormatException('Expected string field: $name');
  return value;
}

T? _optionalEnum<T extends Enum>(
  Map<String, Object?> json,
  String name,
  Iterable<T> values,
) {
  final value = json[name];
  if (value == null) return null;
  if (value is! String) throw FormatException('Expected string field: $name');
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('Unknown $name: $value');
}
