import 'package:coreflame/game/coreflame_game.dart';
import 'package:coreflame/game/observability/runtime_inspection.dart';
import 'package:coreflame/game/observability/tiny_tactics_inspection.dart';
import 'package:coreflame/game/services/fake_game_platform_services.dart';
import 'package:coreflame/game/services/game_feedback.dart';
import 'package:coreflame/game/services/game_platform_services.dart';
import 'package:coreflame/game/tic_tac_toe_match.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoreflameGame observability', () {
    testWithGame<CoreflameGame>(
      'reports semantic and visual state through stable component IDs',
      () {
        SharedPreferences.setMockInitialValues({});
        return CoreflameGame(
          platformServices: FakeGamePlatformServices(),
          feedback: _FakeGameFeedback(),
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

    testWithGame<CoreflameGame>(
      'dispatches revision-checked actions and records their outcomes',
      () {
        SharedPreferences.setMockInitialValues({});
        return CoreflameGame(
          platformServices: FakeGamePlatformServices(),
          feedback: _FakeGameFeedback(),
        );
      },
      (game) async {
        await game.ready();
        final initialRevision = game.revision;

        final played = game.dispatch(
          TinyTacticsCommandRequest(
            command: const PlayCellCommand(4),
            expectedRevision: initialRevision,
          ).toEnvelope(),
        );
        expect(played.accepted, isTrue);
        expect(played.code, MoveOutcome.accepted.name);
        final playedGame = played.snapshot.game.state as TinyTacticsSnapshot;
        expect(playedGame.match.cells[4], Mark.x.name);
        expect(played.currentRevision, initialRevision + 1);

        final stale = game.dispatch(
          TinyTacticsCommandRequest(
            command: const PlayCellCommand(0),
            expectedRevision: initialRevision,
          ).toEnvelope(),
        );
        expect(stale.accepted, isFalse);
        expect(stale.code, 'staleRevision');
        expect(stale.currentRevision, played.currentRevision);

        final occupied = game.dispatch(
          TinyTacticsCommandRequest(
            command: const PlayCellCommand(4),
            expectedRevision: game.revision,
          ).toEnvelope(),
        );
        expect(occupied.accepted, isFalse);
        expect(occupied.code, MoveOutcome.occupied.name);
        expect(occupied.currentRevision, played.currentRevision);

        final sound = game.dispatch(
          TinyTacticsCommandRequest(
            command: const SetFeedbackSettingCommand(
              setting: FeedbackSetting.sound,
              enabled: false,
            ),
            expectedRevision: game.revision,
          ).toEnvelope(),
        );
        expect(sound.accepted, isTrue);
        final soundGame = sound.snapshot.game.state as TinyTacticsSnapshot;
        expect(soundGame.feedback.soundEnabled, isFalse);

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

    testWithGame<CoreflameGame>(
      'preserves platform achievement reporting for agent-dispatched wins',
      () {
        SharedPreferences.setMockInitialValues({});
        return CoreflameGame(
          platformServices: FakeGamePlatformServices(),
          feedback: _FakeGameFeedback(),
        );
      },
      (game) async {
        await game.ready();
        final platformServices =
            game.platformServices as FakeGamePlatformServices;
        await platformServices.authenticate();

        for (final cell in [0, 3, 1, 4, 2]) {
          final result = game.dispatch(
            TinyTacticsCommandRequest(
              command: PlayCellCommand(cell),
              expectedRevision: game.revision,
            ).toEnvelope(),
          );
          expect(result.accepted, isTrue);
        }

        expect(
          platformServices.unlockedAchievements,
          contains(GameAchievement.firstWin),
        );
        expect(platformServices.scores[GameLeaderboard.matchWins], 1);
      },
    );
  });
}

class _FakeGameFeedback extends GameFeedback {
  _FakeGameFeedback() : super(backgroundMusic: _FakeBackgroundMusic());

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
