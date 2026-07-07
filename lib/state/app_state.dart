import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

enum UserRole { guest, user, scorer, organizer }

class AppState extends ChangeNotifier {
  UserRole _currentRole = UserRole.guest;
  
  List<Player> _players = [];
  List<Team> _teams = [];
  List<CricketMatch> _matches = [];
  List<Tournament> _tournaments = [];
  
  CricketMatch? _activeScoringMatch;

  final DatabaseService _db = FirestoreService();
  StreamSubscription? _playersSub;
  StreamSubscription? _teamsSub;
  StreamSubscription? _matchesSub;
  StreamSubscription? _tournamentsSub;

  UserRole get currentRole => _currentRole;
  List<Player> get players => _players;
  List<Team> get teams => _teams;
  List<CricketMatch> get matches => _matches;
  List<Tournament> get tournaments => _tournaments;
  CricketMatch? get activeScoringMatch => _activeScoringMatch;

  AppState() {
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      // 1. Seed database with mock data if it is empty
      await _db.checkAndSeedDatabase();
    } catch (e) {
      debugPrint('Database seeding skipped or blocked: $e');
    }

    // 2. Start listening to Firestore changes in real-time
    _playersSub = _db.streamPlayers().listen((playersList) {
      _players = playersList;
      notifyListeners();
      _listenToTeams();
    });
  }

  void _listenToTeams() {
    _teamsSub?.cancel();
    _teamsSub = _db.streamTeams(_players).listen((teamsList) {
      _teams = teamsList;
      notifyListeners();
      _listenToMatches();
    });
  }

  void _listenToMatches() {
    _matchesSub?.cancel();
    _matchesSub = _db.streamMatches(_teams, _players).listen((matchesList) {
      _matches = matchesList;
      if (_activeScoringMatch != null) {
        final updatedActive = _matches.firstWhere(
          (m) => m.id == _activeScoringMatch!.id,
          orElse: () => _activeScoringMatch!,
        );
        _activeScoringMatch = updatedActive;
      }
      notifyListeners();
      _listenToTournaments();
    });
  }

  void _listenToTournaments() {
    _tournamentsSub?.cancel();
    _tournamentsSub = _db.streamTournaments(_teams, _matches).listen((tournamentsList) {
      _tournaments = tournamentsList;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _playersSub?.cancel();
    _teamsSub?.cancel();
    _matchesSub?.cancel();
    _tournamentsSub?.cancel();
    super.dispose();
  }

  void changeRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearchQuery() {
    _searchQuery = '';
    notifyListeners();
  }

  bool _filterByCreator = false;
  bool get filterByCreator => _filterByCreator;

  void toggleFilterByCreator() {
    _filterByCreator = !_filterByCreator;
    notifyListeners();
  }

  void setFilterByCreator(bool value) {
    _filterByCreator = value;
    notifyListeners();
  }

  void setActiveScoringMatch(CricketMatch? match) {
    _activeScoringMatch = match;
    notifyListeners();
  }

  void addTeam(Team team) {
    _db.addTeam(team);
  }

  void updateTeam(Team team) {
    _db.updateTeamInfo(team);
  }

  void addPlayerToTeam(String teamId, Player player) {
    _db.addPlayerToTeam(teamId, player);
  }

  void removePlayerFromTeam(String teamId, String playerId) {
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      final team = _teams[teamIndex];
      team.players.removeWhere((p) => p.id == playerId);
      if (team.captainId == playerId) {
        team.captainId = null;
      }
      _db.updateTeamInfo(team);
    }
  }

  void updatePlayer(Player player) {
    _db.updatePlayerStats(player);
  }

  void createMatch(CricketMatch match) {
    _db.createMatch(match);
  }

  void updateMatchStatus(String matchId, MatchStatus status) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      match.status = status;
      _db.updateMatch(match);
    }
  }

  void startMatch({
    required String matchId,
    required String tossWinnerId,
    required String decision,
    required Player striker,
    required Player nonStriker,
    required Player bowler,
    List<Player>? teamAPlayingXI,
    List<Player>? teamBPlayingXI,
  }) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      
      // Update team players to selected playing XI
      if (teamAPlayingXI != null) {
        match.teamAPlayerIds = teamAPlayingXI.map((p) => p.id).toList();
        match.teamA.players = teamAPlayingXI;
      }
      if (teamBPlayingXI != null) {
        match.teamBPlayerIds = teamBPlayingXI.map((p) => p.id).toList();
        match.teamB.players = teamBPlayingXI;
      }

      match.tossWinnerId = tossWinnerId;
      match.tossDecision = decision;
      match.status = MatchStatus.live;
      match.innings1 = MatchTeamInnings(
        teamId: match.battingTeam.id,
        battingOrder: [striker.id, nonStriker.id],
      );
      
      match.striker = striker;
      match.nonStriker = nonStriker;
      match.currentBowler = bowler;
      
      match.playerRuns[striker.id] ??= 0;
      match.playerRuns[nonStriker.id] ??= 0;
      match.playerBallsFaced[striker.id] ??= 0;
      match.playerBallsFaced[nonStriker.id] ??= 0;
      
      match.bowlerRunsConceded[bowler.id] ??= 0;
      match.bowlerWickets[bowler.id] ??= 0;
      match.bowlerBallsBowled[bowler.id] ??= 0;
      
      _activeScoringMatch = match;
      _db.updateMatch(match);
    }
  }

  void updateMatchDetails(String matchId, String venue, DateTime date, int totalOvers) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      match.venue = venue;
      match.matchDate = date;
      match.totalOvers = totalOvers;
      _db.updateMatch(match);
      notifyListeners();
    }
  }

  void updateMatchToss(String matchId, String winnerId, String decision) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      match.tossWinnerId = winnerId;
      match.tossDecision = decision;
      match.status = MatchStatus.live;
      match.innings1 = MatchTeamInnings(teamId: match.battingTeam.id);
      _activeScoringMatch = match;
      _db.updateMatch(match);
    }
  }

  void setupLiveScoringPlayers(String matchId, Player striker, Player nonStriker, Player bowler) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      match.striker = striker;
      match.nonStriker = nonStriker;
      match.currentBowler = bowler;
      
      match.playerRuns[striker.id] ??= 0;
      match.playerRuns[nonStriker.id] ??= 0;
      match.playerBallsFaced[striker.id] ??= 0;
      match.playerBallsFaced[nonStriker.id] ??= 0;
      
      final order = match.currentInnings.battingOrder;
      if (!order.contains(striker.id)) {
        order.add(striker.id);
      }
      if (!order.contains(nonStriker.id)) {
        order.add(nonStriker.id);
      }
      
      match.bowlerRunsConceded[bowler.id] ??= 0;
      match.bowlerWickets[bowler.id] ??= 0;
      match.bowlerBallsBowled[bowler.id] ??= 0;
      
      _db.updateMatch(match);
      notifyListeners();
    }
  }

  void retireBatsman(String matchId, String playerId, bool isRetiredOut) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      final innings = match.currentInnings;
      
      // Find batsman name
      final player = [...match.teamA.players, ...match.teamB.players].firstWhere((p) => p.id == playerId);
      final isStriker = match.striker?.id == playerId;
      
      // 1. Create and add BallEvent (non-ball event)
      final event = BallEvent(
        runs: 0,
        isWicket: isRetiredOut,
        wicketType: isRetiredOut ? 'Retired Out' : 'Retired Hurt',
        bowlerName: match.currentBowler?.name ?? 'N/A',
        batsmanName: player.name,
        description: isRetiredOut ? '${player.name} retired out' : '${player.name} retired hurt',
        isRunsOffBat: false,
      );
      
      innings.events.add(event);
      
      // If retired out, it counts as a wicket for the team
      if (isRetiredOut) {
        innings.wickets++;
      }
      
      // 2. Remove from active crease
      if (isStriker) {
        match.striker = null;
      } else {
        match.nonStriker = null;
      }
      
      _activeScoringMatch = match;
      _db.updateMatch(match);
      notifyListeners();
    }
  }

  void recordBall(String matchId, BallEvent event) {
    final match = _matches.firstWhere((m) => m.id == matchId);
    if (match.status == MatchStatus.completed) return;
    
    final innings = match.currentInnings;
    
    innings.events.add(event);
    innings.runs += event.runsAddedToTeam;
    
    if (event.isWicket) {
      innings.wickets++;
    }
    
    if (event.countsAsBall) {
      innings.ballsBowled++;
    }

    final strikerId = match.striker?.id;
    if (strikerId != null) {
      match.playerRuns[strikerId] = (match.playerRuns[strikerId] ?? 0) + event.runsAddedToBatsman;
      if (!event.isWide) {
        match.playerBallsFaced[strikerId] = (match.playerBallsFaced[strikerId] ?? 0) + 1;
      }
    }

    final bowlerId = match.currentBowler?.id;
    if (bowlerId != null) {
      final runsConceded = event.isLegBye || event.isPenalty || event.isBye ? 0 : event.runsAddedToTeam;
      match.bowlerRunsConceded[bowlerId] = (match.bowlerRunsConceded[bowlerId] ?? 0) + runsConceded;
      if (event.countsAsBall) {
        match.bowlerBallsBowled[bowlerId] = (match.bowlerBallsBowled[bowlerId] ?? 0) + 1;
      }
      if (event.isWicket && event.wicketType != 'Run Out' && event.wicketType != 'Retired Out') {
        match.bowlerWickets[bowlerId] = (match.bowlerWickets[bowlerId] ?? 0) + 1;
      }
    }

    if (event.runs % 2 != 0) {
      final temp = match.striker;
      match.striker = match.nonStriker;
      match.nonStriker = temp;
    }

    if (event.countsAsBall && innings.ballsBowled % 6 == 0) {
      final temp = match.striker;
      match.striker = match.nonStriker;
      match.nonStriker = temp;
      match.currentBowler = null;
    }

    final battingTeam = match.battingTeam;
    final isSuperOver = match.currentInningsNum == 3 || match.currentInningsNum == 4;
    final maxWickets = isSuperOver
        ? 2
        : (battingTeam.players.isEmpty ? 10 : (battingTeam.players.length - 1));
    final totalBalls = isSuperOver
        ? 6
        : (match.totalOvers * 6);

    if (innings.wickets >= maxWickets || innings.ballsBowled >= totalBalls) {
      if (match.currentInningsNum == 1) {
        match.currentInningsNum = 2;
        match.innings2 = MatchTeamInnings(teamId: match.battingTeam.id);
        match.striker = null;
        match.nonStriker = null;
        match.currentBowler = null;
      } else if (match.currentInningsNum == 2) {
        completeMatch(matchId);
      } else if (match.currentInningsNum == 3) {
        match.currentInningsNum = 4;
        match.superOverInnings2 = MatchTeamInnings(teamId: match.battingTeam.id);
        match.striker = null;
        match.nonStriker = null;
        match.currentBowler = null;
      } else if (match.currentInningsNum == 4) {
        completeMatch(matchId);
      }
    } else if (match.currentInningsNum == 2) {
      final firstInningsRuns = match.innings1?.runs ?? 0;
      if (innings.runs > firstInningsRuns) {
        completeMatch(matchId);
      }
    } else if (match.currentInningsNum == 4) {
      final superOver1Runs = match.superOverInnings1?.runs ?? 0;
      if (innings.runs > superOver1Runs) {
        completeMatch(matchId);
      }
    }

    _db.updateMatch(match);
  }

  void undoLastBall(String matchId) {
    final match = _matches.firstWhere((m) => m.id == matchId);
    
    if (match.status == MatchStatus.completed) {
      final oldResultString = match.resultString;
      match.status = MatchStatus.live;
      match.resultString = '';
      
      final teamA = _teams.firstWhere((t) => t.id == match.teamA.id);
      final teamB = _teams.firstWhere((t) => t.id == match.teamB.id);
      teamA.matchesPlayed--;
      teamB.matchesPlayed--;
      if (oldResultString.contains(teamA.name)) {
        teamA.matchesWon--;
        teamB.matchesLost--;
      } else if (oldResultString.contains(teamB.name)) {
        teamB.matchesWon--;
        teamA.matchesLost--;
      }
      _db.addTeam(teamA);
      _db.addTeam(teamB);

      for (var tournament in _tournaments) {
        if (tournament.matches.any((m) => m.id == matchId)) {
          tournament.updatePointsTable();
          _db.updateTournament(tournament);
        }
      }

      match.playerRuns.forEach((playerId, runs) {
        final p = _players.firstWhere((pl) => pl.id == playerId);
        p.matchesPlayed--;
        p.runsScored -= runs;
        final balls = match.playerBallsFaced[playerId] ?? 0;
        p.ballsFaced -= balls;
        _db.updatePlayerStats(p);
      });

      match.bowlerBallsBowled.forEach((bowlerId, balls) {
        final p = _players.firstWhere((pl) => pl.id == bowlerId);
        if (!match.playerRuns.containsKey(bowlerId)) {
          p.matchesPlayed--;
        }
        p.ballsBowled -= balls;
        p.runsConceded -= match.bowlerRunsConceded[bowlerId] ?? 0;
        p.wicketsTaken -= match.bowlerWickets[bowlerId] ?? 0;
        _db.updatePlayerStats(p);
      });
    }

    var innings = match.currentInnings;
    
    // Check if we need to transition back from innings 4 to innings 3
    if (match.currentInningsNum == 4 && innings.events.isEmpty && match.superOverInnings1 != null) {
      match.currentInningsNum = 3;
      match.superOverInnings2 = null;
      innings = match.superOverInnings1!;
    }
    // Check if we need to transition back from innings 3 to innings 2
    else if (match.currentInningsNum == 3 && innings.events.isEmpty && match.innings2 != null) {
      match.currentInningsNum = 2;
      match.superOverInnings1 = null;
      match.isSuperOverPlayed = false;
      match.status = MatchStatus.completed;
      match.resultString = 'Match Tied';
      innings = match.innings2!;
    }
    // Check if we need to transition back from innings 2 to innings 1
    else if (match.currentInningsNum == 2 && innings.events.isEmpty && match.innings1 != null) {
      match.currentInningsNum = 1;
      match.innings2 = null;
      innings = match.innings1!;
    }
    
    if (innings.events.isEmpty) return;

    final event = innings.events.removeLast();
    innings.runs -= event.runsAddedToTeam;
    if (event.isWicket) {
      innings.wickets--;
    }
    if (event.countsAsBall) {
      innings.ballsBowled--;
    }

    // 1. Revert wicket replacement/dismissal first so the correct batsman is back at the crease
    if (event.isWicket || event.wicketType == 'Retired Hurt' || event.wicketType == 'Retired Out') {
      final battingTeam = match.battingTeam;
      Player? outBatsman;
      try {
        outBatsman = battingTeam.players.firstWhere((p) => p.name == event.batsmanName);
      } catch (_) {}
      
      if (outBatsman != null) {
        if (match.striker == null) {
          match.striker = outBatsman;
        } else if (match.nonStriker == null) {
          match.nonStriker = outBatsman;
        } else {
          final order = innings.battingOrder;
          if (order.isNotEmpty) {
            final replacementId = order.last;
            if (match.striker?.id == replacementId) {
              match.striker = outBatsman;
              order.removeLast();
            } else if (match.nonStriker?.id == replacementId) {
              match.nonStriker = outBatsman;
              order.removeLast();
            }
          }
        }
      }
    }

    // 2. Revert over-end strike rotation and bowler clearing
    final wasOverEnd = event.countsAsBall && (innings.ballsBowled + 1) % 6 == 0;
    if (wasOverEnd) {
      final temp = match.striker;
      match.striker = match.nonStriker;
      match.nonStriker = temp;
      
      final bowlingTeam = match.bowlingTeam;
      try {
        final prevBowler = bowlingTeam.players.firstWhere((p) => p.name == event.bowlerName);
        match.currentBowler = prevBowler;
      } catch (_) {}
    }

    // 3. Revert run-based strike rotation
    if (event.runs % 2 != 0) {
      final temp = match.striker;
      match.striker = match.nonStriker;
      match.nonStriker = temp;
    }

    // 4. Revert batsman stats (now match.striker is restored to the batsman who faced the ball)
    final strikerId = match.striker?.id;
    if (strikerId != null) {
      match.playerRuns[strikerId] = (match.playerRuns[strikerId] ?? 0) - event.runsAddedToBatsman;
      if (!event.isWide) {
        match.playerBallsFaced[strikerId] = (match.playerBallsFaced[strikerId] ?? 0) - 1;
      }
    }

    // 5. Revert bowler stats
    final bowlerId = match.currentBowler?.id;
    if (bowlerId != null) {
      final runsConceded = event.isLegBye || event.isPenalty || event.isBye ? 0 : event.runsAddedToTeam;
      match.bowlerRunsConceded[bowlerId] = (match.bowlerRunsConceded[bowlerId] ?? 0) - runsConceded;
      if (event.countsAsBall) {
        match.bowlerBallsBowled[bowlerId] = (match.bowlerBallsBowled[bowlerId] ?? 0) - 1;
      }
      if (event.isWicket && event.wicketType != 'Run Out' && event.wicketType != 'Retired Out') {
        match.bowlerWickets[bowlerId] = (match.bowlerWickets[bowlerId] ?? 0) - 1;
      }
    }

    _activeScoringMatch = match;
    _db.updateMatch(match);
    notifyListeners();
  }

  void changeStriker() {
    if (_activeScoringMatch != null) {
      final temp = _activeScoringMatch!.striker;
      _activeScoringMatch!.striker = _activeScoringMatch!.nonStriker;
      _activeScoringMatch!.nonStriker = temp;
      _db.updateMatch(_activeScoringMatch!);
      notifyListeners();
    }
  }

  void changeBowler(Player? newBowler) {
    if (_activeScoringMatch != null) {
      _activeScoringMatch!.currentBowler = newBowler;
      if (newBowler != null) {
        _activeScoringMatch!.bowlerRunsConceded[newBowler.id] ??= 0;
        _activeScoringMatch!.bowlerWickets[newBowler.id] ??= 0;
        _activeScoringMatch!.bowlerBallsBowled[newBowler.id] ??= 0;
      }
      _db.updateMatch(_activeScoringMatch!);
      notifyListeners();
    }
  }

  void changeStrikerPlayer(Player? newStriker, bool isStriker) {
    if (_activeScoringMatch != null) {
      if (isStriker) {
        _activeScoringMatch!.striker = newStriker;
        if (newStriker != null) {
          _activeScoringMatch!.playerRuns[newStriker.id] ??= 0;
          _activeScoringMatch!.playerBallsFaced[newStriker.id] ??= 0;
          
          final order = _activeScoringMatch!.currentInnings.battingOrder;
          if (!order.contains(newStriker.id)) {
            order.add(newStriker.id);
          }
        }
      } else {
        _activeScoringMatch!.nonStriker = newStriker;
        if (newStriker != null) {
          _activeScoringMatch!.playerRuns[newStriker.id] ??= 0;
          _activeScoringMatch!.playerBallsFaced[newStriker.id] ??= 0;
          
          final order = _activeScoringMatch!.currentInnings.battingOrder;
          if (!order.contains(newStriker.id)) {
            order.add(newStriker.id);
          }
        }
      }
      _db.updateMatch(_activeScoringMatch!);
      notifyListeners();
    }
  }

  void completeMatch(String matchId, {String? customResult, bool forceComplete = false}) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];

      // Calculate results to check if it's a tie
      final team1Runs = match.innings1?.runs ?? 0;
      final team2Runs = match.innings2?.runs ?? 0;
      final isTie = team1Runs == team2Runs;

      if (isTie && !match.isSuperOverPlayed && !forceComplete) {
        // If it's a tie and not forced, we do not mark as completed yet.
        match.resultString = "Match Tied";
        _db.updateMatch(match);
        notifyListeners();
        return;
      }

      match.status = MatchStatus.completed;
      
      if (customResult != null) {
        match.resultString = customResult;
      } else if (match.isSuperOverPlayed) {
        final so1Runs = match.superOverInnings1?.runs ?? 0;
        final so2Runs = match.superOverInnings2?.runs ?? 0;
        final so1TeamId = match.superOverInnings1?.teamId;
        final so2TeamId = match.superOverInnings2?.teamId;
        
        final so1TeamName = so1TeamId != null ? _teams.firstWhere((t) => t.id == so1TeamId).name : 'Team 1';
        final so2TeamName = so2TeamId != null ? _teams.firstWhere((t) => t.id == so2TeamId).name : 'Team 2';
        
        if (so2Runs > so1Runs) {
          match.resultString = "$so2TeamName won via Super Over";
        } else if (so1Runs > so2Runs) {
          match.resultString = "$so1TeamName won via Super Over";
        } else {
          match.resultString = "Super Over Tied";
        }
      } else {
        final team1Runs = match.innings1?.runs ?? 0;
        final team2Runs = match.innings2?.runs ?? 0;
        
        final team1Name = match.innings1 != null ? _teams.firstWhere((t) => t.id == match.innings1!.teamId).name : match.teamA.name;
        final team2Name = match.innings2 != null ? _teams.firstWhere((t) => t.id == match.innings2!.teamId).name : match.teamB.name;
        
        if (team2Runs > team1Runs) {
          final chasingTeam = match.innings2 != null ? _teams.firstWhere((t) => t.id == match.innings2!.teamId) : match.bowlingTeam;
          final maxWickets = chasingTeam.players.isEmpty ? 10 : (chasingTeam.players.length - 1);
          final wicketsLeft = maxWickets - (match.innings2?.wickets ?? 0);
          match.resultString = "$team2Name won by $wicketsLeft wickets";
        } else if (team1Runs > team2Runs) {
          final runDiff = team1Runs - team2Runs;
          match.resultString = "$team1Name won by $runDiff runs";
        } else {
          match.resultString = "Match Tied";
        }
      }

      final teamA = _teams.firstWhere((t) => t.id == match.teamA.id);
      final teamB = _teams.firstWhere((t) => t.id == match.teamB.id);
      
      if (!match.isSuperOverPlayed) {
        teamA.matchesPlayed++;
        teamB.matchesPlayed++;
      }
      
      if (match.resultString.contains(teamA.name)) {
        teamA.matchesWon++;
        teamB.matchesLost++;
      } else if (match.resultString.contains(teamB.name)) {
        teamB.matchesWon++;
        teamA.matchesLost++;
      }

      _db.addTeam(teamA);
      _db.addTeam(teamB);

      for (var tournament in _tournaments) {
        if (tournament.matches.any((m) => m.id == matchId)) {
          tournament.updatePointsTable();

          // 1. Check if all league matches are completed, and no playoffs have been generated yet
          final leagueMatches = tournament.matches.where((m) => m.id.contains('_league_')).toList();
          final playoffMatches = tournament.matches.where((m) => m.id.contains('_sf') || m.id.contains('_final')).toList();
          final allLeagueCompleted = leagueMatches.isNotEmpty && leagueMatches.every((m) => m.status == MatchStatus.completed);
          
          if (allLeagueCompleted && playoffMatches.isEmpty) {
            _autoGeneratePlayoffs(tournament);
          }
          // 2. Check if Semifinals are completed, and Final is not generated yet
          else if (playoffMatches.isNotEmpty && tournament.playoffType == 'Semifinals & Final') {
            final sfMatches = playoffMatches.where((m) => m.id.contains('_sf')).toList();
            final finalGenerated = playoffMatches.any((m) => m.id.contains('_final'));
            final sfCompleted = sfMatches.length == 2 && sfMatches.every((m) => m.status == MatchStatus.completed);
            
            if (sfCompleted && !finalGenerated) {
              _autoGenerateFinalFromSemis(tournament);
            }
          }
          
          // 3. Auto-detect tournament winner if Final match is completed
          if (matchId.endsWith('_final')) {
            if (match.resultString.contains(match.teamA.name)) {
              tournament.winnerTeamId = match.teamA.id;
              tournament.status = 'Completed';
            } else if (match.resultString.contains(match.teamB.name)) {
              tournament.winnerTeamId = match.teamB.id;
              tournament.status = 'Completed';
            }
          }
          
          _db.updateTournament(tournament);
        }
      }

      if (!match.isSuperOverPlayed) {
        match.playerRuns.forEach((playerId, runs) {
          final p = _players.firstWhere((pl) => pl.id == playerId);
          p.matchesPlayed++;
          p.runsScored += runs;
          final balls = match.playerBallsFaced[playerId] ?? 0;
          p.ballsFaced += balls;
          if (runs > p.highestScore) {
            p.highestScore = runs;
          }
          _db.updatePlayerStats(p);
        });

        match.bowlerBallsBowled.forEach((bowlerId, balls) {
          final p = _players.firstWhere((pl) => pl.id == bowlerId);
          if (!match.playerRuns.containsKey(bowlerId)) {
            p.matchesPlayed++;
          }
          p.ballsBowled += balls;
          p.runsConceded += match.bowlerRunsConceded[bowlerId] ?? 0;
          p.wicketsTaken += match.bowlerWickets[bowlerId] ?? 0;
          _db.updatePlayerStats(p);
        });
      }

      if (_activeScoringMatch?.id == matchId) {
        _activeScoringMatch = null;
      }
      
      _db.updateMatch(match);
    }
  }

  void startSuperOver(String matchId) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      match.status = MatchStatus.live;
      match.isSuperOverPlayed = true;
      match.currentInningsNum = 3; // Super Over Innings 1
      match.resultString = "";
      match.superOverInnings1 = MatchTeamInnings(teamId: match.battingTeam.id);
      match.superOverInnings2 = null;
      match.striker = null;
      match.nonStriker = null;
      match.currentBowler = null;
      
      // Make this match the active scoring match again
      _activeScoringMatch = match;
      
      _db.updateMatch(match);
      notifyListeners();
    }
  }

  void createTournament(Tournament tournament) {
    _db.createTournament(tournament);
  }

  void addTournamentMatch(String tournamentId, CricketMatch match) {
    final t = _tournaments.firstWhere((t) => t.id == tournamentId);
    final index = t.matches.indexWhere((m) => m.id == match.id);
    if (index != -1) {
      t.matches[index] = match;
    } else {
      t.matches.add(match);
    }
    t.updatePointsTable();
    
    _db.createMatch(match);
    _db.updateTournament(t);
  }

  void addTournamentMatches(String tournamentId, List<CricketMatch> newMatches) {
    final t = _tournaments.firstWhere((t) => t.id == tournamentId);
    for (var newMatch in newMatches) {
      final index = t.matches.indexWhere((m) => m.id == newMatch.id);
      if (index != -1) {
        t.matches[index] = newMatch;
      } else {
        t.matches.add(newMatch);
      }
    }
    t.updatePointsTable();
    
    for (var match in newMatches) {
      _db.createMatch(match);
    }
    _db.updateTournament(t);
  }

  void _autoGeneratePlayoffs(Tournament tour) {
    tour.updatePointsTable();
    final standings = tour.pointsTable;
    if (standings.length < 2) return;

    final List<CricketMatch> playoffMatches = [];

    if (tour.playoffType == 'Direct Final') {
      final top1 = standings[0].team;
      final top2 = standings[1].team;

      final match = CricketMatch(
        id: 'tour_m_${tour.id}_final',
        teamA: top1,
        teamB: top2,
        totalOvers: tour.defaultOvers,
        venue: tour.venue.isNotEmpty ? '${tour.venue} (Final)' : 'Final Venue',
        matchDate: DateTime.now().add(const Duration(days: 1)),
        tournamentId: tour.id,
        tournamentName: tour.name,
        creatorId: tour.creatorId,
      );
      playoffMatches.add(match);
      
      tour.matches.add(match);
      _db.createMatch(match);
    } else if (tour.playoffType == 'Semifinals & Final') {
      if (standings.length < 4) return;
      final top1 = standings[0].team;
      final top2 = standings[1].team;
      final top3 = standings[2].team;
      final top4 = standings[3].team;

      // SF1: Top 1 vs Top 2
      final sf1 = CricketMatch(
        id: 'tour_m_${tour.id}_sf1',
        teamA: top1,
        teamB: top2,
        totalOvers: tour.defaultOvers,
        venue: tour.venue.isNotEmpty ? '${tour.venue} (Semi-Final 1)' : 'SF1 Venue',
        matchDate: DateTime.now().add(const Duration(days: 1)),
        tournamentId: tour.id,
        tournamentName: tour.name,
        creatorId: tour.creatorId,
      );

      // SF2: Top 3 vs Top 4
      final sf2 = CricketMatch(
        id: 'tour_m_${tour.id}_sf2',
        teamA: top3,
        teamB: top4,
        totalOvers: tour.defaultOvers,
        venue: tour.venue.isNotEmpty ? '${tour.venue} (Semi-Final 2)' : 'SF2 Venue',
        matchDate: DateTime.now().add(const Duration(days: 2)),
        tournamentId: tour.id,
        tournamentName: tour.name,
        creatorId: tour.creatorId,
      );

      playoffMatches.addAll([sf1, sf2]);
      
      tour.matches.addAll([sf1, sf2]);
      for (var match in playoffMatches) {
        _db.createMatch(match);
      }
    }
    
    tour.updatePointsTable();
    _db.updateTournament(tour);
  }

  void _autoGenerateFinalFromSemis(Tournament tour) {
    CricketMatch? sf1;
    CricketMatch? sf2;
    try {
      sf1 = tour.matches.firstWhere((m) => m.id.endsWith('_sf1'));
      sf2 = tour.matches.firstWhere((m) => m.id.endsWith('_sf2'));
    } catch (_) {}

    if (sf1 == null || sf2 == null) return;
    if (sf1.status != MatchStatus.completed || sf2.status != MatchStatus.completed) return;

    Team? winner1;
    if (sf1.resultString.contains(sf1.teamA.name)) {
      winner1 = sf1.teamA;
    } else if (sf1.resultString.contains(sf1.teamB.name)) {
      winner1 = sf1.teamB;
    }

    Team? winner2;
    if (sf2.resultString.contains(sf2.teamA.name)) {
      winner2 = sf2.teamA;
    } else if (sf2.resultString.contains(sf2.teamB.name)) {
      winner2 = sf2.teamB;
    }

    if (winner1 == null || winner2 == null) return;

    final finalMatch = CricketMatch(
      id: 'tour_m_${tour.id}_final',
      teamA: winner1,
      teamB: winner2,
      totalOvers: tour.defaultOvers,
      venue: tour.venue.isNotEmpty ? '${tour.venue} (Final)' : 'Final Venue',
      matchDate: DateTime.now().add(const Duration(days: 1)),
      tournamentId: tour.id,
      tournamentName: tour.name,
      creatorId: tour.creatorId,
    );
    
    tour.matches.add(finalMatch);
    _db.createMatch(finalMatch);
    tour.updatePointsTable();
    _db.updateTournament(tour);
  }

  void declarePlayerOfTheMatch(String matchId, String playerId, String playerName) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      match.playerOfTheMatchId = playerId;
      match.playerOfTheMatchName = playerName;
      _db.updateMatch(match);
      notifyListeners();
    }
  }

  void declarePlayerOfTheTournament(String tournamentId, String playerId, String playerName) {
    final index = _tournaments.indexWhere((t) => t.id == tournamentId);
    if (index != -1) {
      final tournament = _tournaments[index];
      tournament.playerOfTheTournamentId = playerId;
      tournament.playerOfTheTournamentName = playerName;
      _db.updateTournament(tournament);
      notifyListeners();
    }
  }
}

