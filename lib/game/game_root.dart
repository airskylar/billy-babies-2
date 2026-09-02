import 'dart:async';

import 'package:flutter/material.dart';

import '../runtime/game_services/game_platform_services.dart';
import '../runtime/inspection/inspectable_flame_game.dart';
import '../runtime/inspection/runtime_inspection.dart';
import 'domain/tic_tac_toe_match.dart';
import 'feedback/feedback.dart';
import 'inspection/protocol.dart';
import 'inspection/adapter.dart';
import 'scene/scene.dart';
import 'theme/game_palette.dart';

class TinyTacticsGame extends InspectableFlameGame {
  TinyTacticsGame({
    required this.platformServices,
    TicTacToeMatch? match,
    TinyTacticsFeedback? feedback,
    RuntimeEventJournal? journal,
  }) : match = match ?? TicTacToeMatch(),
       feedback = feedback ?? TinyTacticsFeedback(),
       super(inspectionJournal: journal) {
    this.feedback.addObserver(_onFeedbackEvent);
  }

  final TicTacToeMatch match;
  final TinyTacticsFeedback feedback;
  final GamePlatformServices platformServices;
  CozyTicTacToeScene? _scene;

  late final TinyTacticsInspectionAdapter _inspectionAdapter =
      TinyTacticsInspectionAdapter(
        match: match,
        feedback: feedback,
        scene: () => _scene,
        recordEvent: recordTypedInspectionEvent,
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
      recordEvent: recordTypedInspectionEvent,
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

  void _onFeedbackEvent(TinyTacticsFeedbackEvent event) {
    final failure = event.kind == TinyTacticsFeedbackEventKind.failure;
    final changesState =
        event.kind == TinyTacticsFeedbackEventKind.settingsLoaded ||
        event.kind == TinyTacticsFeedbackEventKind.settingChanged;
    recordTypedInspectionEvent(
      TinyTacticsEvent.feedback(
        failure: failure,
        changesState: changesState,
        feedbackEvent: event.kind.name,
        details: event.payload,
      ),
    );
  }
}
