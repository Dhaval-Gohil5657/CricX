import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'logged_http.dart' as http;
import 'database_service.dart';
import 'auth_service.dart';
import '../api_endpoints.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';

class ApiDatabaseService implements DatabaseService {
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthService.instance.token != null)
          'Authorization': 'Bearer ${AuthService.instance.token}',
      };

  String _parseId(Map<String, dynamic> json) =>
      json['_id'] ?? json['id'] ?? '';

  // Local caching variables to enable smooth offline support or list stubbing
  static final List<Player> _cachedPlayers = [];
  static final List<Team> _cachedTeams = [];
  static final List<CricketMatch> _cachedMatches = [];
  static final List<Tournament> _cachedTournaments = [];

  // ==========================================
  // Players API
  // ==========================================

  @override
  Future<List<Player>> getPlayers() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.players), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data.map((json) => _playerFromMap(json)).toList();
        _cachedPlayers.clear();
        _cachedPlayers.addAll(list);
        return list;
      }
    } catch (e) {
      debugPrint('Error getting players: $e');
    }
    return [..._cachedPlayers];
  }

  Player _playerFromMap(Map<String, dynamic> data) {
    return Player(
      id: _parseId(data),
      name: data['name'] ?? '',
      role: data['role'] ?? 'Batsman',
      battingStyle: data['battingStyle'] ?? 'Right-hand bat',
      bowlingStyle: data['bowlingStyle'] ?? 'Right-arm medium',
      matchesPlayed: data['matchesPlayed'] ?? 0,
      runsScored: data['runsScored'] ?? 0,
      wicketsTaken: data['wicketsTaken'] ?? 0,
      ballsFaced: data['ballsFaced'] ?? 0,
      ballsBowled: data['ballsBowled'] ?? 0,
      runsConceded: data['runsConceded'] ?? 0,
      highestScore: data['highestScore'] ?? 0,
      bestBowling: data['bestBowling'] ?? '-',
    );
  }

  Map<String, dynamic> _playerToMap(Player player) {
    return {
      'name': player.name,
      'role': player.role,
      'battingStyle': player.battingStyle,
      'bowlingStyle': player.bowlingStyle,
      'matchesPlayed': player.matchesPlayed,
      'runsScored': player.runsScored,
      'wicketsTaken': player.wicketsTaken,
      'ballsFaced': player.ballsFaced,
      'ballsBowled': player.ballsBowled,
      'runsConceded': player.runsConceded,
      'highestScore': player.highestScore,
      'bestBowling': player.bestBowling,
    };
  }

  @override
  Future<void> addPlayer(Player player) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.players),
      headers: _headers,
      body: jsonEncode(_playerToMap(player)),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create player: ${response.body}');
    }
    final newPlayer = _playerFromMap(jsonDecode(response.body));
    _cachedPlayers.removeWhere((p) => p.id == player.id);
    _cachedPlayers.add(newPlayer);
  }

  @override
  Future<void> updatePlayerStats(Player player) async {
    // Try primary update profile, fallback to stats endpoint if needed
    var response = await http.put(
      Uri.parse(ApiEndpoints.playerById(player.id)),
      headers: _headers,
      body: jsonEncode(_playerToMap(player)),
    );
    
    if (response.statusCode != 200) {
      response = await http.put(
        Uri.parse(ApiEndpoints.playerStats(player.id)),
        headers: _headers,
        body: jsonEncode(_playerToMap(player)),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update player: ${response.body}');
      }
    }
    
    _cachedPlayers.removeWhere((p) => p.id == player.id);
    _cachedPlayers.add(player);
  }

  // ==========================================
  // Teams API
  // ==========================================

  @override
  Future<List<Team>> getTeams(List<Player> allPlayers) async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.teams), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data.map((json) => _teamFromMap(json, allPlayers)).toList();
        _cachedTeams.clear();
        _cachedTeams.addAll(list);
        return list;
      }
    } catch (e) {
      debugPrint('Error getting teams: $e');
    }
    return [..._cachedTeams];
  }

  Team _teamFromMap(Map<String, dynamic> data, List<Player> allPlayers) {
    final List<dynamic> pIds = data['playerIds'] ?? [];
    final List<Player> teamPlayers = [];
    for (var pid in pIds) {
      final found = allPlayers.firstWhere(
        (p) => p.id == pid,
        orElse: () => Player(id: pid, name: 'Player $pid', role: 'Batsman', battingStyle: 'Right-hand bat', bowlingStyle: '-'),
      );
      teamPlayers.add(found);
    }

    String emoji = '🏏';
    int color = 0xFF4CAF50;
    final logoStr = data['logo'] as String?;
    if (logoStr != null && logoStr.contains('|')) {
      final parts = logoStr.split('|');
      if (parts.length >= 2) {
        emoji = parts[0];
        color = int.tryParse(parts[1]) ?? 0xFF4CAF50;
      }
    } else if (data['logoEmoji'] != null) {
      emoji = data['logoEmoji'];
      color = data['logoColorHex'] ?? 0xFF4CAF50;
    }

    return Team(
      id: _parseId(data),
      name: data['name'] ?? '',
      abbreviation: data['shortName'] ?? data['abbreviation'] ?? '',
      logoEmoji: emoji,
      logoColorHex: color,
      players: teamPlayers,
      matchesPlayed: data['matchesPlayed'] ?? 0,
      matchesWon: data['matchesWon'] ?? 0,
      matchesLost: data['matchesLost'] ?? 0,
      netRunRate: (data['netRunRate'] as num?)?.toDouble() ?? 0.0,
      creatorId: data['creatorId'],
      captainId: data['captainId'],
    );
  }

  Map<String, dynamic> _teamToMap(Team team) {
    return {
      'name': team.name,
      'shortName': team.abbreviation,
      'logo': '${team.logoEmoji}|${team.logoColorHex}',
      'playerIds': team.players.map((p) => p.id).toList(),
      'matchesPlayed': team.matchesPlayed,
      'matchesWon': team.matchesWon,
      'matchesLost': team.matchesLost,
      'netRunRate': team.netRunRate,
      'creatorId': team.creatorId,
      'captainId': team.captainId,
    };
  }

  @override
  Future<void> addTeam(Team team) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.teams),
      headers: _headers,
      body: jsonEncode(_teamToMap(team)),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create team: ${response.body}');
    }
    
    final createdTeamData = jsonDecode(response.body);
    final teamId = _parseId(createdTeamData);

    if (team.players.isNotEmpty) {
      await http.post(
        Uri.parse(ApiEndpoints.teamPlayers(teamId)),
        headers: _headers,
        body: jsonEncode({
          'playerIds': team.players.map((p) => p.id).toList(),
        }),
      );
    }

    _cachedTeams.removeWhere((t) => t.id == team.id);
    _cachedTeams.add(team);
  }

  @override
  Future<void> updateTeamInfo(Team team) async {
    final response = await http.put(
      Uri.parse(ApiEndpoints.teamById(team.id)),
      headers: _headers,
      body: jsonEncode(_teamToMap(team)),
    );
    if (response.statusCode != 200) {
      debugPrint('Warning: PUT /teams/:id returned status ${response.statusCode}');
    }
    _cachedTeams.removeWhere((t) => t.id == team.id);
    _cachedTeams.add(team);
  }

  @override
  Future<void> addPlayerToTeam(String teamId, Player player) async {
    try {
      await addPlayer(player);
    } catch (_) {}

    final response = await http.post(
      Uri.parse(ApiEndpoints.teamPlayers(teamId)),
      headers: _headers,
      body: jsonEncode({
        'playerIds': [player.id],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add player to team: ${response.body}');
    }

    final teamIndex = _cachedTeams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      final team = _cachedTeams[teamIndex];
      if (!team.players.any((p) => p.id == player.id)) {
        team.players.add(player);
      }
    }
  }

  // ==========================================
  // Matches API
  // ==========================================

  @override
  Future<List<CricketMatch>> getMatches(List<Team> allTeams, List<Player> allPlayers) async {
    try {
      var response = await http.get(Uri.parse(ApiEndpoints.matches), headers: _headers);
      List<dynamic> data = [];
      if (response.statusCode == 200) {
        data = jsonDecode(response.body);
      } else {
        // Fallback to live discovery matches list
        final discResponse = await http.get(Uri.parse(ApiEndpoints.liveMatches), headers: _headers);
        if (discResponse.statusCode == 200) {
          data = jsonDecode(discResponse.body);
        } else {
          throw Exception('Failed to fetch matches: ${response.statusCode}');
        }
      }

      final list = data.map((json) => _matchFromMap(json, allTeams, allPlayers)).toList();
      _cachedMatches.clear();
      _cachedMatches.addAll(list);
      return list;
    } catch (e) {
      debugPrint('Error getting matches: $e');
    }
    return [..._cachedMatches];
  }

  CricketMatch _matchFromMap(
    Map<String, dynamic> data,
    List<Team> allTeams,
    List<Player> allPlayers,
  ) {
    final teamAId = data['teamA'] is Map ? _parseId(data['teamA']) : (data['teamAId'] ?? data['teamA'] ?? '');
    final teamBId = data['teamB'] is Map ? _parseId(data['teamB']) : (data['teamBId'] ?? data['teamB'] ?? '');

    final baseTeamA = allTeams.firstWhere(
      (t) => t.id == teamAId,
      orElse: () => Team(id: teamAId, name: 'Team A', abbreviation: 'A', logoEmoji: '🏏', logoColorHex: 0xFF9E9E9E, players: []),
    );
    final baseTeamB = allTeams.firstWhere(
      (t) => t.id == teamBId,
      orElse: () => Team(id: teamBId, name: 'Team B', abbreviation: 'B', logoEmoji: '🏏', logoColorHex: 0xFF9E9E9E, players: []),
    );

    final teamAPlayerIds = List<String>.from(data['teamAPlayerIds'] ?? []);
    final teamBPlayerIds = List<String>.from(data['teamBPlayerIds'] ?? []);

    final teamA = Team(
      id: baseTeamA.id,
      name: baseTeamA.name,
      abbreviation: baseTeamA.abbreviation,
      logoEmoji: baseTeamA.logoEmoji,
      logoColorHex: baseTeamA.logoColorHex,
      players: teamAPlayerIds.isNotEmpty
          ? baseTeamA.players.where((p) => teamAPlayerIds.contains(p.id)).toList()
          : List.from(baseTeamA.players),
      matchesPlayed: baseTeamA.matchesPlayed,
      matchesWon: baseTeamA.matchesWon,
      matchesLost: baseTeamA.matchesLost,
      netRunRate: baseTeamA.netRunRate,
      creatorId: baseTeamA.creatorId,
      captainId: baseTeamA.captainId,
    );

    final teamB = Team(
      id: baseTeamB.id,
      name: baseTeamB.name,
      abbreviation: baseTeamB.abbreviation,
      logoEmoji: baseTeamB.logoEmoji,
      logoColorHex: baseTeamB.logoColorHex,
      players: teamBPlayerIds.isNotEmpty
          ? baseTeamB.players.where((p) => teamBPlayerIds.contains(p.id)).toList()
          : List.from(baseTeamB.players),
      matchesPlayed: baseTeamB.matchesPlayed,
      matchesWon: baseTeamB.matchesWon,
      matchesLost: baseTeamB.matchesLost,
      netRunRate: baseTeamB.netRunRate,
      creatorId: baseTeamB.creatorId,
      captainId: baseTeamB.captainId,
    );

    final statusStr = data['status'] ?? 'upcoming';
    MatchStatus matchStatus;
    if (statusStr == 'live' || statusStr == 'Ongoing') {
      matchStatus = MatchStatus.live;
    } else if (statusStr == 'completed' || statusStr == 'Completed') {
      matchStatus = MatchStatus.completed;
    } else {
      matchStatus = MatchStatus.upcoming;
    }

    final dateStr = data['matchDate'] ?? data['createdAt'] ?? DateTime.now().toIso8601String();

    final match = CricketMatch(
      id: _parseId(data),
      teamA: teamA,
      teamB: teamB,
      totalOvers: data['overs'] ?? data['totalOvers'] ?? 20,
      status: matchStatus,
      tossWinnerId: data['tossWinnerId'] ?? data['toss']?['winner'],
      tossDecision: data['tossDecision'] ?? data['toss']?['decision'],
      currentInningsNum: data['currentInningsNum'] ?? 1,
      isSuperOverPlayed: data['isSuperOverPlayed'] ?? false,
      isOnBreak: data['isOnBreak'] ?? false,
      breakReason: data['breakReason'],
      resultString: data['resultString'] ?? data['result'] ?? 'Match not started yet',
      venue: data['venue'] ?? 'CricX Stadium',
      matchDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
      tournamentId: data['tournamentId'],
      tournamentName: data['tournamentName'],
      creatorId: data['creatorId'],
      playerOfTheMatchId: data['playerOfTheMatchId'],
      playerOfTheMatchName: data['playerOfTheMatchName'],
      teamAPlayerIds: teamAPlayerIds.isNotEmpty ? teamAPlayerIds : null,
      teamBPlayerIds: teamBPlayerIds.isNotEmpty ? teamBPlayerIds : null,
    );

    if (data['innings1'] != null) {
      match.innings1 = _inningsFromMap(data['innings1']);
    }
    if (data['innings2'] != null) {
      match.innings2 = _inningsFromMap(data['innings2']);
    }
    if (data['superOverInnings1'] != null) {
      match.superOverInnings1 = _inningsFromMap(data['superOverInnings1']);
    }
    if (data['superOverInnings2'] != null) {
      match.superOverInnings2 = _inningsFromMap(data['superOverInnings2']);
    }

    final strikerId = data['strikerId'] ?? data['striker']?['_id'] ?? data['striker'];
    if (strikerId != null) {
      match.striker = allPlayers.firstWhere((p) => p.id == strikerId, orElse: () => allPlayers.first);
    }
    final nonStrikerId = data['nonStrikerId'] ?? data['nonStriker']?['_id'] ?? data['nonStriker'];
    if (nonStrikerId != null) {
      match.nonStriker = allPlayers.firstWhere((p) => p.id == nonStrikerId, orElse: () => allPlayers.first);
    }
    final bowlerId = data['currentBowlerId'] ?? data['bowler']?['_id'] ?? data['bowler'];
    if (bowlerId != null) {
      match.currentBowler = allPlayers.firstWhere((p) => p.id == bowlerId, orElse: () => allPlayers.first);
    }

    match.playerRuns = Map<String, int>.from(data['playerRuns'] ?? {});
    match.playerBallsFaced = Map<String, int>.from(data['playerBallsFaced'] ?? {});
    match.bowlerRunsConceded = Map<String, int>.from(data['bowlerRunsConceded'] ?? {});
    match.bowlerWickets = Map<String, int>.from(data['bowlerWickets'] ?? {});
    match.bowlerBallsBowled = Map<String, int>.from(data['bowlerBallsBowled'] ?? {});

    return match;
  }

  MatchTeamInnings _inningsFromMap(Map<String, dynamic> data) {
    final List<dynamic> eventsRaw = data['events'] ?? [];
    final List<dynamic> battingOrderRaw = data['battingOrder'] ?? [];
    return MatchTeamInnings(
      teamId: data['teamId'] ?? '',
      runs: data['runs'] ?? 0,
      wickets: data['wickets'] ?? 0,
      ballsBowled: data['ballsBowled'] ?? 0,
      events: eventsRaw.map((e) => _ballEventFromMap(e)).toList(),
      battingOrder: List<String>.from(battingOrderRaw),
    );
  }

  BallEvent _ballEventFromMap(Map<String, dynamic> data) {
    return BallEvent(
      runs: data['runs'] ?? 0,
      isWide: data['isWide'] ?? false,
      isNoBall: data['isNoBall'] ?? false,
      isWicket: data['isWicket'] ?? false,
      wicketType: data['wicketType'] ?? '',
      bowlerName: data['bowlerName'] ?? '',
      batsmanName: data['batsmanName'] ?? '',
      description: data['description'] ?? '',
      isRunsOffBat: data['isRunsOffBat'] ?? true,
      isLegBye: data['isLegBye'] ?? false,
      isPenalty: data['isPenalty'] ?? false,
      isBye: data['isBye'] ?? false,
    );
  }

  Map<String, dynamic> _matchToMap(CricketMatch match) {
    return {
      'teamA': match.teamA.id,
      'teamB': match.teamB.id,
      'teamAPlayerIds': match.teamAPlayerIds ?? match.teamA.players.map((p) => p.id).toList(),
      'teamBPlayerIds': match.teamBPlayerIds ?? match.teamB.players.map((p) => p.id).toList(),
      'overs': match.totalOvers,
      'status': match.status.name,
      'tossWinnerId': match.tossWinnerId,
      'tossDecision': match.tossDecision,
      'currentInningsNum': match.currentInningsNum,
      'isSuperOverPlayed': match.isSuperOverPlayed,
      'isOnBreak': match.isOnBreak,
      'breakReason': match.breakReason,
      'resultString': match.resultString,
      'venue': match.venue,
      'matchDate': match.matchDate.toIso8601String(),
      'innings1': match.innings1 != null ? _inningsToMap(match.innings1!) : null,
      'innings2': match.innings2 != null ? _inningsToMap(match.innings2!) : null,
      'superOverInnings1': match.superOverInnings1 != null ? _inningsToMap(match.superOverInnings1!) : null,
      'superOverInnings2': match.superOverInnings2 != null ? _inningsToMap(match.superOverInnings2!) : null,
      'strikerId': match.striker?.id,
      'nonStrikerId': match.nonStriker?.id,
      'currentBowlerId': match.currentBowler?.id,
      'playerRuns': match.playerRuns,
      'playerBallsFaced': match.playerBallsFaced,
      'bowlerRunsConceded': match.bowlerRunsConceded,
      'bowlerWickets': match.bowlerWickets,
      'bowlerBallsBowled': match.bowlerBallsBowled,
      'tournamentId': match.tournamentId,
      'tournamentName': match.tournamentName,
      'creatorId': match.creatorId,
      'playerOfTheMatchId': match.playerOfTheMatchId,
      'playerOfTheMatchName': match.playerOfTheMatchName,
    };
  }

  Map<String, dynamic> _inningsToMap(MatchTeamInnings innings) {
    return {
      'teamId': innings.teamId,
      'runs': innings.runs,
      'wickets': innings.wickets,
      'ballsBowled': innings.ballsBowled,
      'events': innings.events.map((e) => _ballEventToMap(e)).toList(),
      'battingOrder': innings.battingOrder,
    };
  }

  Map<String, dynamic> _ballEventToMap(BallEvent event) {
    return {
      'runs': event.runs,
      'isWide': event.isWide,
      'isNoBall': event.isNoBall,
      'isWicket': event.isWicket,
      'wicketType': event.wicketType,
      'bowlerName': event.bowlerName,
      'batsmanName': event.batsmanName,
      'description': event.description,
      'isRunsOffBat': event.isRunsOffBat,
      'isLegBye': event.isLegBye,
      'isPenalty': event.isPenalty,
      'isBye': event.isBye,
    };
  }

  @override
  Future<void> createMatch(CricketMatch match) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.matches),
      headers: _headers,
      body: jsonEncode({
        'teamA': match.teamA.id,
        'teamB': match.teamB.id,
        'overs': match.totalOvers,
        'venue': match.venue,
        'matchDate': match.matchDate.toIso8601String(),
        'tournamentId': match.tournamentId,
        'tournamentName': match.tournamentName,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to schedule match: ${response.body}');
    }

    final responseData = jsonDecode(response.body);
    final matchId = _parseId(responseData);

    if (match.tournamentId != null) {
      final linkResponse = await http.post(
        Uri.parse(ApiEndpoints.tournamentFixtures(match.tournamentId!)),
        headers: _headers,
        body: jsonEncode({
          'matchId': matchId,
          'stage': 'Group Stage',
          'matchDate': match.matchDate.toIso8601String(),
        }),
      );
      if (linkResponse.statusCode != 200) {
        debugPrint('Failed to link match to tournament: ${linkResponse.body}');
      }
    }

    _cachedMatches.removeWhere((m) => m.id == match.id);
    _cachedMatches.add(match);
  }

  @override
  Future<void> updateMatch(CricketMatch match) async {
    // 1. Sync toss and start if match is live and has no ball events
    if (match.status == MatchStatus.live && match.tossWinnerId != null && match.currentInnings.events.isEmpty) {
      await http.put(
        Uri.parse(ApiEndpoints.matchToss(match.id)),
        headers: _headers,
        body: jsonEncode({
          'winner': match.tossWinnerId,
          'decision': match.tossDecision ?? 'Batting',
        }),
      );

      await http.put(
        Uri.parse(ApiEndpoints.matchStart(match.id)),
        headers: _headers,
        body: jsonEncode({
          'playingXI': {
            'teamA': match.teamAPlayerIds ?? match.teamA.players.map((p) => p.id).toList(),
            'teamB': match.teamBPlayerIds ?? match.teamB.players.map((p) => p.id).toList(),
          }
        }),
      );
    }

    // 2. Score ball updates
    final innings = match.currentInnings;
    if (innings.events.isNotEmpty) {
      final latestBall = innings.events.last;
      await http.post(
        Uri.parse(ApiEndpoints.matchScore(match.id)),
        headers: _headers,
        body: jsonEncode({
          'striker': match.striker?.id,
          'nonStriker': match.nonStriker?.id,
          'bowler': match.currentBowler?.id,
          'runs': latestBall.runs,
          'extras': {
            'type': latestBall.isWide ? 'Wide' : (latestBall.isNoBall ? 'NoBall' : (latestBall.isLegBye ? 'LegBye' : (latestBall.isBye ? 'Bye' : 'None'))),
            'runs': latestBall.runsAddedToTeam - latestBall.runsAddedToBatsman
          },
          'isWicket': latestBall.isWicket,
          'wicketType': latestBall.wicketType.isEmpty ? 'None' : latestBall.wicketType,
        }),
      );
    }

    // 3. Complete match if completed
    if (match.status == MatchStatus.completed) {
      await http.put(
        Uri.parse(ApiEndpoints.matchComplete(match.id)),
        headers: _headers,
      );

      if (match.playerOfTheMatchId != null) {
        await http.patch(
          Uri.parse(ApiEndpoints.matchPlayerOfTheMatch(match.id)),
          headers: _headers,
          body: jsonEncode({
            'playerOfTheMatchId': match.playerOfTheMatchId,
            'playerOfTheMatchName': match.playerOfTheMatchName,
          }),
        );
      }
    }

    // Fallback: update full state via general PUT
    final response = await http.put(
      Uri.parse(ApiEndpoints.matchById(match.id)),
      headers: _headers,
      body: jsonEncode(_matchToMap(match)),
    );
    if (response.statusCode != 200) {
      debugPrint('Warning: PUT /matches/:id returned status ${response.statusCode}');
    }

    _cachedMatches.removeWhere((m) => m.id == match.id);
    _cachedMatches.add(match);
  }

  // ==========================================
  // Tournaments API
  // ==========================================

  @override
  Future<List<Tournament>> getTournaments(List<Team> allTeams, List<CricketMatch> allMatches) async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.tournaments), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data.map((json) => _tournamentFromMap(json, allTeams, allMatches)).toList();
        _cachedTournaments.clear();
        _cachedTournaments.addAll(list);
        return list;
      }
    } catch (e) {
      debugPrint('Error getting tournaments: $e');
    }
    return [..._cachedTournaments];
  }

  Tournament _tournamentFromMap(
    Map<String, dynamic> data,
    List<Team> allTeams,
    List<CricketMatch> allMatches,
  ) {
    final List<dynamic> teamIds = data['teamIds'] ?? [];
    final List<dynamic> matchIds = data['matchIds'] ?? [];

    final List<Team> tTeams = [];
    for (var tid in teamIds) {
      final team = allTeams.firstWhere((t) => t.id == tid, orElse: () => allTeams.first);
      tTeams.add(team);
    }

    final List<CricketMatch> tMatches = [];
    for (var mid in matchIds) {
      final match = allMatches.firstWhere((m) => m.id == mid, orElse: () => allMatches.first);
      tMatches.add(match);
    }

    final startDateStr = data['startDate'] ?? DateTime.now().toIso8601String();

    final tournament = Tournament(
      id: _parseId(data),
      name: data['name'] ?? '',
      type: data['type'] ?? 'League',
      teams: tTeams,
      matches: tMatches,
      status: data['status'] ?? 'Upcoming',
      winnerTeamId: data['winnerTeamId'],
      playerOfTheTournamentId: data['playerOfTheTournamentId'],
      playerOfTheTournamentName: data['playerOfTheTournamentName'],
      playoffType: data['playoffType'] ?? 'Direct Final',
      defaultOvers: data['defaultOvers'] ?? 10,
      startDate: DateTime.tryParse(startDateStr) ?? DateTime.now(),
      venue: data['venue'] ?? 'CricX Turf Arena',
      creatorId: data['creatorId'],
    );

    final List<dynamic>? ptRaw = data['pointsTable'];
    if (ptRaw != null) {
      tournament.pointsTable = ptRaw.map((entry) {
        final teamId = entry['teamId'] ?? '';
        final team = tTeams.firstWhere((t) => t.id == teamId, orElse: () => tTeams.first);
        return PointsTableEntry(
          team: team,
          played: entry['played'] ?? 0,
          won: entry['won'] ?? 0,
          lost: entry['lost'] ?? 0,
          netRunRate: (entry['netRunRate'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    }

    return tournament;
  }

  Map<String, dynamic> _tournamentToMap(Tournament tournament) {
    return {
      'name': tournament.name,
      'startDate': tournament.startDate.toIso8601String(),
      'endDate': tournament.startDate.add(const Duration(days: 30)).toIso8601String(),
      'type': tournament.type,
      'teamIds': tournament.teams.map((t) => t.id).toList(),
      'matchIds': tournament.matches.map((m) => m.id).toList(),
      'status': tournament.status,
      'winnerTeamId': tournament.winnerTeamId,
      'playerOfTheTournamentId': tournament.playerOfTheTournamentId,
      'playerOfTheTournamentName': tournament.playerOfTheTournamentName,
      'playoffType': tournament.playoffType,
      'defaultOvers': tournament.defaultOvers,
      'venue': tournament.venue,
      'creatorId': tournament.creatorId,
    };
  }

  @override
  Future<void> createTournament(Tournament tournament) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.tournaments),
      headers: _headers,
      body: jsonEncode(_tournamentToMap(tournament)),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create tournament: ${response.body}');
    }

    final createdData = jsonDecode(response.body);
    final tournamentId = _parseId(createdData);

    if (tournament.teams.isNotEmpty) {
      await http.post(
        Uri.parse(ApiEndpoints.tournamentTeams(tournamentId)),
        headers: _headers,
        body: jsonEncode({
          'teamIds': tournament.teams.map((t) => t.id).toList(),
        }),
      );
    }

    _cachedTournaments.removeWhere((t) => t.id == tournament.id);
    _cachedTournaments.add(tournament);
  }

  @override
  Future<void> updateTournament(Tournament tournament) async {
    if (tournament.playerOfTheTournamentId != null) {
      await http.patch(
        Uri.parse(ApiEndpoints.tournamentPlayerOfTheTournament(tournament.id)),
        headers: _headers,
        body: jsonEncode({
          'playerOfTheTournamentId': tournament.playerOfTheTournamentId,
          'playerOfTheTournamentName': tournament.playerOfTheTournamentName,
        }),
      );
    }

    final response = await http.put(
      Uri.parse(ApiEndpoints.tournamentById(tournament.id)),
      headers: _headers,
      body: jsonEncode(_tournamentToMap(tournament)),
    );

    if (response.statusCode != 200) {
      debugPrint('Warning: PUT /tournaments/:id returned ${response.statusCode}');
    }

    _cachedTournaments.removeWhere((t) => t.id == tournament.id);
    _cachedTournaments.add(tournament);
  }

  @override
  Future<void> checkAndSeedDatabase() async {
    return;
  }
}
