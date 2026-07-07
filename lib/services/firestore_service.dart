import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';
import 'database_service.dart';

class FirestoreService implements DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _playersCollection => _firestore.collection('players');
  CollectionReference get _teamsCollection => _firestore.collection('teams');
  CollectionReference get _matchesCollection => _firestore.collection('matches');
  CollectionReference get _tournamentsCollection => _firestore.collection('tournaments');

  // ==========================================
  // Streams (Real-time syncing)
  // ==========================================

  @override
  Stream<List<Player>> streamPlayers() {
    return _playersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _playerFromMap(doc.id, data);
      }).toList();
    });
  }

  @override
  Stream<List<Team>> streamTeams(List<Player> allPlayers) {
    return _teamsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _teamFromMap(doc.id, data, allPlayers);
      }).toList();
    });
  }

  @override
  Stream<List<CricketMatch>> streamMatches(List<Team> allTeams, List<Player> allPlayers) {
    return _matchesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _matchFromMap(doc.id, data, allTeams, allPlayers);
      }).toList();
    });
  }

  @override
  Stream<List<Tournament>> streamTournaments(List<Team> allTeams, List<CricketMatch> allMatches) {
    return _tournamentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _tournamentFromMap(doc.id, data, allTeams, allMatches);
      }).toList();
    });
  }

  // ==========================================
  // Mutations
  // ==========================================

  @override
  Future<void> addPlayer(Player player) async {
    await _playersCollection.doc(player.id).set(_playerToMap(player));
  }

  @override
  Future<void> updatePlayerStats(Player player) async {
    await _playersCollection.doc(player.id).update(_playerToMap(player));
  }

  @override
  Future<void> addTeam(Team team) async {
    final batch = _firestore.batch();
    
    // 1. Add team document
    batch.set(_teamsCollection.doc(team.id), _teamToMap(team));
    
    // 2. Add all initial squad players to the players collection
    for (var player in team.players) {
      batch.set(_playersCollection.doc(player.id), _playerToMap(player));
    }
    
    await batch.commit();
  }

  @override
  Future<void> updateTeamInfo(Team team) async {
    await _teamsCollection.doc(team.id).set(_teamToMap(team));
  }

  @override
  Future<void> addPlayerToTeam(String teamId, Player player) async {
    final batch = _firestore.batch();
    
    // 1. Add player document
    batch.set(_playersCollection.doc(player.id), _playerToMap(player));
    
    // 2. Add player ID to team's playerIds array
    batch.update(_teamsCollection.doc(teamId), {
      'playerIds': FieldValue.arrayUnion([player.id]),
    });

    await batch.commit();
  }

  @override
  Future<void> createMatch(CricketMatch match) async {
    await _matchesCollection.doc(match.id).set(_matchToMap(match));
  }

  @override
  Future<void> updateMatch(CricketMatch match) async {
    await _matchesCollection.doc(match.id).set(_matchToMap(match));
  }

  @override
  Future<void> createTournament(Tournament tournament) async {
    await _tournamentsCollection.doc(tournament.id).set(_tournamentToMap(tournament));
  }

  @override
  Future<void> updateTournament(Tournament tournament) async {
    await _tournamentsCollection.doc(tournament.id).set(_tournamentToMap(tournament));
  }

  // ==========================================
  // Mappers (Serialization / Deserialization)
  // ==========================================

  // --- Player ---
  Player _playerFromMap(String id, Map<String, dynamic> data) {
    return Player(
      id: id,
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

  // --- Team ---
  Team _teamFromMap(String id, Map<String, dynamic> data, List<Player> allPlayers) {
    final List<dynamic> playerIds = data['playerIds'] ?? [];
    final List<Player> teamPlayers = [];
    
    for (var pid in playerIds) {
      final found = allPlayers.firstWhere(
        (p) => p.id == pid,
        orElse: () => Player(id: pid, name: 'Unknown Player', role: 'Batsman', battingStyle: 'Right-hand bat', bowlingStyle: '-'),
      );
      teamPlayers.add(found);
    }

    return Team(
      id: id,
      name: data['name'] ?? '',
      abbreviation: data['abbreviation'] ?? '',
      logoEmoji: data['logoEmoji'] ?? '🏏',
      logoColorHex: data['logoColorHex'] ?? 0xFF4CAF50,
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
      'abbreviation': team.abbreviation,
      'logoEmoji': team.logoEmoji,
      'logoColorHex': team.logoColorHex,
      'playerIds': team.players.map((p) => p.id).toList(),
      'matchesPlayed': team.matchesPlayed,
      'matchesWon': team.matchesWon,
      'matchesLost': team.matchesLost,
      'netRunRate': team.netRunRate,
      'creatorId': team.creatorId,
      'captainId': team.captainId,
    };
  }

  // --- BallEvent ---
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

  // --- MatchTeamInnings ---
  MatchTeamInnings _inningsFromMap(Map<String, dynamic> data) {
    final List<dynamic> eventsRaw = data['events'] ?? [];
    final List<dynamic> battingOrderRaw = data['battingOrder'] ?? [];
    return MatchTeamInnings(
      teamId: data['teamId'] ?? '',
      runs: data['runs'] ?? 0,
      wickets: data['wickets'] ?? 0,
      ballsBowled: data['ballsBowled'] ?? 0,
      events: eventsRaw.map((e) => _ballEventFromMap(e as Map<String, dynamic>)).toList(),
      battingOrder: List<String>.from(battingOrderRaw),
    );
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

  // --- CricketMatch ---
  CricketMatch _matchFromMap(
    String id,
    Map<String, dynamic> data,
    List<Team> allTeams,
    List<Player> allPlayers,
  ) {
    final teamAId = data['teamAId'] ?? '';
    final teamBId = data['teamBId'] ?? '';

    final teamAPlayerIds = List<String>.from(data['teamAPlayerIds'] ?? []);
    final teamBPlayerIds = List<String>.from(data['teamBPlayerIds'] ?? []);

    final baseTeamA = allTeams.firstWhere(
      (t) => t.id == teamAId,
      orElse: () => Team(id: teamAId, name: 'Team A (Unknown)', abbreviation: 'A', logoEmoji: '🏏', logoColorHex: 0xFF9E9E9E, players: []),
    );
    final baseTeamB = allTeams.firstWhere(
      (t) => t.id == teamBId,
      orElse: () => Team(id: teamBId, name: 'Team B (Unknown)', abbreviation: 'B', logoEmoji: '🏏', logoColorHex: 0xFF9E9E9E, players: []),
    );

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
    if (statusStr == 'live') {
      matchStatus = MatchStatus.live;
    } else if (statusStr == 'completed') {
      matchStatus = MatchStatus.completed;
    } else {
      matchStatus = MatchStatus.upcoming;
    }

    final match = CricketMatch(
      id: id,
      teamA: teamA,
      teamB: teamB,
      totalOvers: data['totalOvers'] ?? 20,
      status: matchStatus,
      tossWinnerId: data['tossWinnerId'],
      tossDecision: data['tossDecision'],
      currentInningsNum: data['currentInningsNum'] ?? 1,
      isSuperOverPlayed: data['isSuperOverPlayed'] ?? false,
      isOnBreak: data['isOnBreak'] ?? false,
      breakReason: data['breakReason'],
      resultString: data['resultString'] ?? 'Match not started yet',
      venue: data['venue'] ?? 'Unknown Venue',
      matchDate: (data['matchDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tournamentId: data['tournamentId'],
      tournamentName: data['tournamentName'],
      creatorId: data['creatorId'],
      playerOfTheMatchId: data['playerOfTheMatchId'],
      playerOfTheMatchName: data['playerOfTheMatchName'],
      teamAPlayerIds: teamAPlayerIds.isNotEmpty ? teamAPlayerIds : null,
      teamBPlayerIds: teamBPlayerIds.isNotEmpty ? teamBPlayerIds : null,
    );

    // Innings
    if (data['innings1'] != null) {
      match.innings1 = _inningsFromMap(data['innings1'] as Map<String, dynamic>);
    }
    if (data['innings2'] != null) {
      match.innings2 = _inningsFromMap(data['innings2'] as Map<String, dynamic>);
    }
    if (data['superOverInnings1'] != null) {
      match.superOverInnings1 = _inningsFromMap(data['superOverInnings1'] as Map<String, dynamic>);
    }
    if (data['superOverInnings2'] != null) {
      match.superOverInnings2 = _inningsFromMap(data['superOverInnings2'] as Map<String, dynamic>);
    }

    // Active Players
    final strikerId = data['strikerId'];
    if (strikerId != null) {
      match.striker = allPlayers.firstWhere((p) => p.id == strikerId, orElse: () => allPlayers.first);
    }
    final nonStrikerId = data['nonStrikerId'];
    if (nonStrikerId != null) {
      match.nonStriker = allPlayers.firstWhere((p) => p.id == nonStrikerId, orElse: () => allPlayers.first);
    }
    final bowlerId = data['currentBowlerId'];
    if (bowlerId != null) {
      match.currentBowler = allPlayers.firstWhere((p) => p.id == bowlerId, orElse: () => allPlayers.first);
    }

    // Maps
    match.playerRuns = Map<String, int>.from(data['playerRuns'] ?? {});
    match.playerBallsFaced = Map<String, int>.from(data['playerBallsFaced'] ?? {});
    match.bowlerRunsConceded = Map<String, int>.from(data['bowlerRunsConceded'] ?? {});
    match.bowlerWickets = Map<String, int>.from(data['bowlerWickets'] ?? {});
    match.bowlerBallsBowled = Map<String, int>.from(data['bowlerBallsBowled'] ?? {});

    return match;
  }

  Map<String, dynamic> _matchToMap(CricketMatch match) {
    return {
      'teamAId': match.teamA.id,
      'teamBId': match.teamB.id,
      'teamAPlayerIds': match.teamAPlayerIds ?? match.teamA.players.map((p) => p.id).toList(),
      'teamBPlayerIds': match.teamBPlayerIds ?? match.teamB.players.map((p) => p.id).toList(),
      'totalOvers': match.totalOvers,
      'status': match.status.name,
      'tossWinnerId': match.tossWinnerId,
      'tossDecision': match.tossDecision,
      'currentInningsNum': match.currentInningsNum,
      'isSuperOverPlayed': match.isSuperOverPlayed,
      'isOnBreak': match.isOnBreak,
      'breakReason': match.breakReason,
      'resultString': match.resultString,
      'venue': match.venue,
      'matchDate': Timestamp.fromDate(match.matchDate),
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

  // --- Tournament ---
  Tournament _tournamentFromMap(
    String id,
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
      final match = allMatches.firstWhere(
        (m) => m.id == mid,
        orElse: () => CricketMatch(
          id: mid,
          teamA: Team(
            id: 'placeholder_${mid}_a',
            name: 'TBD',
            abbreviation: 'TBD',
            logoEmoji: '🏏',
            logoColorHex: 0xFF9E9E9E,
            players: [],
          ),
          teamB: Team(
            id: 'placeholder_${mid}_b',
            name: 'TBD',
            abbreviation: 'TBD',
            logoEmoji: '🏏',
            logoColorHex: 0xFF9E9E9E,
            players: [],
          ),
          totalOvers: data['defaultOvers'] ?? 10,
          venue: data['venue'] ?? 'CricX Turf Arena',
          matchDate: DateTime.now(),
          tournamentId: id,
          tournamentName: data['name'] ?? '',
        ),
      );
      tMatches.add(match);
    }

    final tournament = Tournament(
      id: id,
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
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      venue: data['venue'] ?? 'CricX Turf Arena',
      creatorId: data['creatorId'],
    );

    // Reconstruct Points Table
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
      'type': tournament.type,
      'teamIds': tournament.teams.map((t) => t.id).toList(),
      'matchIds': tournament.matches.map((m) => m.id).toList(),
      'status': tournament.status,
      'winnerTeamId': tournament.winnerTeamId,
      'playerOfTheTournamentId': tournament.playerOfTheTournamentId,
      'playerOfTheTournamentName': tournament.playerOfTheTournamentName,
      'playoffType': tournament.playoffType,
      'defaultOvers': tournament.defaultOvers,
      'startDate': Timestamp.fromDate(tournament.startDate),
      'venue': tournament.venue,
      'pointsTable': tournament.pointsTable.map((e) => {
        'teamId': e.team.id,
        'played': e.played,
        'won': e.won,
        'lost': e.lost,
        'netRunRate': e.netRunRate,
      }).toList(),
      'creatorId': tournament.creatorId,
    };
  }

  // ==========================================
  // Database Seeding Logic
  // ==========================================

  @override
  Future<void> checkAndSeedDatabase() async {
    // Seeding disabled, start with a completely empty database.
    return;
  }
}
