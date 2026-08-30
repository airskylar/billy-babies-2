import 'dart:convert';

import 'package:coreflame/game/services/fake_game_platform_services.dart';
import 'package:coreflame/game/services/game_platform_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VersionedGameSave', () {
    test('round-trips strict JSON and records revision ancestry', () {
      final first = VersionedGameSave.initial(
        schemaVersion: 1,
        writtenAtUtc: DateTime.utc(2026, 8, 30, 12),
        payload: '{"wins":1}',
      );
      final second = first.next(
        schemaVersion: 2,
        writtenAtUtc: DateTime.utc(2026, 8, 30, 13),
        payload: '{"wins":2}',
      );

      final decoded = VersionedGameSave.fromEncodedJson(second.toEncodedJson());

      expect(decoded.schemaVersion, 2);
      expect(decoded.revision, 2);
      expect(decoded.parentRevision, 1);
      expect(decoded.writtenAtUtc, DateTime.utc(2026, 8, 30, 13));
      expect(decoded.payload, '{"wins":2}');
    });

    test('rejects unknown JSON fields', () {
      final source = jsonEncode({
        'schemaVersion': 1,
        'revision': 1,
        'parentRevision': null,
        'writtenAtUtc': '2026-08-30T12:00:00.000Z',
        'payload': '{}',
        'unexpected': true,
      });

      expect(
        () => VersionedGameSave.fromEncodedJson(source),
        throwsFormatException,
      );
    });

    test('rejects non-UTC timestamps', () {
      expect(
        () => VersionedGameSave.initial(
          schemaVersion: 1,
          writtenAtUtc: DateTime(2026, 8, 30),
          payload: '{}',
        ),
        throwsFormatException,
      );
    });

    test('rejects missing or invalid revision ancestry', () {
      final invalidDocuments = [
        {
          'schemaVersion': 1,
          'revision': 1,
          'parentRevision': 0,
          'writtenAtUtc': '2026-08-30T12:00:00.000Z',
          'payload': '{}',
        },
        {
          'schemaVersion': 1,
          'revision': 2,
          'parentRevision': null,
          'writtenAtUtc': '2026-08-30T13:00:00.000Z',
          'payload': '{}',
        },
      ];

      for (final document in invalidDocuments) {
        expect(
          () => VersionedGameSave.fromEncodedJson(jsonEncode(document)),
          throwsFormatException,
        );
      }
    });
  });

  group('GameServicesConfiguration', () {
    test('requires both native IDs for every configured logical ID', () {
      final configuration = GameServicesConfiguration(
        enabled: true,
        cloudSavesEnabled: false,
        achievementIds: const {
          GameAchievement.firstWin: PlatformGameServiceIds(
            android: 'android-id',
            ios: '',
          ),
        },
        leaderboardIds: const {},
      );

      expect(configuration.validate(), contains('first_win'));
    });
  });

  group('FakeGamePlatformServices', () {
    test(
      'authenticates and records logical achievement and score IDs',
      () async {
        final services = FakeGamePlatformServices();

        await services.authenticate();
        final achievement = await services.unlockAchievement(
          GameAchievement.firstWin,
        );
        await services.submitScore(
          leaderboard: GameLeaderboard.matchWins,
          score: 3,
        );
        await services.submitScore(
          leaderboard: GameLeaderboard.matchWins,
          score: 2,
        );

        expect(achievement.isSuccess, isTrue);
        expect(
          services.unlockedAchievements,
          contains(GameAchievement.firstWin),
        );
        expect(services.scores[GameLeaderboard.matchWins], 3);
        expect(
          services.calls.map((call) => call.logicalId),
          containsAll(['first_win', 'match_wins']),
        );
      },
    );

    test('stores versioned saves in memory', () async {
      final services = FakeGamePlatformServices();
      final save = VersionedGameSave.initial(
        schemaVersion: 1,
        writtenAtUtc: DateTime.utc(2026, 8, 30),
        payload: '{"wins":4}',
      );

      await services.authenticate();
      await services.saveGame(slot: GameSaveSlot.progress, save: save);
      final result = await services.loadGame(GameSaveSlot.progress);

      expect(result, isA<GameServiceSuccess<VersionedGameSave?>>());
      final loaded = (result as GameServiceSuccess<VersionedGameSave?>).value;
      expect(loaded?.revision, 1);
      expect(loaded?.payload, '{"wins":4}');
      expect(
        services.cloudSaveConflictBehavior,
        GameSaveConflictBehavior.platformResolved,
      );
    });

    test('returns a typed failure before authentication', () async {
      final services = FakeGamePlatformServices();

      final result = await services.unlockAchievement(GameAchievement.firstWin);

      expect(result, isA<GameServiceFailure<GameServiceUnit>>());
      final failure = result as GameServiceFailure<GameServiceUnit>;
      expect(failure.error.code, GameServiceErrorCode.notAuthenticated);
    });
  });
}
