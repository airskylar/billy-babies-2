import '../../runtime/game_services/game_platform_services.dart';

import 'tiny_tactics_game_service_ids.dart';

final gameServicesConfiguration = GameServicesConfiguration(
  enabled: const bool.fromEnvironment('GAME_SERVICES_ENABLED'),
  cloudSavesEnabled: const bool.fromEnvironment('GAME_SERVICES_CLOUD_SAVES'),
  achievementIds: {
    TinyTacticsGameServiceIds.firstWinAchievement: PlatformGameServiceIds(
      android: String.fromEnvironment('ANDROID_ACHIEVEMENT_FIRST_WIN'),
      ios: String.fromEnvironment('IOS_ACHIEVEMENT_FIRST_WIN'),
    ),
  },
  leaderboardIds: {
    TinyTacticsGameServiceIds.matchWinsLeaderboard: PlatformGameServiceIds(
      android: String.fromEnvironment('ANDROID_LEADERBOARD_MATCH_WINS'),
      ios: String.fromEnvironment('IOS_LEADERBOARD_MATCH_WINS'),
    ),
  },
  appStoreId: const String.fromEnvironment('APP_STORE_ID'),
  androidServerClientId: const String.fromEnvironment(
    'GOOGLE_GAMES_SERVER_CLIENT_ID',
  ),
);
