import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../models/player_model.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import 'main_navigation_screen.dart';

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
    final String label1 = team1.name;
    final String label2 = team2.name;

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  Tab(text: label1),
                  Tab(text: label2),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGreen, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.venue,
                style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
              ),
              Text(
                '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}',
                style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
              ),
            ],
          ),
          const Divider(color: AppColors.borderGreen, height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewTeam(match.teamA, match.teamAInnings?.runs, match.teamAInnings?.wickets, match.teamAInnings?.oversCompleted),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('VS', style: TextStyle(color: AppColors.textDarkDisabled, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Expanded(
                child: _buildOverviewTeam(match.teamB, match.teamBInnings?.runs, match.teamBInnings?.wickets, match.teamBInnings?.oversCompleted),
              ),
            ],
          ),
          const Divider(color: AppColors.borderGreen, height: 20),
          Text(
            match.status == MatchStatus.upcoming
                ? 'Match starting soon'
                : (match.tossWinnerId != null
                    ? '${appState.teams.firstWhere((t) => t.id == match.tossWinnerId).name} won the toss & elected to ${match.tossDecision}'
                    : 'Toss details not updated'),
            style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: null,
          ),
          if (match.status == MatchStatus.completed) ...[
            const SizedBox(height: 8),
            Text(
              match.resultString,
              style: const TextStyle(color: AppColors.pitchGold, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewTeam(Team team, int? runs, int? wickets, double? overs) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(team.logoColorHex).withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Color(team.logoColorHex).withOpacity(0.5), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(team.logoEmoji, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(height: 8),
        Text(
          team.name,
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          runs != null ? '$runs/$wickets' : 'Yet to Bat',
          style: TextStyle(
            color: runs != null ? AppColors.accentCrease : AppColors.textDarkMuted,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (overs != null)
          Text(
            '($overs Ov)',
            style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
          ),
      ],
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
                          player.name,
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
                      player.name,
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
      ],
    );
  }

}
