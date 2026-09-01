import 'game_platform_services.dart';

final gameServicesConfiguration = GameServicesConfiguration(
  enabled: const bool.fromEnvironment('GAME_SERVICES_ENABLED'),
  cloudSavesEnabled: const bool.fromEnvironment('GAME_SERVICES_CLOUD_SAVES'),
  achievementIds: const {
    GameAchievement.firstWin: PlatformGameServiceIds(
      android: String.fromEnvironment('ANDROID_ACHIEVEMENT_FIRST_WIN'),
      ios: String.fromEnvironment('IOS_ACHIEVEMENT_FIRST_WIN'),
    ),
  },
  leaderboardIds: const {
    GameLeaderboard.matchWins: PlatformGameServiceIds(
      android: String.fromEnvironment('ANDROID_LEADERBOARD_MATCH_WINS'),
      ios: String.fromEnvironment('IOS_LEADERBOARD_MATCH_WINS'),
    ),
  },
  appStoreId: const String.fromEnvironment('APP_STORE_ID'),
  androidServerClientId: const String.fromEnvironment(
    'GOOGLE_GAMES_SERVER_CLIENT_ID',
  ),
);
