import 'team_model.dart';
import 'match_model.dart';

class PointsTableEntry {
  final Team team;
  int played;
  int won;
  int lost;
  double netRunRate;

  PointsTableEntry({
    required this.team,
    this.played = 0,
    this.won = 0,
    this.lost = 0,
    this.netRunRate = 0.0,
  });

  int get points => won * 2;
}

class Tournament {
  final String id;
  final String name;
  final String type; // 'League', 'Knockout' (kept for backwards compatibility)
  final List<Team> teams;
  final List<CricketMatch> matches;
  List<PointsTableEntry> pointsTable;
  String status; // 'Upcoming', 'Ongoing', 'Completed'
  String? winnerTeamId;
  String? playerOfTheTournamentId;
  String? playerOfTheTournamentName;
  final String playoffType; // 'Direct Final', 'Semifinals & Final'
  final int defaultOvers;
  final DateTime startDate;
  final String venue;
  final String? creatorId;

  Tournament({
    required this.id,
    required this.name,
    this.type = 'League',
    required this.teams,
    required this.matches,
    this.status = 'Upcoming',
    this.winnerTeamId,
    this.playerOfTheTournamentId,
    this.playerOfTheTournamentName,
    this.playoffType = 'Direct Final',
    this.defaultOvers = 10,
    DateTime? startDate,
    this.venue = 'CricX Turf Arena',
    this.creatorId,
  })  : this.startDate = startDate ?? DateTime.now(),
        this.pointsTable = teams.map((t) => PointsTableEntry(team: t)).toList() {
    refreshStatus();
  }

  void refreshStatus() {
    if (status == 'Completed') return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tourStartDate = DateTime(startDate.year, startDate.month, startDate.day);

    final hasStartedMatches = matches.any((m) => m.status == MatchStatus.live || m.status == MatchStatus.completed);
    final allCompleted = matches.isNotEmpty && matches.every((m) => m.status == MatchStatus.completed);
    final finalMatchCompleted = matches.any((m) => m.id.endsWith('_final') && m.status == MatchStatus.completed);

    if (finalMatchCompleted || (matches.isNotEmpty && allCompleted)) {
      status = 'Completed';
    } else if (hasStartedMatches) {
      status = 'Ongoing';
    } else if (tourStartDate.isAfter(today)) {
      status = 'Upcoming';
    } else {
      status = 'Ongoing';
    }
  }

  void updatePointsTable() {
    refreshStatus();
    pointsTable = teams.map((t) => PointsTableEntry(team: t)).toList();
    
    // Accumulators for Net Run Rate calculation
    final Map<String, double> runsScoredMap = {};
    final Map<String, double> oversFacedMap = {};
    final Map<String, double> runsConcededMap = {};
    final Map<String, double> oversBowledMap = {};

    for (var team in teams) {
      runsScoredMap[team.id] = 0.0;
      oversFacedMap[team.id] = 0.0;
      runsConcededMap[team.id] = 0.0;
      oversBowledMap[team.id] = 0.0;
    }

    for (var match in matches) {
      if (match.status == MatchStatus.completed) {
        // Skip playoff matches in league points table calculation
        if (match.id.contains('_sf') || match.id.contains('_final')) {
          continue;
        }

        // Find which team won
        final result = match.resultString;
        final teamAEntry = pointsTable.firstWhere((e) => e.team.id == match.teamA.id);
        final teamBEntry = pointsTable.firstWhere((e) => e.team.id == match.teamB.id);
        
        teamAEntry.played++;
        teamBEntry.played++;
        
        if (result.contains(match.teamA.name)) {
          teamAEntry.won++;
          teamBEntry.lost++;
        } else if (result.contains(match.teamB.name)) {
          teamBEntry.won++;
          teamAEntry.lost++;
        }

        // Net Run Rate Math Accumulation
        final innings1 = match.innings1;
        final innings2 = match.innings2;
        if (innings1 != null && innings2 != null) {
          final isTeamAInnings1 = innings1.teamId == match.teamA.id;
          final teamAInnings = isTeamAInnings1 ? innings1 : innings2;
          final teamBInnings = isTeamAInnings1 ? innings2 : innings1;

          final double teamAOversFaced = _calculateOversForNRR(teamAInnings, match.totalOvers, match.teamA);
          final double teamBOversFaced = _calculateOversForNRR(teamBInnings, match.totalOvers, match.teamB);

          runsScoredMap[match.teamA.id] = (runsScoredMap[match.teamA.id] ?? 0.0) + teamAInnings.runs;
          oversFacedMap[match.teamA.id] = (oversFacedMap[match.teamA.id] ?? 0.0) + teamAOversFaced;
          runsConcededMap[match.teamA.id] = (runsConcededMap[match.teamA.id] ?? 0.0) + teamBInnings.runs;
          oversBowledMap[match.teamA.id] = (oversBowledMap[match.teamA.id] ?? 0.0) + teamBOversFaced;

          runsScoredMap[match.teamB.id] = (runsScoredMap[match.teamB.id] ?? 0.0) + teamBInnings.runs;
          oversFacedMap[match.teamB.id] = (oversFacedMap[match.teamB.id] ?? 0.0) + teamBOversFaced;
          runsConcededMap[match.teamB.id] = (runsConcededMap[match.teamB.id] ?? 0.0) + teamAInnings.runs;
          oversBowledMap[match.teamB.id] = (oversBowledMap[match.teamB.id] ?? 0.0) + teamAOversFaced;
        }
      }
    }

    // Set calculated NRR for each team
    for (var entry in pointsTable) {
      final teamId = entry.team.id;
      final runsScored = runsScoredMap[teamId] ?? 0.0;
      final oversFaced = oversFacedMap[teamId] ?? 0.0;
      final runsConceded = runsConcededMap[teamId] ?? 0.0;
      final oversBowled = oversBowledMap[teamId] ?? 0.0;

      double battingRate = 0.0;
      if (oversFaced > 0.0) {
        battingRate = runsScored / oversFaced;
      }

      double bowlingRate = 0.0;
      if (oversBowled > 0.0) {
        bowlingRate = runsConceded / oversBowled;
      }

      entry.netRunRate = battingRate - bowlingRate;
    }

    // Sort by points desc, then netRunRate desc
    pointsTable.sort((a, b) {
      int cmp = b.points.compareTo(a.points);
      if (cmp != 0) return cmp;
      return b.netRunRate.compareTo(a.netRunRate);
    });
  }

  double _calculateOversForNRR(MatchTeamInnings innings, int totalOvers, Team battingTeam) {
    final maxWickets = battingTeam.players.isEmpty ? 10 : (battingTeam.players.length - 1);
    if (innings.wickets >= maxWickets) {
      return totalOvers.toDouble();
    }
    final completedOvers = innings.ballsBowled ~/ 6;
    final remainingBalls = innings.ballsBowled % 6;
    return completedOvers + (remainingBalls / 6.0);
  }
}
