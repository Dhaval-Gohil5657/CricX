class ApiEndpoints {
  static const String baseUrl = 'https://cricx-kcid.onrender.com/api';
  static const String baseV1 = '$baseUrl/v1';

  // Auth / Users Endpoints
  static const String register = '$baseV1/users/register';
  static const String login = '$baseV1/users/login';
  static const String guest = '$baseV1/users/guest';
  static const String refresh = '$baseV1/users/refresh';
  static const String logout = '$baseV1/users/logout';
  static const String profile = '$baseV1/users/profile';
  static const String updateRole = '$baseV1/users/role';

  // Players Endpoints
  static const String players = '$baseV1/players';
  static String playerById(String id) => '$baseV1/players/$id';
  static String playerStats(String id) => '$baseV1/players/$id/stats';

  // Teams Endpoints
  static const String teams = '$baseV1/teams';
  static String teamById(String id) => '$baseV1/teams/$id';
  static String teamPlayers(String teamId) => '$baseV1/teams/$teamId/players';

  // Matches Endpoints
  static const String matches = '$baseV1/matches';
  static String matchById(String id) => '$baseV1/matches/$id';
  static String matchToss(String id) => '$baseV1/matches/$id/toss';
  static String matchStart(String id) => '$baseV1/matches/$id/start';
  static String matchScore(String id) => '$baseV1/matches/$id/score';
  static String matchScorecard(String id) => '$baseV1/matches/$id/scorecard';
  static String matchComplete(String id) => '$baseV1/matches/$id/complete';
  static String matchPlayerOfTheMatch(String id) => '$baseV1/matches/$id/player-of-the-match';

  // Tournaments Endpoints
  static const String tournaments = '$baseV1/tournaments';
  static String tournamentById(String id) => '$baseV1/tournaments/$id';
  static String tournamentTeams(String id) => '$baseV1/tournaments/$id/teams';
  static String tournamentFixtures(String id) => '$baseV1/tournaments/$id/fixtures';
  static String tournamentPointsTable(String id) => '$baseV1/tournaments/$id/points-table';
  static String tournamentPlayerOfTheTournament(String id) => '$baseV1/tournaments/$id/player-of-the-tournament';

  // Discovery & Stats
  static const String liveMatches = '$baseUrl/discovery/live-matches';
  static const String search = '$baseUrl/discovery/search';
  static const String playerLeaderboard = '$baseV1/stats/players';
  static const String teamLeaderboard = '$baseV1/stats/teams';
  
  // Notifications
  static const String notifications = '$baseV1/notifications';
  static String markNotificationRead(String id) => '$baseV1/notifications/$id/read';

  // Admin Controls
  static String adminUserStatus(String userId) => '$baseUrl/admin/users/$userId/status';
  static String adminTeam(String teamId) => '$baseUrl/admin/teams/$teamId';
}
