import '../../runtime/inspection/runtime_inspection.dart';
import '../feedback/feedback.dart' show FeedbackSetting;

export '../feedback/feedback.dart' show FeedbackSetting;

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

class FeedbackFailureSnapshot {
  const FeedbackFailureSnapshot({
    required this.feature,
    required this.errorType,
    required this.message,
  });

  final String feature;
  final String errorType;
  final String message;

  Map<String, Object?> toJson() => {
    'feature': feature,
    'errorType': errorType,
    'message': message,
  };
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

  final bool isLandscape;
  final RectSnapshot panel;
  final RectSnapshot board;
  final List<RectSnapshot> cells;
  final RectSnapshot roundButton;
  final RectSnapshot settingsButton;
  final RectSnapshot settingsCard;
  final RectSnapshot settingsCloseButton;
  final List<RectSnapshot> settingRows;

  Map<String, Object?> toJson() => {
    'orientation': isLandscape ? 'landscape' : 'portrait',
    'panel': panel.toJson(),
    'board': board.toJson(),
    'cells': cells.map((cell) => cell.toJson()).toList(growable: false),
    'roundButton': roundButton.toJson(),
    'settingsButton': settingsButton.toJson(),
    'settingsCard': settingsCard.toJson(),
    'settingsCloseButton': settingsCloseButton.toJson(),
    'settingRows': settingRows
        .map((row) => row.toJson())
        .toList(growable: false),
  };
}

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
  final int? lastPlacedCell;
  final double? elapsedSeconds;
  final List<double>? markProgress;
  final double? winningLineProgress;
  final String? roundButtonPhase;
  final double? roundButtonSink;
  final double? roundButtonVelocity;
  final SceneLayoutSnapshot? layout;

  Map<String, Object?> toJson() => {
    'overlay': overlay,
    'assetsLoaded': assetsLoaded,
    'animationsSettled': animationsSettled,
    'lastPlacedCell': lastPlacedCell,
    'elapsedSeconds': ?elapsedSeconds,
    'markProgress': ?markProgress,
    'winningLineProgress': ?winningLineProgress,
    'roundButtonPhase': ?roundButtonPhase,
    'roundButtonSink': ?roundButtonSink,
    'roundButtonVelocity': ?roundButtonVelocity,
    if (layout case final value?) 'layout': value.toJson(),
  };
}

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
  Map<String, Object?> toJson() => {
    'match': match.toJson(),
    'feedback': feedback.toJson(),
    'scene': scene?.toJson(),
  };
}

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

enum TinyTacticsCommandKind {
  playCell(
    wireName: 'playCell',
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
  startNextRound(
    wireName: 'startNextRound',
    description: 'Clear the board and alternate the starting player.',
  ),
  resetMatch(
    wireName: 'resetMatch',
    description: 'Reset the board, scores, and starting player.',
  ),
  setSettingsOpen(
    wireName: 'setSettingsOpen',
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
  setFeedbackSetting(
    wireName: 'setFeedbackSetting',
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
  );

  const TinyTacticsCommandKind({
    required this.wireName,
    required this.description,
    this.parameters = const [],
  });

  final String wireName;
  final String description;
  final List<CommandParameterDescriptor> parameters;

  CommandDescriptor get descriptor => CommandDescriptor(
    name: wireName,
    description: description,
    parameters: parameters,
  );

  static TinyTacticsCommandKind parse(String wireName) {
    for (final kind in values) {
      if (kind.wireName == wireName) return kind;
    }
    throw FormatException('Unknown command: $wireName');
  }
}

sealed class TinyTacticsCommand {
  const TinyTacticsCommand();

  TinyTacticsCommandKind get kind;

  String get name => kind.wireName;
}

class PlayCellCommand extends TinyTacticsCommand {
  const PlayCellCommand(this.cell);

  final int cell;

  @override
  TinyTacticsCommandKind get kind => TinyTacticsCommandKind.playCell;
}

class StartNextRoundCommand extends TinyTacticsCommand {
  const StartNextRoundCommand();

  @override
  TinyTacticsCommandKind get kind => TinyTacticsCommandKind.startNextRound;
}

class ResetMatchCommand extends TinyTacticsCommand {
  const ResetMatchCommand();

  @override
  TinyTacticsCommandKind get kind => TinyTacticsCommandKind.resetMatch;
}

class SetSettingsOpenCommand extends TinyTacticsCommand {
  const SetSettingsOpenCommand(this.open);

  final bool open;

  @override
  TinyTacticsCommandKind get kind => TinyTacticsCommandKind.setSettingsOpen;
}

class SetFeedbackSettingCommand extends TinyTacticsCommand {
  const SetFeedbackSettingCommand({
    required this.setting,
    required this.enabled,
  });

  final FeedbackSetting setting;
  final bool enabled;

  @override
  TinyTacticsCommandKind get kind => TinyTacticsCommandKind.setFeedbackSetting;
}

class TinyTacticsCommandRequest {
  const TinyTacticsCommandRequest({
    required this.command,
    this.expectedRevision,
  });

  final TinyTacticsCommand command;
  final int? expectedRevision;

  static TinyTacticsCommandRequest parse(RuntimeCommandEnvelope envelope) {
    final arguments = envelope.arguments;
    final kind = TinyTacticsCommandKind.parse(envelope.name);
    final command = switch (kind) {
      TinyTacticsCommandKind.playCell => PlayCellCommand(
        _requiredInt(arguments, 'cell'),
      ),
      TinyTacticsCommandKind.startNextRound => const StartNextRoundCommand(),
      TinyTacticsCommandKind.resetMatch => const ResetMatchCommand(),
      TinyTacticsCommandKind.setSettingsOpen => SetSettingsOpenCommand(
        _requiredBool(arguments, 'open'),
      ),
      TinyTacticsCommandKind.setFeedbackSetting => SetFeedbackSettingCommand(
        setting: _requiredSetting(arguments),
        enabled: _requiredBool(arguments, 'enabled'),
      ),
    };

    final allowedKeys = kind.parameters
        .map((parameter) => parameter.name)
        .toSet();
    final unexpectedKeys = arguments.keys
        .where((key) => !allowedKeys.contains(key))
        .toList(growable: false);
    if (unexpectedKeys.isNotEmpty) {
      throw FormatException(
        'Unexpected command parameter(s): ${unexpectedKeys.join(', ')}',
      );
    }

    return TinyTacticsCommandRequest(
      command: command,
      expectedRevision: envelope.expectedRevision,
    );
  }

  RuntimeCommandEnvelope toEnvelope() {
    final arguments = switch (command) {
      PlayCellCommand(:final cell) => {'cell': '$cell'},
      StartNextRoundCommand() ||
      ResetMatchCommand() => const <String, String>{},
      SetSettingsOpenCommand(:final open) => {'open': '$open'},
      SetFeedbackSettingCommand(:final setting, :final enabled) => {
        'setting': setting.name,
        'enabled': '$enabled',
      },
    };
    return RuntimeCommandEnvelope(
      name: command.name,
      expectedRevision: expectedRevision,
      arguments: arguments,
    );
  }

  static int _requiredInt(Map<String, String> arguments, String key) {
    final value = arguments[key];
    final parsed = value == null ? null : int.tryParse(value);
    if (parsed == null) {
      throw FormatException('Expected integer parameter: $key');
    }
    return parsed;
  }

  static bool _requiredBool(Map<String, String> arguments, String key) {
    return switch (arguments[key]) {
      'true' => true,
      'false' => false,
      _ => throw FormatException('Expected boolean parameter: $key'),
    };
  }

  static FeedbackSetting _requiredSetting(Map<String, String> arguments) {
    return switch (arguments['setting']) {
      'sound' => FeedbackSetting.sound,
      'music' => FeedbackSetting.music,
      'vibration' => FeedbackSetting.vibration,
      _ => throw const FormatException(
        'Expected setting parameter: sound, music, or vibration',
      ),
    };
  }
}
