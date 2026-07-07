import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_model.dart';
import '../../state/app_state.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/custom_snackbar.dart';
import '../main_navigation_screen.dart';

class LiveScoringScreen extends StatelessWidget {
  final CricketMatch match;

  const LiveScoringScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // Find the latest state of the match from appState list
    final currentMatch = appState.matches.firstWhere((m) => m.id == match.id, orElse: () => match);
    
    // Safely retrieve teams
    final battingTeam = currentMatch.battingTeam;
    final bowlingTeam = currentMatch.bowlingTeam;
    final innings = currentMatch.currentInnings;
    
    final isSecondInnings = currentMatch.currentInningsNum == 2 || currentMatch.currentInningsNum == 4;
    final target = currentMatch.currentInningsNum == 2 
        ? (currentMatch.innings1!.runs + 1) 
        : (currentMatch.currentInningsNum == 4 ? (currentMatch.superOverInnings1!.runs + 1) : null);
    
    // Calculate balls bowled in current over
    final currentOverBalls = innings.ballsBowled % 6;
    final oversCompletedText = '${innings.ballsBowled ~/ 6}.$currentOverBalls';

    // Retrieve all events in the current over (including Wides and No Balls)
    final List<BallEvent> currentOverEvents = [];
    int legalBallsCount = 0;
    final targetLegalCount = currentOverBalls;
    
    for (int i = innings.events.length - 1; i >= 0; i--) {
      final ev = innings.events[i];
      if (ev.countsAsBall) {
        if (legalBallsCount >= targetLegalCount) {
          break;
        }
        legalBallsCount++;
      }
      currentOverEvents.add(ev);
    }
    final recentEvents = currentOverEvents.reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () {
              appState.setActiveScoringMatch(null);
              Navigator.pop(context);
            },
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
          title: Text(
            currentMatch.currentInningsNum >= 3
                ? 'Super Over Scoring'
                : 'Live Scoring – Overs: ${currentMatch.totalOvers}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            if (currentMatch.isOnBreak)
              IconButton(
                icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                tooltip: 'Resume Play',
                onPressed: () => appState.endMatchBreak(currentMatch.id),
              )
            else
              IconButton(
                icon: const Icon(Icons.incomplete_circle_rounded, color: Colors.white),
                tooltip: 'Start Break',
                onPressed: () => _showStartBreakDialog(context, currentMatch, appState),
              ),
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              tooltip: 'Complete Match',
              onPressed: () => _showCompleteMatchDialog(context, currentMatch, appState),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Match Header Info Card
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderWood, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: currentMatch.currentInningsNum >= 3
                                  ? AppColors.woodMahogany.withOpacity(0.5)
                                  : AppColors.primaryTurf.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentMatch.currentInningsNum >= 3 ? '⚡ SUPER OVER BATTING' : 'BATTING TEAM',
                              style: TextStyle(
                                color: currentMatch.currentInningsNum >= 3
                                    ? AppColors.cardBg
                                    : AppColors.primaryTurf,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            battingTeam.name,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${innings.runs}/${innings.wickets}',
                                style: const TextStyle(
                                  color: AppColors.primaryTurf,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '($oversCompletedText ov)',
                                style: const TextStyle(
                                  color: AppColors.textDarkSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.textDarkSecondary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Run Rate: ${innings.runRate.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.textDarkSecondary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isSecondInnings && target != null) ...[
                          if (currentMatch.resultString == "Match Tied" && currentMatch.currentInningsNum < 3) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1),
                              ),
                              child: const Text(
                                'Match Tied',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.pitchGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.pitchGold.withOpacity(0.4), width: 1),
                              ),
                              child: Text(
                                'Target: $target',
                                style: const TextStyle(
                                  color: AppColors.woodMahogany,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (currentMatch.status != MatchStatus.completed) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Need ${target - innings.runs <= 0 ? 0 : target - innings.runs} from ${((currentMatch.currentInningsNum >= 3 ? 1 : currentMatch.totalOvers) * 6) - innings.ballsBowled} b',
                                style: const TextStyle(
                                  color: AppColors.textDarkMuted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
                if (currentMatch.status == MatchStatus.completed) ...[
                  const Divider(color: AppColors.borderWood, height: 10),
                  Text(
                    currentMatch.resultString,
                    style: const TextStyle(
                      color: AppColors.woodMahogany,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: null,
                  ),
                ],
                const Divider(color: AppColors.borderWood, height: 12),
                
                // Current Over Tracker
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'THIS OVER: ',
                      style: TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: recentEvents.isEmpty
                            ? [
                                Text(
                                  'Over starting...',
                                  style: TextStyle(
                                    color: AppColors.textDarkMuted.withOpacity(0.6),
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              ]
                            : recentEvents.map((ev) => _buildOverBallCircle(ev)).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: currentMatch.isOnBreak
                ? _buildBreakView(context, currentMatch, appState)
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 15, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // Active Batsmen
                        if (!(currentMatch.resultString == "Match Tied" && !currentMatch.isSuperOverPlayed)) ...[
                          _buildBatsmenCard(context, currentMatch, battingTeam, appState),
                          const SizedBox(height: 15),
                        ],
                        
                        // Active Bowler
                        if (!(currentMatch.resultString == "Match Tied" && !currentMatch.isSuperOverPlayed)) ...[
                          _buildBowlerCard(context, currentMatch, bowlingTeam, appState),
                          const SizedBox(height: 15),
                        ],

                        // Scoring Buttons Grid wrapped in a card Container
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGreen, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTurf.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SCORING PAD',
                                    style: TextStyle(
                                      color: AppColors.primaryTurf,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildScoringPad(context, currentMatch, appState),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverBallCircle(BallEvent event) {
    Color bg = AppColors.guestCardBg;
    Color textCol = Colors.black; // High-contrast black text by default on light cream background
    String text = '${event.runs}';

    if (event.isWicket) {
      bg = Colors.red;
      text = event.runs > 0 ? 'W+${event.runs}' : 'W';
      textCol = Colors.white;
    } else if (event.isWide) {
      bg = Colors.amber.shade900; // Darker amber for high contrast with white text
      text = event.runs > 0 ? 'Wd+${event.runs}' : 'Wd';
      textCol = Colors.white;
    } else if (event.isNoBall) {
      bg = Colors.orange.shade800; // Dark orange
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
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: bg == AppColors.leatherWhite 
            ? Border.all(color: AppColors.borderGreen, width: 0.8) 
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontWeight: FontWeight.bold,
          fontSize: text.length > 3 ? 6.5 : (text.length > 2 ? 7.5 : 9.5),
        ),
      ),
    );
  }

  Widget _buildBatsmenCard(BuildContext context, CricketMatch match, Team battingTeam, AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg, // Warm cream/wood theme card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGreen, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTurf.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_cricket, color: AppColors.primaryTurf, size: 12),
                      const SizedBox(width: 4),
                      const Text(
                        'BATTING',
                        style: TextStyle(
                          color: AppColors.primaryTurf,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => appState.changeStriker(),
                  icon: const Icon(Icons.swap_horiz, size: 12, color: AppColors.primaryTurf),
                  label: const Text(
                    'Rotate Strike',
                    style: TextStyle(
                      color: AppColors.primaryTurf,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryTurf, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Batting Column Headers (Shown only once at the top)
            if (match.striker != null || match.nonStriker != null) ...[
              Row(
                children: [
                  const Icon(Icons.sports_cricket, color: Colors.transparent, size: 14),
                  const SizedBox(width: 6),
                  const Expanded(
                    flex: 5,
                    child: Text(
                      'BATSMAN',
                      style: TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _buildBatsmanHeaderItem('R'),
                  _buildBatsmanHeaderItem('B'),
                  _buildBatsmanHeaderItem('4S'),
                  _buildBatsmanHeaderItem('6S'),
                  _buildBatsmanHeaderItem('SR', flex: 2),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(color: AppColors.borderGreen, height: 1),
              const SizedBox(height: 4),
            ],
            
            // Striker Row
            _buildBatsmanRow(context, match, match.striker, true, battingTeam, appState),
            const Divider(color: AppColors.borderGreen, height: 10,thickness: 0.6,),
            // Non-Striker Row
            _buildBatsmanRow(context, match, match.nonStriker, false, battingTeam, appState),
          ],
        ),
      ),
    );
  }

  Widget _buildBatsmanHeaderItem(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 9.5, fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildBatsmanRow(
    BuildContext context,
    CricketMatch match,
    Player? player,
    bool isStriker,
    Team battingTeam,
    AppState appState,
  ) {
    if (player == null || player.id == 'dummy') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
        decoration: BoxDecoration(
          color: AppColors.woodLight.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderWood, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                 Icon(Icons.person_add_alt_1_rounded, color: AppColors.woodMahogany, size: 16),
                const SizedBox(width: 6),
                Text(
                  isStriker ? 'Select Striker *' : 'Select Non-Striker',
                  style: TextStyle(color: AppColors.woodMahogany, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.woodMahogany,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                final activeStrikerId = match.striker?.id;
                final activeNonStrikerId = match.nonStriker?.id;
                final availablePlayers = battingTeam.players.where((p) {
                  final hasBatted = match.currentInnings.battingOrder.contains(p.id);
                  final isAtCrease = p.id == activeStrikerId || p.id == activeNonStrikerId;
                  return !hasBatted && !isAtCrease;
                }).toList();

                _showPlayerSelector(context, availablePlayers, (newPlayer) {
                  appState.changeStrikerPlayer(newPlayer, isStriker);
                }, isBowler: false);
              },
              child: const Text('SELECT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final runs = match.currentInningsNum >= 3
        ? match.currentInnings.events.where((e) => e.batsmanName == player.name).fold(0, (sum, e) => sum + e.runsAddedToBatsman)
        : match.playerRuns[player.id] ?? 0;
    final balls = match.currentInningsNum >= 3
        ? match.currentInnings.events.where((e) => e.batsmanName == player.name && e.countsAsBall).length
        : match.playerBallsFaced[player.id] ?? 0;
    final fours = match.currentInnings.events.where((e) => e.batsmanName == player.name && e.runs == 4 && !e.isWide && (e.isNoBall ? e.isRunsOffBat : true)).length;
    final sixes = match.currentInnings.events.where((e) => e.batsmanName == player.name && e.runs == 6 && !e.isWide && (e.isNoBall ? e.isRunsOffBat : true)).length;
    final sr = balls > 0 ? (runs / balls) * 100 : 0.0;

    final content = Row(
      children: [
        Icon(
          isStriker ? Icons.sports_cricket : Icons.sports_cricket_outlined,
          color: isStriker ? AppColors.woodMahogany : AppColors.textDarkDisabled,
          size: 16,
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 5,
          child: Text(
            '${player.name}${player.id == battingTeam.captainId && player.role == 'Wicketkeeper' ? ' (C)(Wk)' : player.id == battingTeam.captainId ? ' (C)' : player.role == 'Wicketkeeper' ? ' (Wk)' : ''}',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: isStriker ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildBatsmanValueItem('$runs', isHighlight: isStriker),
        _buildBatsmanValueItem('$balls'),
        _buildBatsmanValueItem('$fours'),
        _buildBatsmanValueItem('$sixes'),
        _buildBatsmanValueItem(sr.toStringAsFixed(1), flex: 2, isHighlight: isStriker),
      ],
    );

    if (isStriker) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryTurf.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryTurf.withOpacity(0.2), width: 0.5),
        ),
        child: content,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        child: content,
      );
    }
  }

  Widget _buildBatsmanValueItem(String value, {int flex = 1, bool isHighlight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: TextStyle(
          color: isHighlight ? AppColors.primaryTurf : AppColors.textDark,
          fontSize: 12,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildBowlerCard(BuildContext context, CricketMatch match, Team bowlingTeam, AppState appState) {
    final bowler = match.currentBowler;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg, // Warm scorer card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderWood, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.woodMahogany.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_baseball_rounded, color: AppColors.woodMahogany, size: 12),
                      const SizedBox(width: 4),
                      const Text(
                        'BOWLING',
                        style: TextStyle(
                          color: AppColors.woodMahogany,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showPlayerSelector(context, bowlingTeam.players, (newBowler) {
                    appState.changeBowler(newBowler);
                  }, isBowler: true, match: match),
                  icon: const Icon(Icons.swap_horiz, size: 12, color: AppColors.woodMahogany),
                  label: const Text(
                    'Change Bowler',
                    style: TextStyle(
                      color: AppColors.woodMahogany,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.woodMahogany, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (bowler == null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryTurf.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGreen, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryTurf, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Select Bowler *',
                          style: TextStyle(color: AppColors.primaryTurf, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTurf,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showPlayerSelector(context, bowlingTeam.players, (newBowler) {
                        appState.changeBowler(newBowler);
                      }, isBowler: true, match: match),
                      child: const Text('SELECT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            else ...[
              Builder(
                builder: (context) {
                  final bowlerBalls = match.currentInningsNum >= 3
                      ? match.currentInnings.events.where((e) => e.bowlerName == bowler.name && e.countsAsBall).length
                      : match.bowlerBallsBowled[bowler.id] ?? 0;

                  final bowlerRuns = match.currentInningsNum >= 3
                      ? match.currentInnings.events.where((e) => e.bowlerName == bowler.name).fold(0, (sum, e) => sum + e.runsAddedToTeam)
                      : match.bowlerRunsConceded[bowler.id] ?? 0;

                  final bowlerWickets = match.currentInningsNum >= 3
                      ? match.currentInnings.events.where((e) => e.bowlerName == bowler.name && e.isWicket && e.wicketType != 'Run Out').length
                      : match.bowlerWickets[bowler.id] ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Headers
                      Row(
                        children: [
                          const Icon(Icons.sports_baseball_rounded, color: Colors.transparent, size: 16),
                          const SizedBox(width: 6),
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'BOWLER',
                              style: TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildBowlerHeaderItem('O'),
                          _buildBowlerHeaderItem('R'),
                          _buildBowlerHeaderItem('W'),
                          _buildBowlerHeaderItem('ECON'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Divider(color: AppColors.borderWood, height: 1, thickness: 0.8),
                      const SizedBox(height: 5),

                      // Row 2: Bowler Name & Values
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                        decoration: BoxDecoration(
                          color: AppColors.woodMahogany.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.woodMahogany.withOpacity(0.2), width: 0.8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.sports_baseball_rounded, color: AppColors.woodMahogany, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${bowler.name}${bowler.id == bowlingTeam.captainId && bowler.role == 'Wicketkeeper' ? ' (C)(Wk)' : bowler.id == bowlingTeam.captainId ? ' (C)' : bowler.role == 'Wicketkeeper' ? ' (Wk)' : ''}',
                                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildBowlerValueItem('${bowlerBalls ~/ 6}.${bowlerBalls % 6}'),
                            _buildBowlerValueItem('$bowlerRuns'),
                            _buildBowlerValueItem('$bowlerWickets'),
                            _buildBowlerValueItem(_calculateEcon(bowlerRuns, bowlerBalls)),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBowlerHeaderItem(String label) {
    return Expanded(
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 9.5, fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildBowlerValueItem(String value) {
    return Expanded(
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  void _showStartSuperOverDialog(BuildContext context, CricketMatch match, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Start Super Over?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will re-open the match in Live Scoring mode for a 1-over tie-breaker. Are you sure you want to proceed?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              appState.startSuperOver(match.id);
            },
            child: const Text('PROCEED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _calculateEcon(int runs, int balls) {
    if (balls == 0) return '0.0';
    return ((runs / balls) * 6).toStringAsFixed(1);
  }

  Widget _buildScoringPad(BuildContext context, CricketMatch match, AppState appState) {
    final isTiedState = match.resultString == "Match Tied" && !match.isSuperOverPlayed;

    if (match.status == MatchStatus.completed || isTiedState) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.pitchGold,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              match.status == MatchStatus.completed ? 'MATCH COMPLETED' : 'MATCH TIED',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              match.resultString,
              style: const TextStyle(
                color: AppColors.accentCrease,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: null,
            ),
            const SizedBox(height: 24),
            if (isTiedState) ...[
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        appState.completeMatch(match.id, forceComplete: true);
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 18, color: Colors.white),
                      label: const Text('MARK MATCH AS COMPLETED (TIE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTurf,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showStartSuperOverDialog(context, match, appState);
                      },
                      icon: const Icon(Icons.bolt, size: 18, color: Colors.white),
                      label: const Text('START SUPER OVER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      appState.setActiveScoringMatch(null);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.dashboard_rounded, size: 16, color: AppColors.primaryTurf),
                    label: const Text('Return to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryTurf)),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  appState.setActiveScoringMatch(null);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                label: const Text('Return to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTurf,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final hasPlayers = match.striker != null && match.nonStriker != null && match.currentBowler != null;

    // Row 4: OUT button & UNDO button
    final canUndo = match.currentInnings.events.isNotEmpty ||
        (match.currentInningsNum == 2 &&
            match.innings2?.events.isEmpty == true &&
            match.innings1 != null &&
            match.innings1!.events.isNotEmpty) ||
        (match.currentInningsNum == 3 &&
            match.superOverInnings1?.events.isEmpty == true &&
            match.innings2 != null &&
            match.innings2!.events.isNotEmpty) ||
        (match.currentInningsNum == 4 &&
            match.superOverInnings2?.events.isEmpty == true &&
            match.superOverInnings1 != null &&
            match.superOverInnings1!.events.isNotEmpty);

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.6,
          children: [
            // Row 1: 0, 1, 2, 3
            _buildScoringButton(context, title: '0', subtitle: 'Dot', isEnabled: hasPlayers, color: const Color(0xFF4A5D4E), onTap: () {
              _recordBallEvent(context, match, appState, runs: 0);
            }),
            _buildScoringButton(context, title: '1', subtitle: 'Run', isEnabled: hasPlayers, color: AppColors.primaryTurf, onTap: () {
              _recordBallEvent(context, match, appState, runs: 1);
            }),
            _buildScoringButton(context, title: '2', subtitle: 'Runs', isEnabled: hasPlayers, color: AppColors.primaryTurf, onTap: () {
              _recordBallEvent(context, match, appState, runs: 2);
            }),
            _buildScoringButton(context, title: '3', subtitle: 'Runs', isEnabled: hasPlayers, color: AppColors.primaryTurf, onTap: () {
              _recordBallEvent(context, match, appState, runs: 3);
            }),
            
            // Row 2: 4, 5, 6, Wd
            _buildScoringButton(context, title: '4', subtitle: 'Boundary', isEnabled: hasPlayers, color: AppColors.woodMahogany, onTap: () {
              _recordBallEvent(context, match, appState, runs: 4, comment: '${match.striker!.name} hits a boundary!');
            }),
            _buildScoringButton(context, title: '5', subtitle: 'Overthrow', isEnabled: hasPlayers, color: AppColors.primaryTurf, onTap: () {
              _recordBallEvent(context, match, appState, runs: 5, comment: 'Overthrow runs! ${match.striker!.name} scores 5 runs.');
            }),
            _buildScoringButton(context, title: '6', subtitle: 'Maximum', isEnabled: hasPlayers, color: AppColors.accentCrease, onTap: () {
              _recordBallEvent(context, match, appState, runs: 6, comment: 'MASSIVE SIX! ${match.striker!.name} launches it!');
            }),
            _buildScoringButton(context, title: 'Wd', subtitle: 'Wide', isEnabled: hasPlayers, color: Colors.amber.shade900, onTap: () {
              _showWideDialog(context, match, appState);
            }),
            
            // Row 3: Nb, Lb, B, Pen
            _buildScoringButton(context, title: 'Nb', subtitle: 'No Ball', isEnabled: hasPlayers, color: Colors.orange.shade800, onTap: () {
              _showNoBallDialog(context, match, appState);
            }),
            _buildScoringButton(context, title: 'Lb', subtitle: 'Leg Bye', isEnabled: hasPlayers, color: Colors.teal.shade800, onTap: () {
              _showLegByeDialog(context, match, appState);
            }),
            _buildScoringButton(context, title: 'B', subtitle: 'Byes', isEnabled: hasPlayers, color: Colors.cyan.shade800, onTap: () {
              _showByeDialog(context, match, appState);
            }),
            _buildScoringButton(context, title: 'Pen', subtitle: 'Penalty', isEnabled: hasPlayers, color: Colors.deepPurple.shade800, onTap: () {
              _showPenaltyDialog(context, match, appState);
            }),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Out Button
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPlayers ? Colors.red.shade900 : Colors.grey.shade200,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: hasPlayers ? Colors.transparent : AppColors.borderGreen,
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: hasPlayers ? () => _showWicketDialog(context, match, appState) : () {
                    CustomSnackBar.show(
                      context,
                      message: 'Please select striker, non-striker, and bowler first!',
                      type: SnackBarType.warning,
                    );
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_baseball, color: hasPlayers ? Colors.white : Colors.black38, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'OUT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasPlayers ? Colors.white : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Retire Button
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPlayers ? Colors.orange.shade900 : Colors.grey.shade200,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: hasPlayers ? Colors.transparent : AppColors.borderGreen,
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: hasPlayers ? () => _showRetireDialog(context, match, appState) : () {
                    CustomSnackBar.show(
                      context,
                      message: 'Please select striker, non-striker, and bowler first!',
                      type: SnackBarType.warning,
                    );
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.airline_seat_flat_angled_rounded, color: hasPlayers ? Colors.white : Colors.black38, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'RETIRE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasPlayers ? Colors.white : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Undo Button
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canUndo ? Colors.blueGrey.shade800 : Colors.grey.shade200,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: canUndo ? Colors.transparent : AppColors.borderGreen,
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: canUndo ? () => _undoLastAction(context, match, appState) : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.undo_rounded, color: canUndo ? Colors.white : Colors.black38, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'UNDO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: canUndo ? Colors.white : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoringButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isEnabled,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final finalTextColor = isEnabled 
        ? (textColor ?? Colors.white) 
        : Colors.black38;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? color : Colors.grey.shade100,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isEnabled ? Colors.transparent : Colors.grey.shade300,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      ),
      onPressed: isEnabled ? onTap : () {
        CustomSnackBar.show(
          context,
          message: 'Please select striker, non-striker, and bowler first!',
          type: SnackBarType.warning,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: finalTextColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: finalTextColor,
            ),
          ),
        ],
      ),
    );
  }

  void _recordBallEvent(BuildContext context, CricketMatch match, AppState appState, {required int runs, String? comment}) {
    final desc = comment ?? '${match.striker!.name} scores $runs runs.';
    appState.recordBall(match.id, BallEvent(
      runs: runs,
      batsmanName: match.striker!.name,
      bowlerName: match.currentBowler!.name,
      description: desc,
    ));
  }

  void _undoLastAction(BuildContext context, CricketMatch match, AppState appState) {
    appState.undoLastBall(match.id);
    CustomSnackBar.show(
      context,
      message: 'Last action undone successfully.',
      type: SnackBarType.info,
      duration: const Duration(seconds: 2),
    );
  }

  void _showPlayerSelector(
    BuildContext context, 
    List<Player> players, 
    Function(Player) onSelected, {
    bool isBowler = false,
    CricketMatch? match,
  }) {
    // Sort players based on requirements
    final List<Player> sortedPlayers = List.from(players);
    if (isBowler) {
      // bowler list: bowler, all rounder then other player (Wicketkeeper, Batsman)
      sortedPlayers.sort((a, b) {
        int getPriority(String r) {
          if (r == 'Bowler') return 0;
          if (r == 'All-Rounder') return 1;
          if (r == 'Wicketkeeper') return 2;
          if (r == 'Batsman') return 3;
          return 4;
        }
        return getPriority(a.role).compareTo(getPriority(b.role));
      });
    } else {
      // batter list: batters, wicketkeeper, all rounder and then bowler name
      sortedPlayers.sort((a, b) {
        int getPriority(String r) {
          if (r == 'Batsman') return 0;
          if (r == 'Wicketkeeper') return 1;
          if (r == 'All-Rounder') return 2;
          if (r == 'Bowler') return 3;
          return 4;
        }
        return getPriority(a.role).compareTo(getPriority(b.role));
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center drag bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBowler ? 'Select Bowler 🥎' : 'Select Batter 🏏',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textDarkMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.dividerGreen, height: 1),
                  const SizedBox(height: 12),
                  
                  // Player List
                  Expanded(
                    child: sortedPlayers.isEmpty
                        ? const Center(
                            child: Text(
                              'No players available',
                              style: TextStyle(color: AppColors.textDarkSecondary),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: sortedPlayers.length,
                            itemBuilder: (context, index) {
                              final p = sortedPlayers[index];
                              final isLast = index == sortedPlayers.length - 1;
                              final typeText = isBowler ? p.bowlingStyle : p.battingStyle;

                              // Calculate trailing widget: show completed overs for bowler/all-rounder selection
                              Widget trailingWidget;
                              if (isBowler && match != null && (p.role == 'Bowler' || p.role == 'All-Rounder')) {
                                final balls = match.bowlerBallsBowled[p.id] ?? 0;
                                final oversStr = '${balls ~/ 6}.${balls % 6}';
                                trailingWidget = Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTurf.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$oversStr Ov',
                                    style: const TextStyle(
                                      color: AppColors.primaryTurf,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              } else {
                                trailingWidget = const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppColors.textDarkDisabled,
                                  size: 12,
                                );
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isLast ? Colors.transparent : AppColors.dividerGreen.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  title: Text(
                                    p.name,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${p.role} • $typeText',
                                    style: const TextStyle(
                                      color: AppColors.textDarkSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  trailing: trailingWidget,
                                  onTap: () {
                                    onSelected(p);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWicketDialog(BuildContext context, CricketMatch match, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String wicketType = 'Bowled';
        Player outBatsman = match.striker!;
        int completedRuns = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Out! Record Wicket',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wicket Type:', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped', 'Hit Wicket'].map((t) {
                        final isSelected = wicketType == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          selectedColor: AppColors.primaryTurf,
                          backgroundColor: AppColors.appBarBg,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => wicketType = t);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Batsman Out:', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [match.striker!, match.nonStriker!].map((p) {
                        final isSelected = outBatsman.id == p.id;
                        final isStriker = p.id == match.striker!.id;
                        return ChoiceChip(
                          label: Text('${p.name} ${isStriker ? "(Striker)" : "(Non-Striker)"}'),
                          selected: isSelected,
                          selectedColor: Colors.red.shade800,
                          backgroundColor: AppColors.appBarBg,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => outBatsman = p);
                          },
                        );
                      }).toList(),
                    ),

                    if (wicketType == 'Run Out') ...[
                      const Divider(height: 24, color: AppColors.borderGreen),
                      const Text('Completed runs before Run Out:', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [0, 1, 2, 3].map((r) {
                          final isSelected = completedRuns == r;
                          return ChoiceChip(
                            label: Text('$r run${r != 1 ? 's' : ''}'),
                            selected: isSelected,
                            selectedColor: AppColors.primaryTurf,
                            backgroundColor: AppColors.appBarBg,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => completedRuns = r);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final runs = wicketType == 'Run Out' ? completedRuns : 0;
                    final desc = wicketType == 'Run Out'
                        ? 'WICKET! Run Out! ${outBatsman.name} is run out after completing $runs run(s).'
                        : 'WICKET! ${outBatsman.name} is out ($wicketType) bowled by ${match.currentBowler!.name}.';
                    
                    // Record Wicket event
                    appState.recordBall(match.id, BallEvent(
                      runs: runs,
                      isWicket: true,
                      wicketType: wicketType,
                      batsmanName: outBatsman.name,
                      bowlerName: match.currentBowler!.name,
                      description: desc,
                    ));
                    
                    // Fetch the latest state of the match after recordBall
                    final latestMatch = appState.matches.firstWhere((m) => m.id == match.id, orElse: () => match);
                    
                    // Determine if the out batsman is currently at the striker end in the updated state
                    final isStrikerOutCurrently = latestMatch.striker != null && outBatsman.id == latestMatch.striker!.id;

                    // Replace out batsman in UI
                    appState.changeStrikerPlayer(null, isStrikerOutCurrently);

                    Navigator.pop(context);

                    // Automatically prompt to choose the next batsman of the batting team (if same innings and match still live)
                    if (latestMatch.status == MatchStatus.live && latestMatch.currentInningsNum == match.currentInningsNum) {
                      final battingTeam = latestMatch.battingTeam;
                      final activeStrikerId = latestMatch.striker?.id;
                      final activeNonStrikerId = latestMatch.nonStriker?.id;
                      final availablePlayers = battingTeam.players.where((p) {
                        final hasBatted = latestMatch.currentInnings.battingOrder.contains(p.id);
                        final isAtCrease = p.id == activeStrikerId || p.id == activeNonStrikerId;
                        return !hasBatted && !isAtCrease;
                      }).toList();

                      if (availablePlayers.isNotEmpty) {
                        _showPlayerSelector(context, availablePlayers, (newPlayer) {
                          appState.changeStrikerPlayer(newPlayer, isStrikerOutCurrently);
                        }, isBowler: false);
                      }
                    }
                  },
                  child: const Text('RECORD WICKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRetireDialog(BuildContext context, CricketMatch match, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String retirementType = 'Retired Hurt';
        Player selectedPlayer = match.striker!;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Retire Batsman',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Batsman:', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [match.striker!, match.nonStriker!].map((p) {
                      final isSelected = selectedPlayer.id == p.id;
                      final isStriker = p.id == match.striker!.id;
                      return ChoiceChip(
                        label: Text('${p.name} ${isStriker ? "(Striker)" : "(Non-Striker)"}'),
                        selected: isSelected,
                        selectedColor: AppColors.primaryTurf,
                        backgroundColor: AppColors.appBarBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => selectedPlayer = p);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Retirement Type:', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Retired Hurt', 'Retired Out'].map((t) {
                      final isSelected = retirementType == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: isSelected,
                        selectedColor: AppColors.primaryTurf,
                        backgroundColor: AppColors.appBarBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => retirementType = t);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkMuted, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final isRetiredOut = retirementType == 'Retired Out';
                    final isStriker = selectedPlayer.id == match.striker!.id;
                    
                    appState.retireBatsman(match.id, selectedPlayer.id, isRetiredOut);
                    Navigator.pop(context);

                    // Prompt to choose the next batsman immediately
                    final battingTeam = match.battingTeam;
                    final activeStrikerId = match.striker?.id;
                    final activeNonStrikerId = match.nonStriker?.id;
                    final availablePlayers = battingTeam.players.where((p) {
                      final hasBatted = match.currentInnings.battingOrder.contains(p.id);
                      final isAtCrease = p.id == activeStrikerId || p.id == activeNonStrikerId;
                      return !hasBatted && !isAtCrease;
                    }).toList();

                    if (availablePlayers.isNotEmpty) {
                      _showPlayerSelector(context, availablePlayers, (newPlayer) {
                        appState.changeStrikerPlayer(newPlayer, isStriker);
                      }, isBowler: false, match: match);
                    }
                  },
                  child: const Text('RETIRE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBreakView(BuildContext context, CricketMatch match, AppState appState) {
    final isSuperOver = match.currentInningsNum >= 3;
    
    String title = "Match on Break";
    String description = "";
    
    if (match.breakReason == 'Innings Break') {
      title = isSuperOver ? "Super Over Innings Break" : "Innings Break";
      if (match.currentInningsNum == 2 && match.innings1 != null) {
        final target = match.innings1!.runs + 1;
        description = "${match.battingTeam.name} needs $target runs from ${match.totalOvers} overs to win.";
      } else if (match.currentInningsNum == 4 && match.superOverInnings1 != null) {
        final target = match.superOverInnings1!.runs + 1;
        description = "${match.battingTeam.name} needs $target runs from 1 over (6 balls) to win the Super Over.";
      } else if (match.currentInningsNum == 3) {
        description = "Ready for the Super Over to begin. ${match.battingTeam.name} to bat first.";
      }
    } else {
      title = match.breakReason ?? "Match Paused";
      description = "Scoring is temporarily suspended. Resume play to continue recording balls.";
    }

    final canUndo = match.currentInnings.events.isNotEmpty ||
        (match.currentInningsNum == 2 &&
            match.innings2?.events.isEmpty == true &&
            match.innings1 != null &&
            match.innings1!.events.isNotEmpty) ||
        (match.currentInningsNum == 3 &&
            match.superOverInnings1?.events.isEmpty == true &&
            match.innings2 != null &&
            match.innings2!.events.isNotEmpty) ||
        (match.currentInningsNum == 4 &&
            match.superOverInnings2?.events.isEmpty == true &&
            match.superOverInnings1 != null &&
            match.superOverInnings1!.events.isNotEmpty);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryTurf.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryTurf.withOpacity(0.2), width: 2),
              ),
              child: Icon(
                match.breakReason == 'Rain Delay'
                    ? Icons.cloudy_snowing
                    : (match.breakReason == 'Drinks Break'
                        ? Icons.local_cafe_rounded
                        : Icons.pause_circle_filled_rounded),
                size: 48,
                color: AppColors.primaryTurf,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                description,
                style: const TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTurf,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () {
                appState.endMatchBreak(match.id);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text(
                'RESUME PLAY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (canUndo) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                onPressed: () {
                  _undoLastAction(context, match, appState);
                },
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text(
                  'UNDO LAST BALL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStartBreakDialog(BuildContext context, CricketMatch match, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Start Match Break',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_cafe_rounded, color: AppColors.primaryTurf),
              title: const Text('Drinks Break', style: TextStyle(color: AppColors.textDark, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                appState.startMatchBreak(match.id, 'Drinks Break');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloudy_snowing, color: Colors.blueAccent),
              title: const Text('Rain Delay', style: TextStyle(color: AppColors.textDark, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                appState.startMatchBreak(match.id, 'Rain Delay');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline_rounded, color: Colors.grey),
              title: const Text('General Break', style: TextStyle(color: AppColors.textDark, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                appState.startMatchBreak(match.id, 'General Break');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteMatchDialog(BuildContext context, CricketMatch match, AppState appState) {
    String selectedOption = 'team_a'; // Default option
    if (match.innings2 != null) {
      selectedOption = match.battingTeam.id == match.teamA.id ? 'team_a' : 'team_b';
    }
    
    final resultController = TextEditingController();
    
    String getResultString(String option, String customVal) {
      if (option == 'team_a') {
        return '${match.teamA.name} won';
      } else if (option == 'team_b') {
        return '${match.teamB.name} won';
      } else if (option == 'tied') {
        return 'Match Tied';
      } else if (option == 'abandoned') {
        return 'Match Abandoned';
      } else {
        return customVal;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Complete Match',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select the match outcome:',
                    style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderGreen, width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedOption,
                        isExpanded: true,
                        dropdownColor: AppColors.cardBg,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryTurf),
                        style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                        items: [
                          DropdownMenuItem(
                            value: 'team_a',
                            child: Text('${match.teamA.name} Won'),
                          ),
                          DropdownMenuItem(
                            value: 'team_b',
                            child: Text('${match.teamB.name} Won'),
                          ),
                          const DropdownMenuItem(
                            value: 'tied',
                            child: Text('Match Tied'),
                          ),
                          const DropdownMenuItem(
                            value: 'abandoned',
                            child: Text('Match Abandoned'),
                          ),
                          const DropdownMenuItem(
                            value: 'custom',
                            child: Text('Custom Result...'),
                          ),
                        ],
                        onChanged: (String? newVal) {
                          if (newVal != null) {
                            setState(() {
                              selectedOption = newVal;
                              if (newVal == 'custom') {
                                resultController.text = '';
                              } else {
                                resultController.text = getResultString(newVal, '');
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  if (selectedOption == 'custom') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Enter custom result description:',
                      style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: resultController,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'e.g. Mumbai Titans won by 15 runs',
                        hintStyle: const TextStyle(color: AppColors.textDarkMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderGreen, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primaryTurf, width: 1.5),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTurf.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderGreen.withOpacity(0.4), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RESULT PREVIEW',
                            style: TextStyle(
                              color: AppColors.primaryTurf,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            getResultString(selectedOption, ''),
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    final finalResult = getResultString(selectedOption, resultController.text.trim());
                    appState.completeMatch(
                      match.id,
                      customResult: finalResult.isNotEmpty ? finalResult : 'Match Completed',
                      forceComplete: true,
                    );
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close LiveScoringScreen
                  },
                  child: const Text('FINISH MATCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWideDialog(BuildContext context, CricketMatch match, AppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Wide Extras',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Were there any additional runs scored (byes/boundary)?',
                style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDialogOption(context, 'Just Wide (+1)', () {
                    _recordWide(match, appState, 0);
                    Navigator.pop(context);
                  }),
                  _buildDialogOption(context, '+1 Run (2 total)', () {
                    _recordWide(match, appState, 1);
                    Navigator.pop(context);
                  }),
                  _buildDialogOption(context, '+2 Runs (3 total)', () {
                    _recordWide(match, appState, 2);
                    Navigator.pop(context);
                  }),
                  _buildDialogOption(context, '+3 Runs (4 total)', () {
                    _recordWide(match, appState, 3);
                    Navigator.pop(context);
                  }),
                  _buildDialogOption(context, 'Boundary (+4) (5 total)', () {
                    _recordWide(match, appState, 4);
                    Navigator.pop(context);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _recordWide(CricketMatch match, AppState appState, int additionalRuns) {
    final desc = additionalRuns == 4 
        ? 'Wide delivery plus 4 runs boundary.' 
        : (additionalRuns > 0 ? 'Wide delivery plus $additionalRuns run(s).' : 'Wide delivery.');
    
    appState.recordBall(
      match.id,
      BallEvent(
        runs: additionalRuns,
        isWide: true,
        batsmanName: match.striker!.name,
        bowlerName: match.currentBowler!.name,
        description: desc,
      ),
    );
  }

  void _showNoBallDialog(BuildContext context, CricketMatch match, AppState appState) {
    int runs = 0;
    bool isRunsOffBat = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'No Ball Extras',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select runs scored from this No Ball:',
                    style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  
                  // Wrap scoring options
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 1, 2, 3, 4, 6].map((r) {
                      final isSelected = runs == r;
                      return ChoiceChip(
                        label: Text(r == 0 ? 'No runs' : '$r run${r > 1 ? 's' : ''}'),
                        selected: isSelected,
                        selectedColor: AppColors.primaryTurf,
                        backgroundColor: AppColors.appBarBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => runs = r);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  
                  if (runs > 0) ...[
                    const Divider(height: 24, color: AppColors.borderGreen),
                    // Checkbox for Batsman runs vs Extras (Byes/Leg Byes)
                    CheckboxListTile(
                      title: const Text(
                        'Runs scored off bat',
                        style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isRunsOffBat 
                            ? 'Runs credited to ${match.striker!.name}' 
                            : 'Runs credited to team extras (byes)',
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: isRunsOffBat,
                      activeColor: AppColors.primaryTurf,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => isRunsOffBat = val);
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _recordNoBall(match, appState, runs, isRunsOffBat);
                    Navigator.pop(context);
                  },
                  child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _recordNoBall(CricketMatch match, AppState appState, int runs, bool isRunsOffBat) {
    String desc = 'No ball.';
    if (runs > 0) {
      desc = isRunsOffBat 
          ? 'No ball, batsman scores $runs runs off bat.' 
          : 'No ball plus $runs extras (byes).';
    }
    
    appState.recordBall(
      match.id,
      BallEvent(
        runs: runs,
        isNoBall: true,
        isRunsOffBat: isRunsOffBat,
        batsmanName: match.striker!.name,
        bowlerName: match.currentBowler!.name,
        description: desc,
      ),
    );
  }

  Widget _buildDialogOption(BuildContext context, String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cardBg,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.borderGreen, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  void _showLegByeDialog(BuildContext context, CricketMatch match, AppState appState) {
    int runs = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Leg Byes (LB)',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Leg Byes scored from this ball:',
                    style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 1, 2, 3, 4, 5, 6].map((r) {
                      final isSelected = runs == r;
                      String label;
                      if (r == 0) {
                        label = 'Simple LB (0 runs)';
                      } else if (r == 4) {
                        label = '4 runs (Boundary)';
                      } else {
                        label = '$r run${r > 1 ? 's' : ''}';
                      }
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.primaryTurf,
                        backgroundColor: AppColors.appBarBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => runs = r);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _recordLegBye(match, appState, runs);
                    Navigator.pop(context);
                  },
                  child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _recordLegBye(CricketMatch match, AppState appState, int runs) {
    final desc = runs == 0 ? 'Leg bye delivery, no run.' : 'Leg byes: $runs run(s) scored.';
    appState.recordBall(
      match.id,
      BallEvent(
        runs: runs,
        isLegBye: true,
        batsmanName: match.striker!.name,
        bowlerName: match.currentBowler!.name,
        description: desc,
      ),
    );
  }

  void _showByeDialog(BuildContext context, CricketMatch match, AppState appState) {
    int runs = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Byes (B)',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Byes scored from this ball:',
                    style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 1, 2, 3, 4, 5, 6].map((r) {
                      final isSelected = runs == r;
                      String label;
                      if (r == 0) {
                        label = 'Simple Bye (0 runs)';
                      } else if (r == 4) {
                        label = '4 runs (Boundary)';
                      } else {
                        label = '$r run${r > 1 ? 's' : ''}';
                      }
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.primaryTurf,
                        backgroundColor: AppColors.appBarBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => runs = r);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _recordBye(match, appState, runs);
                    Navigator.pop(context);
                  },
                  child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _recordBye(CricketMatch match, AppState appState, int runs) {
    final desc = runs == 0 ? 'Bye delivery, no run.' : 'Byes: $runs run(s) scored.';
    appState.recordBall(
      match.id,
      BallEvent(
        runs: runs,
        isBye: true,
        batsmanName: match.striker!.name,
        bowlerName: match.currentBowler!.name,
        description: desc,
      ),
    );
  }

  void _showPenaltyDialog(BuildContext context, CricketMatch match, AppState appState) {
    int runs = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Penalty Runs',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select penalty runs to award batting team:',
                    style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 2, 3, 4, 5, 6].map((r) {
                      final isSelected = runs == r;
                      return ChoiceChip(
                        label: Text(r == 5 ? '5 runs (Standard)' : '$r run${r > 1 ? 's' : ''}'),
                        selected: isSelected,
                        selectedColor: AppColors.primaryTurf,
                        backgroundColor: AppColors.appBarBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => runs = r);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _recordPenalty(match, appState, runs);
                    Navigator.pop(context);
                  },
                  child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _recordPenalty(CricketMatch match, AppState appState, int runs) {
    appState.recordBall(
      match.id,
      BallEvent(
        runs: runs,
        isPenalty: true,
        batsmanName: match.striker!.name,
        bowlerName: match.currentBowler!.name,
        description: 'Penalty runs: $runs runs awarded.',
      ),
    );
  }
}
