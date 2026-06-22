class Player {
  final String id;
  final String name;
  final String role; // 'Batsman', 'Bowler', 'All-Rounder', 'Wicketkeeper'
  final String battingStyle; // 'Right-hand bat', 'Left-hand bat'
  final String bowlingStyle; // 'Right-arm medium', 'Right-arm spin', etc.
  int matchesPlayed;
  int runsScored;
  int wicketsTaken;
  int ballsFaced;
  int ballsBowled;
  int runsConceded;
  int highestScore;
  String bestBowling; // e.g. "3/15"

  Player({
    required this.id,
    required this.name,
    required this.role,
    required this.battingStyle,
    required this.bowlingStyle,
    this.matchesPlayed = 0,
    this.runsScored = 0,
    this.wicketsTaken = 0,
    this.ballsFaced = 0,
    this.ballsBowled = 0,
    this.runsConceded = 0,
    this.highestScore = 0,
    this.bestBowling = '-',
  });

  double get strikeRate => ballsFaced > 0 ? (runsScored / ballsFaced) * 100 : 0.0;
  double get battingAverage => (matchesPlayed - wicketsTaken) > 0 ? runsScored / (matchesPlayed - wicketsTaken) : runsScored.toDouble();
  double get economyRate => ballsBowled > 0 ? (runsConceded / ballsBowled) * 6 : 0.0;
}
