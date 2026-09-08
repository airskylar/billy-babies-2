import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../runtime/inspection/runtime_inspection.dart';
import '../inspection/protocol.dart';
import '../theme/game_palette.dart';

class BillyBabiesDuelScene extends PositionComponent
    implements RuntimeInspectable {
  BillyBabiesDuelScene() : super(key: ComponentKey.named('duel-shell'));

  static const sceneName = 'Billy Babies Duel Shell';
  EdgeInsets _safePadding = EdgeInsets.zero;

  @override
  String get inspectionId => 'duel-shell';

  DuelSceneSnapshot snapshot(SnapshotDetail detail) => DuelSceneSnapshot(
    name: sceneName,
    ready: isLoaded && isMounted,
    orientation: size.x >= size.y ? 'landscape' : 'portrait',
    bounds: detail == SnapshotDetail.visual
        ? RectSnapshot(x: 0, y: 0, width: size.x, height: size.y)
        : null,
  );

  @override
  Map<String, Object?> inspectState(SnapshotDetail detail) =>
      snapshot(detail).toJson();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    applySafeViewport(findGame()!.size, _safePadding);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    applySafeViewport(size, _safePadding);
  }

  void applySafeViewport(Vector2 gameSize, EdgeInsets padding) {
    _safePadding = padding;
    position = Vector2(padding.left, padding.top);
    size = Vector2(
      math.max(0, gameSize.x - padding.horizontal),
      math.max(0, gameSize.y - padding.vertical),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sceneRect = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(sceneRect, Paint()..color = DuelPalette.canvas);

    final panelWidth = math.min(size.x - 32, 760.0);
    final panelHeight = math.min(size.y - 32, 360.0);
    final panel = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: sceneRect.center,
        width: math.max(0, panelWidth),
        height: math.max(0, panelHeight),
      ),
      const Radius.circular(28),
    );
    canvas.drawRRect(panel, Paint()..color = DuelPalette.panel);
    canvas.drawRRect(
      panel,
      Paint()
        ..color = DuelPalette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final center = panel.outerRect.center;
    _drawQualityMark(canvas, Offset(center.dx, center.dy - 88));
    _drawCenteredText(
      canvas,
      'BILLY BABIES DUEL',
      Offset(center.dx, center.dy - 16),
      const TextStyle(
        color: DuelPalette.ink,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
    _drawCenteredText(
      canvas,
      'Prototype foundation',
      Offset(center.dx, center.dy + 30),
      const TextStyle(
        color: DuelPalette.violet,
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
    );
    _drawCenteredText(
      canvas,
      'Setup is not available yet',
      Offset(center.dx, center.dy + 66),
      const TextStyle(color: DuelPalette.mutedInk, fontSize: 15),
    );
  }

  void _drawQualityMark(Canvas canvas, Offset center) {
    final linePaint = Paint()
      ..color = DuelPalette.outline
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawLine(
      center.translate(-70, 0),
      center.translate(70, 0),
      linePaint,
    );
    canvas.drawCircle(center, 20, Paint()..color = DuelPalette.violet);
    canvas.drawCircle(
      center.translate(-70, 0),
      8,
      Paint()..color = DuelPalette.mint,
    );
    canvas.drawCircle(
      center.translate(70, 0),
      8,
      Paint()..color = DuelPalette.coral,
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: math.max(0, size.x - 48));
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }
}
