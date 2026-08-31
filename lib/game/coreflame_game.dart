import 'dart:async';

import 'package:flutter/material.dart';

import 'components/cozy_tic_tac_toe_scene.dart';
import 'observability/inspectable_flame_game.dart';
import 'observability/runtime_inspection.dart';
import 'observability/tiny_tactics_inspection.dart';
import 'observability/tiny_tactics_inspection_adapter.dart';
import 'services/game_feedback.dart';
import 'services/game_platform_services.dart';
import 'theme/game_palette.dart';
import 'tic_tac_toe_match.dart';

class CoreflameGame extends InspectableFlameGame {
  CoreflameGame({
    required this.platformServices,
    TicTacToeMatch? match,
    GameFeedback? feedback,
    RuntimeEventJournal? journal,
  }) : match = match ?? TicTacToeMatch(),
       feedback = feedback ?? GameFeedback(),
       super(inspectionJournal: journal) {
    this.feedback.addObserver(_onFeedbackEvent);
  }

  final TicTacToeMatch match;
  final GameFeedback feedback;
  final GamePlatformServices platformServices;
  CozyTicTacToeScene? _scene;

  late final TinyTacticsInspectionAdapter _inspectionAdapter =
      TinyTacticsInspectionAdapter(
        match: match,
        feedback: feedback,
        scene: () => _scene,
        recordEvent: recordInspectionEvent,
      );

  @override
  RuntimeInspectionAdapter get inspectionAdapter => _inspectionAdapter;

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
      recordEvent: recordInspectionEvent,
    );
    _scene = scene;
    await add(scene);
    scene.applySafeViewport(size, safePadding);
    unawaited(feedback.startBackgroundMusic());
  }

  @override
  void onSafePaddingChanged(EdgeInsets value) {
    _scene?.applySafeViewport(size, value);
  }

  @override
  void onRemove() {
    super.onRemove();
    unawaited(
      feedback.dispose().whenComplete(() {
        feedback.removeObserver(_onFeedbackEvent);
      }),
    );
  }

  void _onFeedbackEvent(GameFeedbackEvent event) {
    final failure = event.kind == GameFeedbackEventKind.failure;
    final changesState =
        event.kind == GameFeedbackEventKind.settingsLoaded ||
        event.kind == GameFeedbackEventKind.settingChanged;
    recordInspectionEvent(
      failure
          ? TinyTacticsEventKind.feedbackFailure
          : TinyTacticsEventKind.feedbackStateChanged,
      {'feedbackEvent': event.kind.name, ...event.payload},
      changesState: changesState,
    );
  }
}
