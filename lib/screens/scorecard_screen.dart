import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/custom_snackbar.dart';
import 'main_navigation_screen.dart';
import 'organizer/tournament_detail_screen.dart';

class ScorecardScreen extends StatelessWidget {
  final CricketMatch match;

  const ScorecardScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // Find the latest state of the match from appState list
    final currentMatch = appState.matches.firstWhere((m) => m.id == match.id, orElse: () => match);
    
    // Determine the teams for Innings 1 and Innings 2
    final team1 = currentMatch.innings1 != null 
        ? appState.teams.firstWhere((t) => t.id == currentMatch.innings1!.teamId) 
        : currentMatch.teamA;
        
    final team2 = currentMatch.innings2 != null 
        ? appState.teams.firstWhere((t) => t.id == currentMatch.innings2!.teamId) 
        : (currentMatch.innings1 != null 
            ? (currentMatch.innings1!.teamId == currentMatch.teamA.id ? currentMatch.teamB : currentMatch.teamA) 
            : currentMatch.teamB);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            flexibleSpace: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: PitchCreasePainter(
                    groundColorLight: const Color(0xFF2E6B3E),
                    groundColorDark: const Color(0xFF1F4D28),
                  ),
                ),
              ),
            ),
            title: const Text(
              'Match Scorecard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: Column(
          children: [
            if (currentMatch.tournamentId != null && currentMatch.tournamentId!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  try {
                    final tour = appState.tournaments.firstWhere((t) => t.id == currentMatch.tournamentId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TournamentDetailScreen(tournament: tour),
                      ),
                    );
                  } catch (_) {
                    CustomSnackBar.show(
                      context,
                      message: 'Tournament details not found.',
                      type: SnackBarType.error,
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTurf.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryTurf.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: AppColors.pitchGold, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentMatch.tournamentName ?? 'Tournament Match',
                          style: const TextStyle(
                            color: AppColors.primaryTurf,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),

                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryTurf, size: 13),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                currentMatch.tournamentId != null && currentMatch.tournamentId!.isNotEmpty ? 8 : 16,
                16,
                8,
              ),
              child: _buildMatchOverviewCard(currentMatch, appState),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderGreen, width: 1),
                ),
              ),
              child: TabBar(
                indicatorColor: AppColors.primaryTurf,
                indicatorWeight: 3,
                labelColor: AppColors.primaryTurf,
                unselectedLabelColor: AppColors.textDarkSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13.0),
                tabs: [
                  Tab(
                    child: Text(
                      team1.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.1),
                    ),
                  ),
                  Tab(
                    child: Text(
                      team2.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildInningsTabContent(context, currentMatch, 1, appState),
                  _buildInningsTabContent(context, currentMatch, 2, appState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInningsTabContent(BuildContext context, CricketMatch match, int inningsNum, AppState appState) {
    final innings = inningsNum == 1 ? match.innings1 : match.innings2;
    if (innings == null) {
      final team1 = match.innings1 != null 
          ? appState.teams.firstWhere((t) => t.id == match.innings1!.teamId) 
          : match.teamA;
      final team2 = match.innings2 != null 
          ? appState.teams.firstWhere((t) => t.id == match.innings2!.teamId) 
          : (match.innings1 != null 
              ? (match.innings1!.teamId == match.teamA.id ? match.teamB : match.teamA) 
              : match.teamB);
      final team = inningsNum == 1 ? team1 : team2;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGreen.withOpacity(0.5), width: 1.5),
                ),
                child: Text(team.logoEmoji, style: const TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 16),
              Text(
                '${team.name} has not batted yet',
                style: const TextStyle(
                  color: AppColors.textDarkMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                match.status == MatchStatus.upcoming 
                    ? 'Scorecard will be available when the match starts.' 
                    : 'Wait for the first innings to complete or start scoring.',
                style: const TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildInningsTable(context, match, innings, appState),
      ),
    );
  }

  Widget _buildMatchOverviewCard(CricketMatch match, AppState appState) {
    final runsA = match.teamAInnings?.runs;
    final wicketsA = match.teamAInnings?.wickets;
    final oversA = match.teamAInnings?.oversCompleted;
    final scoreAStr = runsA != null ? '$runsA/$wicketsA' : 'Yet to Bat';
    final oversAStr = oversA != null ? '($oversA/${match.totalOvers})' : '';

    final runsB = match.teamBInnings?.runs;
    final wicketsB = match.teamBInnings?.wickets;
    final oversB = match.teamBInnings?.oversCompleted;
    final scoreBStr = runsB != null ? '$runsB/$wicketsB' : 'Yet to Bat';
    final oversBStr = oversB != null ? '($oversB/${match.totalOvers})' : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        // color: AppColors.cardBg,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF4D1A9), // Soft light willow wood edge
            Color(0xFFFCF7F0), // Extra light wood face
            Color(0xFFF4D1A9), // Soft light willow wood edge
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderWood, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.venue,
                style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10),
              ),
              Text(
                '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}',
                style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team A (Left aligned completely)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(match.teamA.logoColorHex).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(match.teamA.logoEmoji, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          match.teamA.abbreviation.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scoreAStr,
                          style: TextStyle(
                            color: runsA != null ? AppColors.woodMahogany : AppColors.textDarkMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: runsA != null ? 15 : 11,
                          ),
                        ),
                        if (oversAStr.isNotEmpty)
                          Text(
                            oversAStr,
                            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10,fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  match.status == MatchStatus.live ? 'LIVE' : 'VS',
                  style: TextStyle(
                    color: match.status == MatchStatus.live ? Colors.redAccent : AppColors.textDarkDisabled,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              // Team B (Right aligned completely)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scoreBStr,
                          style: TextStyle(
                            color: runsB != null ? AppColors.woodMahogany : AppColors.textDarkMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: runsB != null ? 15 : 11,
                          ),
                        ),
                        if (oversBStr.isNotEmpty)
                          Text(
                            oversBStr,
                            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10,fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(match.teamB.logoColorHex).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(match.teamB.logoEmoji, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          match.teamB.abbreviation.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (match.status == MatchStatus.completed) ...[
            const SizedBox(height: 10),
            Text(
              match.resultString,
              style: const TextStyle(color: AppColors.woodMahogany, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ] else if (match.tossWinnerId != null) ...[
            const SizedBox(height: 10),
            Text(
              '${appState.teams.firstWhere((t) => t.id == match.tossWinnerId).name} won toss & elected to ${match.tossDecision}',
              style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11,fontWeight:FontWeight.w500),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInningsTable(BuildContext context, CricketMatch match, MatchTeamInnings innings, AppState appState) {
    final team = appState.teams.firstWhere((t) => t.id == innings.teamId);
    final oppTeamId = team.id == match.teamA.id ? match.teamB.id : match.teamA.id;
    final oppTeam = appState.teams.firstWhere((t) => t.id == oppTeamId);
    
    final hasStarted = match.status == MatchStatus.live || match.status == MatchStatus.completed || innings.events.isNotEmpty;
    final activeBowlers = hasStarted 
        ? oppTeam.players.where((p) => (match.bowlerBallsBowled[p.id] ?? 0) > 0 || (match.bowlerRunsConceded[p.id] ?? 0) > 0).toList()
        : oppTeam.players.take(2).toList();

    // Separate batted players (in batting order) from yet-to-bat players
    final battedPlayers = team.players.where((player) {
      if (!hasStarted) return true;
      final isCurrentBatsman = player.id == match.striker?.id || player.id == match.nonStriker?.id;
      return match.playerBallsFaced[player.id] != null || isCurrentBatsman;
    }).toList();

    if (hasStarted) {
      final battingOrder = innings.battingOrder;
      battedPlayers.sort((a, b) {
        final indexA = battingOrder.indexOf(a.id);
        final indexB = battingOrder.indexOf(b.id);
        if (indexA == -1 && indexB == -1) return 0;
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    }

    final yetToBatPlayers = hasStarted
        ? team.players.where((player) {
            final isCurrentBatsman = player.id == match.striker?.id || player.id == match.nonStriker?.id;
            return !(match.playerBallsFaced[player.id] != null || isCurrentBatsman);
          }).toList()
        : <Player>[];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Batting Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          color: AppColors.appBarBg,
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Batsman', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text('R', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
              Expanded(
                child: Text('B', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
              Expanded(
                child: Text('4s', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
              Expanded(
                child: Text('6s', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 2,
                child: Text('SR', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
        
        // Batting Entries
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: battedPlayers.length,
          itemBuilder: (context, index) {
            final player = battedPlayers[index];
            
            int runs = match.playerRuns[player.id] ?? (hasStarted ? 0 : (index == 0 ? 34 : (index == 1 ? 21 : 5)));
            int balls = match.playerBallsFaced[player.id] ?? (hasStarted ? 0 : (index == 0 ? 22 : (index == 1 ? 16 : 8)));
            
            int fours = hasStarted 
                ? innings.events.where((e) => e.batsmanName == player.name && e.runs == 4 && !e.isWide && (e.isNoBall ? e.isRunsOffBat : true)).length
                : ((runs * 0.4).toInt() ~/ 4);
            int sixes = hasStarted 
                ? innings.events.where((e) => e.batsmanName == player.name && e.runs == 6 && !e.isWide && (e.isNoBall ? e.isRunsOffBat : true)).length
                : ((runs * 0.2).toInt() ~/ 6);
            double sr = balls > 0 ? (runs / balls) * 100 : 0.0;

            final isOut = hasStarted && innings.events.any((e) => e.isWicket && e.batsmanName == player.name);
            final isCurrentBatsman = hasStarted && (player.id == match.striker?.id || player.id == match.nonStriker?.id);
            final hasBatted = hasStarted && (match.playerBallsFaced[player.id] != null || isCurrentBatsman);

            String statusStr = 'yet to bat';
            if (!hasStarted) {
              statusStr = index < 2 ? 'not out' : 'c. sub b. bowler';
            } else if (isOut) {
              final wicketEvent = innings.events.firstWhere((e) => e.isWicket && e.batsmanName == player.name);
              statusStr = wicketEvent.wicketType.isNotEmpty
                  ? '${wicketEvent.wicketType} b. ${wicketEvent.bowlerName}'
                  : 'out';
            } else if (isCurrentBatsman) {
              statusStr = 'not out*';
            } else if (hasBatted) {
              statusStr = 'not out';
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.dividerGreen, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${player.name}${player.id == team.captainId && player.role == 'Wicketkeeper' ? ' (C)(Wk)' : player.id == team.captainId ? ' (C)' : player.role == 'Wicketkeeper' ? ' (Wk)' : ''}',
                          style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          statusStr,
                          style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text('$runs', style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    child: Text('$balls', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    child: Text('$fours', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    child: Text('$sixes', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(sr.toStringAsFixed(1), style: const TextStyle(color: AppColors.accentCrease, fontSize: 13), textAlign: TextAlign.right),
                  ),
                ],
              ),
            );
          },
        ),

        // Extras and Total Summary Rows
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.dividerGreen, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Extras',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '${innings.totalExtras} (wd ${innings.wideExtras}, nb ${innings.noBallExtras}, lb ${innings.legByeExtras}, b ${innings.byeExtras}, pen ${innings.penaltyExtras})',
                style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: const BoxDecoration(
            color: AppColors.appBarBg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '${innings.runs}/${innings.wickets} (${innings.oversCompleted} Ov, RR: ${innings.runRate.toStringAsFixed(2)})',
                style: const TextStyle(color: AppColors.primaryTurf, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        
        if (hasStarted && yetToBatPlayers.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.dividerGreen, width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yet to bat: ',
                  style: TextStyle(
                    color: AppColors.textDarkSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    yetToBatPlayers.map((p) => p.name).join(', '),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Bowling Table Header
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          color: AppColors.appBarBg,
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Bowler', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text('O', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
              Expanded(
                child: Text('M', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
              Expanded(
                child: Text('R', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
              Expanded(
                child: Text('W', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 2,
                child: Text('Econ', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
            ],
          ),
        ),

        // Bowling Entries (Opposition team bowlers)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeBowlers.length,
          itemBuilder: (context, index) {
            final player = activeBowlers[index];
            
            int balls = match.bowlerBallsBowled[player.id] ?? (hasStarted ? 0 : (index == 0 ? 12 : 6));
            int runs = match.bowlerRunsConceded[player.id] ?? (hasStarted ? 0 : (index == 0 ? 14 : 9));
            int wickets = match.bowlerWickets[player.id] ?? (hasStarted ? 0 : (index == 0 ? 2 : 0));
            
            double overs = (balls ~/ 6) + (balls % 6) / 10;
            double econ = balls > 0 ? (runs / balls) * 6 : 0.0;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.dividerGreen, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      '${player.name}${player.id == oppTeam.captainId && player.role == 'Wicketkeeper' ? ' (C)(Wk)' : player.id == oppTeam.captainId ? ' (C)' : player.role == 'Wicketkeeper' ? ' (Wk)' : ''}',
                      style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(overs.toStringAsFixed(1), style: const TextStyle(color: AppColors.textDark, fontSize: 13), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    child: const Text('0', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    child: Text('$runs', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    child: Text('$wickets', style: TextStyle(color: AppColors.pitchGold, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(econ.toStringAsFixed(2), style: const TextStyle(color: AppColors.accentCrease, fontSize: 13), textAlign: TextAlign.right),
                  ),
                ],
              ),
            );
          },
        ),
        if (innings.events.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'BALL BY BALL TIMELINE',
            style: TextStyle(
              color: AppColors.primaryTurf,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildOversTimelineList(innings),
        ],
      ],
    );
  }

  Widget _buildOversTimelineList(MatchTeamInnings innings) {
    final List<List<BallEvent>> oversList = [];
    List<BallEvent> currentOver = [];
    int legalBalls = 0;
    
    for (var event in innings.events) {
      currentOver.add(event);
      if (event.countsAsBall) {
        legalBalls++;
        if (legalBalls == 6) {
          oversList.add(currentOver);
          currentOver = [];
          legalBalls = 0;
        }
      }
    }
    if (currentOver.isNotEmpty) {
      oversList.add(currentOver);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGreen, width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: oversList.length,
        separatorBuilder: (context, index) => const Divider(color: AppColors.dividerGreen, height: 12),
        itemBuilder: (context, index) {
          final overEvents = oversList[index];
          final runs = overEvents.fold<int>(0, (sum, ev) => sum + ev.runsAddedToTeam);
          final wickets = overEvents.where((ev) => ev.isWicket).length;
          
          String overSummary = '$runs run${runs != 1 ? 's' : ''}';
          if (wickets > 0) {
            overSummary += ', $wickets Wkt${wickets != 1 ? 's' : ''}';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Over ${index + 1}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        overSummary,
                        style: const TextStyle(
                          color: AppColors.textDarkMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: overEvents.map((ev) => _buildOverBallCircle(ev)).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverBallCircle(BallEvent event) {
    Color bg = AppColors.logoBg;
    Color textCol = Colors.black;
    String text = '${event.runs}';

    if (event.isWicket) {
      bg = Colors.red;
      text = event.runs > 0 ? 'W+${event.runs}' : 'W';
      textCol = Colors.white;
    } else if (event.isWide) {
      bg = Colors.amber.shade900;
      text = event.runs > 0 ? 'Wd+${event.runs}' : 'Wd';
      textCol = Colors.white;
    } else if (event.isNoBall) {
      bg = Colors.orange.shade800;
      text = event.runs > 0 ? 'Nb+${event.runs}' : 'Nb';
      textCol = Colors.white;
    } else if (event.isLegBye) {
      bg = Colors.teal.shade800;
      text = event.runs > 0 ? 'Lb+${event.runs}' : 'Lb';
      textCol = Colors.white;
    } else if (event.isBye) {
      bg = Colors.cyan.shade800;
      text = event.runs > 0 ? 'B+${event.runs}' : 'B';
      textCol = Colors.white;
    } else if (event.isPenalty) {
      bg = Colors.deepPurple.shade800;
      text = 'Pen+${event.runs}';
      textCol = Colors.white;
    } else if (event.runs == 4) {
      bg = AppColors.woodLight;
      text = '4';
      textCol = Colors.black;
    } else if (event.runs == 6) {
      bg = AppColors.accentCrease;
      text = '6';
      textCol = Colors.black;
    } else if (event.runs == 0) {
      bg = AppColors.leatherWhite;
      text = '•';
      textCol = Colors.black;
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: bg == AppColors.leatherWhite 
            ? Border.all(color: AppColors.borderGreen, width: 1) 
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontWeight: FontWeight.bold,
          fontSize: text.length > 3 ? 7 : (text.length > 2 ? 8 : 10),
        ),
      ),
    );
  }
}
