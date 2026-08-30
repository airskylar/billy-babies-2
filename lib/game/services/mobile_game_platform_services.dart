import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart' as native;
import 'package:in_app_review/in_app_review.dart';

import 'game_platform_services.dart';

final class MobileGamePlatformServices implements GamePlatformServices {
  MobileGamePlatformServices({
    required this.configuration,
    InAppReview? inAppReview,
    this._requestTimeout = const Duration(seconds: 20),
  }) : _inAppReview = inAppReview ?? InAppReview.instance;

  final GameServicesConfiguration configuration;
  final InAppReview _inAppReview;
  final Duration _requestTimeout;
  bool _disposed = false;

  bool get _isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  @override
  late final Set<GameServiceCapability> capabilities = _buildCapabilities();

  @override
  GameSaveConflictBehavior get cloudSaveConflictBehavior =>
      GameSaveConflictBehavior.platformResolved;

  Set<GameServiceCapability> _buildCapabilities() {
    if (!_isSupportedPlatform) return const {};

    final result = <GameServiceCapability>{GameServiceCapability.reviews};
    if (!configuration.enabled) return Set.unmodifiable(result);

    result.addAll(const {
      GameServiceCapability.authentication,
      GameServiceCapability.serverCredentials,
    });
    if (configuration.achievementIds.isNotEmpty) {
      result.add(GameServiceCapability.achievements);
    }
    if (configuration.leaderboardIds.isNotEmpty) {
      result.add(GameServiceCapability.leaderboards);
    }
    if (configuration.cloudSavesEnabled) {
      result.add(GameServiceCapability.cloudSaves);
    }
    return Set.unmodifiable(result);
  }

  @override
  Future<GameServiceResult<GamePlayer>> authenticate() async {
    final failure = _preflight<GamePlayer>(
      GameServiceOperation.authenticate,
      capability: GameServiceCapability.authentication,
    );
    if (failure != null) return failure;

    return _run(GameServiceOperation.authenticate, () async {
      await native.GameAuth.signIn().timeout(_requestTimeout);
      final player = await native.GameAuth.player.first.timeout(
        _requestTimeout,
      );
      if (player == null) {
        throw PlatformException(
          code: 'not_authenticated',
          message: 'The platform did not return an authenticated player.',
        );
      }
      return GamePlayer(
        displayName: player.displayName,
        playerId: player.playerID,
        teamPlayerId: player.teamPlayerID,
        iconImage: player.iconImage,
      );
    });
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> unlockAchievement(
    GameAchievement achievement,
  ) async {
    final failure = _preflight<GameServiceUnit>(
      GameServiceOperation.unlockAchievement,
      capability: GameServiceCapability.achievements,
    );
    if (failure != null) return failure;

    final ids = configuration.achievementIds[achievement];
    if (ids == null) {
      return _notConfigured(
        GameServiceOperation.unlockAchievement,
        'Achievement "${achievement.logicalId}" is not configured.',
      );
    }

    return _run(GameServiceOperation.unlockAchievement, () async {
      await native.Achievements.unlock(
        achievement: native.Achievement(androidID: ids.android, iOSID: ids.ios),
      ).timeout(_requestTimeout);
      return GameServiceUnit.completed;
    });
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> submitScore({
    required GameLeaderboard leaderboard,
    required int score,
  }) async {
    final failure = _preflight<GameServiceUnit>(
      GameServiceOperation.submitScore,
      capability: GameServiceCapability.leaderboards,
    );
    if (failure != null) return failure;
    if (score < 0) {
      return _failure(
        GameServiceOperation.submitScore,
        GameServiceErrorCode.invalidData,
        'Leaderboard scores must not be negative.',
      );
    }

    final ids = configuration.leaderboardIds[leaderboard];
    if (ids == null) {
      return _notConfigured(
        GameServiceOperation.submitScore,
        'Leaderboard "${leaderboard.logicalId}" is not configured.',
      );
    }

    return _run(GameServiceOperation.submitScore, () async {
      await native.Leaderboards.submitScore(
        score: native.Score(
          androidLeaderboardID: ids.android,
          iOSLeaderboardID: ids.ios,
          value: score,
        ),
      ).timeout(_requestTimeout);
      return GameServiceUnit.completed;
    });
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> showAchievements() async {
    final failure = _preflight<GameServiceUnit>(
      GameServiceOperation.showAchievements,
      capability: GameServiceCapability.achievements,
    );
    if (failure != null) return failure;

    return _run(GameServiceOperation.showAchievements, () async {
      await native.Achievements.showAchievements().timeout(_requestTimeout);
      return GameServiceUnit.completed;
    });
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> showLeaderboard(
    GameLeaderboard leaderboard,
  ) async {
    final failure = _preflight<GameServiceUnit>(
      GameServiceOperation.showLeaderboard,
      capability: GameServiceCapability.leaderboards,
    );
    if (failure != null) return failure;

    final ids = configuration.leaderboardIds[leaderboard];
    if (ids == null) {
      return _notConfigured(
        GameServiceOperation.showLeaderboard,
        'Leaderboard "${leaderboard.logicalId}" is not configured.',
      );
    }

    return _run(GameServiceOperation.showLeaderboard, () async {
      await native.Leaderboards.showLeaderboards(
        androidLeaderboardID: ids.android,
        iOSLeaderboardID: ids.ios,
      ).timeout(_requestTimeout);
      return GameServiceUnit.completed;
    });
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> saveGame({
    required GameSaveSlot slot,
    required VersionedGameSave save,
  }) async {
    final failure = _preflight<GameServiceUnit>(
      GameServiceOperation.saveGame,
      capability: GameServiceCapability.cloudSaves,
    );
    if (failure != null) return failure;

    return _run(GameServiceOperation.saveGame, () async {
      await native.SaveGame.saveGame(
        data: save.toEncodedJson(),
        name: slot.logicalId,
      ).timeout(_requestTimeout);
      return GameServiceUnit.completed;
    });
  }

  @override
  Future<GameServiceResult<VersionedGameSave?>> loadGame(
    GameSaveSlot slot,
  ) async {
    final failure = _preflight<VersionedGameSave?>(
      GameServiceOperation.loadGame,
      capability: GameServiceCapability.cloudSaves,
    );
    if (failure != null) return failure;

    return _run(GameServiceOperation.loadGame, () async {
      final source = await native.SaveGame.loadGame(
        name: slot.logicalId,
      ).timeout(_requestTimeout);
      return source == null ? null : VersionedGameSave.fromEncodedJson(source);
    });
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> deleteGame(
    GameSaveSlot slot,
  ) async {
    final failure = _preflight<GameServiceUnit>(
      GameServiceOperation.deleteGame,
      capability: GameServiceCapability.cloudSaves,
    );
    if (failure != null) return failure;

    return _run(GameServiceOperation.deleteGame, () async {
      await native.SaveGame.deleteGame(
        name: slot.logicalId,
      ).timeout(_requestTimeout);
      return GameServiceUnit.completed;
    });
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> requestReview() async {
    final failure = _preflight<GameServiceUnit>(
      GameServiceOperation.requestReview,
      capability: GameServiceCapability.reviews,
      requiresConfiguration: false,
    );
    if (failure != null) return failure;

    return _run(GameServiceOperation.requestReview, () async {
      if (!await _inAppReview.isAvailable().timeout(_requestTimeout)) {
        throw UnsupportedError('The in-app review flow is unavailable.');
      }
      await _inAppReview.requestReview().timeout(_requestTimeout);
      return GameServiceUnit.completed;
    });
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> openReviewPage() async {
    final failure = _preflight<GameServiceUnit>(
      GameServiceOperation.openReviewPage,
      capability: GameServiceCapability.reviews,
      requiresConfiguration: false,
    );
    if (failure != null) return failure;
    if (Platform.isIOS && configuration.appStoreId.trim().isEmpty) {
      return _notConfigured(
        GameServiceOperation.openReviewPage,
        'APP_STORE_ID is required to open the iOS review page.',
      );
    }

    return _run(GameServiceOperation.openReviewPage, () async {
      await _inAppReview
          .openStoreListing(
            appStoreId: Platform.isIOS ? configuration.appStoreId : null,
          )
          .timeout(_requestTimeout);
      return GameServiceUnit.completed;
    });
  }

  @override
  Future<GameServiceResult<GameServerCredentials>>
  requestServerCredentials() async {
    final failure = _preflight<GameServerCredentials>(
      GameServiceOperation.requestServerCredentials,
      capability: GameServiceCapability.serverCredentials,
    );
    if (failure != null) return failure;

    return _run(GameServiceOperation.requestServerCredentials, () async {
      if (Platform.isAndroid) {
        final clientId = configuration.androidServerClientId.trim();
        if (clientId.isEmpty) {
          throw PlatformException(
            code: 'not_configured',
            message: 'GOOGLE_GAMES_SERVER_CLIENT_ID is required on Android.',
          );
        }
        final authCode = await native.GameAuth.getAuthCode(
          clientId,
          forceRefreshToken: true,
        ).timeout(_requestTimeout);
        if (authCode == null || authCode.isEmpty) {
          throw PlatformException(
            code: 'credentials_unavailable',
            message: 'Google Play Games did not return a server auth code.',
          );
        }
        return AndroidGameServerCredentials(authCode: authCode);
      }

      final signature =
          await native.GameAuth.fetchIdentityVerificationSignature().timeout(
            _requestTimeout,
          );
      if (signature == null) {
        throw PlatformException(
          code: 'credentials_unavailable',
          message: 'Game Center did not return an identity signature.',
        );
      }
      return AppleGameServerCredentials(
        publicKeyUrl: Uri.parse(signature.publicKeyURL),
        signature: signature.signature,
        salt: signature.salt,
        timestamp: signature.timestamp,
      );
    });
  }

  GameServiceFailure<T>? _preflight<T>(
    GameServiceOperation operation, {
    required GameServiceCapability capability,
    bool requiresConfiguration = true,
  }) {
    if (_disposed) {
      return _failure(
        operation,
        GameServiceErrorCode.disposed,
        'Game platform services have been disposed.',
      );
    }
    if (!_isSupportedPlatform || !capabilities.contains(capability)) {
      return _failure(
        operation,
        GameServiceErrorCode.unsupported,
        'This operation is unavailable on the current platform.',
      );
    }
    if (!requiresConfiguration) return null;
    if (!configuration.enabled) {
      return _failure(
        operation,
        GameServiceErrorCode.disabled,
        'Game services are disabled for this build.',
      );
    }
    final configurationError = configuration.validate();
    if (configurationError != null) {
      return _failure(
        operation,
        GameServiceErrorCode.invalidConfiguration,
        configurationError,
      );
    }
    return null;
  }

  Future<GameServiceResult<T>> _run<T>(
    GameServiceOperation operation,
    Future<T> Function() action,
  ) async {
    try {
      return GameServiceSuccess(await action());
    } on TimeoutException catch (error, stackTrace) {
      return _failure(
        operation,
        GameServiceErrorCode.timeout,
        'The platform operation timed out.',
        cause: error,
        stackTrace: stackTrace,
      );
    } on FormatException catch (error, stackTrace) {
      return _failure(
        operation,
        GameServiceErrorCode.invalidData,
        error.message,
        cause: error,
        stackTrace: stackTrace,
      );
    } on UnsupportedError catch (error, stackTrace) {
      return _failure(
        operation,
        GameServiceErrorCode.unsupported,
        error.message ?? 'The platform operation is unsupported.',
        cause: error,
        stackTrace: stackTrace,
      );
    } on PlatformException catch (error, stackTrace) {
      return _failure(
        operation,
        _errorCodeFor(error),
        error.message ?? 'The platform operation failed.',
        platformCode: error.code,
        cause: error,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      return _failure(
        operation,
        GameServiceErrorCode.platform,
        'The platform operation failed.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  GameServiceErrorCode _errorCodeFor(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('not_configured')) {
      return GameServiceErrorCode.notConfigured;
    }
    if (code.contains('cancel')) return GameServiceErrorCode.cancelled;
    if (code.contains('network')) return GameServiceErrorCode.network;
    if (code.contains('not_authenticated') ||
        code.contains('sign_in_required')) {
      return GameServiceErrorCode.notAuthenticated;
    }
    if (code.contains('auth') || code.contains('sign_in')) {
      return GameServiceErrorCode.authenticationFailed;
    }
    return GameServiceErrorCode.platform;
  }

  GameServiceFailure<T> _notConfigured<T>(
    GameServiceOperation operation,
    String message,
  ) {
    return _failure(operation, GameServiceErrorCode.notConfigured, message);
  }

  GameServiceFailure<T> _failure<T>(
    GameServiceOperation operation,
    GameServiceErrorCode code,
    String message, {
    String? platformCode,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return GameServiceFailure(
      GameServiceError(
        operation: operation,
        code: code,
        message: message,
        platformCode: platformCode,
        cause: cause,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }
}
