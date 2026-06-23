import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
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
            Container(
              color: Colors.transparent,
              height: 38,
              child: const TabBar(
                indicatorColor: AppColors.primaryTurf,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorPadding: EdgeInsets.only(bottom: 4),
                labelColor: AppColors.primaryTurf,
                unselectedLabelColor: AppColors.textDarkMuted,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(text: 'SCORECARD'),
                  Tab(text: 'BALL-BY-BALL'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildScorecardTab(context, currentMatch, appState),
                  _buildBallByBallTab(context, currentMatch, appState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardTab(BuildContext context, CricketMatch match, AppState appState) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMatchOverviewCard(match, appState),
            const SizedBox(height: 20),
            
            // Innings 1 Scorecard
            if (match.innings1 != null) ...[
              _buildInningsHeader(context, match, 1, appState),
              const SizedBox(height: 10),
              _buildInningsTable(context, match, match.innings1!, appState),
              const SizedBox(height: 24),
            ],

            // Innings 2 Scorecard
            if (match.innings2 != null) ...[
              _buildInningsHeader(context, match, 2, appState),
              const SizedBox(height: 10),
              _buildInningsTable(context, match, match.innings2!, appState),
              const SizedBox(height: 24),
            ],
          ],
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewTeam(match.teamA, match.innings1?.runs, match.innings1?.wickets, match.innings1?.oversCompleted),
              const Text('VS', style: TextStyle(color: AppColors.textDarkDisabled, fontWeight: FontWeight.bold, fontSize: 18)),
              _buildOverviewTeam(match.teamB, match.innings2?.runs, match.innings2?.wickets, match.innings2?.oversCompleted),
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
          ),
          if (match.status == MatchStatus.completed) ...[
            const SizedBox(height: 8),
            Text(
              match.resultString,
              style: TextStyle(color: AppColors.pitchGold, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
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

  Widget _buildInningsHeader(BuildContext context, CricketMatch match, int inningsNum, AppState appState) {
    final innings = inningsNum == 1 ? match.innings1 : match.innings2;
    final teamId = innings?.teamId;
    final teamName = teamId != null ? appState.teams.firstWhere((t) => t.id == teamId).name : (inningsNum == 1 ? match.teamA.name : match.teamB.name);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$teamName Innings',
          style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          '${innings?.runs ?? 0}/${innings?.wickets ?? 0} (${innings?.oversCompleted ?? 0} Ov)',
          style: const TextStyle(color: AppColors.accentCrease, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInningsTable(BuildContext context, CricketMatch match, MatchTeamInnings innings, AppState appState) {
    // Generate batting entries
    final team = appState.teams.firstWhere((t) => t.id == innings.teamId);
    
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
          itemCount: team.players.length,
          itemBuilder: (context, index) {
            final player = team.players[index];
            // Mock batsman runs in this match
            int runs = match.playerRuns[player.id] ?? (index == 0 ? 34 : (index == 1 ? 21 : 5));
            int balls = match.playerBallsFaced[player.id] ?? (index == 0 ? 22 : (index == 1 ? 16 : 8));
            int fours = (runs * 0.4).toInt() ~/ 4;
            int sixes = (runs * 0.2).toInt() ~/ 6;
            double sr = balls > 0 ? (runs / balls) * 100 : 0.0;

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
                          index < 2 ? 'not out' : 'c. sub b. bowler',
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
          itemCount: 2, // Mocking top 2 bowlers
          itemBuilder: (context, index) {
            final oppTeamId = team.id == match.teamA.id ? match.teamB.id : match.teamA.id;
            final oppTeam = appState.teams.firstWhere((t) => t.id == oppTeamId);
            final player = oppTeam.players[index % oppTeam.players.length];
            
            int balls = match.bowlerBallsBowled[player.id] ?? (index == 0 ? 12 : 6);
            int runs = match.bowlerRunsConceded[player.id] ?? (index == 0 ? 14 : 9);
            int wickets = match.bowlerWickets[player.id] ?? (index == 0 ? 2 : 0);
            
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

  Widget _buildBallByBallTab(BuildContext context, CricketMatch match, AppState appState) {
    final currentInnings = match.currentInnings;
    
    // Reverse events for chronological top-down display (latest first)
    final events = currentInnings.events.reversed.toList();

    if (events.isEmpty) {
      // Mock events for completed/existing matches to showcase high fidelity
      return _buildMockCommentary(match);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final event = events[index];
        final ballIndex = events.length - index;
        final overNum = ((ballIndex - 1) ~/ 6) + 1;
        final ballNum = ((ballIndex - 1) % 6) + 1;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.dividerGreen, width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    '$overNum.$ballNum',
                    style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _buildBallOutcomeCircle(event),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${event.bowlerName} to ${event.batsmanName}',
                      style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBallOutcomeCircle(BallEvent event) {
    Color bg = AppColors.logoBg;
    Color textCol = Colors.white;
    String label = '${event.runs}';

    if (event.isWicket) {
      bg = Colors.red;
      label = 'W';
    } else if (event.isWide) {
      bg = Colors.amber.shade700;
      label = 'Wd';
    } else if (event.isNoBall) {
      bg = Colors.orange.shade800;
      label = 'NB';
    } else if (event.runs == 4) {
      bg = AppColors.woodLight;
      label = '4';
      textCol = Colors.black;
    } else if (event.runs == 6) {
      bg = AppColors.accentCrease;
      label = '6';
      textCol = Colors.black;
    } else if (event.runs == 0) {
      bg = AppColors.leatherWhite;
      label = '•';
      textCol = Colors.black;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textCol,
          fontWeight: FontWeight.bold,
          fontSize: event.isWide || event.isNoBall ? 10 : 12,
        ),
      ),
    );
  }

  Widget _buildMockCommentary(CricketMatch match) {
    // Generate beautiful mock comments
    final mockEvents = [
      {'over': '5.2', 'runs': '6', 'desc': 'Boom! Virat Sharma hits a massive six over mid-wicket off Ravindra Jadeja. Sublime shot!'},
      {'over': '5.1', 'runs': '1', 'desc': 'Jadeja pitches it short, nudged gently towards cover for a single.'},
      {'over': '4.6', 'runs': 'W', 'desc': 'OUT! Rohit Rahul is caught at long-on by MS Dhoni. Big breakthrough!'},
      {'over': '4.5', 'runs': '4', 'desc': 'Flicked off the pads elegantly! Rohit Rahul hits a beautiful boundary through deep square leg.'},
      {'over': '4.4', 'runs': '0', 'desc': 'Excellent delivery, right blockhole. Defended back to the bowler.'},
      {'over': '4.3', 'runs': 'Wd', 'desc': 'Wide ball down the leg side.'},
      {'over': '4.2', 'runs': '2', 'desc': 'Driven through extra cover. Good running between wickets for two runs.'},
      {'over': '4.1', 'runs': '1', 'desc': 'Pushed to mid-off for a quick single.'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockEvents.length,
      itemBuilder: (context, index) {
        final ev = mockEvents[index];
        final isWicket = ev['runs'] == 'W';
        final isSix = ev['runs'] == '6';
        final isFour = ev['runs'] == '4';
        final isWide = ev['runs'] == 'Wd';
        final isDot = ev['runs'] == '0';
        
        Color bg = AppColors.logoBg;
        Color textCol = Colors.white;
        if (isWicket) bg = Colors.red;
        if (isWide) bg = Colors.amber.shade700;
        if (isFour) {
          bg = AppColors.woodLight;
          textCol = Colors.black;
        }
        if (isSix) {
          bg = AppColors.accentCrease;
          textCol = Colors.black;
        }
        if (isDot) {
          bg = AppColors.leatherWhite;
          textCol = Colors.black;
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.dividerGreen, width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    ev['over']!,
                    style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ev['runs']!,
                      style: TextStyle(
                        color: textCol,
                        fontWeight: FontWeight.bold,
                        fontSize: isWide ? 10 : 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bowler to Batsman',
                      style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ev['desc']!,
                      style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
