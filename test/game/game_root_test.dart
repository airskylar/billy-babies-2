import 'package:coreflame/game/domain/tic_tac_toe_match.dart';
import 'package:coreflame/game/feedback/feedback.dart';
import 'package:coreflame/game/inspection/protocol.dart';
import 'package:coreflame/game/services/service_ids.dart';
import 'package:coreflame/game/game_root.dart';
import 'package:coreflame/runtime/inspection/runtime_inspection.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_game_platform_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TinyTacticsGame observability', () {
    testWithGame<TinyTacticsGame>(
      'reports semantic and visual state through stable component IDs',
      () {
        SharedPreferences.setMockInitialValues({});
        return TinyTacticsGame(
          platformServices: FakeGamePlatformServices(),
          feedback: _FakeTinyTacticsFeedback(),
        );
      },
      (game) async {
        await game.ready();

        final semantic = game.snapshot(SnapshotDetail.semantic);
        final visual = game.snapshot(SnapshotDetail.visual);
        final semanticGame = semantic.game.state as TinyTacticsSnapshot;
        final visualGame = visual.game.state as TinyTacticsSnapshot;

        expect(semanticGame.match.cells, everyElement(isNull));
        expect(semanticGame.scene?.layout, isNull);
        expect(
          semantic.components.map((component) => component.transform),
          everyElement(isNull),
        );
        expect(visualGame.scene?.layout?.cells, hasLength(9));
        expect(
          visual.components
              .singleWhere((component) => component.id == 'scene')
              .transform,
          isNotNull,
        );
        final scene = semantic.components.singleWhere(
          (component) => component.id == 'scene',
        );
        expect(scene.parentId, 'game');
        expect(
          scene.childIds,
          containsAll(const {
            'board-state',
            'round-control-state',
            'settings-state',
          }),
        );
        expect(
          semantic.components.map((component) => component.id),
          containsAll(const {
            'game',
            'scene',
            'board-state',
            'round-control-state',
            'settings-state',
          }),
        );
        expect(
          semantic.toJson()['protocolVersion'],
          RuntimeSnapshot.protocolVersion,
        );
        expect(semantic.game.id, 'tinyTactics');
        expect(semantic.game.schemaVersion, 1);
      },
    );

    testWithGame<TinyTacticsGame>(
      'dispatches revision-checked actions and records their outcomes',
      () {
        SharedPreferences.setMockInitialValues({});
        return TinyTacticsGame(
          platformServices: FakeGamePlatformServices(),
          feedback: _FakeTinyTacticsFeedback(),
        );
      },
      (game) async {
        await game.ready();
        final initialRevision = game.revision;

        final played = await game.dispatch(
          const PlayCellCommand(
            4,
          ).toEnvelope(expectedRevision: initialRevision),
        );
        expect(played.disposition, RuntimeCommandDisposition.applied);
        expect(played.code, MoveOutcome.accepted.name);
        final playedGame = played.snapshot.game.state as TinyTacticsSnapshot;
        expect(playedGame.match.cells[4], Mark.x.name);
        expect(played.currentRevision, initialRevision + 1);

        final stale = await game.dispatch(
          const PlayCellCommand(
            0,
          ).toEnvelope(expectedRevision: initialRevision),
        );
        expect(stale.disposition, RuntimeCommandDisposition.rejected);
        expect(stale.code, 'staleRevision');
        expect(stale.currentRevision, played.currentRevision);

        final occupied = await game.dispatch(
          const PlayCellCommand(4).toEnvelope(expectedRevision: game.revision),
        );
        expect(occupied.disposition, RuntimeCommandDisposition.rejected);
        expect(occupied.code, MoveOutcome.occupied.name);
        expect(occupied.currentRevision, played.currentRevision);

        final sound = await game.dispatch(
          const SetFeedbackSettingCommand(
            setting: FeedbackSetting.sound,
            enabled: false,
          ).toEnvelope(expectedRevision: game.revision),
        );
        expect(sound.disposition, RuntimeCommandDisposition.applied);
        final soundGame = sound.snapshot.game.state as TinyTacticsSnapshot;
        expect(soundGame.feedback.soundEnabled, isFalse);

        final unchangedSound = await game.dispatch(
          const SetFeedbackSettingCommand(
            setting: FeedbackSetting.sound,
            enabled: false,
          ).toEnvelope(expectedRevision: game.revision),
        );
        expect(unchangedSound.disposition, RuntimeCommandDisposition.noChange);
        expect(unchangedSound.currentRevision, sound.currentRevision);

        final events = game.eventBatchAfter(0).events;
        expect(
          events.map((event) => event.kind),
          containsAll(const {
            RuntimeEventKind.gameLoaded,
            TinyTacticsEventKind.moveAccepted,
            TinyTacticsEventKind.moveRejected,
            TinyTacticsEventKind.feedbackStateChanged,
          }),
        );
      },
    );

    testWithGame<TinyTacticsGame>(
      'preserves platform achievement reporting for agent-dispatched wins',
      () {
        SharedPreferences.setMockInitialValues({});
        return TinyTacticsGame(
          platformServices: FakeGamePlatformServices(),
          feedback: _FakeTinyTacticsFeedback(),
        );
      },
      (game) async {
        await game.ready();
        final platformServices =
            game.platformServices as FakeGamePlatformServices;
        await platformServices.authenticate();

        for (final cell in [0, 3, 1, 4, 2]) {
          final result = await game.dispatch(
            PlayCellCommand(cell).toEnvelope(expectedRevision: game.revision),
          );
          expect(result.disposition, RuntimeCommandDisposition.applied);
        }

        expect(
          platformServices.unlockedAchievements,
          contains(TinyTacticsGameServiceIds.firstWinAchievement),
        );
        expect(
          platformServices.scores[TinyTacticsGameServiceIds
              .matchWinsLeaderboard],
          1,
        );
      },
    );
  });
}

class _FakeTinyTacticsFeedback extends TinyTacticsFeedback {
  _FakeTinyTacticsFeedback() : super(backgroundMusic: _FakeBackgroundMusic());

  @override
  Future<void> preload() async {}

  @override
  Future<void> startBackgroundMusic({bool fromUserGesture = false}) async {}

  @override
  Future<void> dispose() async {}

  @override
  void playMove(Mark mark, {bool isWinningMove = false}) {}

  @override
  void playButtonHaptic() {}
}

class _FakeBackgroundMusic implements BackgroundMusicController {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> play(String asset, {required double volume}) async {}

  @override
  Future<void> stop() async {}
}
