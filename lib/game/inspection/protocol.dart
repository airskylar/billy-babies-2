import 'package:json_annotation/json_annotation.dart';

import '../../runtime/inspection/runtime_inspection.dart';
import '../feedback/feedback.dart' show FeedbackSetting;

export '../feedback/feedback.dart' show FeedbackSetting;

part 'protocol.g.dart';

class MatchSnapshot {
  const MatchSnapshot({
    required this.cells,
    required this.turn,
    required this.starter,
    required this.result,
    required this.winningCells,
    required this.xScore,
    required this.oScore,
    required this.draws,
  });

  final List<String?> cells;
  final String turn;
  final String starter;
  final String result;
  final List<int> winningCells;
  final int xScore;
  final int oScore;
  final int draws;

  int get moveCount => cells.where((cell) => cell != null).length;

  Map<String, Object?> toJson() => {
    'cells': cells,
    'turn': turn,
    'starter': starter,
    'result': result,
    'winningCells': winningCells,
    'scores': {'x': xScore, 'o': oScore, 'draws': draws},
    'moveCount': moveCount,
  };
}

@JsonSerializable(createFactory: false)
class FeedbackFailureSnapshot {
  const FeedbackFailureSnapshot({
    required this.feature,
    required this.errorType,
    required this.message,
  });

  final String feature;
  final String errorType;
  final String message;

  Map<String, Object?> toJson() => _$FeedbackFailureSnapshotToJson(this);
}

class FeedbackSnapshot {
  const FeedbackSnapshot({
    required this.lifecycle,
    required this.backgroundMusic,
    required this.preferencesLoaded,
    required this.soundEnabled,
    required this.musicEnabled,
    required this.vibrationEnabled,
    this.lastFailure,
  });

  final String lifecycle;
  final String backgroundMusic;
  final bool preferencesLoaded;
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final FeedbackFailureSnapshot? lastFailure;

  Map<String, Object?> toJson() => {
    'lifecycle': lifecycle,
    'backgroundMusic': backgroundMusic,
    'preferencesLoaded': preferencesLoaded,
    'settings': {
      'soundEnabled': soundEnabled,
      'musicEnabled': musicEnabled,
      'vibrationEnabled': vibrationEnabled,
    },
    if (lastFailure case final value?) 'lastFailure': value.toJson(),
  };
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class SceneLayoutSnapshot {
  const SceneLayoutSnapshot({
    required this.isLandscape,
    required this.panel,
    required this.board,
    required this.cells,
    required this.roundButton,
    required this.settingsButton,
    required this.settingsCard,
    required this.settingsCloseButton,
    required this.settingRows,
  });

  @JsonKey(name: 'orientation', toJson: _orientationToJson)
  final bool isLandscape;
  final RectSnapshot panel;
  final RectSnapshot board;
  final List<RectSnapshot> cells;
  final RectSnapshot roundButton;
  final RectSnapshot settingsButton;
  final RectSnapshot settingsCard;
  final RectSnapshot settingsCloseButton;
  final List<RectSnapshot> settingRows;

  Map<String, Object?> toJson() => _$SceneLayoutSnapshotToJson(this);
}

@JsonSerializable(
  createFactory: false,
  explicitToJson: true,
  includeIfNull: false,
)
class SceneSnapshot {
  const SceneSnapshot({
    required this.overlay,
    required this.assetsLoaded,
    required this.animationsSettled,
    required this.lastPlacedCell,
    this.elapsedSeconds,
    this.markProgress,
    this.winningLineProgress,
    this.roundButtonPhase,
    this.roundButtonSink,
    this.roundButtonVelocity,
    this.layout,
  });

  final String overlay;
  final bool assetsLoaded;
  final bool animationsSettled;
  @JsonKey(includeIfNull: true)
  final int? lastPlacedCell;
  final double? elapsedSeconds;
  final List<double>? markProgress;
  final double? winningLineProgress;
  final String? roundButtonPhase;
  final double? roundButtonSink;
  final double? roundButtonVelocity;
  final SceneLayoutSnapshot? layout;

  Map<String, Object?> toJson() => _$SceneSnapshotToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class TinyTacticsSnapshot implements GameInspectionState {
  const TinyTacticsSnapshot({
    required this.match,
    required this.feedback,
    this.scene,
  });

  final MatchSnapshot match;
  final FeedbackSnapshot feedback;
  final SceneSnapshot? scene;

  @override
  Map<String, Object?> toJson() => _$TinyTacticsSnapshotToJson(this);
}

String _orientationToJson(bool isLandscape) =>
    isLandscape ? 'landscape' : 'portrait';

enum TinyTacticsEventKind implements InspectionEventKind {
  moveAccepted,
  moveRejected,
  roundStarted,
  matchReset,
  settingsOpened,
  settingsClosed,
  feedbackStateChanged,
  feedbackFailure;

  @override
  String get wireName => name;
}

final class TinyTacticsEvent implements InspectionEventData {
  const TinyTacticsEvent._({
    required this.kind,
    required this.payload,
    this.changesState = true,
  });

  factory TinyTacticsEvent.moveAccepted({
    required int cell,
    required String mark,
    required String result,
    required List<int> winningCells,
    required String origin,
  }) => TinyTacticsEvent._(
    kind: TinyTacticsEventKind.moveAccepted,
    payload: {
      'cell': cell,
      'mark': mark,
      'result': result,
      'winningCells': winningCells,
      'origin': origin,
    },
  );

  factory TinyTacticsEvent.moveRejected({
    required int cell,
    required String reason,
    required String origin,
  }) => TinyTacticsEvent._(
    kind: TinyTacticsEventKind.moveRejected,
    payload: {'cell': cell, 'reason': reason, 'origin': origin},
    changesState: false,
  );

  factory TinyTacticsEvent.roundStarted({
    required String starter,
    required String origin,
  }) => TinyTacticsEvent._(
    kind: TinyTacticsEventKind.roundStarted,
    payload: {'starter': starter, 'origin': origin},
  );

  factory TinyTacticsEvent.matchReset({required String origin}) =>
      TinyTacticsEvent._(
        kind: TinyTacticsEventKind.matchReset,
        payload: {'origin': origin},
      );

  factory TinyTacticsEvent.settingsChanged({
    required bool open,
    required String origin,
  }) => TinyTacticsEvent._(
    kind: open
        ? TinyTacticsEventKind.settingsOpened
        : TinyTacticsEventKind.settingsClosed,
    payload: {'origin': origin},
  );

  factory TinyTacticsEvent.feedback({
    required bool failure,
    required bool changesState,
    required String feedbackEvent,
    required Map<String, Object?> details,
  }) => TinyTacticsEvent._(
    kind: failure
        ? TinyTacticsEventKind.feedbackFailure
        : TinyTacticsEventKind.feedbackStateChanged,
    payload: {'feedbackEvent': feedbackEvent, ...details},
    changesState: changesState,
  );

  @override
  final TinyTacticsEventKind kind;

  @override
  final Map<String, Object?> payload;

  @override
  final bool changesState;
}

class PlayCellCommand {
  const PlayCellCommand(this.cell);

  final int cell;

  static final spec = RuntimeCommandSpec<PlayCellCommand>(
    descriptor: const CommandDescriptor(
      name: 'playCell',
      description: 'Place the current player mark in a board cell.',
      parameters: [
        CommandParameterDescriptor(
          name: 'cell',
          type: CommandParameterType.integer,
          required: true,
          description: 'Zero-based board cell index.',
        ),
      ],
    ),
    decode: (arguments) => PlayCellCommand(arguments.requireInt('cell')),
    encode: (command) => {'cell': '${command.cell}'},
  );

  RuntimeCommandEnvelope toEnvelope({int? expectedRevision}) =>
      spec.envelope(this, expectedRevision: expectedRevision);
}

class StartNextRoundCommand {
  const StartNextRoundCommand();

  static final spec = RuntimeCommandSpec<StartNextRoundCommand>(
    descriptor: const CommandDescriptor(
      name: 'startNextRound',
      description: 'Clear the board and alternate the starting player.',
    ),
    decode: (_) => const StartNextRoundCommand(),
    encode: (_) => const {},
  );

  RuntimeCommandEnvelope toEnvelope({int? expectedRevision}) =>
      spec.envelope(this, expectedRevision: expectedRevision);
}

class ResetMatchCommand {
  const ResetMatchCommand();

  static final spec = RuntimeCommandSpec<ResetMatchCommand>(
    descriptor: const CommandDescriptor(
      name: 'resetMatch',
      description: 'Reset the board, scores, and starting player.',
    ),
    decode: (_) => const ResetMatchCommand(),
    encode: (_) => const {},
  );

  RuntimeCommandEnvelope toEnvelope({int? expectedRevision}) =>
      spec.envelope(this, expectedRevision: expectedRevision);
}

class SetSettingsOpenCommand {
  const SetSettingsOpenCommand(this.open);

  final bool open;

  static final spec = RuntimeCommandSpec<SetSettingsOpenCommand>(
    descriptor: const CommandDescriptor(
      name: 'setSettingsOpen',
      description: 'Open or close the settings overlay.',
      parameters: [
        CommandParameterDescriptor(
          name: 'open',
          type: CommandParameterType.boolean,
          required: true,
          description: 'Whether the settings overlay should be open.',
        ),
      ],
    ),
    decode: (arguments) =>
        SetSettingsOpenCommand(arguments.requireBool('open')),
    encode: (command) => {'open': '${command.open}'},
  );

  RuntimeCommandEnvelope toEnvelope({int? expectedRevision}) =>
      spec.envelope(this, expectedRevision: expectedRevision);
}

class SetFeedbackSettingCommand {
  const SetFeedbackSettingCommand({
    required this.setting,
    required this.enabled,
  });

  final FeedbackSetting setting;
  final bool enabled;

  static final spec = RuntimeCommandSpec<SetFeedbackSettingCommand>(
    descriptor: const CommandDescriptor(
      name: 'setFeedbackSetting',
      description: 'Enable or disable a sound, music, or vibration setting.',
      parameters: [
        CommandParameterDescriptor(
          name: 'setting',
          type: CommandParameterType.string,
          required: true,
          description: 'One of sound, music, or vibration.',
        ),
        CommandParameterDescriptor(
          name: 'enabled',
          type: CommandParameterType.boolean,
          required: true,
          description: 'Whether the setting should be enabled.',
        ),
      ],
    ),
    decode: (arguments) => SetFeedbackSettingCommand(
      setting: arguments.requireEnum('setting', FeedbackSetting.values),
      enabled: arguments.requireBool('enabled'),
    ),
    encode: (command) => {
      'setting': command.setting.name,
      'enabled': '${command.enabled}',
    },
  );

  RuntimeCommandEnvelope toEnvelope({int? expectedRevision}) =>
      spec.envelope(this, expectedRevision: expectedRevision);
}
