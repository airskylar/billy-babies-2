import '../../runtime/inspection/runtime_inspection.dart';
import '../domain/game_action_origin.dart';
import '../domain/tic_tac_toe_match.dart';
import '../feedback/tiny_tactics_feedback.dart';
import '../scene/cozy_tic_tac_toe_scene.dart';
import 'tiny_tactics_inspection.dart';

class TinyTacticsInspectionAdapter implements RuntimeInspectionAdapter {
  TinyTacticsInspectionAdapter({
    required this.match,
    required this.feedback,
    required this.scene,
    required this.recordEvent,
  });

  final TicTacToeMatch match;
  final TinyTacticsFeedback feedback;
  final CozyTicTacToeScene? Function() scene;
  final RuntimeEventRecorder recordEvent;

  @override
  String get gameId => 'tinyTactics';

  @override
  int get schemaVersion => 1;

  @override
  List<CommandDescriptor> get commands => TinyTacticsCommandKind.values
      .map((kind) => kind.descriptor)
      .toList(growable: false);

  @override
  TinyTacticsSnapshot snapshot(SnapshotDetail detail) => TinyTacticsSnapshot(
    match: MatchSnapshot(
      cells: match.cells.map((mark) => mark?.name).toList(growable: false),
      turn: match.turn.name,
      starter: match.starter.name,
      result: match.result.name,
      winningCells: match.winningCells,
      xScore: match.xScore,
      oScore: match.oScore,
      draws: match.draws,
    ),
    feedback: FeedbackSnapshot(
      lifecycle: feedback.lifecycle.name,
      backgroundMusic: feedback.backgroundMusicPhase.name,
      preferencesLoaded: feedback.preferencesLoaded,
      soundEnabled: feedback.soundEnabled,
      musicEnabled: feedback.musicEnabled,
      vibrationEnabled: feedback.vibrationEnabled,
      lastFailure: switch (feedback.lastFailure) {
        final failure? => FeedbackFailureSnapshot(
          feature: failure.feature,
          errorType: failure.errorType,
          message: failure.message,
        ),
        null => null,
      },
    ),
    scene: scene()?.snapshot(detail),
  );

  @override
  Future<RuntimeCommandOutcome> dispatch(
    RuntimeCommandEnvelope envelope,
  ) async {
    final request = TinyTacticsCommandRequest.parse(envelope);
    final activeScene = scene();
    if (activeScene == null || !activeScene.isMounted) {
      return const RuntimeCommandOutcome(
        disposition: RuntimeCommandDisposition.rejected,
        code: 'gameNotReady',
        message: 'The Tiny Tactics scene is not mounted',
      );
    }

    return switch (request.command) {
      PlayCellCommand(:final cell) => _dispatchPlayCell(activeScene, cell),
      StartNextRoundCommand() => _dispatchAction(
        activeScene.startNextRound,
        message: 'Started the next round',
      ),
      ResetMatchCommand() => _dispatchAction(
        activeScene.resetMatch,
        message: 'Reset the match',
      ),
      SetSettingsOpenCommand(:final open) => _dispatchChange(
        () => activeScene.setSettingsOpen(open, origin: GameActionOrigin.agent),
        changedMessage: open ? 'Opened settings' : 'Closed settings',
      ),
      SetFeedbackSettingCommand(:final setting, :final enabled) =>
        _dispatchChange(
          () => activeScene.setFeedbackSetting(
            setting,
            enabled,
            origin: GameActionOrigin.agent,
          ),
          changedMessage: 'Set ${setting.name} to $enabled',
        ),
    };
  }

  RuntimeCommandOutcome _dispatchPlayCell(
    CozyTicTacToeScene activeScene,
    int cell,
  ) {
    if (cell < 0 || cell >= match.cells.length) {
      recordEvent(TinyTacticsEventKind.moveRejected, {
        'cell': cell,
        'reason': 'outOfRange',
        'origin': GameActionOrigin.agent.name,
      }, changesState: false);
      return const RuntimeCommandOutcome(
        disposition: RuntimeCommandDisposition.rejected,
        code: 'outOfRange',
        message: 'Cell must be between 0 and 8',
      );
    }

    final outcome = activeScene.playCell(cell, origin: GameActionOrigin.agent);
    return RuntimeCommandOutcome(
      disposition: outcome == MoveOutcome.accepted
          ? RuntimeCommandDisposition.applied
          : RuntimeCommandDisposition.rejected,
      code: outcome.name,
      message: switch (outcome) {
        MoveOutcome.accepted => 'Played cell $cell',
        MoveOutcome.occupied => 'Cell $cell is already occupied',
        MoveOutcome.roundFinished => 'The round is already finished',
      },
    );
  }

  RuntimeCommandOutcome _dispatchAction(
    void Function({GameActionOrigin origin}) action, {
    required String message,
  }) {
    action(origin: GameActionOrigin.agent);
    return RuntimeCommandOutcome(
      disposition: RuntimeCommandDisposition.applied,
      code: 'applied',
      message: message,
    );
  }

  RuntimeCommandOutcome _dispatchChange(
    bool Function() action, {
    required String changedMessage,
  }) {
    final changed = action();
    return RuntimeCommandOutcome(
      disposition: changed
          ? RuntimeCommandDisposition.applied
          : RuntimeCommandDisposition.noChange,
      code: changed ? 'applied' : 'noChange',
      message: changed
          ? changedMessage
          : 'State already had the requested value',
    );
  }
}
