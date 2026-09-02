import 'package:coreflame/runtime/input/pointer_trace.dart';
import 'package:coreflame/runtime/inspection/inspectable_flame_game.dart';
import 'package:coreflame/runtime/inspection/inspection_surface.dart';
import 'package:coreflame/runtime/inspection/runtime_inspection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

void main() {
  group('InspectableGameSurface', () {
    testWidgets('steps, presents, and captures one atomic frame', (
      tester,
    ) async {
      final game = _CaptureGame();
      await tester.pumpWidget(
        Center(
          child: SizedBox.square(
            dimension: 64,
            child: InspectableGameSurface(game: game),
          ),
        ),
      );
      await tester.pump();
      game.pauseEngine();
      final initialFrame = game.frameNumber;

      final pending = game.captureFrame(
        const InspectionCaptureRequest(stepSeconds: 1 / 60, includePng: true),
      );
      await tester.pump();
      await tester.pump();
      final result = (await tester.runAsync(() => pending))!;

      expect(game.paused, isTrue);
      expect(game.frameNumber, initialFrame + 1);
      expect(result.presentedFrameNumber, game.frameNumber);
      expect(
        result.snapshot.engine.presentedFrameNumber,
        result.snapshot.engine.frameNumber,
      );
      expect(result.pngBytes!.take(4), const [137, 80, 78, 71]);
    });

    testWidgets('rejects capture while the engine is running', (tester) async {
      final game = _CaptureGame();
      await tester.pumpWidget(InspectableGameSurface(game: game));
      await tester.pump();

      await expectLater(
        game.captureFrame(const InspectionCaptureRequest()),
        throwsFormatException,
      );
    });

    testWidgets('replays pointer traces through Flutter and Flame', (
      tester,
    ) async {
      final game = _CaptureGame();
      await tester.pumpWidget(
        Center(
          child: SizedBox.square(
            dimension: 64,
            child: InspectableGameSurface(game: game),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      game.pauseEngine();

      final pending = game.replayPointerTrace(
        PointerTrace(
          events: const [
            PointerTraceEvent(
              timeMicros: 0,
              pointer: 42,
              phase: PointerTracePhase.down,
              x: 32,
              y: 32,
            ),
            PointerTraceEvent(
              timeMicros: 16000,
              pointer: 42,
              phase: PointerTracePhase.up,
              x: 32,
              y: 32,
            ),
          ],
        ),
      );
      await tester.pump();
      final result = (await tester.runAsync(() => pending))!;
      await tester.pump(const Duration(milliseconds: 50));

      expect(result.eventsDispatched, 2);
      expect(game.wasTapped, isTrue);
      expect((result.snapshot.game.state as _CaptureState).wasTapped, isTrue);
    });
  });
}

class _CaptureGame extends InspectableFlameGame {
  late final _CaptureAdapter _adapter = _CaptureAdapter(this);
  final Paint _paint = Paint()..color = Colors.blue;
  bool wasTapped = false;

  @override
  RuntimeInspectionAdapter get inspectionAdapter => _adapter;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(_TapTarget(onTap: () => wasTapped = true));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(Offset.zero & Size(canvasSize.x, canvasSize.y), _paint);
  }
}

class _CaptureAdapter implements RuntimeInspectionAdapter {
  _CaptureAdapter(this.game);

  final _CaptureGame game;

  @override
  final RuntimeCommandRegistry commandRegistry = RuntimeCommandRegistry([]);

  @override
  String get gameId => 'capture';

  @override
  int get schemaVersion => 1;

  @override
  GameInspectionState snapshot(SnapshotDetail detail) =>
      _CaptureState(wasTapped: game.wasTapped);
}

class _CaptureState implements GameInspectionState {
  const _CaptureState({required this.wasTapped});

  final bool wasTapped;

  @override
  Map<String, Object?> toJson() => {'wasTapped': wasTapped};
}

class _TapTarget extends PositionComponent with TapCallbacks {
  _TapTarget({required this.onTap})
    : super(position: Vector2.zero(), size: Vector2.all(64));

  final VoidCallback onTap;

  @override
  void onTapDown(TapDownEvent event) => onTap();
}
