import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';

enum UserRole { guest, user, scorer, organizer }

class AppState extends ChangeNotifier {
  UserRole _currentRole = UserRole.guest;
  
  List<Player> _players = [];
  List<Team> _teams = [];
  List<CricketMatch> _matches = [];
  List<Tournament> _tournaments = [];
  
  CricketMatch? _activeScoringMatch;

  UserRole get currentRole => _currentRole;
  List<Player> get players => _players;
  List<Team> get teams => _teams;
  List<CricketMatch> get matches => _matches;
  List<Tournament> get tournaments => _tournaments;
  CricketMatch? get activeScoringMatch => _activeScoringMatch;

  AppState() {
    _initializeMockData();
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
    _teams.add(team);
    notifyListeners();
  }

  void addPlayerToTeam(String teamId, Player player) {
    _players.add(player);
    final team = _teams.firstWhere((t) => t.id == teamId);
    team.players.add(player);
    notifyListeners();
  }

  void createMatch(CricketMatch match) {
    _matches.insert(0, match);
    notifyListeners();
  }

  void updateMatchStatus(String matchId, MatchStatus status) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      _matches[index].status = status;
      notifyListeners();
    }
  }

  void updateMatchToss(String matchId, String winnerId, String decision) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      _matches[index].tossWinnerId = winnerId;
      _matches[index].tossDecision = decision;
      _matches[index].status = MatchStatus.live;
      // Initialize innings 1
      final match = _matches[index];
      match.innings1 = MatchTeamInnings(teamId: match.battingTeam.id);
      _activeScoringMatch = match;
      notifyListeners();
    }
  }

  void setupLiveScoringPlayers(String matchId, Player striker, Player nonStriker, Player bowler) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = _matches[index];
      match.striker = striker;
      match.nonStriker = nonStriker;
      match.currentBowler = bowler;
      
      // Initialize scoring maps if empty
      match.playerRuns[striker.id] ??= 0;
      match.playerRuns[nonStriker.id] ??= 0;
      match.playerBallsFaced[striker.id] ??= 0;
      match.playerBallsFaced[nonStriker.id] ??= 0;
      
      match.bowlerRunsConceded[bowler.id] ??= 0;
      match.bowlerWickets[bowler.id] ??= 0;
      match.bowlerBallsBowled[bowler.id] ??= 0;
      
      notifyListeners();
    }
  }

  void recordBall(String matchId, BallEvent event) {
    final match = _matches.firstWhere((m) => m.id == matchId);
    final innings = match.currentInnings;
    
    innings.events.add(event);
    
    // Update team score
    innings.runs += event.runsAddedToTeam;
    
    if (event.isWicket) {
      innings.wickets++;
    }
    
    if (event.countsAsBall) {
      innings.ballsBowled++;
    }

    // Update batsman statistics in current match state
    final strikerId = match.striker?.id;
    if (strikerId != null) {
      match.playerRuns[strikerId] = (match.playerRuns[strikerId] ?? 0) + event.runsAddedToBatsman;
      if (!event.isWide) {
        match.playerBallsFaced[strikerId] = (match.playerBallsFaced[strikerId] ?? 0) + 1;
      }
    }

    // Update bowler statistics in current match state
    final bowlerId = match.currentBowler?.id;
    if (bowlerId != null) {
      final runsConceded = event.isLegBye || event.isPenalty || event.isBye ? 0 : event.runsAddedToTeam;
      match.bowlerRunsConceded[bowlerId] = (match.bowlerRunsConceded[bowlerId] ?? 0) + runsConceded; // wide/noball runs count against bowler, but legbyes/byes/penalties don't
      if (event.countsAsBall) {
        match.bowlerBallsBowled[bowlerId] = (match.bowlerBallsBowled[bowlerId] ?? 0) + 1;
      }
      if (event.isWicket && event.wicketType != 'Run Out') {
        match.bowlerWickets[bowlerId] = (match.bowlerWickets[bowlerId] ?? 0) + 1;
      }
    }

    // Switch striker if odd runs scored off the bat or run as extras (e.g. wide byes, no ball byes)
    if (event.runs % 2 != 0) {
      final temp = match.striker;
      match.striker = match.nonStriker;
      match.nonStriker = temp;
    }

    // Over complete switch
    if (event.countsAsBall && innings.ballsBowled % 6 == 0) {
      final temp = match.striker;
      match.striker = match.nonStriker;
      match.nonStriker = temp;
      // Bowler needs to be reselected (we nullify it to prompt user in UI)
      match.currentBowler = null;
    }

    // Check if innings complete (e.g. all out (10 wickets) or overs completed)
    final totalBalls = match.totalOvers * 6;
    if (innings.wickets >= 10 || innings.ballsBowled >= totalBalls) {
      if (match.currentInningsNum == 1) {
        // Switch to innings 2
        match.currentInningsNum = 2;
        match.innings2 = MatchTeamInnings(teamId: match.battingTeam.id);
        
        // Reset active players
        match.striker = null;
        match.nonStriker = null;
        match.currentBowler = null;
      } else {
        // Match completed!
        completeMatch(matchId);
      }
    } else if (match.currentInningsNum == 2) {
      // Innings 2 is running, check if chasing team has won
      final firstInningsRuns = match.innings1?.runs ?? 0;
      if (innings.runs > firstInningsRuns) {
        completeMatch(matchId);
      }
    }

    notifyListeners();
  }

  void changeStriker() {
    if (_activeScoringMatch != null) {
      final temp = _activeScoringMatch!.striker;
      _activeScoringMatch!.striker = _activeScoringMatch!.nonStriker;
      _activeScoringMatch!.nonStriker = temp;
      notifyListeners();
    }
  }

  void changeBowler(Player newBowler) {
    if (_activeScoringMatch != null) {
      _activeScoringMatch!.currentBowler = newBowler;
      _activeScoringMatch!.bowlerRunsConceded[newBowler.id] ??= 0;
      _activeScoringMatch!.bowlerWickets[newBowler.id] ??= 0;
      _activeScoringMatch!.bowlerBallsBowled[newBowler.id] ??= 0;
      notifyListeners();
    }
  }

  void changeStrikerPlayer(Player newStriker, bool isStriker) {
    if (_activeScoringMatch != null) {
      if (isStriker) {
        _activeScoringMatch!.striker = newStriker;
        _activeScoringMatch!.playerRuns[newStriker.id] ??= 0;
        _activeScoringMatch!.playerBallsFaced[newStriker.id] ??= 0;
      } else {
        _activeScoringMatch!.nonStriker = newStriker;
        _activeScoringMatch!.playerRuns[newStriker.id] ??= 0;
        _activeScoringMatch!.playerBallsFaced[newStriker.id] ??= 0;
      }
      notifyListeners();
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
          final wicketsLeft = 10 - (match.innings2?.wickets ?? 0);
          match.resultString = "$team2Name won by $wicketsLeft wickets";
        } else if (team1Runs > team2Runs) {
          final runDiff = team1Runs - team2Runs;
          match.resultString = "$team1Name won by $runDiff runs";
        } else {
          match.resultString = "Match Tied";
        }
      }

      // Update team stats
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

      // Update tournament points tables
      for (var tournament in _tournaments) {
        if (tournament.matches.any((m) => m.id == matchId)) {
          tournament.updatePointsTable();
        }
      }

      // Update individual player career stats based on this match
      match.playerRuns.forEach((playerId, runs) {
        final p = _players.firstWhere((pl) => pl.id == playerId);
        p.matchesPlayed++;
        p.runsScored += runs;
        final balls = match.playerBallsFaced[playerId] ?? 0;
        p.ballsFaced += balls;
        if (runs > p.highestScore) {
          p.highestScore = runs;
        }
      });

      match.bowlerBallsBowled.forEach((bowlerId, balls) {
        final p = _players.firstWhere((pl) => pl.id == bowlerId);
        // If matchesPlayed wasn't updated by batting
        if (!match.playerRuns.containsKey(bowlerId)) {
          p.matchesPlayed++;
        }
        p.ballsBowled += balls;
        p.runsConceded += match.bowlerRunsConceded[bowlerId] ?? 0;
        p.wicketsTaken += match.bowlerWickets[bowlerId] ?? 0;
      });

      if (_activeScoringMatch?.id == matchId) {
        _activeScoringMatch = null;
      }
      
      notifyListeners();
    }
  }

  void createTournament(Tournament tournament) {
    _tournaments.insert(0, tournament);
    notifyListeners();
  }

  void addTournamentMatch(String tournamentId, CricketMatch match) {
    final t = _tournaments.firstWhere((t) => t.id == tournamentId);
    t.matches.add(match);
    _matches.insert(0, match);
    t.updatePointsTable();
    notifyListeners();
  }

  void _initializeMockData() {
    // Generate 20 Players (5 players per team)
    final playerNames = [
      'Virat Sharma', 'Rohit Rahul', 'Hardik Bumrah', 'Jasprit Pandya', 'Kevon Pollard',
      'Rishabh Gill', 'Shubman Pant', 'Ravindra Jadeja', 'Ravichandran Ashwin', 'Rashid Khan',
      'Axar Patel', 'MS Dhoni', 'Kuldeep Yadav', 'Shreyas Iyer', 'Sanju Samson',
      'Ishana Kishan', 'Yashasvi Jaiswal', 'Rinku Singh', 'Shivam Dube', 'Arshdeep Singh'
    ];
    
    final roles = [
      'Batsman', 'Batsman', 'All-Rounder', 'Bowler', 'All-Rounder',
      'Wicketkeeper', 'Batsman', 'All-Rounder', 'Bowler', 'Bowler',
      'All-Rounder', 'Wicketkeeper', 'Bowler', 'Batsman', 'Wicketkeeper',
      'Batsman', 'Batsman', 'Batsman', 'All-Rounder', 'Bowler'
    ];

    for (int i = 0; i < playerNames.length; i++) {
      _players.add(
        Player(
          id: 'p${i + 1}',
          name: playerNames[i],
          role: roles[i],
          battingStyle: i % 2 == 0 ? 'Right-hand bat' : 'Left-hand bat',
          bowlingStyle: i % 3 == 0 ? 'Right-arm medium' : (i % 3 == 1 ? 'Right-arm spin' : 'Left-arm orthodox'),
          matchesPlayed: 10 + i,
          runsScored: (i % 2 == 0 ? (i + 1) * 150 : (i + 1) * 35),
          wicketsTaken: (i % 3 == 0 ? i * 2 : i * 5),
          ballsFaced: (i % 2 == 0 ? (i + 1) * 120 : (i + 1) * 30),
          ballsBowled: (i % 3 != 0 ? (i + 1) * 60 : 0),
          runsConceded: (i % 3 != 0 ? (i + 1) * 45 : 0),
          highestScore: i % 2 == 0 ? 82 : 24,
          bestBowling: i % 3 != 0 ? '${i % 3 + 1}/${15 + i}' : '-',
        ),
      );
    }

    // Generate 4 Teams
    final teamNames = ['Mumbai Titans', 'Bangalore Strikers', 'Delhi Blasters', 'Chennai Kings'];
    final abbs = ['MT', 'BS', 'DB', 'CK'];
    final emojis = ['🔥', '⚡', '🌪️', '🦁'];
    final colors = [0xFFE3F2FD, 0xFFFFF3E0, 0xFFE8F5E9, 0xFFFFFDE7]; // Material light colors for avatars
    final colorHexes = [0xFF2196F3, 0xFFFF9800, 0xFF4CAF50, 0xFFFFEB3B]; // Primary theme color for team logo

    for (int i = 0; i < teamNames.length; i++) {
      // Assign 5 players to each team
      final teamPlayers = [
        _players[i * 5],
        _players[i * 5 + 1],
        _players[i * 5 + 2],
        _players[i * 5 + 3],
        _players[i * 5 + 4],
      ];

      _teams.add(
        Team(
          id: 't${i + 1}',
          name: teamNames[i],
          abbreviation: abbs[i],
          logoEmoji: emojis[i],
          logoColorHex: colorHexes[i],
          players: teamPlayers,
          matchesPlayed: 4,
          matchesWon: 4 - i,
          matchesLost: i,
          netRunRate: 1.25 - (i * 0.5),
        ),
      );
    }

    // Create a few matches (Upcoming, Live, Completed)
    final match1 = CricketMatch(
      id: 'm1',
      teamA: _teams[0],
      teamB: _teams[1],
      totalOvers: 10,
      status: MatchStatus.completed,
      tossWinnerId: 't1',
      tossDecision: 'Bat',
      resultString: 'Mumbai Titans won by 15 runs',
      venue: 'Wankhede Cricket Ground',
      matchDate: DateTime.now().subtract(const Duration(days: 2)),
    );
    
    // Innings 1 (Mumbai Titans batting)
    final m1Innings1 = MatchTeamInnings(teamId: 't1', runs: 95, wickets: 4, ballsBowled: 60);
    m1Innings1.events.addAll([
      BallEvent(runs: 4, batsmanName: 'Virat Sharma', bowlerName: 'Ravindra Jadeja', description: 'Boundary!'),
      BallEvent(runs: 6, batsmanName: 'Virat Sharma', bowlerName: 'Ravindra Jadeja', description: 'Six!'),
      BallEvent(runs: 4, batsmanName: 'Rohit Rahul', bowlerName: 'Ravindra Jadeja', description: 'Boundary!'),
      BallEvent(runs: 6, batsmanName: 'Rohit Rahul', bowlerName: 'Ravindra Jadeja', description: 'Six!'),
      BallEvent(
        runs: 0,
        isWicket: true,
        wicketType: 'Caught',
        batsmanName: 'Rohit Rahul',
        bowlerName: 'Ravindra Jadeja',
        description: 'Rohit Rahul caught by MS Dhoni.',
      ),
      BallEvent(
        runs: 0,
        isWicket: true,
        wicketType: 'Bowled',
        batsmanName: 'Hardik Bumrah',
        bowlerName: 'Ravichandran Ashwin',
        description: 'Hardik Bumrah clean bowled by Ravichandran Ashwin.',
      ),
      BallEvent(
        runs: 0,
        isWicket: true,
        wicketType: 'Run Out',
        batsmanName: 'Jasprit Pandya',
        bowlerName: 'Ravichandran Ashwin',
        description: 'Jasprit Pandya run out.',
      ),
      BallEvent(
        runs: 0,
        isWicket: true,
        wicketType: 'Caught',
        batsmanName: 'Kevon Pollard',
        bowlerName: 'Rashid Khan',
        description: 'Kevon Pollard caught.',
      ),
      BallEvent(runs: 1, isWide: true, batsmanName: 'Virat Sharma', bowlerName: 'Ravindra Jadeja', description: 'Wide.'),
      BallEvent(runs: 1, isWide: true, batsmanName: 'Virat Sharma', bowlerName: 'Ravindra Jadeja', description: 'Wide.'),
      BallEvent(runs: 1, isWide: true, batsmanName: 'Virat Sharma', bowlerName: 'Ravindra Jadeja', description: 'Wide.'),
    ]);
    match1.innings1 = m1Innings1;

    // Innings 2 (Bangalore Strikers batting)
    final m1Innings2 = MatchTeamInnings(teamId: 't2', runs: 80, wickets: 3, ballsBowled: 60);
    m1Innings2.events.addAll([
      BallEvent(runs: 4, batsmanName: 'Rishabh Gill', bowlerName: 'Hardik Bumrah', description: 'Boundary!'),
      BallEvent(runs: 6, batsmanName: 'Rishabh Gill', bowlerName: 'Hardik Bumrah', description: 'Six!'),
      BallEvent(runs: 4, batsmanName: 'Shubman Pant', bowlerName: 'Jasprit Pandya', description: 'Boundary!'),
      BallEvent(
        runs: 0,
        isWicket: true,
        wicketType: 'Caught',
        batsmanName: 'Rishabh Gill',
        bowlerName: 'Hardik Bumrah',
        description: 'Rishabh Gill caught by Virat Sharma.',
      ),
      BallEvent(
        runs: 0,
        isWicket: true,
        wicketType: 'LBW',
        batsmanName: 'Shubman Pant',
        bowlerName: 'Jasprit Pandya',
        description: 'Shubman Pant LBW.',
      ),
      BallEvent(
        runs: 0,
        isWicket: true,
        wicketType: 'Bowled',
        batsmanName: 'Ravindra Jadeja',
        bowlerName: 'Kevon Pollard',
        description: 'Ravindra Jadeja clean bowled by Kevon Pollard.',
      ),
      BallEvent(runs: 1, isWide: true, batsmanName: 'Rishabh Gill', bowlerName: 'Hardik Bumrah', description: 'Wide.'),
      BallEvent(runs: 1, isWide: true, batsmanName: 'Rishabh Gill', bowlerName: 'Hardik Bumrah', description: 'Wide.'),
      BallEvent(runs: 1, isWide: true, batsmanName: 'Rishabh Gill', bowlerName: 'Hardik Bumrah', description: 'Wide.'),
      BallEvent(runs: 1, isWide: true, batsmanName: 'Rishabh Gill', bowlerName: 'Hardik Bumrah', description: 'Wide.'),
    ]);
    match1.innings2 = m1Innings2;

    // Innings 1 Batsmen stats
    match1.playerRuns[_players[0].id] = 42; // Virat Sharma
    match1.playerBallsFaced[_players[0].id] = 26;
    match1.playerRuns[_players[1].id] = 28; // Rohit Rahul
    match1.playerBallsFaced[_players[1].id] = 18;
    match1.playerRuns[_players[2].id] = 15; // Hardik Bumrah
    match1.playerBallsFaced[_players[2].id] = 10;
    match1.playerRuns[_players[3].id] = 4;  // Jasprit Pandya
    match1.playerBallsFaced[_players[3].id] = 4;
    match1.playerRuns[_players[4].id] = 2;  // Kevon Pollard
    match1.playerBallsFaced[_players[4].id] = 2;

    // Innings 1 Bowlers stats
    match1.bowlerBallsBowled[_players[7].id] = 24; // Ravindra Jadeja
    match1.bowlerRunsConceded[_players[7].id] = 32;
    match1.bowlerWickets[_players[7].id] = 2;

    match1.bowlerBallsBowled[_players[8].id] = 18; // Ravichandran Ashwin
    match1.bowlerRunsConceded[_players[8].id] = 28;
    match1.bowlerWickets[_players[8].id] = 1;
 
    match1.bowlerBallsBowled[_players[9].id] = 18; // Rashid Khan
    match1.bowlerRunsConceded[_players[9].id] = 31;
    match1.bowlerWickets[_players[9].id] = 1;
 
    // Innings 2 Batsmen stats
    match1.playerRuns[_players[5].id] = 35; // Rishabh Gill
    match1.playerBallsFaced[_players[5].id] = 20;
    match1.playerRuns[_players[6].id] = 18; // Shubman Pant
    match1.playerBallsFaced[_players[6].id] = 14;
    match1.playerRuns[_players[7].id] = 12; // Ravindra Jadeja
    match1.playerBallsFaced[_players[7].id] = 12;
    match1.playerRuns[_players[8].id] = 5;  // Ravichandran Ashwin
    match1.playerBallsFaced[_players[8].id] = 6;
    match1.playerRuns[_players[9].id] = 4;  // Rashid Khan
    match1.playerBallsFaced[_players[9].id] = 8;

    // Innings 2 Bowlers stats
    match1.bowlerBallsBowled[_players[2].id] = 24; // Hardik Bumrah
    match1.bowlerRunsConceded[_players[2].id] = 28;
    match1.bowlerWickets[_players[2].id] = 1;

    match1.bowlerBallsBowled[_players[3].id] = 18; // Jasprit Pandya
    match1.bowlerRunsConceded[_players[3].id] = 22;
    match1.bowlerWickets[_players[3].id] = 1;

    match1.bowlerBallsBowled[_players[4].id] = 18; // Kevon Pollard
    match1.bowlerRunsConceded[_players[4].id] = 24;
    match1.bowlerWickets[_players[4].id] = 1;

    final match2 = CricketMatch(
      id: 'm2',
      teamA: _teams[2],
      teamB: _teams[3],
      totalOvers: 8,
      status: MatchStatus.live,
      tossWinnerId: 't3',
      tossDecision: 'Bowl',
      resultString: 'Delhi Blasters won toss & elected to bowl',
      venue: 'Chinnaswamy Turf',
      matchDate: DateTime.now(),
    );
    
    // Chennai (t4) batting first. Delhi (t3) bowling first.
    final innings1 = MatchTeamInnings(teamId: 't4', runs: 58, wickets: 2, ballsBowled: 32);
    
    // Add real event history to generate exact scorecard lists
    innings1.events.addAll([
      // Rinku Singh's innings (12 runs off 8 balls)
      BallEvent(runs: 4, batsmanName: 'Rinku Singh', bowlerName: 'Axar Patel', description: 'Boundary off the first ball!'),
      BallEvent(runs: 0, batsmanName: 'Rinku Singh', bowlerName: 'Axar Patel', description: 'Dot ball.'),
      BallEvent(runs: 6, batsmanName: 'Rinku Singh', bowlerName: 'Axar Patel', description: 'MASSIVE SIX over long-on!'),
      BallEvent(runs: 1, batsmanName: 'Rinku Singh', bowlerName: 'Axar Patel', description: 'Single to deep mid-wicket.'),
      BallEvent(runs: 0, batsmanName: 'Rinku Singh', bowlerName: 'Axar Patel', description: 'Dot ball.'),
      BallEvent(runs: 1, batsmanName: 'Rinku Singh', bowlerName: 'Axar Patel', description: 'Single.'),
      BallEvent(runs: 0, batsmanName: 'Rinku Singh', bowlerName: 'Axar Patel', description: 'Dot ball.'),
      BallEvent(
        runs: 0,
        isWicket: true,
        wicketType: 'Caught',
        batsmanName: 'Rinku Singh',
        bowlerName: 'Axar Patel',
        description: 'Rinku Singh caught at deep mid-wicket.',
      ),

      // Shivam Dube's innings (4 runs off 3 balls)
      BallEvent(runs: 4, batsmanName: 'Shivam Dube', bowlerName: 'Kuldeep Yadav', description: 'Shivam Dube hits a boundary through covers!'),
      BallEvent(runs: 0, batsmanName: 'Shivam Dube', bowlerName: 'Kuldeep Yadav', description: 'Dot ball.'),
      BallEvent(
        runs: 0,
        isWicket: true,
        wicketType: 'Bowled',
        batsmanName: 'Shivam Dube',
        bowlerName: 'Kuldeep Yadav',
        description: 'Clean bowled! Shivam Dube missed the straight delivery.',
      ),

      // Ishana Kishan's innings (24 runs off 12 balls, two 4s and two 6s)
      BallEvent(runs: 4, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Boundary to backward point!'),
      BallEvent(runs: 4, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Boundary through extra cover!'),
      BallEvent(runs: 6, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Pulled away for six!'),
      BallEvent(runs: 6, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Six over wide long-on!'),
      BallEvent(runs: 1, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Single.'),
      BallEvent(runs: 1, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Single.'),
      BallEvent(runs: 1, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Single.'),
      BallEvent(runs: 1, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Single.'),
      BallEvent(runs: 0, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Dot ball.'),
      BallEvent(runs: 0, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Dot ball.'),
      BallEvent(runs: 0, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Dot ball.'),
      BallEvent(runs: 0, batsmanName: 'Ishana Kishan', bowlerName: 'Axar Patel', description: 'Dot ball.'),
      // Wides faced by Ishana Kishan (does not count as ball faced, adds 2 wide extras: 1 wide + 1 runs)
      BallEvent(
        runs: 1, 
        isWide: true, 
        batsmanName: 'Ishana Kishan', 
        bowlerName: 'Axar Patel', 
        description: 'Wide delivery plus one extra run.',
      ),

      // Yashasvi Jaiswal's innings (15 runs off 9 balls, one 4 and one 6)
      BallEvent(runs: 4, batsmanName: 'Yashasvi Jaiswal', bowlerName: 'Kuldeep Yadav', description: 'Boundary through mid-wicket!'),
      BallEvent(runs: 6, batsmanName: 'Yashasvi Jaiswal', bowlerName: 'Kuldeep Yadav', description: 'Huge six over deep square leg!'),
      BallEvent(runs: 1, batsmanName: 'Yashasvi Jaiswal', bowlerName: 'Kuldeep Yadav', description: 'Single.'),
      BallEvent(runs: 1, batsmanName: 'Yashasvi Jaiswal', bowlerName: 'Kuldeep Yadav', description: 'Single.'),
      BallEvent(runs: 1, batsmanName: 'Yashasvi Jaiswal', bowlerName: 'Kuldeep Yadav', description: 'Single.'),
      BallEvent(runs: 1, batsmanName: 'Yashasvi Jaiswal', bowlerName: 'Kuldeep Yadav', description: 'Single.'),
      BallEvent(runs: 1, batsmanName: 'Yashasvi Jaiswal', bowlerName: 'Kuldeep Yadav', description: 'Single.'),
      BallEvent(runs: 0, batsmanName: 'Yashasvi Jaiswal', bowlerName: 'Kuldeep Yadav', description: 'Dot.'),
      BallEvent(runs: 0, batsmanName: 'Yashasvi Jaiswal', bowlerName: 'Kuldeep Yadav', description: 'Dot.'),
      // Leg bye faced by Yashasvi Jaiswal (counts as ball faced but batsman runs = 0)
      BallEvent(
        runs: 1, 
        isLegBye: true, 
        batsmanName: 'Yashasvi Jaiswal', 
        bowlerName: 'Kuldeep Yadav', 
        description: 'Leg bye. Ball deflecting off pads.',
      ),
    ]);
    
    match2.innings1 = innings1;
    
    // Active batsmen from Chennai Kings (t4)
    match2.striker = _players[15]; // Ishana Kishan
    match2.nonStriker = _players[16]; // Yashasvi Jaiswal
    
    // Active bowler from Delhi Blasters (t3)
    match2.currentBowler = _players[12]; // Kuldeep Yadav
    
    // Batsmen runs and balls faced (ordered by batting order: Rinku and Shivam opened, then Ishana and Yashasvi came in)
    match2.playerRuns[_players[17].id] = 12; // Rinku Singh (Out)
    match2.playerBallsFaced[_players[17].id] = 8;
    match2.playerRuns[_players[18].id] = 4;  // Shivam Dube (Out)
    match2.playerBallsFaced[_players[18].id] = 3;
    match2.playerRuns[_players[15].id] = 24; // Ishana
    match2.playerBallsFaced[_players[15].id] = 12;
    match2.playerRuns[_players[16].id] = 15; // Yashasvi
    match2.playerBallsFaced[_players[16].id] = 9;
    
    // Bowlers balls bowled and runs conceded
    match2.bowlerBallsBowled[_players[10].id] = 18; // Axar Patel: 3.0 overs
    match2.bowlerRunsConceded[_players[10].id] = 31;
    match2.bowlerWickets[_players[10].id] = 1;
    
    match2.bowlerBallsBowled[_players[12].id] = 14; // Kuldeep Yadav: 2.2 overs
    match2.bowlerRunsConceded[_players[12].id] = 26;
    match2.bowlerWickets[_players[12].id] = 1;

    final match3 = CricketMatch(
      id: 'm3',
      teamA: _teams[0],
      teamB: _teams[3],
      totalOvers: 12,
      status: MatchStatus.upcoming,
      venue: 'DY Patil Stadium',
      matchDate: DateTime.now().add(const Duration(days: 1)),
    );

    _matches.addAll([match2, match1, match3]);

    // Create 1 Tournament
    final tournament = Tournament(
      id: 'tour1',
      name: 'CricX Premier League 2026',
      type: 'League',
      teams: _teams,
      matches: [match1],
      status: 'Ongoing',
    );
    tournament.updatePointsTable();
    _tournaments.add(tournament);
  }
}
