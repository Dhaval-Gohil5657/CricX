import 'team_model.dart';
import 'player_model.dart';

enum MatchStatus { upcoming, live, completed }

class BallEvent {
  final int runs;
  final bool isWide;
  final bool isNoBall;
  final bool isWicket;
  final String wicketType; // 'Bowled', 'Caught', 'Run Out', 'LBW'
  final String bowlerName;
  final String batsmanName;
  final String description;
  final bool isRunsOffBat;
  final bool isLegBye;
  final bool isPenalty;
  final bool isBye;

  BallEvent({
    required this.runs,
    this.isWide = false,
    this.isNoBall = false,
    this.isWicket = false,
    this.wicketType = '',
    required this.bowlerName,
    required this.batsmanName,
    required this.description,
    this.isRunsOffBat = true,
    this.isLegBye = false,
    this.isPenalty = false,
    this.isBye = false,
  });

  int get runsAddedToTeam => runs + (isWide || isNoBall ? 1 : 0);
  int get runsAddedToBatsman => (isWide || isLegBye || isPenalty || isBye) ? 0 : (isNoBall ? (isRunsOffBat ? runs : 0) : runs);
  bool get countsAsBall => !isWide && !isNoBall && !isPenalty && wicketType != 'Retired Hurt' && wicketType != 'Retired Out';
}

class MatchTeamInnings {
  final String teamId;
  int runs;
  int wickets;
  int ballsBowled;
  List<BallEvent> events;
  List<String> battingOrder;

  MatchTeamInnings({
    required this.teamId,
    this.runs = 0,
    this.wickets = 0,
    this.ballsBowled = 0,
    List<BallEvent>? events,
    List<String>? battingOrder,
  }) : this.events = events ?? [],
       this.battingOrder = battingOrder ?? [];

  double get oversCompleted => (ballsBowled ~/ 6) + (ballsBowled % 6) / 10;
  double get runRate => ballsBowled > 0 ? (runs / ballsBowled) * 6 : 0.0;

  int get wideExtras => events.where((e) => e.isWide).fold(0, (sum, e) => sum + e.runs + 1);
  int get noBallExtras => events.where((e) => e.isNoBall).fold(0, (sum, e) => sum + 1 + (!e.isRunsOffBat ? e.runs : 0));
  int get legByeExtras => events.where((e) => e.isLegBye).fold(0, (sum, e) => sum + e.runs);
  int get byeExtras => events.where((e) => e.isBye).fold(0, (sum, e) => sum + e.runs);
  int get penaltyExtras => events.where((e) => e.isPenalty).fold(0, (sum, e) => sum + e.runs);
  int get totalExtras => wideExtras + noBallExtras + legByeExtras + byeExtras + penaltyExtras;
}

class CricketMatch {
  final String id;
  final Team teamA;
  final Team teamB;
  int totalOvers;
  
  MatchStatus status;
  String? tossWinnerId;
  String? tossDecision; // 'Bat' or 'Bowl'
  
  // Scoring state
  MatchTeamInnings? innings1;
  MatchTeamInnings? innings2;
  MatchTeamInnings? superOverInnings1;
  MatchTeamInnings? superOverInnings2;
  int currentInningsNum; // 1, 2, 3 (Super Over 1), or 4 (Super Over 2)
  bool isSuperOverPlayed;
  
  // Live player states
  Player? striker;
  Player? nonStriker;
  Player? currentBowler;
  
  // Batting stats in active match
  Map<String, int> playerRuns = {};
  Map<String, int> playerBallsFaced = {};
  // Bowling stats in active match
  Map<String, int> bowlerRunsConceded = {};
  Map<String, int> bowlerWickets = {};
  Map<String, int> bowlerBallsBowled = {};

  String resultString;
  String venue;
  DateTime matchDate;

  String? tournamentId;
  String? tournamentName;
  final String? creatorId;

  String? playerOfTheMatchId;
  String? playerOfTheMatchName;
  List<String>? teamAPlayerIds;
  List<String>? teamBPlayerIds;

  CricketMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.totalOvers,
    this.status = MatchStatus.upcoming,
    this.tossWinnerId,
    this.tossDecision,
    this.currentInningsNum = 1,
    this.isSuperOverPlayed = false,
    this.superOverInnings1,
    this.superOverInnings2,
    this.resultString = 'Match not started yet',
    required this.venue,
    required this.matchDate,
    this.tournamentId,
    this.tournamentName,
    this.creatorId,
    this.playerOfTheMatchId,
    this.playerOfTheMatchName,
    this.teamAPlayerIds,
    this.teamBPlayerIds,
  });

  Team get battingTeam {
    final Team teamFirst = tossDecision == 'Bat'
        ? (tossWinnerId == teamA.id ? teamA : teamB)
        : (tossWinnerId == teamA.id ? teamB : teamA);
    final Team teamSecond = teamFirst.id == teamA.id ? teamB : teamA;

    if (currentInningsNum == 1) return teamFirst;
    if (currentInningsNum == 2) return teamSecond;
    if (currentInningsNum == 3) return teamSecond; // Super Over Innings 1 (Second team in main match bats first)
    return teamFirst;                              // Super Over Innings 2 (First team in main match chases)
  }

  Team get bowlingTeam => battingTeam.id == teamA.id ? teamB : teamA;

  MatchTeamInnings get currentInnings {
    if (currentInningsNum == 1) {
      return innings1 ??= MatchTeamInnings(teamId: battingTeam.id);
    } else if (currentInningsNum == 2) {
      return innings2 ??= MatchTeamInnings(teamId: battingTeam.id);
    } else if (currentInningsNum == 3) {
      return superOverInnings1 ??= MatchTeamInnings(teamId: battingTeam.id);
    } else {
      return superOverInnings2 ??= MatchTeamInnings(teamId: battingTeam.id);
    }
  }

  MatchTeamInnings? get teamAInnings => innings1?.teamId == teamA.id 
      ? innings1 
      : (innings2?.teamId == teamA.id ? innings2 : null);

  MatchTeamInnings? get teamBInnings => innings1?.teamId == teamB.id 
      ? innings1 
      : (innings2?.teamId == teamB.id ? innings2 : null);

  String get statusText {
    if (status == MatchStatus.upcoming) {
      return 'Match not started yet';
    }
    if (resultString == "Match Tied" && !isSuperOverPlayed) {
      return "Match Tied";
    }
    if (status == MatchStatus.live) {
      if (tossWinnerId != null && tossDecision != null) {
        final tossWinnerTeam = tossWinnerId == teamA.id ? teamA : teamB;
        if (currentInningsNum == 1) {
          return "${tossWinnerTeam.name} won toss & elected to ${tossDecision!.toLowerCase()} first";
        } else if (currentInningsNum == 2) {
          final target = (innings1?.runs ?? 0) + 1;
          final currentRuns = innings2?.runs ?? 0;
          final runsNeeded = target - currentRuns;
          final ballsBowled = innings2?.ballsBowled ?? 0;
          final ballsRemaining = (totalOvers * 6) - ballsBowled;
          return "${battingTeam.name} needs $runsNeeded runs from $ballsRemaining balls";
        } else if (currentInningsNum == 3) {
          return "Super Over: ${battingTeam.name} batting (Innings 1)";
        } else if (currentInningsNum == 4) {
          final target = (superOverInnings1?.runs ?? 0) + 1;
          final currentRuns = superOverInnings2?.runs ?? 0;
          final runsNeeded = target - currentRuns;
          final ballsBowled = superOverInnings2?.ballsBowled ?? 0;
          final ballsRemaining = 6 - ballsBowled;
          return "Super Over: ${battingTeam.name} needs $runsNeeded runs from $ballsRemaining balls";
        }
      }
      return 'Match in progress';
    } else {
      return resultString;
    }
  }
}
