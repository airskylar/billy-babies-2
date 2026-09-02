// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$FeedbackFailureSnapshotToJson(
  FeedbackFailureSnapshot instance,
) => <String, dynamic>{
  'feature': instance.feature,
  'errorType': instance.errorType,
  'message': instance.message,
};

Map<String, dynamic> _$SceneLayoutSnapshotToJson(
  SceneLayoutSnapshot instance,
) => <String, dynamic>{
  'orientation': _orientationToJson(instance.isLandscape),
  'panel': instance.panel.toJson(),
  'board': instance.board.toJson(),
  'cells': instance.cells.map((e) => e.toJson()).toList(),
  'roundButton': instance.roundButton.toJson(),
  'settingsButton': instance.settingsButton.toJson(),
  'settingsCard': instance.settingsCard.toJson(),
  'settingsCloseButton': instance.settingsCloseButton.toJson(),
  'settingRows': instance.settingRows.map((e) => e.toJson()).toList(),
};

Map<String, dynamic> _$SceneSnapshotToJson(SceneSnapshot instance) =>
    <String, dynamic>{
      'overlay': instance.overlay,
      'assetsLoaded': instance.assetsLoaded,
      'animationsSettled': instance.animationsSettled,
      'lastPlacedCell': instance.lastPlacedCell,
      'elapsedSeconds': ?instance.elapsedSeconds,
      'markProgress': ?instance.markProgress,
      'winningLineProgress': ?instance.winningLineProgress,
      'roundButtonPhase': ?instance.roundButtonPhase,
      'roundButtonSink': ?instance.roundButtonSink,
      'roundButtonVelocity': ?instance.roundButtonVelocity,
      'layout': ?instance.layout?.toJson(),
    };

Map<String, dynamic> _$TinyTacticsSnapshotToJson(
  TinyTacticsSnapshot instance,
) => <String, dynamic>{
  'match': instance.match.toJson(),
  'feedback': instance.feedback.toJson(),
  'scene': instance.scene?.toJson(),
};
