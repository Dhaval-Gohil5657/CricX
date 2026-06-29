import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';

abstract class DatabaseService {
  // Streams for real-time syncing
  Stream<List<Player>> streamPlayers();
  Stream<List<Team>> streamTeams(List<Player> allPlayers);
  Stream<List<CricketMatch>> streamMatches(List<Team> allTeams, List<Player> allPlayers);
  Stream<List<Tournament>> streamTournaments(List<Team> allTeams, List<CricketMatch> allMatches);

  // Players
  Future<void> addPlayer(Player player);
  Future<void> updatePlayerStats(Player player);

  // Teams
  Future<void> addTeam(Team team);
  Future<void> updateTeamInfo(Team team);
  Future<void> addPlayerToTeam(String teamId, Player player);

  // Matches
  Future<void> createMatch(CricketMatch match);
  Future<void> updateMatch(CricketMatch match);

  // Tournaments
  Future<void> createTournament(Tournament tournament);
  Future<void> updateTournament(Tournament tournament);
  
  // Database setup / seeding (to add initial data if database is empty)
  Future<void> checkAndSeedDatabase();
}
