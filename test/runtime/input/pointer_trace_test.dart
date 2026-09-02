import 'package:coreflame/runtime/input/pointer_trace.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PointerTrace', () {
    test('round-trips a valid multi-pointer trace', () {
      final trace = PointerTrace(
        coordinateSpace: PointerTraceCoordinateSpace.normalized,
        events: const [
          PointerTraceEvent(
            timeMicros: 0,
            pointer: 1,
            phase: PointerTracePhase.down,
            x: 0.25,
            y: 0.5,
          ),
          PointerTraceEvent(
            timeMicros: 0,
            pointer: 2,
            phase: PointerTracePhase.down,
            x: 0.75,
            y: 0.5,
          ),
          PointerTraceEvent(
            timeMicros: 16000,
            pointer: 1,
            phase: PointerTracePhase.up,
            x: 0.25,
            y: 0.5,
          ),
          PointerTraceEvent(
            timeMicros: 16000,
            pointer: 2,
            phase: PointerTracePhase.cancel,
            x: 0.75,
            y: 0.5,
          ),
        ],
      );

      final decoded = PointerTrace.fromJson(trace.toJson());

      expect(decoded.coordinateSpace, PointerTraceCoordinateSpace.normalized);
      expect(decoded.events, hasLength(4));
      expect(decoded.events.first.kind, PointerDeviceKind.touch);
    });

    test('rejects invalid pointer lifecycles and unknown fields', () {
      expect(
        () => PointerTrace(
          events: const [
            PointerTraceEvent(
              timeMicros: 0,
              pointer: 1,
              phase: PointerTracePhase.move,
              x: 10,
              y: 10,
            ),
          ],
        ),
        throwsFormatException,
      );
      expect(
        () => PointerTrace.fromJson(const {
          'protocolVersion': 1,
          'coordinateSpace': 'surface',
          'events': <Object?>[],
          'unexpected': true,
        }),
        throwsFormatException,
      );
    });
  });
}
