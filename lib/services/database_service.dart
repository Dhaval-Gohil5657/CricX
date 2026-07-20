import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';

abstract class DatabaseService {
  // Futures for explicit fetching
  Future<List<Player>> getPlayers();
  Future<List<Team>> getTeams(List<Player> allPlayers);
  Future<List<CricketMatch>> getMatches(List<Team> allTeams, List<Player> allPlayers);
  Future<List<Tournament>> getTournaments(List<Team> allTeams, List<CricketMatch> allMatches);

  // Players
  Future<void> addPlayer(Player player);
  Future<void> updatePlayerStats(Player player);

  // Teams
  Future<void> addTeam(Team team);
  Future<void> updateTeamInfo(Team team);
  Future<void> addPlayerToTeam(String teamId, Player player);
  Future<void> removePlayerFromTeam(String teamId, String playerId);

  // Matches
  Future<CricketMatch> createMatch(CricketMatch match);
  Future<void> updateMatch(CricketMatch match);

  // Tournaments
  Future<void> createTournament(Tournament tournament);
  Future<void> updateTournament(Tournament tournament);
  Future<void> declarePlayerOfTheTournament(String tournamentId, String playerId, String playerName);
  
  // Database setup / seeding
  Future<void> checkAndSeedDatabase();
}
