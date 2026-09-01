import 'dart:convert';

import 'package:coreflame/runtime/game_services/game_platform_services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_game_platform_services.dart';

const _testAchievement = GameAchievementId('achievement.test');
const _testLeaderboard = GameLeaderboardId('leaderboard.test');
const _testSaveSlot = GameSaveSlotId('save.test');

void main() {
  test('logical IDs compare by value without mixing identifier kinds', () {
    expect(
      const GameAchievementId('achievement.test'),
      const GameAchievementId('achievement.test'),
    );
    expect(
      const GameAchievementId('same.value'),
      isNot(equals(const GameLeaderboardId('same.value'))),
    );
  });

  group('VersionedGameSave', () {
    test('round-trips strict JSON and records revision ancestry', () {
      final first = VersionedGameSave.initial(
        schemaVersion: 1,
        writtenAtUtc: DateTime.utc(2026, 8, 30, 12),
        payload: '{"value":1}',
      );
      final second = first.next(
        schemaVersion: 2,
        writtenAtUtc: DateTime.utc(2026, 8, 30, 13),
        payload: '{"value":2}',
      );

      final decoded = VersionedGameSave.fromEncodedJson(second.toEncodedJson());

      expect(decoded.schemaVersion, 2);
      expect(decoded.revision, 2);
      expect(decoded.parentRevision, 1);
      expect(decoded.writtenAtUtc, DateTime.utc(2026, 8, 30, 13));
      expect(decoded.payload, '{"value":2}');
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
        achievementIds: {
          _testAchievement: PlatformGameServiceIds(
            android: 'android-id',
            ios: '',
          ),
        },
        leaderboardIds: const {},
      );

      expect(configuration.validate(), contains('achievement.test'));
    });
  });

  group('FakeGamePlatformServices', () {
    test(
      'authenticates and records logical achievement and score IDs',
      () async {
        final services = FakeGamePlatformServices();

        await services.authenticate();
        final achievement = await services.unlockAchievement(_testAchievement);
        await services.submitScore(leaderboard: _testLeaderboard, score: 3);
        await services.submitScore(leaderboard: _testLeaderboard, score: 2);

        expect(achievement.isSuccess, isTrue);
        expect(services.unlockedAchievements, contains(_testAchievement));
        expect(services.scores[_testLeaderboard], 3);
        expect(
          services.calls.map((call) => call.logicalId),
          containsAll(['achievement.test', 'leaderboard.test']),
        );
      },
    );

    test('stores versioned saves in memory', () async {
      final services = FakeGamePlatformServices();
      final save = VersionedGameSave.initial(
        schemaVersion: 1,
        writtenAtUtc: DateTime.utc(2026, 8, 30),
        payload: '{"value":4}',
      );

      await services.authenticate();
      await services.saveGame(slot: _testSaveSlot, save: save);
      final result = await services.loadGame(_testSaveSlot);

      expect(result, isA<GameServiceSuccess<VersionedGameSave?>>());
      final loaded = (result as GameServiceSuccess<VersionedGameSave?>).value;
      expect(loaded?.revision, 1);
      expect(loaded?.payload, '{"value":4}');
      expect(
        services.cloudSaveConflictBehavior,
        GameSaveConflictBehavior.platformResolved,
      );
    });

    test('returns a typed failure before authentication', () async {
      final services = FakeGamePlatformServices();

      final result = await services.unlockAchievement(_testAchievement);

      expect(result, isA<GameServiceFailure<GameServiceUnit>>());
      final failure = result as GameServiceFailure<GameServiceUnit>;
      expect(failure.error.code, GameServiceErrorCode.notAuthenticated);
    });
  });
}
