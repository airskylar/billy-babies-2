import 'package:coreflame/game/coreflame_game.dart';
import 'package:coreflame/game/observability/coreflame_observability.dart';
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

        expect(semantic.match.cells, everyElement(isNull));
        expect(semantic.scene?.layout, isNull);
        expect(
          semantic.components.map((component) => component.transform),
          everyElement(isNull),
        );
        expect(visual.scene?.layout?.cells, hasLength(9));
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
          semantic.toJson()['schemaVersion'],
          CoreflameSnapshot.schemaVersion,
        );
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
          CoreflameCommandRequest(
            command: const PlayCellCommand(4),
            expectedRevision: initialRevision,
          ),
        );
        expect(played.accepted, isTrue);
        expect(played.code, MoveOutcome.accepted.name);
        expect(played.snapshot.match.cells[4], Mark.x.name);
        expect(played.currentRevision, initialRevision + 1);

        final stale = game.dispatch(
          CoreflameCommandRequest(
            command: const PlayCellCommand(0),
            expectedRevision: initialRevision,
          ),
        );
        expect(stale.accepted, isFalse);
        expect(stale.code, 'staleRevision');
        expect(stale.currentRevision, played.currentRevision);

        final occupied = game.dispatch(
          CoreflameCommandRequest(
            command: const PlayCellCommand(4),
            expectedRevision: game.revision,
          ),
        );
        expect(occupied.accepted, isFalse);
        expect(occupied.code, MoveOutcome.occupied.name);
        expect(occupied.currentRevision, played.currentRevision);

        final sound = game.dispatch(
          CoreflameCommandRequest(
            command: const SetFeedbackSettingCommand(
              setting: FeedbackSetting.sound,
              enabled: false,
            ),
            expectedRevision: game.revision,
          ),
        );
        expect(sound.accepted, isTrue);
        expect(sound.snapshot.feedback.soundEnabled, isFalse);

        final events = game.eventBatchAfter(0).events;
        expect(
          events.map((event) => event.kind),
          containsAll(const {
            CoreflameEventKind.gameLoaded,
            CoreflameEventKind.moveAccepted,
            CoreflameEventKind.moveRejected,
            CoreflameEventKind.feedbackStateChanged,
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
            CoreflameCommandRequest(
              command: PlayCellCommand(cell),
              expectedRevision: game.revision,
            ),
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
