class ApiEndpoints {
  static const String baseUrl = 'https://cricx-kcid.onrender.com/api';
  static const String baseV1 = '$baseUrl/v1';

  // Auth / Users Endpoints
  static const String register = '$baseV1/users/register';
  static const String login = '$baseV1/users/login';
  static const String guest = '$baseV1/users/guest';
  static const String refresh = '$baseV1/users/refresh';
  static const String updateRole = '$baseV1/users/role';

  // Players Endpoints
  static const String players = '$baseV1/players';
  static String playerById(String id) => '$baseV1/players/$id';

  // Teams Endpoints
  static const String teams = '$baseV1/teams';
  static String teamById(String id) => '$baseV1/teams/$id';
  static String teamPlayers(String teamId) => '$baseV1/teams/$teamId/players';
  static String removePlayerFromTeam(String teamId, String playerId) => '$baseV1/teams/$teamId/players/$playerId';

  // Matches Endpoints
  static const String matches = '$baseV1/matches';
  static String matchById(String id) => '$baseV1/matches/$id';
  static String matchStart(String id) => '$baseV1/matches/$id/start';
  static String matchScore(String id) => '$baseV1/matches/$id/score';

  // Tournaments Endpoints
  static const String tournaments = '$baseV1/tournaments';
  static String tournamentById(String id) => '$baseV1/tournaments/$id';
  static String tournamentTeams(String id) => '$baseV1/tournaments/$id/teams';

  // Stats
  static const String playerLeaderboard = '$baseV1/stats/players';
  static const String teamLeaderboard = '$baseV1/stats/teams';

}

/*
Placeholder/Proposed Endpoints (Commented out until implemented by backend team)

  =========================================================================
  REMAINING/NOT WORKING BACKEND APIS (Currently returning 404 from server)

  1. UPDATE PLAYER DETAILS: PUT /api/v1/players/:playerId
     - Returns: 404 Not Found (Cannot PUT /api/v1/players/:playerId)
     - Used in: ApiDatabaseService.updatePlayerStats
  2. UPDATE TEAM DETAILS: PUT /api/v1/teams/:teamId
     - Returns: 404 Not Found (Cannot PUT /api/v1/teams/:teamId)
     - Used in: ApiDatabaseService.updateTeamInfo
  3. REMOVE PLAYER FROM TEAM: DELETE /api/v1/teams/:teamId/players/:playerId
     - Returns: 404 Not Found (Cannot DELETE /api/v1/teams/:teamId/players/:playerId)
     - Used in: AppState.removePlayerFromTeam
  4. START MATCH / CHOOSE PLAYING XI: PUT /api/v1/matches/:matchId/start
     - Returns: 404 Not Found (Cannot PUT /api/v1/matches/:matchId/start)
     - Used in: ApiDatabaseService.updateMatch (initializes toss, playing XI, and live status)
 */