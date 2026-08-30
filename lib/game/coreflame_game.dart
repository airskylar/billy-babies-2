import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/cozy_tic_tac_toe_scene.dart';
import 'services/game_feedback.dart';
import 'theme/game_palette.dart';
import 'tic_tac_toe_match.dart';

class CoreflameGame extends FlameGame {
  CoreflameGame({TicTacToeMatch? match, GameFeedback? feedback})
    : match = match ?? TicTacToeMatch(),
      feedback = feedback ?? GameFeedback();

  final TicTacToeMatch match;
  final GameFeedback feedback;
  EdgeInsets _safePadding = EdgeInsets.zero;
  CozyTicTacToeScene? _scene;

  set safePadding(EdgeInsets value) {
    if (_safePadding == value) return;
    _safePadding = value;
    _scene?.applySafeViewport(size, value);
  }

  @override
  Color backgroundColor() => GamePalette.cream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await feedback.preload();
    final scene = CozyTicTacToeScene(match: match, feedback: feedback);
    _scene = scene;
    await add(scene);
    scene.applySafeViewport(size, _safePadding);
    unawaited(feedback.startBackgroundMusic());
  }

  @override
  void onRemove() {
    super.onRemove();
    unawaited(feedback.dispose());
  }
}
