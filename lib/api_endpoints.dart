class ApiEndpoints {
  static const String baseUrl = 'https://cricx-kcid.onrender.com/api';
  static const String baseV1 = '$baseUrl/v1';

  // Auth / Users Endpoints
  static const String register = '$baseV1/users/register'; //Working
  static const String login = '$baseV1/users/login'; //Working
  static const String guest = '$baseV1/users/guest'; //Working
  static const String refresh = '$baseV1/users/refresh';
  static const String updateRole = '$baseV1/users/role'; //Working

  // Players Endpoints
  static const String players = '$baseV1/players'; //Working
  static String playerById(String id) => '$baseV1/players/$id'; //Working

  // Teams Endpoints
  static const String teams = '$baseV1/teams'; //Working
  static String teamById(String id) => '$baseV1/teams/$id'; //Working
  static String teamPlayers(String teamId) => '$baseV1/teams/$teamId/players'; //Working
  static String removePlayerFromTeam(String teamId, String playerId) => '$baseV1/teams/$teamId/players/$playerId'; //Working

  // Matches Endpoints
  static const String matches = '$baseV1/matches'; //Working
  static String matchById(String id) => '$baseV1/matches/$id'; //Working
  static String matchStart(String id) => '$baseV1/matches/$id/start'; //Working
  static String matchScore(String id) => '$baseV1/matches/$id/score'; // working

  // Tournaments Endpoints
  static const String tournaments = '$baseV1/tournaments'; //Working
  static String tournamentById(String id) => '$baseV1/tournaments/$id'; // working
  static String tournamentTeams(String id) => '$baseV1/tournaments/$id/teams'; // working
  static String declarePlayerOfTheTournament(String id) => '$baseV1/tournaments/$id/player-of-the-tournament';

  // Stats
  static const String playerLeaderboard = '$baseV1/stats/players';
  static const String teamLeaderboard = '$baseV1/stats/teams';

}

/*
Placeholder/Proposed Endpoints (Commented out until implemented by backend team)

  =========================================================================
  REMAINING/NOT WORKING BACKEND APIS (Currently returning 404 from server)
 */