import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'game_platform_services.g.dart';

sealed class GameServiceId {
  const GameServiceId(this.logicalId);

  final String logicalId;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is GameServiceId &&
      other.logicalId == logicalId;

  @override
  int get hashCode => Object.hash(runtimeType, logicalId);

  @override
  String toString() => logicalId;
}

final class GameAchievementId extends GameServiceId {
  const GameAchievementId(super.logicalId);
}

final class GameLeaderboardId extends GameServiceId {
  const GameLeaderboardId(super.logicalId);
}

final class GameSaveSlotId extends GameServiceId {
  const GameSaveSlotId(super.logicalId);
}

enum GameServiceCapability {
  authentication,
  achievements,
  leaderboards,
  cloudSaves,
  reviews,
  serverCredentials,
}

enum GameServiceOperation {
  authenticate,
  unlockAchievement,
  submitScore,
  showAchievements,
  showLeaderboard,
  saveGame,
  loadGame,
  deleteGame,
  requestReview,
  openReviewPage,
  requestServerCredentials,
}

enum GameServiceErrorCode {
  disabled,
  disposed,
  invalidConfiguration,
  notConfigured,
  unsupported,
  notAuthenticated,
  authenticationFailed,
  cancelled,
  network,
  invalidData,
  timeout,
  platform,
}

enum GameSaveConflictBehavior {
  /// Game Center or Play Games resolves conflicts before Dart receives a save.
  platformResolved,
}

enum GameServiceUnit { completed }

final class PlatformGameServiceIds {
  const PlatformGameServiceIds({required this.android, required this.ios});

  final String android;
  final String ios;

  bool get isComplete => android.trim().isNotEmpty && ios.trim().isNotEmpty;
}

final class GameServicesConfiguration {
  GameServicesConfiguration({
    required this.enabled,
    required this.cloudSavesEnabled,
    required Map<GameAchievementId, PlatformGameServiceIds> achievementIds,
    required Map<GameLeaderboardId, PlatformGameServiceIds> leaderboardIds,
    this.appStoreId = '',
    this.androidServerClientId = '',
  }) : achievementIds = Map.unmodifiable(achievementIds),
       leaderboardIds = Map.unmodifiable(leaderboardIds);

  final bool enabled;
  final bool cloudSavesEnabled;
  final Map<GameAchievementId, PlatformGameServiceIds> achievementIds;
  final Map<GameLeaderboardId, PlatformGameServiceIds> leaderboardIds;
  final String appStoreId;
  final String androidServerClientId;

  String? validate() {
    if (!enabled) return null;

    for (final entry in achievementIds.entries) {
      if (!entry.value.isComplete) {
        return 'Achievement "${entry.key.logicalId}" needs Android and iOS IDs.';
      }
    }
    for (final entry in leaderboardIds.entries) {
      if (!entry.value.isComplete) {
        return 'Leaderboard "${entry.key.logicalId}" needs Android and iOS IDs.';
      }
    }
    return null;
  }
}

final class GamePlayer {
  const GamePlayer({
    required this.displayName,
    this.playerId,
    this.teamPlayerId,
    this.iconImage,
  });

  final String displayName;
  final String? playerId;
  final String? teamPlayerId;
  final String? iconImage;
}

sealed class GameServerCredentials {
  const GameServerCredentials();
}

final class AndroidGameServerCredentials extends GameServerCredentials {
  const AndroidGameServerCredentials({required this.authCode});

  final String authCode;
}

final class AppleGameServerCredentials extends GameServerCredentials {
  const AppleGameServerCredentials({
    required this.publicKeyUrl,
    required this.signature,
    required this.salt,
    required this.timestamp,
  });

  final Uri publicKeyUrl;
  final String signature;
  final String salt;
  final int timestamp;
}

final class GameServiceError {
  const GameServiceError({
    required this.operation,
    required this.code,
    required this.message,
    this.platformCode,
    this.cause,
    this.stackTrace,
  });

  final GameServiceOperation operation;
  final GameServiceErrorCode code;
  final String message;
  final String? platformCode;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final nativeCode = platformCode == null ? '' : ' ($platformCode)';
    return '${operation.name}: $message$nativeCode';
  }
}

sealed class GameServiceResult<T> {
  const GameServiceResult();

  bool get isSuccess => this is GameServiceSuccess<T>;
}

final class GameServiceSuccess<T> extends GameServiceResult<T> {
  const GameServiceSuccess(this.value);

  final T value;
}

final class GameServiceFailure<T> extends GameServiceResult<T> {
  const GameServiceFailure(this.error);

  final GameServiceError error;
}

@JsonSerializable(checked: true, disallowUnrecognizedKeys: true)
final class VersionedGameSave {
  const VersionedGameSave({
    required this.schemaVersion,
    required this.revision,
    required this.parentRevision,
    required this.writtenAtUtc,
    required this.payload,
  });

  final int schemaVersion;
  final int revision;

  @JsonKey(required: true)
  final int? parentRevision;

  final DateTime writtenAtUtc;
  final String payload;

  factory VersionedGameSave.initial({
    required int schemaVersion,
    required DateTime writtenAtUtc,
    required String payload,
  }) {
    return VersionedGameSave(
      schemaVersion: schemaVersion,
      revision: 1,
      parentRevision: null,
      writtenAtUtc: writtenAtUtc,
      payload: payload,
    ).._validate();
  }

  factory VersionedGameSave.fromJson(Map<String, dynamic> json) {
    final save = _$VersionedGameSaveFromJson(json);
    save._validate();
    return save;
  }

  factory VersionedGameSave.fromEncodedJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('The save document must be a JSON object.');
      }
      return VersionedGameSave.fromJson(decoded);
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid versioned save document: $error');
    }
  }

  Map<String, dynamic> toJson() => _$VersionedGameSaveToJson(this);

  String toEncodedJson() => jsonEncode(toJson());

  VersionedGameSave next({
    required int schemaVersion,
    required DateTime writtenAtUtc,
    required String payload,
  }) {
    return VersionedGameSave(
      schemaVersion: schemaVersion,
      revision: revision + 1,
      parentRevision: revision,
      writtenAtUtc: writtenAtUtc,
      payload: payload,
    ).._validate();
  }

  void _validate() {
    if (schemaVersion < 1) {
      throw const FormatException('schemaVersion must be at least 1.');
    }
    if (revision < 1) {
      throw const FormatException('revision must be at least 1.');
    }
    final expectedParentRevision = revision == 1 ? null : revision - 1;
    if (parentRevision != expectedParentRevision) {
      throw const FormatException(
        'parentRevision must be null for revision 1 and immediately precede '
        'later revisions.',
      );
    }
    if (!writtenAtUtc.isUtc) {
      throw const FormatException('writtenAtUtc must use UTC.');
    }
  }
}

abstract interface class GamePlatformServices {
  Set<GameServiceCapability> get capabilities;

  GameSaveConflictBehavior get cloudSaveConflictBehavior;

  Future<GameServiceResult<GamePlayer>> authenticate();

  Future<GameServiceResult<GameServiceUnit>> unlockAchievement(
    GameAchievementId achievement,
  );

  Future<GameServiceResult<GameServiceUnit>> submitScore({
    required GameLeaderboardId leaderboard,
    required int score,
  });

  Future<GameServiceResult<GameServiceUnit>> showAchievements();

  Future<GameServiceResult<GameServiceUnit>> showLeaderboard(
    GameLeaderboardId leaderboard,
  );

  Future<GameServiceResult<GameServiceUnit>> saveGame({
    required GameSaveSlotId slot,
    required VersionedGameSave save,
  });

  Future<GameServiceResult<VersionedGameSave?>> loadGame(GameSaveSlotId slot);

  Future<GameServiceResult<GameServiceUnit>> deleteGame(GameSaveSlotId slot);

  Future<GameServiceResult<GameServiceUnit>> requestReview();

  Future<GameServiceResult<GameServiceUnit>> openReviewPage();

  Future<GameServiceResult<GameServerCredentials>> requestServerCredentials();

  Future<void> dispose();
}
