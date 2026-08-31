import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import '../game_action_origin.dart';
import '../observability/runtime_inspection.dart';
import '../observability/tiny_tactics_inspection.dart';
import '../services/game_feedback.dart';
import '../services/game_platform_services.dart';
import '../theme/game_palette.dart';
import '../tic_tac_toe_match.dart';

class CozyTicTacToeScene extends PositionComponent
    with TapCallbacks
    implements RuntimeInspectable {
  CozyTicTacToeScene({
    required this.match,
    required this.feedback,
    required this.platformServices,
    required this.recordEvent,
  }) : _boardState = _BoardStateComponent(match),
       _roundControl = _RoundControlStateComponent(),
       _settingsState = _SettingsStateComponent(),
       super(key: ComponentKey.named('scene')) {
    addAll([_boardState, _roundControl, _settingsState]);
  }

  static const _fontFamily = 'Gluten';

  final TicTacToeMatch match;
  final GameFeedback feedback;
  final GamePlatformServices platformServices;
  final RuntimeEventRecorder recordEvent;
  final _BoardStateComponent _boardState;
  final _RoundControlStateComponent _roundControl;
  final _SettingsStateComponent _settingsState;

  _SceneLayout? _layout;
  Svg? _restartIcon;
  Svg? _settingsIcon;
  EdgeInsets _safePadding = EdgeInsets.zero;
  double _elapsed = 0;

  @override
  String get inspectionId => 'scene';

  SceneSnapshot snapshot(SnapshotDetail detail) {
    final visual = detail == SnapshotDetail.visual;
    return SceneSnapshot(
      overlay: _settingsState.overlay.name,
      assetsLoaded: _restartIcon != null && _settingsIcon != null,
      animationsSettled:
          _boardState.animationsSettled && _roundControl.animationSettled,
      lastPlacedCell: _boardState.lastPlacedCell,
      elapsedSeconds: visual ? _elapsed : null,
      markProgress: visual ? List.unmodifiable(_boardState.markProgress) : null,
      winningLineProgress: visual ? _boardState.winningLineProgress : null,
      roundButtonPhase: visual ? _roundControl.phase.name : null,
      roundButtonSink: visual ? _roundControl.sink : null,
      roundButtonVelocity: visual ? _roundControl.velocity : null,
      layout: visual ? _layout?.snapshotForSize(size.x, size.y) : null,
    );
  }

  @override
  Map<String, Object?> inspectState(SnapshotDetail detail) =>
      snapshot(detail).toJson();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    applySafeViewport(findGame()!.size, _safePadding);
    _restartIcon = await Svg.load('icons/mingcute_refresh_4_line.svg');
    _settingsIcon = await Svg.load('icons/mingcute_settings_4_fill.svg');
  }

  @override
  void onRemove() {
    super.onRemove();
    _restartIcon?.dispose();
    _settingsIcon?.dispose();
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
    _layout = _SceneLayout.fromSize(size.x, size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  MoveOutcome playCell(
    int cell, {
    GameActionOrigin origin = GameActionOrigin.system,
  }) {
    final placedMark = match.turn;
    final outcome = match.play(cell);
    if (outcome != MoveOutcome.accepted) {
      recordEvent(TinyTacticsEventKind.moveRejected, {
        'cell': cell,
        'reason': outcome.name,
        'origin': origin.name,
      }, changesState: false);
      return outcome;
    }

    feedback.playMove(placedMark, isWinningMove: match.winningCells.isNotEmpty);
    _boardState.onMovePlaced(cell);
    if (match.isFinished) {
      _elapsed = 0;
      _boardState.onRoundFinished();
      _reportFinishedRound();
    }
    recordEvent(TinyTacticsEventKind.moveAccepted, {
      'cell': cell,
      'mark': placedMark.name,
      'result': match.result.name,
      'winningCells': match.winningCells,
      'origin': origin.name,
    });
    return outcome;
  }

  void startNextRound({GameActionOrigin origin = GameActionOrigin.system}) {
    match.startNextRound();
    _boardState.onRoundStarted();
    recordEvent(TinyTacticsEventKind.roundStarted, {
      'starter': match.starter.name,
      'origin': origin.name,
    });
  }

  void resetMatch({GameActionOrigin origin = GameActionOrigin.system}) {
    match.resetMatch();
    _boardState.onRoundStarted();
    _elapsed = 0;
    recordEvent(TinyTacticsEventKind.matchReset, {'origin': origin.name});
  }

  bool setSettingsOpen(
    bool open, {
    GameActionOrigin origin = GameActionOrigin.system,
  }) {
    if (_settingsState.isOpen == open) return false;
    _settingsState.setOpen(open);
    if (open) {
      _roundControl.release();
    }
    recordEvent(
      open
          ? TinyTacticsEventKind.settingsOpened
          : TinyTacticsEventKind.settingsClosed,
      {'origin': origin.name},
    );
    return true;
  }

  bool setFeedbackSetting(
    FeedbackSetting setting,
    bool enabled, {
    GameActionOrigin origin = GameActionOrigin.system,
  }) {
    final currentValue = switch (setting) {
      FeedbackSetting.sound => feedback.soundEnabled,
      FeedbackSetting.music => feedback.musicEnabled,
      FeedbackSetting.vibration => feedback.vibrationEnabled,
    };
    if (currentValue == enabled) return false;

    switch (setting) {
      case FeedbackSetting.sound:
        feedback.setSoundEnabled(enabled, origin: origin);
      case FeedbackSetting.music:
        feedback.setMusicEnabled(enabled, origin: origin);
      case FeedbackSetting.vibration:
        feedback.setVibrationEnabled(enabled, origin: origin);
    }
    return true;
  }

  @override
  void onTapDown(TapDownEvent event) {
    feedback.handleUserGesture();
    final layout = _layout ?? _SceneLayout.fromSize(size.x, size.y);
    final point = Offset(event.localPosition.x, event.localPosition.y);

    if (_settingsState.isOpen) {
      _handleSettingsTap(point);
      return;
    }

    if (layout.settingsButton.contains(point)) {
      feedback.playButtonHaptic();
      setSettingsOpen(true, origin: GameActionOrigin.pointer);
      return;
    }

    if (layout.roundButton.contains(point)) {
      feedback.playButtonHaptic();
      _roundControl.press();
      return;
    }

    final cell = layout.cellAt(point);
    if (cell == null) {
      return;
    }
    playCell(cell, origin: GameActionOrigin.pointer);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_roundControl.phase != _RoundButtonPhase.pressed) return;

    final layout = _layout ?? _SceneLayout.fromSize(size.x, size.y);
    final point = Offset(event.localPosition.x, event.localPosition.y);
    final shouldStartRound = layout.roundButton.contains(point);
    _roundControl.release();

    if (shouldStartRound) {
      startNextRound(origin: GameActionOrigin.pointer);
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _roundControl.release();
  }

  void _reportFinishedRound() {
    switch (match.result) {
      case RoundResult.xWon || RoundResult.oWon:
        unawaited(platformServices.unlockAchievement(GameAchievement.firstWin));
        unawaited(
          platformServices.submitScore(
            leaderboard: GameLeaderboard.matchWins,
            score: math.max(match.xScore, match.oScore),
          ),
        );
        return;
      case RoundResult.playing || RoundResult.draw:
        return;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final layout = _layout ?? _SceneLayout.fromSize(size.x, size.y);

    _drawBackground(canvas, layout);
    _drawHeader(canvas, layout);
    _drawScores(canvas, layout);
    _drawStatus(canvas, layout);
    _drawBoard(canvas, layout);
    _drawRoundButton(canvas, layout);
    _drawFooter(canvas, layout);

    if (match.isFinished) {
      _drawCelebration(canvas, layout);
    }
    _drawSettingsButton(canvas, layout);
    if (_settingsState.isOpen) {
      _drawSettingsModal(canvas);
    }
  }

  void _drawBackground(Canvas canvas, _SceneLayout layout) {
    final bounds = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GamePalette.cream, Color(0xFFFFF4EE)],
        ).createShader(bounds),
    );

    final washPaint = Paint()..color = GamePalette.berryWash.withAlpha(120);
    canvas.drawCircle(
      Offset(size.x * 0.08, size.y * 0.12),
      math.min(size.x, size.y) * 0.13,
      washPaint,
    );
    washPaint.color = GamePalette.mintWash.withAlpha(155);
    canvas.drawCircle(
      Offset(size.x * 0.93, size.y * 0.82),
      math.min(size.x, size.y) * 0.18,
      washPaint,
    );

    final sparkleRadius = math.max(
      3.0,
      math.min(7.0, math.min(size.x, size.y) * 0.012),
    );
    _drawSparkle(
      canvas,
      Offset(size.x * 0.88, size.y * 0.1),
      sparkleRadius,
      GamePalette.sunshine.withAlpha(165),
      0.15,
    );
    _drawSparkle(
      canvas,
      Offset(size.x * 0.08, size.y * 0.78),
      sparkleRadius * 0.75,
      GamePalette.peach.withAlpha(120),
      -0.1,
    );

    if (layout.isLandscape) {
      _drawSparkle(
        canvas,
        Offset(layout.panelBounds.right - 12, layout.panelBounds.top + 22),
        sparkleRadius * 0.7,
        GamePalette.mint.withAlpha(150),
        0,
      );
    }
  }

  void _drawHeader(Canvas canvas, _SceneLayout layout) {
    final flowerCenter = Offset(
      layout.titleCenter.dx - layout.titleWidth * 0.42,
      layout.titleTop + layout.titleSize * 0.48,
    );
    _drawFlower(canvas, flowerCenter, layout.titleSize * 0.23);

    _drawText(
      canvas,
      'Tiny Tactics',
      Offset(layout.titleCenter.dx, layout.titleTop),
      TextStyle(
        color: GamePalette.ink,
        fontSize: layout.titleSize,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.1,
        height: 1,
      ),
      anchor: _TextAnchor.topCenter,
    );
    _drawText(
      canvas,
      'A cozy little Flame game',
      Offset(layout.titleCenter.dx, layout.subtitleTop),
      TextStyle(
        color: GamePalette.mutedInk,
        fontSize: layout.subtitleSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      anchor: _TextAnchor.topCenter,
    );
  }

  void _drawSettingsButton(Canvas canvas, _SceneLayout layout) {
    final rect = layout.settingsButton;
    final center = rect.center;
    final radius = rect.width / 2;
    canvas.drawCircle(
      center.translate(0, 3),
      radius,
      Paint()..color = GamePalette.shadow,
    );
    canvas.drawCircle(center, radius, Paint()..color = GamePalette.paper);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = GamePalette.outline,
    );
    _drawTintedSvg(
      canvas,
      _settingsIcon,
      rect.deflate(rect.width * 0.24),
      GamePalette.berry,
    );
  }

  void _handleSettingsTap(Offset point) {
    final modal = _SettingsModalLayout.fromSize(size.x, size.y);
    if (modal.closeButton.contains(point)) {
      feedback.playButtonHaptic();
      setSettingsOpen(false, origin: GameActionOrigin.pointer);
      return;
    }
    if (!modal.card.contains(point)) {
      setSettingsOpen(false, origin: GameActionOrigin.pointer);
      return;
    }

    for (final row in modal.rows) {
      if (!row.rect.contains(point)) continue;
      switch (row.kind) {
        case _SettingKind.sound:
          feedback.playButtonHaptic();
          setFeedbackSetting(
            FeedbackSetting.sound,
            !feedback.soundEnabled,
            origin: GameActionOrigin.pointer,
          );
        case _SettingKind.music:
          feedback.playButtonHaptic();
          setFeedbackSetting(
            FeedbackSetting.music,
            !feedback.musicEnabled,
            origin: GameActionOrigin.pointer,
          );
        case _SettingKind.vibration:
          setFeedbackSetting(
            FeedbackSetting.vibration,
            !feedback.vibrationEnabled,
            origin: GameActionOrigin.pointer,
          );
      }
      return;
    }
  }

  void _drawSettingsModal(Canvas canvas) {
    final modal = _SettingsModalLayout.fromSize(size.x, size.y);
    canvas.drawRect(
      Rect.fromLTRB(
        -_safePadding.left,
        -_safePadding.top,
        size.x + _safePadding.right,
        size.y + _safePadding.bottom,
      ),
      Paint()..color = GamePalette.ink.withAlpha(112),
    );

    final card = RRect.fromRectAndRadius(
      modal.card,
      Radius.circular(modal.card.width * 0.07),
    );
    canvas.drawRRect(
      card.shift(const Offset(0, 8)),
      Paint()..color = GamePalette.shadow,
    );
    canvas.drawRRect(card, Paint()..color = GamePalette.paper);
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = GamePalette.outline,
    );

    final iconRect = Rect.fromLTWH(
      modal.card.left + 20,
      modal.card.top + 20,
      34,
      34,
    );
    canvas.drawCircle(
      iconRect.center,
      iconRect.width / 2,
      Paint()..color = GamePalette.berryWash,
    );
    _drawTintedSvg(
      canvas,
      _settingsIcon,
      iconRect.deflate(7),
      GamePalette.berry,
    );
    _drawText(
      canvas,
      'Settings',
      Offset(iconRect.right + 11, modal.card.top + 19),
      const TextStyle(
        color: GamePalette.ink,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
      anchor: _TextAnchor.topLeft,
    );
    _drawText(
      canvas,
      'Make it feel just right',
      Offset(iconRect.right + 11, modal.card.top + 46),
      const TextStyle(
        color: GamePalette.mutedInk,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      anchor: _TextAnchor.topLeft,
    );

    canvas.drawCircle(
      modal.closeButton.center,
      modal.closeButton.width / 2,
      Paint()..color = GamePalette.berryWash.withAlpha(150),
    );
    final closeExtent = modal.closeButton.width * 0.18;
    final closePaint = Paint()
      ..color = GamePalette.mutedInk
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    canvas.drawLine(
      modal.closeButton.center.translate(-closeExtent, -closeExtent),
      modal.closeButton.center.translate(closeExtent, closeExtent),
      closePaint,
    );
    canvas.drawLine(
      modal.closeButton.center.translate(closeExtent, -closeExtent),
      modal.closeButton.center.translate(-closeExtent, closeExtent),
      closePaint,
    );

    for (final row in modal.rows) {
      final (label, detail, enabled, wash) = switch (row.kind) {
        _SettingKind.sound => (
          'Sound',
          'Move effects',
          feedback.soundEnabled,
          GamePalette.berryWash,
        ),
        _SettingKind.music => (
          'Music',
          'Blossom loop',
          feedback.musicEnabled,
          GamePalette.peachWash,
        ),
        _SettingKind.vibration => (
          'Vibrate',
          'Pulsar haptics',
          feedback.vibrationEnabled,
          GamePalette.mintWash,
        ),
      };
      final rowRRect = RRect.fromRectAndRadius(
        row.rect,
        Radius.circular(row.rect.height * 0.25),
      );
      canvas.drawRRect(rowRRect, Paint()..color = wash.withAlpha(145));
      canvas.drawRRect(
        rowRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = GamePalette.outline.withAlpha(150),
      );
      _drawText(
        canvas,
        label,
        Offset(row.rect.left + 16, row.rect.top + row.rect.height * 0.2),
        TextStyle(
          color: GamePalette.ink,
          fontSize: math.min(15, row.rect.height * 0.28),
          fontWeight: FontWeight.w800,
        ),
        anchor: _TextAnchor.topLeft,
      );
      _drawText(
        canvas,
        detail,
        Offset(row.rect.left + 16, row.rect.top + row.rect.height * 0.53),
        TextStyle(
          color: GamePalette.mutedInk,
          fontSize: math.min(11, row.rect.height * 0.2),
          fontWeight: FontWeight.w600,
        ),
        anchor: _TextAnchor.topLeft,
      );
      _drawToggle(canvas, row.toggle, enabled);
    }
  }

  void _drawToggle(Canvas canvas, Rect rect, bool enabled) {
    final track = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    canvas.drawRRect(
      track,
      Paint()..color = enabled ? GamePalette.berry : GamePalette.outline,
    );
    final knobRadius = rect.height * 0.37;
    final knobCenter = Offset(
      enabled ? rect.right - rect.height / 2 : rect.left + rect.height / 2,
      rect.center.dy,
    );
    canvas.drawCircle(
      knobCenter.translate(0, 1.5),
      knobRadius,
      Paint()..color = GamePalette.shadow,
    );
    canvas.drawCircle(knobCenter, knobRadius, Paint()..color = Colors.white);
  }

  void _drawTintedSvg(Canvas canvas, Svg? svg, Rect rect, Color color) {
    canvas.save();
    canvas.translate(rect.left, rect.top);
    svg?.render(
      canvas,
      Vector2(rect.width, rect.height),
      overridePaint: Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
    );
    canvas.restore();
  }

  void _drawScores(Canvas canvas, _SceneLayout layout) {
    _drawScoreCard(
      canvas,
      layout.xScoreCard,
      mark: Mark.x,
      score: match.xScore,
      isCurrent: !match.isFinished && match.turn == Mark.x,
    );
    _drawScoreCard(
      canvas,
      layout.oScoreCard,
      mark: Mark.o,
      score: match.oScore,
      isCurrent: !match.isFinished && match.turn == Mark.o,
    );
  }

  void _drawScoreCard(
    Canvas canvas,
    Rect rect, {
    required Mark mark,
    required int score,
    required bool isCurrent,
  }) {
    final baseColor = mark == Mark.x ? GamePalette.berry : GamePalette.peach;
    final washColor = mark == Mark.x
        ? GamePalette.berryWash
        : GamePalette.peachWash;
    final card = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height * 0.3),
    );

    canvas.drawRRect(
      card.shift(const Offset(0, 4)),
      Paint()..color = GamePalette.shadow,
    );
    canvas.drawRRect(card, Paint()..color = GamePalette.paper);
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 2.4 : 1.3
        ..color = isCurrent ? baseColor : GamePalette.outline,
    );

    final badgeCenter = Offset(rect.left + rect.height * 0.5, rect.center.dy);
    canvas.drawCircle(
      badgeCenter,
      rect.height * 0.31,
      Paint()..color = washColor,
    );
    _drawText(
      canvas,
      mark.symbol,
      badgeCenter,
      TextStyle(
        color: baseColor,
        fontSize: rect.height * 0.34,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
      anchor: _TextAnchor.center,
    );

    final labelX = rect.left + rect.height * 0.91;
    _drawText(
      canvas,
      mark.nickname.toUpperCase(),
      Offset(labelX, rect.top + rect.height * 0.23),
      TextStyle(
        color: GamePalette.mutedInk,
        fontSize: math.max(8, rect.height * 0.16),
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        height: 1,
      ),
      anchor: _TextAnchor.topLeft,
    );
    _drawText(
      canvas,
      '$score',
      Offset(labelX, rect.top + rect.height * 0.47),
      TextStyle(
        color: GamePalette.ink,
        fontSize: rect.height * 0.3,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
      anchor: _TextAnchor.topLeft,
    );
  }

  void _drawStatus(Canvas canvas, _SceneLayout layout) {
    final rect = layout.statusPill;
    final pill = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    canvas.drawRRect(pill, Paint()..color = GamePalette.paper.withAlpha(220));
    canvas.drawRRect(
      pill,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = GamePalette.outline,
    );

    final (message, dotColor) = switch (match.result) {
      RoundResult.playing => (
        '${match.turn.nickname}\'s turn  •  choose a square',
        match.turn == Mark.x ? GamePalette.berry : GamePalette.peach,
      ),
      RoundResult.xWon => (
        'Berry wins!  Tiny victory dance!',
        GamePalette.berry,
      ),
      RoundResult.oWon => (
        'Peach wins!  Tiny victory dance!',
        GamePalette.peach,
      ),
      RoundResult.draw => ('A perfectly cozy tie!', GamePalette.sunshine),
    };

    final fontSize = math.min(14.0, math.max(10.0, rect.height * 0.3));
    final dotRadius = math.max(3.5, rect.height * 0.09);
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700);
    final textWidth = _measureTextWidth(message, style);
    final groupWidth = dotRadius * 2 + 9 + textWidth;
    final dotCenter = Offset(
      rect.center.dx - groupWidth / 2 + dotRadius,
      rect.center.dy,
    );
    canvas.drawCircle(
      dotCenter,
      dotRadius + 3,
      Paint()..color = dotColor.withAlpha(35),
    );
    canvas.drawCircle(dotCenter, dotRadius, Paint()..color = dotColor);
    _drawText(
      canvas,
      message,
      Offset(dotCenter.dx + dotRadius + 9, rect.center.dy),
      style.copyWith(color: GamePalette.ink),
      anchor: _TextAnchor.centerLeft,
    );
  }

  void _drawBoard(Canvas canvas, _SceneLayout layout) {
    final board = layout.board;
    final boardRadius = Radius.circular(board.width * 0.075);
    final boardRRect = RRect.fromRectAndRadius(board, boardRadius);

    canvas.drawRRect(
      boardRRect.shift(Offset(0, board.width * 0.025)),
      Paint()..color = GamePalette.shadow,
    );
    canvas.drawRRect(boardRRect, Paint()..color = GamePalette.paper);
    canvas.drawRRect(
      boardRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = GamePalette.outline,
    );

    for (var index = 0; index < layout.cells.length; index += 1) {
      final rect = layout.cells[index];
      final isWinner = match.winningCells.contains(index);
      final cellColor = isWinner
          ? GamePalette.mintWash
          : index.isEven
          ? const Color(0xFFFFFBF8)
          : const Color(0xFFFBF8FF);
      final cell = RRect.fromRectAndRadius(
        rect,
        Radius.circular(rect.width * 0.16),
      );
      canvas.drawRRect(cell, Paint()..color = cellColor);
      canvas.drawRRect(
        cell,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, rect.width * 0.012)
          ..color = isWinner
              ? GamePalette.mint
              : GamePalette.outline.withAlpha(185),
      );

      final mark = match.markAt(index);
      if (mark != null) {
        final progress = Curves.easeOutBack.transform(
          _boardState.markProgress[index],
        );
        if (mark == Mark.x) {
          _drawBerryMark(canvas, rect.center, rect.width * 0.25 * progress);
        } else {
          _drawPeachMark(canvas, rect.center, rect.width * 0.27 * progress);
        }
      }
    }

    _drawWinningLine(canvas, layout);
  }

  void _drawBerryMark(Canvas canvas, Offset center, double radius) {
    if (radius <= 0) return;
    final shadowPaint = Paint()
      ..color = GamePalette.shadow
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.46;
    final paint = Paint()
      ..color = GamePalette.berry
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.33;
    final inset = radius * 0.68;

    canvas.drawLine(
      Offset(center.dx - inset, center.dy - inset + radius * 0.12),
      Offset(center.dx + inset, center.dy + inset + radius * 0.12),
      shadowPaint,
    );
    canvas.drawLine(
      Offset(center.dx + inset, center.dy - inset + radius * 0.12),
      Offset(center.dx - inset, center.dy + inset + radius * 0.12),
      shadowPaint,
    );
    canvas.drawLine(
      Offset(center.dx - inset, center.dy - inset),
      Offset(center.dx + inset, center.dy + inset),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + inset, center.dy - inset),
      Offset(center.dx - inset, center.dy + inset),
      paint,
    );
    final cheekPaint = Paint()..color = GamePalette.peach.withAlpha(135);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.76, center.dy + radius * 0.12),
      radius * 0.1,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.76, center.dy + radius * 0.12),
      radius * 0.1,
      cheekPaint,
    );
  }

  void _drawPeachMark(Canvas canvas, Offset center, double radius) {
    if (radius <= 0) return;
    canvas.drawCircle(
      center.translate(0, radius * 0.08),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.39
        ..color = GamePalette.shadow,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.28
        ..color = GamePalette.peach,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.2,
      0.72,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.11
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withAlpha(190),
    );
  }

  void _drawWinningLine(Canvas canvas, _SceneLayout layout) {
    if (match.winningCells.length != 3) return;
    final start = layout.cells[match.winningCells.first].center;
    final target = layout.cells[match.winningCells.last].center;
    final eased = Curves.easeOutCubic.transform(
      _boardState.winningLineProgress,
    );
    final end = Offset.lerp(start, target, eased)!;
    final lineWidth = layout.board.width * 0.025;

    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = GamePalette.paper.withAlpha(225)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = lineWidth * 1.75,
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = GamePalette.sunshine
        ..strokeCap = StrokeCap.round
        ..strokeWidth = lineWidth,
    );
  }

  void _drawRoundButton(Canvas canvas, _SceneLayout layout) {
    final rect = layout.roundButton;
    final button = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height * 0.36),
    );
    canvas.drawRRect(
      button.shift(const Offset(0, 5)),
      Paint()..color = GamePalette.shadow,
    );

    final spring = _roundControl.sink.clamp(-0.12, 1.12);
    final sinkDistance = rect.height * 0.085 * spring;
    final compression = 1 - math.max(0, spring) * 0.018;
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy + sinkDistance);
    canvas.scale(compression, compression);
    canvas.translate(-rect.center.dx, -rect.center.dy);

    canvas.drawRRect(
      button,
      Paint()
        ..shader = const LinearGradient(
          colors: [GamePalette.berry, Color(0xFFA27DD4)],
        ).createShader(rect),
    );
    if (match.isFinished) {
      _drawPlayAgainShimmer(canvas, button, rect);
    }

    _drawText(
      canvas,
      match.isFinished ? 'PLAY AGAIN' : 'FRESH ROUND',
      rect.center,
      TextStyle(
        color: Colors.white,
        fontSize: math.min(14, rect.height * 0.29),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.25,
      ),
      anchor: _TextAnchor.center,
    );

    final iconCenter = Offset(rect.left + rect.height * 0.62, rect.center.dy);
    final iconSize = rect.height * 0.43;
    canvas.save();
    canvas.translate(
      iconCenter.dx - iconSize / 2,
      iconCenter.dy - iconSize / 2,
    );
    _restartIcon?.render(
      canvas,
      Vector2.all(iconSize),
      overridePaint: Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = ColorFilter.mode(
          Colors.white.withAlpha(220),
          BlendMode.srcIn,
        ),
    );
    canvas.restore();
    canvas.restore();
  }

  void _drawPlayAgainShimmer(Canvas canvas, RRect button, Rect rect) {
    const cycleSeconds = 2.4;
    final phase = Curves.easeInOutCubic.transform(
      (_elapsed % cycleSeconds) / cycleSeconds,
    );
    final bandWidth = rect.height * 0.95;
    final travel = rect.width + bandWidth * 2;
    final centerX = rect.left - bandWidth + travel * phase;
    final band = Rect.fromCenter(
      center: Offset(centerX, rect.center.dy),
      width: bandWidth,
      height: rect.height * 3,
    );

    canvas.save();
    canvas.clipRRect(button);
    canvas.translate(centerX, rect.center.dy);
    canvas.rotate(-0.32);
    canvas.translate(-centerX, -rect.center.dy);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withAlpha(0),
            Colors.white.withAlpha(18),
            Colors.white.withAlpha(92),
            Colors.white.withAlpha(18),
            Colors.white.withAlpha(0),
          ],
          stops: const [0, 0.28, 0.5, 0.72, 1],
        ).createShader(band),
    );
    canvas.restore();
  }

  void _drawFooter(Canvas canvas, _SceneLayout layout) {
    final footerY = layout.footerY;
    if (footerY == null) return;
    final text = 'Pass, play, and be kind  •  draws ${match.draws}';
    final availableWidth = layout.panelBounds.width - 16;
    final preferredFontSize = math.min(11.0, layout.subtitleSize * 0.82);
    final preferredStyle = TextStyle(
      color: GamePalette.mutedInk.withAlpha(190),
      fontSize: preferredFontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    );
    final measuredWidth = _measureTextWidth(text, preferredStyle);
    final fittedFontSize = measuredWidth > availableWidth
        ? math.max(8.0, preferredFontSize * availableWidth / measuredWidth)
        : preferredFontSize;
    _drawText(
      canvas,
      text,
      Offset(layout.titleCenter.dx, footerY),
      preferredStyle.copyWith(fontSize: fittedFontSize),
      anchor: _TextAnchor.topCenter,
    );
  }

  void _drawCelebration(Canvas canvas, _SceneLayout layout) {
    const colors = [
      GamePalette.berry,
      GamePalette.peach,
      GamePalette.sunshine,
      GamePalette.mint,
    ];
    final travel = layout.board.height + 90;
    for (var index = 0; index < 18; index += 1) {
      final lane = (index * 37 % 101) / 100;
      final x = layout.board.left + lane * layout.board.width;
      final y = layout.board.top - 45 + ((_elapsed * 82 + index * 41) % travel);
      final sway = math.sin(_elapsed * 2.3 + index) * 7;
      final particleSize = layout.board.width * (0.008 + (index % 3) * 0.0025);
      final color = colors[index % colors.length].withAlpha(190);

      if (index.isEven) {
        _drawSparkle(
          canvas,
          Offset(x + sway, y),
          particleSize,
          color,
          _elapsed + index,
        );
      } else {
        final rect = Rect.fromCenter(
          center: Offset(x + sway, y),
          width: particleSize * 1.4,
          height: particleSize * 0.75,
        );
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.rotate(_elapsed * 1.7 + index);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: rect.width,
              height: rect.height,
            ),
            Radius.circular(particleSize),
          ),
          Paint()..color = color,
        );
        canvas.restore();
      }
    }
  }

  void _drawFlower(Canvas canvas, Offset center, double radius) {
    final petalPaint = Paint()..color = GamePalette.peach;
    for (var index = 0; index < 5; index += 1) {
      final angle = -math.pi / 2 + index * (math.pi * 2 / 5);
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * radius * 0.58,
          center.dy + math.sin(angle) * radius * 0.58,
        ),
        radius * 0.44,
        petalPaint,
      );
    }
    canvas.drawCircle(
      center,
      radius * 0.38,
      Paint()..color = GamePalette.sunshine,
    );
  }

  void _drawSparkle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double rotation,
  ) {
    final path = Path();
    for (var index = 0; index < 8; index += 1) {
      final angle = rotation + index * math.pi / 4;
      final distance = index.isEven ? radius : radius * 0.28;
      final point = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontFamily: _fontFamily),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    required _TextAnchor anchor,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontFamily: _fontFamily),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final offset = switch (anchor) {
      _TextAnchor.topLeft => position,
      _TextAnchor.topCenter => Offset(
        position.dx - painter.width / 2,
        position.dy,
      ),
      _TextAnchor.centerLeft => Offset(
        position.dx,
        position.dy - painter.height / 2,
      ),
      _TextAnchor.center => Offset(
        position.dx - painter.width / 2,
        position.dy - painter.height / 2,
      ),
    };
    painter.paint(canvas, offset);
  }
}

enum _TextAnchor { topLeft, topCenter, centerLeft, center }

enum _SettingKind { sound, music, vibration }

class _SettingRowLayout {
  const _SettingRowLayout({
    required this.kind,
    required this.rect,
    required this.toggle,
  });

  final _SettingKind kind;
  final Rect rect;
  final Rect toggle;
}

class _SettingsModalLayout {
  const _SettingsModalLayout({
    required this.card,
    required this.closeButton,
    required this.rows,
  });

  factory _SettingsModalLayout.fromSize(double width, double height) {
    final cardWidth = math.min(360.0, width - 32);
    final cardHeight = math.min(330.0, height - 32);
    final card = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: cardWidth,
      height: cardHeight,
    );
    final closeButton = Rect.fromLTWH(card.right - 50, card.top + 18, 32, 32);
    final rowsTop = card.top + 82;
    const gap = 9.0;
    final rowHeight = (card.bottom - 18 - rowsTop - gap * 2) / 3;
    final rows = <_SettingRowLayout>[];
    for (var index = 0; index < _SettingKind.values.length; index += 1) {
      final row = Rect.fromLTWH(
        card.left + 18,
        rowsTop + index * (rowHeight + gap),
        card.width - 36,
        rowHeight,
      );
      final toggleHeight = math.min(28.0, row.height * 0.48);
      final toggle = Rect.fromLTWH(
        row.right - 16 - toggleHeight * 1.75,
        row.center.dy - toggleHeight / 2,
        toggleHeight * 1.75,
        toggleHeight,
      );
      rows.add(
        _SettingRowLayout(
          kind: _SettingKind.values[index],
          rect: row,
          toggle: toggle,
        ),
      );
    }

    return _SettingsModalLayout(
      card: card,
      closeButton: closeButton,
      rows: rows,
    );
  }

  final Rect card;
  final Rect closeButton;
  final List<_SettingRowLayout> rows;
}

class _SceneLayout {
  _SceneLayout({
    required this.isLandscape,
    required this.panelBounds,
    required this.titleCenter,
    required this.titleTop,
    required this.titleWidth,
    required this.titleSize,
    required this.subtitleTop,
    required this.subtitleSize,
    required this.xScoreCard,
    required this.oScoreCard,
    required this.statusPill,
    required this.board,
    required this.cells,
    required this.roundButton,
    required this.settingsButton,
    required this.footerY,
  });

  factory _SceneLayout.fromSize(double width, double height) {
    final isLandscape = width > height * 1.22;
    late final Rect panelBounds;
    late final Offset titleCenter;
    late final double titleTop;
    late final double titleWidth;
    late final double titleSize;
    late final double subtitleTop;
    late final double subtitleSize;
    late final Rect xScoreCard;
    late final Rect oScoreCard;
    late final Rect statusPill;
    late final Rect board;
    late final Rect roundButton;
    late final Rect settingsButton;
    double? footerY;

    if (isLandscape) {
      final margin = math.max(16.0, math.min(30.0, height * 0.055));
      final boardSide = math.min(height - margin * 2, width * 0.54);
      board = Rect.fromLTWH(
        width - margin - boardSide,
        (height - boardSide) / 2,
        boardSide,
        boardSide,
      );
      panelBounds = Rect.fromLTRB(
        margin,
        margin,
        board.left - margin,
        height - margin,
      );
      titleCenter = Offset(panelBounds.center.dx, panelBounds.top + 4);
      titleTop = panelBounds.top + 2;
      titleWidth = panelBounds.width;
      titleSize = math.max(27, math.min(38, panelBounds.width * 0.125));
      subtitleSize = math.max(10, math.min(14, titleSize * 0.36));
      subtitleTop = titleTop + titleSize + 5;
      final scoreTop = subtitleTop + subtitleSize + 15;
      final scoreGap = math.max(8.0, panelBounds.width * 0.035);
      final scoreWidth = (panelBounds.width - scoreGap) / 2;
      final scoreHeight = math.max(50.0, math.min(64.0, height * 0.16));
      xScoreCard = Rect.fromLTWH(
        panelBounds.left,
        scoreTop,
        scoreWidth,
        scoreHeight,
      );
      oScoreCard = Rect.fromLTWH(
        xScoreCard.right + scoreGap,
        scoreTop,
        scoreWidth,
        scoreHeight,
      );
      final statusTop = xScoreCard.bottom + math.max(9, height * 0.025);
      statusPill = Rect.fromLTWH(
        panelBounds.left,
        statusTop,
        panelBounds.width,
        math.max(38, math.min(44, height * 0.115)),
      );
      final buttonHeight = math.max(44.0, math.min(54.0, height * 0.135));
      final preferredButtonTop =
          statusPill.bottom + math.max(12, height * 0.035);
      roundButton = Rect.fromLTWH(
        panelBounds.left,
        math.min(preferredButtonTop, panelBounds.bottom - buttonHeight - 18),
        panelBounds.width,
        buttonHeight,
      );
      if (panelBounds.bottom - roundButton.bottom > 22) {
        footerY = roundButton.bottom + 10;
      }
      final settingsSide = math.max(34.0, math.min(40.0, titleSize * 1.05));
      settingsButton = Rect.fromLTWH(
        panelBounds.right - settingsSide,
        titleTop,
        settingsSide,
        settingsSide,
      );
    } else {
      final horizontalMargin = math.max(16.0, math.min(28.0, width * 0.055));
      final contentWidth = width - horizontalMargin * 2;
      final contentLeft = (width - contentWidth) / 2;
      panelBounds = Rect.fromLTWH(contentLeft, 0, contentWidth, height);
      titleCenter = Offset(width / 2, 0);
      titleTop = math.max(10, math.min(25, height * 0.024));
      titleWidth = contentWidth;
      titleSize = math.max(27, math.min(42, width * 0.09));
      subtitleSize = math.max(10.5, math.min(14, titleSize * 0.35));
      subtitleTop = titleTop + titleSize + 3;
      final scoreTop =
          subtitleTop + subtitleSize + math.max(12, height * 0.018);
      final scoreGap = math.max(10.0, contentWidth * 0.025);
      final scoreWidth = (contentWidth - scoreGap) / 2;
      final scoreHeight = math.max(52.0, math.min(66.0, height * 0.09));
      xScoreCard = Rect.fromLTWH(
        contentLeft,
        scoreTop,
        scoreWidth,
        scoreHeight,
      );
      oScoreCard = Rect.fromLTWH(
        xScoreCard.right + scoreGap,
        scoreTop,
        scoreWidth,
        scoreHeight,
      );
      final statusTop = xScoreCard.bottom + math.max(10, height * 0.014);
      statusPill = Rect.fromLTWH(
        contentLeft,
        statusTop,
        contentWidth,
        math.max(40, math.min(46, height * 0.06)),
      );
      final boardTop = statusPill.bottom + math.max(12, height * 0.017);
      final buttonHeight = math.max(46.0, math.min(54.0, height * 0.07));
      final buttonGap = math.max(18.0, math.min(24.0, height * 0.024));
      final bottomPadding = math.max(10.0, math.min(20.0, height * 0.025));
      final availableBoardHeight =
          height - boardTop - buttonGap - buttonHeight - bottomPadding;
      final boardSide = math.max(
        0.0,
        math.min(contentWidth, availableBoardHeight),
      );
      board = Rect.fromLTWH(
        (width - boardSide) / 2,
        boardTop,
        boardSide,
        boardSide,
      );
      final buttonWidth = math.min(
        contentWidth,
        math.max(220.0, contentWidth * 0.72),
      );
      roundButton = Rect.fromLTWH(
        (width - buttonWidth) / 2,
        board.bottom + buttonGap,
        buttonWidth,
        buttonHeight,
      );
      if (height - roundButton.bottom >= 27) {
        footerY = roundButton.bottom + 10;
      }
      final settingsSide = math.max(34.0, math.min(40.0, titleSize * 1.05));
      settingsButton = Rect.fromLTWH(
        panelBounds.right - settingsSide,
        titleTop,
        settingsSide,
        settingsSide,
      );
    }

    final boardPadding = board.width * 0.045;
    final gap = board.width * 0.026;
    final cellSide = (board.width - boardPadding * 2 - gap * 2) / 3;
    final cells = <Rect>[];
    for (var row = 0; row < 3; row += 1) {
      for (var column = 0; column < 3; column += 1) {
        cells.add(
          Rect.fromLTWH(
            board.left + boardPadding + column * (cellSide + gap),
            board.top + boardPadding + row * (cellSide + gap),
            cellSide,
            cellSide,
          ),
        );
      }
    }

    return _SceneLayout(
      isLandscape: isLandscape,
      panelBounds: panelBounds,
      titleCenter: titleCenter,
      titleTop: titleTop,
      titleWidth: titleWidth,
      titleSize: titleSize,
      subtitleTop: subtitleTop,
      subtitleSize: subtitleSize,
      xScoreCard: xScoreCard,
      oScoreCard: oScoreCard,
      statusPill: statusPill,
      board: board,
      cells: cells,
      roundButton: roundButton,
      settingsButton: settingsButton,
      footerY: footerY,
    );
  }

  final bool isLandscape;
  final Rect panelBounds;
  final Offset titleCenter;
  final double titleTop;
  final double titleWidth;
  final double titleSize;
  final double subtitleTop;
  final double subtitleSize;
  final Rect xScoreCard;
  final Rect oScoreCard;
  final Rect statusPill;
  final Rect board;
  final List<Rect> cells;
  final Rect roundButton;
  final Rect settingsButton;
  final double? footerY;

  SceneLayoutSnapshot snapshotForSize(double width, double height) {
    final modal = _SettingsModalLayout.fromSize(width, height);
    return SceneLayoutSnapshot(
      isLandscape: isLandscape,
      panel: _rectSnapshot(panelBounds),
      board: _rectSnapshot(board),
      cells: cells.map(_rectSnapshot).toList(growable: false),
      roundButton: _rectSnapshot(roundButton),
      settingsButton: _rectSnapshot(settingsButton),
      settingsCard: _rectSnapshot(modal.card),
      settingsCloseButton: _rectSnapshot(modal.closeButton),
      settingRows: modal.rows
          .map((row) => _rectSnapshot(row.rect))
          .toList(growable: false),
    );
  }

  int? cellAt(Offset point) {
    for (var index = 0; index < cells.length; index += 1) {
      if (cells[index].contains(point)) return index;
    }
    return null;
  }
}

RectSnapshot _rectSnapshot(Rect rect) => RectSnapshot(
  x: rect.left,
  y: rect.top,
  width: rect.width,
  height: rect.height,
);

class _BoardStateComponent extends Component implements RuntimeInspectable {
  _BoardStateComponent(this.match)
    : super(key: ComponentKey.named('board-state'));

  final TicTacToeMatch match;
  final List<double> markProgress = List<double>.filled(9, 1);
  int? lastPlacedCell;
  double winningLineProgress = 0;

  @override
  String get inspectionId => 'board-state';

  bool get animationsSettled =>
      markProgress.every((progress) => progress >= 1) &&
      (match.winningCells.isEmpty || winningLineProgress >= 1);

  void onMovePlaced(int cell) {
    lastPlacedCell = cell;
    markProgress[cell] = 0;
  }

  void onRoundFinished() {
    winningLineProgress = 0;
  }

  void onRoundStarted() {
    lastPlacedCell = null;
    markProgress.fillRange(0, markProgress.length, 1);
    winningLineProgress = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final cell = lastPlacedCell;
    if (cell != null && markProgress[cell] < 1) {
      markProgress[cell] = math.min(1, markProgress[cell] + (dt / 0.24));
    }
    if (match.winningCells.isNotEmpty && winningLineProgress < 1) {
      winningLineProgress = math.min(1, winningLineProgress + (dt / 0.42));
    }
  }

  @override
  Map<String, Object?> inspectState(SnapshotDetail detail) => {
    'lastPlacedCell': lastPlacedCell,
    'animationsSettled': animationsSettled,
    if (detail == SnapshotDetail.visual) ...{
      'markProgress': List.unmodifiable(markProgress),
      'winningLineProgress': winningLineProgress,
    },
  };
}

enum _RoundButtonPhase { idle, pressed }

class _RoundControlStateComponent extends Component
    implements RuntimeInspectable {
  _RoundControlStateComponent()
    : super(key: ComponentKey.named('round-control-state'));

  _RoundButtonPhase phase = _RoundButtonPhase.idle;
  double sink = 0;
  double velocity = 0;

  @override
  String get inspectionId => 'round-control-state';

  bool get animationSettled =>
      phase == _RoundButtonPhase.idle &&
      sink.abs() < 0.001 &&
      velocity.abs() < 0.001;

  void press() {
    phase = _RoundButtonPhase.pressed;
    sink = math.max(sink, 0.08);
    velocity = math.max(velocity, 6.0);
  }

  void release() {
    phase = _RoundButtonPhase.idle;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final step = math.min(dt, 1 / 30);
    final target = phase == _RoundButtonPhase.pressed ? 1.0 : 0.0;
    const stiffness = 310.0;
    const damping = 22.0;
    final acceleration = stiffness * (target - sink) - damping * velocity;

    velocity += acceleration * step;
    sink += velocity * step;

    if (phase == _RoundButtonPhase.idle && animationSettled) {
      sink = 0;
      velocity = 0;
    }
  }

  @override
  Map<String, Object?> inspectState(SnapshotDetail detail) => {
    'phase': phase.name,
    'animationSettled': animationSettled,
    if (detail == SnapshotDetail.visual) ...{
      'sink': sink,
      'velocity': velocity,
    },
  };
}

enum _SceneOverlay { none, settings }

class _SettingsStateComponent extends Component implements RuntimeInspectable {
  _SettingsStateComponent() : super(key: ComponentKey.named('settings-state'));

  _SceneOverlay overlay = _SceneOverlay.none;

  @override
  String get inspectionId => 'settings-state';

  bool get isOpen => overlay == _SceneOverlay.settings;

  void setOpen(bool open) {
    overlay = open ? _SceneOverlay.settings : _SceneOverlay.none;
  }

  @override
  Map<String, Object?> inspectState(SnapshotDetail detail) => {
    'overlay': overlay.name,
  };
}
