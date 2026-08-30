import 'game_platform_services.dart';

final class GameServiceCall {
  const GameServiceCall({
    required this.operation,
    this.logicalId,
    this.score,
    this.revision,
  });

  final GameServiceOperation operation;
  final String? logicalId;
  final int? score;
  final int? revision;
}

final class FakeGamePlatformServices implements GamePlatformServices {
  FakeGamePlatformServices({
    this.player = const GamePlayer(
      playerId: 'test-player',
      displayName: 'Test Player',
    ),
    this.serverCredentials = const AndroidGameServerCredentials(
      authCode: 'test-auth-code',
    ),
    Set<GameServiceCapability> capabilities = const {
      GameServiceCapability.authentication,
      GameServiceCapability.achievements,
      GameServiceCapability.leaderboards,
      GameServiceCapability.cloudSaves,
      GameServiceCapability.reviews,
      GameServiceCapability.serverCredentials,
    },
    Map<GameServiceOperation, GameServiceError> failures = const {},
  }) : capabilities = Set.unmodifiable(capabilities),
       _failures = Map.unmodifiable(failures);

  final GamePlayer player;
  final GameServerCredentials serverCredentials;

  @override
  final Set<GameServiceCapability> capabilities;

  final Map<GameServiceOperation, GameServiceError> _failures;
  final List<GameServiceCall> _calls = [];
  final Set<GameAchievement> _unlockedAchievements = {};
  final Map<GameLeaderboard, int> _scores = {};
  final Map<GameSaveSlot, VersionedGameSave> _saves = {};
  bool _authenticated = false;
  bool _disposed = false;
  int _reviewRequests = 0;
  int _reviewPageOpens = 0;

  List<GameServiceCall> get calls => List.unmodifiable(_calls);
  Set<GameAchievement> get unlockedAchievements =>
      Set.unmodifiable(_unlockedAchievements);
  Map<GameLeaderboard, int> get scores => Map.unmodifiable(_scores);
  Map<GameSaveSlot, VersionedGameSave> get saves => Map.unmodifiable(_saves);
  bool get isAuthenticated => _authenticated;
  bool get isDisposed => _disposed;
  int get reviewRequests => _reviewRequests;
  int get reviewPageOpens => _reviewPageOpens;

  @override
  GameSaveConflictBehavior get cloudSaveConflictBehavior =>
      GameSaveConflictBehavior.platformResolved;

  @override
  Future<GameServiceResult<GamePlayer>> authenticate() async {
    _record(GameServiceOperation.authenticate);
    final failure = _guard<GamePlayer>(
      GameServiceOperation.authenticate,
      GameServiceCapability.authentication,
      requiresAuthentication: false,
    );
    if (failure != null) return failure;
    _authenticated = true;
    return GameServiceSuccess(player);
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> unlockAchievement(
    GameAchievement achievement,
  ) async {
    _record(
      GameServiceOperation.unlockAchievement,
      logicalId: achievement.logicalId,
    );
    final failure = _guard<GameServiceUnit>(
      GameServiceOperation.unlockAchievement,
      GameServiceCapability.achievements,
    );
    if (failure != null) return failure;
    _unlockedAchievements.add(achievement);
    return const GameServiceSuccess(GameServiceUnit.completed);
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> submitScore({
    required GameLeaderboard leaderboard,
    required int score,
  }) async {
    _record(
      GameServiceOperation.submitScore,
      logicalId: leaderboard.logicalId,
      score: score,
    );
    final failure = _guard<GameServiceUnit>(
      GameServiceOperation.submitScore,
      GameServiceCapability.leaderboards,
    );
    if (failure != null) return failure;
    if (score < 0) {
      return _failure(
        GameServiceOperation.submitScore,
        GameServiceErrorCode.invalidData,
        'Leaderboard scores must not be negative.',
      );
    }
    final current = _scores[leaderboard];
    if (current == null || score > current) {
      _scores[leaderboard] = score;
    }
    return const GameServiceSuccess(GameServiceUnit.completed);
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> showAchievements() async {
    _record(GameServiceOperation.showAchievements);
    final failure = _guard<GameServiceUnit>(
      GameServiceOperation.showAchievements,
      GameServiceCapability.achievements,
    );
    return failure ?? const GameServiceSuccess(GameServiceUnit.completed);
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> showLeaderboard(
    GameLeaderboard leaderboard,
  ) async {
    _record(
      GameServiceOperation.showLeaderboard,
      logicalId: leaderboard.logicalId,
    );
    final failure = _guard<GameServiceUnit>(
      GameServiceOperation.showLeaderboard,
      GameServiceCapability.leaderboards,
    );
    return failure ?? const GameServiceSuccess(GameServiceUnit.completed);
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> saveGame({
    required GameSaveSlot slot,
    required VersionedGameSave save,
  }) async {
    _record(
      GameServiceOperation.saveGame,
      logicalId: slot.logicalId,
      revision: save.revision,
    );
    final failure = _guard<GameServiceUnit>(
      GameServiceOperation.saveGame,
      GameServiceCapability.cloudSaves,
    );
    if (failure != null) return failure;
    _saves[slot] = save;
    return const GameServiceSuccess(GameServiceUnit.completed);
  }

  @override
  Future<GameServiceResult<VersionedGameSave?>> loadGame(
    GameSaveSlot slot,
  ) async {
    _record(GameServiceOperation.loadGame, logicalId: slot.logicalId);
    final failure = _guard<VersionedGameSave?>(
      GameServiceOperation.loadGame,
      GameServiceCapability.cloudSaves,
    );
    if (failure != null) return failure;
    return GameServiceSuccess(_saves[slot]);
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> deleteGame(
    GameSaveSlot slot,
  ) async {
    _record(GameServiceOperation.deleteGame, logicalId: slot.logicalId);
    final failure = _guard<GameServiceUnit>(
      GameServiceOperation.deleteGame,
      GameServiceCapability.cloudSaves,
    );
    if (failure != null) return failure;
    _saves.remove(slot);
    return const GameServiceSuccess(GameServiceUnit.completed);
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> requestReview() async {
    _record(GameServiceOperation.requestReview);
    final failure = _guard<GameServiceUnit>(
      GameServiceOperation.requestReview,
      GameServiceCapability.reviews,
      requiresAuthentication: false,
    );
    if (failure != null) return failure;
    _reviewRequests += 1;
    return const GameServiceSuccess(GameServiceUnit.completed);
  }

  @override
  Future<GameServiceResult<GameServiceUnit>> openReviewPage() async {
    _record(GameServiceOperation.openReviewPage);
    final failure = _guard<GameServiceUnit>(
      GameServiceOperation.openReviewPage,
      GameServiceCapability.reviews,
      requiresAuthentication: false,
    );
    if (failure != null) return failure;
    _reviewPageOpens += 1;
    return const GameServiceSuccess(GameServiceUnit.completed);
  }

  @override
  Future<GameServiceResult<GameServerCredentials>>
  requestServerCredentials() async {
    _record(GameServiceOperation.requestServerCredentials);
    final failure = _guard<GameServerCredentials>(
      GameServiceOperation.requestServerCredentials,
      GameServiceCapability.serverCredentials,
    );
    if (failure != null) return failure;
    return GameServiceSuccess(serverCredentials);
  }

  GameServiceFailure<T>? _guard<T>(
    GameServiceOperation operation,
    GameServiceCapability capability, {
    bool requiresAuthentication = true,
  }) {
    if (_disposed) {
      return _failure(
        operation,
        GameServiceErrorCode.disposed,
        'Game platform services have been disposed.',
      );
    }
    final scriptedFailure = _failures[operation];
    if (scriptedFailure != null) return GameServiceFailure(scriptedFailure);
    if (!capabilities.contains(capability)) {
      return _failure(
        operation,
        GameServiceErrorCode.unsupported,
        'The fake does not support ${capability.name}.',
      );
    }
    if (requiresAuthentication && !_authenticated) {
      return _failure(
        operation,
        GameServiceErrorCode.notAuthenticated,
        'Authenticate the fake player before this operation.',
      );
    }
    return null;
  }

  void _record(
    GameServiceOperation operation, {
    String? logicalId,
    int? score,
    int? revision,
  }) {
    _calls.add(
      GameServiceCall(
        operation: operation,
        logicalId: logicalId,
        score: score,
        revision: revision,
      ),
    );
  }

  GameServiceFailure<T> _failure<T>(
    GameServiceOperation operation,
    GameServiceErrorCode code,
    String message,
  ) {
    return GameServiceFailure(
      GameServiceError(operation: operation, code: code, message: message),
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }
}
