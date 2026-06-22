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
  final String type; // 'League', 'Knockout'
  final List<Team> teams;
  final List<CricketMatch> matches;
  List<PointsTableEntry> pointsTable;
  String status; // 'Upcoming', 'Ongoing', 'Completed'
  String? winnerTeamId;

  Tournament({
    required this.id,
    required this.name,
    required this.type,
    required this.teams,
    required this.matches,
    this.status = 'Upcoming',
    this.winnerTeamId,
  }) : this.pointsTable = teams.map((t) => PointsTableEntry(team: t)).toList();

  void updatePointsTable() {
    pointsTable = teams.map((t) => PointsTableEntry(team: t)).toList();
    for (var match in matches) {
      if (match.status == MatchStatus.completed) {
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
      }
    }
    // Sort by points desc, then netRunRate desc
    pointsTable.sort((a, b) {
      int cmp = b.points.compareTo(a.points);
      if (cmp != 0) return cmp;
      return b.netRunRate.compareTo(a.netRunRate);
    });
  }
}
