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

  void setActiveScoringMatch(CricketMatch? match) {
    _activeScoringMatch = match;
    notifyListeners();
  }

  void addTeam(Team team) {
    _db.addTeam(team);
  }

  void addPlayerToTeam(String teamId, Player player) {
    _db.addPlayerToTeam(teamId, player);
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
  }) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
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
      
      match.bowlerRunsConceded[bowler.id] ??= 0;
      match.bowlerWickets[bowler.id] ??= 0;
      match.bowlerBallsBowled[bowler.id] ??= 0;
      
      _db.updateMatch(match);
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
      if (event.isWicket && event.wicketType != 'Run Out') {
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
    final maxWickets = battingTeam.players.isEmpty ? 10 : (battingTeam.players.length - 1);
    final totalBalls = match.totalOvers * 6;
    if (innings.wickets >= maxWickets || innings.ballsBowled >= totalBalls) {
      if (match.currentInningsNum == 1) {
        match.currentInningsNum = 2;
        match.innings2 = MatchTeamInnings(teamId: match.battingTeam.id);
        match.striker = null;
        match.nonStriker = null;
        match.currentBowler = null;
      } else {
        completeMatch(matchId);
      }
    } else if (match.currentInningsNum == 2) {
      final firstInningsRuns = match.innings1?.runs ?? 0;
      if (innings.runs > firstInningsRuns) {
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
    
    // Check if we need to transition back from innings 2 to innings 1
    if (match.currentInningsNum == 2 && innings.events.isEmpty && match.innings1 != null) {
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

    // 1. Revert over-end strike rotation and bowler clearing
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

    // 2. Revert run-based strike rotation
    if (event.runs % 2 != 0) {
      final temp = match.striker;
      match.striker = match.nonStriker;
      match.nonStriker = temp;
    }

    // 3. Revert batsman stats
    final strikerId = match.striker?.id;
    if (strikerId != null) {
      match.playerRuns[strikerId] = (match.playerRuns[strikerId] ?? 0) - event.runsAddedToBatsman;
      if (!event.isWide) {
        match.playerBallsFaced[strikerId] = (match.playerBallsFaced[strikerId] ?? 0) - 1;
      }
    }

    // 4. Revert bowler stats
    final bowlerId = match.currentBowler?.id;
    if (bowlerId != null) {
      final runsConceded = event.isLegBye || event.isPenalty || event.isBye ? 0 : event.runsAddedToTeam;
      match.bowlerRunsConceded[bowlerId] = (match.bowlerRunsConceded[bowlerId] ?? 0) - runsConceded;
      if (event.countsAsBall) {
        match.bowlerBallsBowled[bowlerId] = (match.bowlerBallsBowled[bowlerId] ?? 0) - 1;
      }
      if (event.isWicket && event.wicketType != 'Run Out') {
        match.bowlerWickets[bowlerId] = (match.bowlerWickets[bowlerId] ?? 0) - 1;
      }
    }

    // 5. Revert wicket replacement/dismissal
    if (event.isWicket) {
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
    }
  }

  void completeMatch(String matchId, [String? customResult]) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      match.status = MatchStatus.completed;
      
      final team1Runs = match.innings1?.runs ?? 0;
      final team2Runs = match.innings2?.runs ?? 0;
      
      final team1Name = match.innings1 != null ? _teams.firstWhere((t) => t.id == match.innings1!.teamId).name : match.teamA.name;
      final team2Name = match.innings2 != null ? _teams.firstWhere((t) => t.id == match.innings2!.teamId).name : match.teamB.name;
      
      if (customResult != null) {
        match.resultString = customResult;
      } else {
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
      
      teamA.matchesPlayed++;
      teamB.matchesPlayed++;
      
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

      if (_activeScoringMatch?.id == matchId) {
        _activeScoringMatch = null;
      }
      
      _db.updateMatch(match);
    }
  }

  void createTournament(Tournament tournament) {
    _db.createTournament(tournament);
  }

  void addTournamentMatch(String tournamentId, CricketMatch match) {
    final t = _tournaments.firstWhere((t) => t.id == tournamentId);
    t.matches.add(match);
    t.updatePointsTable();
    
    _db.createMatch(match);
    _db.updateTournament(t);
  }

  void addTournamentMatches(String tournamentId, List<CricketMatch> newMatches) {
    final t = _tournaments.firstWhere((t) => t.id == tournamentId);
    t.matches.addAll(newMatches);
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
    );
    
    tour.matches.add(finalMatch);
    _db.createMatch(finalMatch);
    tour.updatePointsTable();
    _db.updateTournament(tour);
  }
}

