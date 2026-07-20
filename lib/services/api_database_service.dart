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

  String _parseId(Map<String, dynamic> json) {
    if (json.containsKey('\$oid')) {
      return json['\$oid'].toString();
    }
    final idVal = json['_id'] ?? json['id'];
    if (idVal == null) return '';
    if (idVal is Map) {
      if (idVal.containsKey('\$oid')) {
        return idVal['\$oid'].toString();
      }
      return _parseId(Map<String, dynamic>.from(idVal));
    }
    return idVal.toString();
  }

  String? _parseIdOrString(dynamic val) {
    if (val == null) return null;
    if (val is Map) {
      return _parseId(Map<String, dynamic>.from(val));
    }
    return val.toString();
  }

  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Map && val.containsKey('\$date')) {
      return DateTime.tryParse(val['\$date'].toString()) ?? DateTime.now();
    }
    if (val is String) {
      return DateTime.tryParse(val) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _getCleanErrorMessage(String action, http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return '$action (Status Code: ${response.statusCode})';
    }
    
    if (body.startsWith('<')) {
      if (body.contains('Cannot PUT') || body.contains('Cannot POST') || body.contains('Cannot DELETE')) {
        final match = RegExp(r'Cannot\s+(?:PUT|POST|DELETE|GET)\s+\S+').firstMatch(body);
        if (match != null) {
          return '$action: ${match.group(0)}';
        }
      }
      return '$action: Server error (Status Code: ${response.statusCode})';
    }
    
    try {
      final Map<String, dynamic> data = jsonDecode(body);
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
    } catch (_) {}
    
    if (body.length < 100) {
      return '$action: $body';
    }
    
    return '$action: Server error (Status Code: ${response.statusCode})';
  }

  // Local caching variables to enable smooth offline support or list stubbing
  static final List<Player> _cachedPlayers = [];
  static final List<Team> _cachedTeams = [];
  static final List<CricketMatch> _cachedMatches = [];
  static final Map<String, int> _lastSentEventCounts = {};
  static final Map<String, int> _lastSentInningsNums = {};
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
        
        for (var p in list) {
          final idx = _cachedPlayers.indexWhere((cp) => cp.id == p.id);
          if (idx != -1) {
            _cachedPlayers[idx] = p;
          } else {
            _cachedPlayers.add(p);
          }
        }
        return [..._cachedPlayers];
      }
    } catch (e) {
      debugPrint('Error getting players: $e');
    }
    return [..._cachedPlayers];
  }

  Player _playerFromMap(Map<String, dynamic> data) {
    String roleVal = data['playingRole'] ?? data['role'] ?? 'Batsman';
    if (roleVal == 'Wicket-Keeper') {
      roleVal = 'Wicketkeeper';
    }
    return Player(
      id: _parseId(data),
      name: data['name'] ?? '',
      role: roleVal,
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
    String roleVal = player.role;
    if (roleVal == 'Wicketkeeper') {
      roleVal = 'Wicket-Keeper';
    }

    final bStyle = (player.battingStyle == '-' || player.battingStyle == 'None')
        ? 'Right-hand bat'
        : player.battingStyle;
    final bowlStyle = (player.bowlingStyle == '-' || player.bowlingStyle == 'None')
        ? null
        : player.bowlingStyle;

    return {
      'name': player.name,
      'playingRole': roleVal,
      'role': roleVal,
      if (bStyle != null) 'battingStyle': bStyle,
      if (bowlStyle != null) 'bowlingStyle': bowlStyle,
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
      throw Exception(_getCleanErrorMessage('Failed to create player', response));
    }
    final newPlayer = _playerFromMap(jsonDecode(response.body));
    _cachedPlayers.removeWhere((p) => p.id == player.id);
    _cachedPlayers.add(newPlayer);
  }

  @override
  Future<void> updatePlayerStats(Player player) async {
    final response = await http.put(
      Uri.parse(ApiEndpoints.playerById(player.id)),
      headers: _headers,
      body: jsonEncode(_playerToMap(player)),
    );
    
    if (response.statusCode != 200) {
      throw Exception(_getCleanErrorMessage('Failed to update player', response));
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
      if (pid is Map) {
        teamPlayers.add(_playerFromMap(Map<String, dynamic>.from(pid)));
      } else {
        final String idStr = pid.toString();
        final found = allPlayers.firstWhere(
          (p) => p.id == idStr,
          orElse: () => Player(id: idStr, name: 'Player $idStr', role: 'Batsman', battingStyle: 'Right-hand bat', bowlingStyle: '-'),
        );
        teamPlayers.add(found);
      }
    }

    String emoji = '🏏';
    int color = 0xFF4CAF50;
    if (data['logoEmoji'] != null) {
      emoji = data['logoEmoji'];
      color = data['logoColorHex'] ?? 0xFF4CAF50;
    } else {
      final logoVal = data['logo'];
      if (logoVal is String && logoVal.contains('|')) {
        final parts = logoVal.split('|');
        if (parts.length >= 2) {
          emoji = parts[0];
          color = int.tryParse(parts[1]) ?? 0xFF4CAF50;
        }
      }
    }

    final capId = data['captainId'] is Map 
        ? _parseId(Map<String, dynamic>.from(data['captainId'] as Map)) 
        : data['captainId']?.toString();
    final creId = data['creatorId'] is Map 
        ? _parseId(Map<String, dynamic>.from(data['creatorId'] as Map)) 
        : data['creatorId']?.toString();

    return Team(
      id: _parseId(data),
      name: data['name'] ?? '',
      abbreviation: data['abbreviation'] ?? data['shortName'] ?? '',
      logoEmoji: emoji,
      logoColorHex: color,
      players: teamPlayers,
      matchesPlayed: data['matchesPlayed'] ?? 0,
      matchesWon: data['matchesWon'] ?? 0,
      matchesLost: data['matchesLost'] ?? 0,
      netRunRate: (data['netRunRate'] as num?)?.toDouble() ?? 0.0,
      creatorId: creId,
      captainId: capId,
    );
  }

  Map<String, dynamic> _teamToMap(Team team) {
    return {
      'name': team.name,
      'abbreviation': team.abbreviation,
      'logoEmoji': team.logoEmoji,
      'logoColorHex': team.logoColorHex,
      'playerIds': team.players.map((p) => p.id).toList(),
      if (team.captainId != null) 'captainId': team.captainId,
    };
  }

  @override
  Future<void> addTeam(Team team) async {
    final List<Player> updatedPlayers = [];
    String? updatedCaptainId = team.captainId;

    for (var player in team.players) {
      if (player.id.startsWith('p_new_')) {
        final response = await http.post(
          Uri.parse(ApiEndpoints.players),
          headers: _headers,
          body: jsonEncode(_playerToMap(player)),
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          final newPlayer = _playerFromMap(jsonDecode(response.body));
          updatedPlayers.add(newPlayer);
          
          if (team.captainId == player.id) {
            updatedCaptainId = newPlayer.id;
          }
        } else {
          throw Exception(_getCleanErrorMessage('Failed to create player "${player.name}"', response));
        }
      } else {
        updatedPlayers.add(player);
      }
    }

    final teamToSend = Team(
      id: team.id,
      name: team.name,
      abbreviation: team.abbreviation,
      logoEmoji: team.logoEmoji,
      logoColorHex: team.logoColorHex,
      players: updatedPlayers,
      creatorId: team.creatorId,
      captainId: updatedCaptainId,
      matchesPlayed: team.matchesPlayed,
      matchesWon: team.matchesWon,
      matchesLost: team.matchesLost,
      netRunRate: team.netRunRate,
    );

    final response = await http.post(
      Uri.parse(ApiEndpoints.teams),
      headers: _headers,
      body: jsonEncode(_teamToMap(teamToSend)),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_getCleanErrorMessage('Failed to create team', response));
    }
    
    final createdTeamData = jsonDecode(response.body);
    final newTeam = _teamFromMap(createdTeamData, updatedPlayers);

    _cachedTeams.removeWhere((t) => t.id == team.id);
    _cachedTeams.add(newTeam);

    for (var p in updatedPlayers) {
      if (!_cachedPlayers.any((cp) => cp.id == p.id)) {
        _cachedPlayers.add(p);
      }
    }
  }

  @override
  Future<void> updateTeamInfo(Team team) async {
    final response = await http.put(
      Uri.parse(ApiEndpoints.teamById(team.id)),
      headers: _headers,
      body: jsonEncode(_teamToMap(team)),
    );
    
    if (response.statusCode != 200) {
      throw Exception(_getCleanErrorMessage('Failed to update team', response));
    }
    
    final updatedTeamData = jsonDecode(response.body);
    final newTeam = _teamFromMap(updatedTeamData, team.players);
    
    _cachedTeams.removeWhere((t) => t.id == team.id);
    _cachedTeams.add(newTeam);
  }

  @override
  Future<void> addPlayerToTeam(String teamId, Player player) async {
    String actualPlayerId = player.id;
    
    // If it's a temporary ID, we must create the player first and capture its backend ObjectId!
    if (player.id.startsWith('p_')) {
      final response = await http.post(
        Uri.parse(ApiEndpoints.players),
        headers: _headers,
        body: jsonEncode(_playerToMap(player)),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        actualPlayerId = _parseId(data);
      } else {
        throw Exception(_getCleanErrorMessage('Failed to create player profile', response));
      }
    }

    final response = await http.post(
      Uri.parse(ApiEndpoints.teamPlayers(teamId)),
      headers: _headers,
      body: jsonEncode({
        'playerId': actualPlayerId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getCleanErrorMessage('Failed to add player to team', response));
    }

    final newPlayer = Player(
      id: actualPlayerId,
      name: player.name,
      role: player.role,
      battingStyle: player.battingStyle,
      bowlingStyle: player.bowlingStyle,
      matchesPlayed: player.matchesPlayed,
      runsScored: player.runsScored,
      wicketsTaken: player.wicketsTaken,
      ballsFaced: player.ballsFaced,
      ballsBowled: player.ballsBowled,
      runsConceded: player.runsConceded,
      highestScore: player.highestScore,
      bestBowling: player.bestBowling,
    );

    if (!_cachedPlayers.any((p) => p.id == actualPlayerId)) {
      _cachedPlayers.add(newPlayer);
    }

    final teamIndex = _cachedTeams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      final team = _cachedTeams[teamIndex];
      if (!team.players.any((p) => p.id == actualPlayerId)) {
        team.players.add(newPlayer);
      }
    }
  }

  @override
  Future<void> removePlayerFromTeam(String teamId, String playerId) async {
    final response = await http.delete(
      Uri.parse(ApiEndpoints.removePlayerFromTeam(teamId, playerId)),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_getCleanErrorMessage('Failed to remove player from team', response));
    }

    final teamIndex = _cachedTeams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      final team = _cachedTeams[teamIndex];
      team.players.removeWhere((p) => p.id == playerId);
      if (team.captainId == playerId) {
        team.captainId = null;
      }
    }
  }

  // ==========================================
  // Matches API
  // ==========================================

  @override
  Future<List<CricketMatch>> getMatches(List<Team> allTeams, List<Player> allPlayers) async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.matches), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data.map((json) => _matchFromMap(json, allTeams, allPlayers)).toList();
        _cachedMatches.clear();
        _cachedMatches.addAll(list);
        for (var m in list) {
          _lastSentEventCounts[m.id] = m.currentInnings.events.length;
          _lastSentInningsNums[m.id] = m.currentInningsNum;
        }
        return list;
      }
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
    final teamAId = _parseIdOrString(data['teamA'] ?? data['teamAId']) ?? '';
    final teamBId = _parseIdOrString(data['teamB'] ?? data['teamBId']) ?? '';

    final baseTeamA = allTeams.firstWhere(
      (t) => t.id == teamAId,
      orElse: () => Team(id: teamAId, name: 'Team A', abbreviation: 'A', logoEmoji: '🏏', logoColorHex: 0xFF9E9E9E, players: []),
    );
    final baseTeamB = allTeams.firstWhere(
      (t) => t.id == teamBId,
      orElse: () => Team(id: teamBId, name: 'Team B', abbreviation: 'B', logoEmoji: '🏏', logoColorHex: 0xFF9E9E9E, players: []),
    );

    final teamAPlayerIds = (data['teamAPlayerIds'] as List? ?? [])
        .map((p) => _parseIdOrString(p) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final teamBPlayerIds = (data['teamBPlayerIds'] as List? ?? [])
        .map((p) => _parseIdOrString(p) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

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
    final match = CricketMatch(
      id: _parseId(data),
      teamA: teamA,
      teamB: teamB,
      totalOvers: data['overs'] ?? data['totalOvers'] ?? 20,
      status: matchStatus,
      tossWinnerId: _parseIdOrString(data['tossWinnerId'] ?? data['toss']?['winner']),
      tossDecision: data['tossDecision'] is Map 
          ? _parseIdOrString(data['tossDecision']) 
          : data['tossDecision']?.toString(),
      currentInningsNum: data['currentInningsNum'] ?? 1,
      isSuperOverPlayed: data['isSuperOverPlayed'] ?? false,
      isOnBreak: data['isOnBreak'] ?? false,
      breakReason: data['breakReason'],
      resultString: data['resultString'] is Map 
          ? (_parseIdOrString(data['resultString']) ?? 'Match not started yet')
          : (data['resultString']?.toString() ?? data['result']?.toString() ?? 'Match not started yet'),
      venue: data['venue'] is Map 
          ? (_parseIdOrString(data['venue']) ?? 'CricX Stadium') 
          : (data['venue']?.toString() ?? 'CricX Stadium'),
      matchDate: _parseDate(data['matchDate'] ?? data['createdAt']),
      tournamentId: _parseIdOrString(data['tournamentId']),
      tournamentName: data['tournamentName']?.toString(),
      creatorId: _parseIdOrString(data['creatorId']),
      playerOfTheMatchId: _parseIdOrString(data['playerOfTheMatchId']),
      playerOfTheMatchName: data['playerOfTheMatchName']?.toString(),
      teamAPlayerIds: teamAPlayerIds.isNotEmpty ? teamAPlayerIds : null,
      teamBPlayerIds: teamBPlayerIds.isNotEmpty ? teamBPlayerIds : null,
      stage: data['stage']?.toString(),
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

    final strikerId = _parseIdOrString(data['strikerId'] ?? data['striker']);
    if (strikerId != null && allPlayers.isNotEmpty) {
      final index = allPlayers.indexWhere((p) => p.id == strikerId);
      match.striker = index != -1 ? allPlayers[index] : allPlayers.first;
    }
    final nonStrikerId = _parseIdOrString(data['nonStrikerId'] ?? data['nonStriker']);
    if (nonStrikerId != null && allPlayers.isNotEmpty) {
      final index = allPlayers.indexWhere((p) => p.id == nonStrikerId);
      match.nonStriker = index != -1 ? allPlayers[index] : allPlayers.first;
    }
    final bowlerId = _parseIdOrString(data['currentBowlerId'] ?? data['bowler']);
    if (bowlerId != null && allPlayers.isNotEmpty) {
      final index = allPlayers.indexWhere((p) => p.id == bowlerId);
      match.currentBowler = index != -1 ? allPlayers[index] : allPlayers.first;
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
    
    final tId = _parseIdOrString(data['teamId']) ?? '';

    return MatchTeamInnings(
      teamId: tId,
      runs: data['runs'] ?? 0,
      wickets: data['wickets'] ?? 0,
      ballsBowled: data['ballsBowled'] ?? 0,
      events: eventsRaw.map((e) => _ballEventFromMap(Map<String, dynamic>.from(e))).toList(),
      battingOrder: battingOrderRaw.map((b) => _parseIdOrString(b) ?? '').toList(),
    );
  }

  BallEvent _ballEventFromMap(Map<String, dynamic> data) {
    return BallEvent(
      runs: data['runs'] ?? 0,
      isWide: data['isWide'] ?? false,
      isNoBall: data['isNoBall'] ?? false,
      isWicket: data['isWicket'] ?? false,
      wicketType: data['wicketType']?.toString() ?? '',
      bowlerName: data['bowlerName']?.toString() ?? '',
      batsmanName: data['batsmanName']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
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
      'stage': match.stage,
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
  Future<CricketMatch> createMatch(CricketMatch match) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.matches),
      headers: _headers,
      body: jsonEncode({
        'teamAId': match.teamA.id,
        'teamBId': match.teamB.id,
        'totalOvers': match.totalOvers,
        'venue': match.venue,
        'matchDate': match.matchDate.toIso8601String(),
        if (match.stage != null) 'stage': match.stage,
        if (match.tournamentId != null) 'tournamentId': match.tournamentId,
        if (match.tournamentName != null) 'tournamentName': match.tournamentName,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to schedule match: ${response.body}');
    }

    final responseData = jsonDecode(response.body);
    final newMatch = _matchFromMap(responseData, _cachedTeams, _cachedPlayers);
    _cachedMatches.removeWhere((m) => m.id == match.id);
    _cachedMatches.add(newMatch);
    _lastSentEventCounts[newMatch.id] = 0;
    _lastSentInningsNums[newMatch.id] = 1;
    return newMatch;
  }

  @override
  Future<void> updateMatch(CricketMatch match) async {
    try {
      final newEventCount = match.currentInnings.events.length;
      final lastSentInnings = _lastSentInningsNums[match.id] ?? 1;
      
      int oldEventCount = 0;
      if (lastSentInnings == match.currentInningsNum) {
        oldEventCount = _lastSentEventCounts[match.id] ?? 0;
      }

      // 1. Start match if live and events are empty
      if (match.status == MatchStatus.live && match.currentInnings.events.isEmpty) {
        // First call start match API to register playingXI and transition status
        final startResponse = await http.put(
          Uri.parse(ApiEndpoints.matchStart(match.id)),
          headers: _headers,
          body: jsonEncode({
            'playingXI': {
              'teamA': match.teamAPlayerIds ?? match.teamA.players.map((p) => p.id).toList(),
              'teamB': match.teamBPlayerIds ?? match.teamB.players.map((p) => p.id).toList(),
            },
          }),
        );

        if (startResponse.statusCode != 200) {
          throw Exception('[HTTP PUT] Response (${ApiEndpoints.matchStart(match.id)}): Status ${startResponse.statusCode}');
        }

        // Then call the PUT match API to set striker, non-striker, bowler, toss details, etc.
        final putResponse = await http.put(
          Uri.parse(ApiEndpoints.matchById(match.id)),
          headers: _headers,
          body: jsonEncode(_matchToMap(match)),
        );

        if (putResponse.statusCode != 200) {
          throw Exception('[HTTP PUT] Response (${ApiEndpoints.matchById(match.id)}): Status ${putResponse.statusCode}');
        }
      } else if (newEventCount > oldEventCount) {
        // 2. Score ball updates (only if a new event is added)
        final latestBall = match.currentInnings.events.last;
        final scoreResponse = await http.post(
          Uri.parse(ApiEndpoints.matchScore(match.id)),
          headers: _headers,
          body: jsonEncode({
            'striker': match.striker?.id,
            'nonStriker': match.nonStriker?.id,
            'bowler': match.currentBowler?.id,
            'strikerId': match.striker?.id,
            'nonStrikerId': match.nonStriker?.id,
            'currentBowlerId': match.currentBowler?.id,
            'batsmanName': latestBall.batsmanName,
            'bowlerName': latestBall.bowlerName,
            'runs': latestBall.runs,
            'extras': {
              'type': latestBall.isWide ? 'Wide' : (latestBall.isNoBall ? 'NoBall' : (latestBall.isLegBye ? 'LegBye' : (latestBall.isBye ? 'Bye' : 'None'))),
              'runs': latestBall.runsAddedToTeam - latestBall.runsAddedToBatsman
            },
            'isWicket': latestBall.isWicket,
            'wicketType': latestBall.wicketType.isEmpty ? 'None' : latestBall.wicketType,
          }),
        );

        if (scoreResponse.statusCode != 200 && scoreResponse.statusCode != 201) {
          throw Exception('[HTTP POST] Response (${ApiEndpoints.matchScore(match.id)}): Status ${scoreResponse.statusCode}');
        }

        // Also call PUT match to sync all other fields like strikerId, nonStrikerId, currentBowlerId, scores, batsman/bowler stats, etc.
        final putResponse = await http.put(
          Uri.parse(ApiEndpoints.matchById(match.id)),
          headers: _headers,
          body: jsonEncode(_matchToMap(match)),
        );

        if (putResponse.statusCode != 200) {
          throw Exception('[HTTP PUT] Response (${ApiEndpoints.matchById(match.id)}): Status ${putResponse.statusCode}');
        }
      } else {
        // 3. General updates (strike rotated, bowler changed, match completed, undo ball, etc.)
        final putResponse = await http.put(
          Uri.parse(ApiEndpoints.matchById(match.id)),
          headers: _headers,
          body: jsonEncode(_matchToMap(match)),
        );

        if (putResponse.statusCode != 200) {
          throw Exception('[HTTP PUT] Response (${ApiEndpoints.matchById(match.id)}): Status ${putResponse.statusCode}');
        }
      }

      // Always update local cache and event counts on success
      _cachedMatches.removeWhere((m) => m.id == match.id);
      _cachedMatches.add(match);
      _lastSentEventCounts[match.id] = match.currentInnings.events.length;
      _lastSentInningsNums[match.id] = match.currentInningsNum;
    } catch (e) {
      debugPrint('Error updating match on server: $e');
      rethrow;
    }
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
    final List<dynamic> rawTeamIds = data['participatingTeams'] ?? data['teamIds'] ?? [];
    final List<dynamic> rawMatchIds = data['fixtures'] ?? data['matchIds'] ?? [];

    final List<Team> tTeams = [];
    for (var tid in rawTeamIds) {
      final String idStr = tid is Map ? _parseId(Map<String, dynamic>.from(tid)) : tid.toString();
      final teamIndex = allTeams.indexWhere((t) => t.id == idStr);
      if (teamIndex != -1) {
        tTeams.add(allTeams[teamIndex]);
      } else if (allTeams.isNotEmpty) {
        tTeams.add(allTeams.first);
      }
    }

    final List<CricketMatch> tMatches = [];
    for (var mid in rawMatchIds) {
      String idStr;
      String? matchStage;
      if (mid is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(mid);
        if (map.containsKey('matchId')) {
          idStr = _parseIdOrString(map['matchId']) ?? '';
        } else {
          idStr = _parseId(map);
        }
        if (map.containsKey('stage')) {
          matchStage = map['stage']?.toString();
        }
      } else {
        idStr = mid.toString();
      }
      final matchIndex = allMatches.indexWhere((m) => m.id == idStr);
      if (matchIndex != -1) {
        final match = allMatches[matchIndex];
        if (matchStage != null) {
          match.stage = matchStage;
        }
        tMatches.add(match);
      }
    }

    final winId = data['winnerTeamId'] is Map 
        ? _parseId(Map<String, dynamic>.from(data['winnerTeamId'] as Map)) 
        : data['winnerTeamId']?.toString();
    final potId = data['playerOfTheTournamentId'] is Map 
        ? _parseId(Map<String, dynamic>.from(data['playerOfTheTournamentId'] as Map)) 
        : data['playerOfTheTournamentId']?.toString();
    final creId = data['creatorId'] is Map 
        ? _parseId(Map<String, dynamic>.from(data['creatorId'] as Map)) 
        : data['creatorId']?.toString();

    final tournament = Tournament(
      id: _parseId(data),
      name: data['name'] ?? '',
      type: data['type'] ?? 'League',
      teams: tTeams,
      matches: tMatches,
      status: data['status'] ?? 'Upcoming',
      winnerTeamId: winId,
      playerOfTheTournamentId: potId,
      playerOfTheTournamentName: data['playerOfTheTournamentName'],
      playoffType: data['playoffType'] ?? 'Direct Final',
      defaultOvers: data['defaultOvers'] ?? 10,
      startDate: _parseDate(data['startDate']),
      venue: data['venue'] ?? 'CricX Turf Arena',
      creatorId: creId,
    );

    final List<dynamic>? ptRaw = data['pointsTable'];
    if (ptRaw != null) {
      tournament.pointsTable = ptRaw.map((entry) {
        final teamId = entry['teamId'] is Map 
            ? _parseId(Map<String, dynamic>.from(entry['teamId'] as Map)) 
            : entry['teamId']?.toString() ?? '';
        final team = tTeams.isNotEmpty 
            ? tTeams.firstWhere((t) => t.id == teamId, orElse: () => tTeams.first) 
            : Team(
                id: teamId,
                name: 'Unknown Team',
                abbreviation: 'UNK',
                logoEmoji: '🏏',
                logoColorHex: 0xFF4CAF50,
                players: [],
                matchesPlayed: 0,
                matchesWon: 0,
                matchesLost: 0,
                netRunRate: 0.0,
                creatorId: '',
              );
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
      body: jsonEncode({
        'name': tournament.name,
        'type': tournament.type,
        'playoffType': tournament.playoffType,
        'defaultOvers': tournament.defaultOvers,
        'venue': tournament.venue,
        'startDate': tournament.startDate.toIso8601String(),
        'endDate': tournament.startDate.add(const Duration(days: 30)).toIso8601String(),
      }),
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

    final newTournament = Tournament(
      id: tournamentId,
      name: tournament.name,
      type: tournament.type,
      teams: tournament.teams,
      matches: tournament.matches,
      status: tournament.status,
      winnerTeamId: tournament.winnerTeamId,
      playerOfTheTournamentId: tournament.playerOfTheTournamentId,
      playerOfTheTournamentName: tournament.playerOfTheTournamentName,
      playoffType: tournament.playoffType,
      defaultOvers: tournament.defaultOvers,
      startDate: tournament.startDate,
      venue: tournament.venue,
      creatorId: createdData['creatorId'] is Map 
          ? _parseId(Map<String, dynamic>.from(createdData['creatorId'] as Map)) 
          : createdData['creatorId']?.toString(),
    );

    _cachedTournaments.removeWhere((t) => t.id == tournament.id);
    _cachedTournaments.add(newTournament);
  }

  @override
  Future<void> updateTournament(Tournament tournament) async {
    try {
      final response = await http.put(
        Uri.parse(ApiEndpoints.tournamentById(tournament.id)),
        headers: _headers,
        body: jsonEncode({
          'status': tournament.status,
          'fixtures': tournament.matches.map((m) => {
            'matchId': m.id,
            'stage': m.stage ?? (m.id.endsWith('_final') || m.id.contains('_final') ? 'Final' : (m.id.contains('_sf') ? 'Semifinal' : 'League')),
          }).toList(),
          'matchIds': tournament.matches.map((m) => {
            'matchId': m.id,
            'stage': m.stage ?? (m.id.endsWith('_final') || m.id.contains('_final') ? 'Final' : (m.id.contains('_sf') ? 'Semifinal' : 'League')),
          }).toList(),
          if (tournament.winnerTeamId != null) 'winnerTeamId': tournament.winnerTeamId,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Warning: PUT /tournaments/:id returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating tournament on server: $e');
    }

    _cachedTournaments.removeWhere((t) => t.id == tournament.id);
    _cachedTournaments.add(tournament);
  }

  @override
  Future<void> declarePlayerOfTheTournament(String tournamentId, String playerId, String playerName) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiEndpoints.declarePlayerOfTheTournament(tournamentId)),
        headers: _headers,
        body: jsonEncode({
          'playerOfTheTournamentId': playerId,
          'playerOfTheTournamentName': playerName,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('[HTTP PATCH] Response (${ApiEndpoints.declarePlayerOfTheTournament(tournamentId)}): Status ${response.statusCode}');
      }

      // Update the cache if the tournament exists in cache
      final idx = _cachedTournaments.indexWhere((t) => t.id == tournamentId);
      if (idx != -1) {
        _cachedTournaments[idx].playerOfTheTournamentId = playerId;
        _cachedTournaments[idx].playerOfTheTournamentName = playerName;
      }
    } catch (e) {
      debugPrint('Error declaring player of the tournament on server: $e');
      rethrow;
    }
  }

  @override
  Future<void> checkAndSeedDatabase() async {
    return;
  }
}
