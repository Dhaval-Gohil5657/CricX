import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_model.dart';
import '../../state/app_state.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../constants/app_colors.dart';
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
    
    final isSecondInnings = currentMatch.currentInningsNum == 2;
    final target = isSecondInnings ? (currentMatch.innings1!.runs + 1) : null;
    
    // Calculate balls bowled in current over
    final currentOverBalls = innings.ballsBowled % 6;
    final oversCompletedText = '${innings.ballsBowled ~/ 6}.$currentOverBalls';

    // Retrieve all events in the current over (including Wides and No Balls)
    final List<BallEvent> currentOverEvents = [];
    int legalBallsCount = 0;
    final targetLegalCount = currentOverBalls > 0 ? currentOverBalls : 6;
    
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
            'Live Scoring – Overs: ${currentMatch.totalOvers}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
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
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGreen, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          battingTeam.name,
                          style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${innings.runs}/${innings.wickets}',
                              style: const TextStyle(color: AppColors.accentCrease, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($oversCompletedText Overs)',
                              style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Run Rate: ${innings.runRate.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (isSecondInnings && target != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Target: $target',
                            style: const TextStyle(color: AppColors.pitchGold, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          if (currentMatch.status != MatchStatus.completed)
                            Text(
                              'Need ${target - innings.runs <= 0 ? 0 : target - innings.runs} from ${(currentMatch.totalOvers * 6) - innings.ballsBowled} balls',
                              style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (currentMatch.status == MatchStatus.completed) ...[
                  const Divider(color: AppColors.borderGreen, height: 16),
                  Text(
                    currentMatch.resultString,
                    style: const TextStyle(
                      color: AppColors.pitchGold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: null,
                  ),
                ],
                const Divider(color: AppColors.borderGreen, height: 24),
                
                // Current Over Tracker
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6.0),
                      child: Text(
                        'This Over: ',
                        style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: recentEvents.map((ev) => _buildOverBallCircle(ev)).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Batsmen
                  _buildBatsmenCard(context, currentMatch, battingTeam, appState),
                  const SizedBox(height: 12),
                  
                  // Active Bowler
                  _buildBowlerCard(context, currentMatch, bowlingTeam, appState),
                  const SizedBox(height: 12),
                  
                  // Scoring Buttons Grid wrapped in a card Container
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGreen, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SCORING PAD',
                            style: TextStyle(
                              color: AppColors.primaryTurf,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
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
    Color bg = AppColors.logoBg;
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

  Widget _buildBatsmenCard(BuildContext context, CricketMatch match, Team battingTeam, AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGreen, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BATTING', style: TextStyle(color: AppColors.accentCrease, fontSize: 12, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => appState.changeStriker(),
                  icon: const Icon(Icons.swap_horiz, size: 16, color: AppColors.accentCrease),
                  label: const Text('Rotate Strike', style: TextStyle(color: AppColors.accentCrease, fontSize: 11, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Batting Column Headers (Shown only once at the top)
            if (match.striker != null || match.nonStriker != null) ...[
              Row(
                children: [
                  const Icon(Icons.sports_cricket, color: Colors.transparent, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 3,
                    child: Text('Batsman', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  _buildBatsmanHeaderItem('R'),
                  _buildBatsmanHeaderItem('B'),
                  _buildBatsmanHeaderItem('4s'),
                  _buildBatsmanHeaderItem('6s'),
                  _buildBatsmanHeaderItem('SR', flex: 2),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(color: AppColors.borderGreen, height: 1),
              const SizedBox(height: 6),
            ],
            
            // Striker Row
            _buildBatsmanRow(context, match, match.striker, true, battingTeam, appState),
            const Divider(color: AppColors.borderGreen, height: 15),
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
        style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold),
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
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Select Batsman', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dividerGreen,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
            ),
            onPressed: () {
              final availablePlayers = battingTeam.players.where((p) {
                return !match.currentInnings.battingOrder.contains(p.id);
              }).toList();

              _showPlayerSelector(context, availablePlayers, (newPlayer) {
                appState.changeStrikerPlayer(newPlayer, isStriker);
              });
            },
            child: const Text('Select', style: TextStyle(color: AppColors.textDark, fontSize: 11)),
          ),
        ],
      );
    }

    final runs = match.playerRuns[player.id] ?? 0;
    final balls = match.playerBallsFaced[player.id] ?? 0;
    final fours = match.currentInnings.events.where((e) => e.batsmanName == player.name && e.runs == 4 && !e.isWide && (e.isNoBall ? e.isRunsOffBat : true)).length;
    final sixes = match.currentInnings.events.where((e) => e.batsmanName == player.name && e.runs == 6 && !e.isWide && (e.isNoBall ? e.isRunsOffBat : true)).length;
    final sr = balls > 0 ? (runs / balls) * 100 : 0.0;

    return Row(
      children: [
        Icon(
          isStriker ? Icons.sports_cricket : Icons.sports_cricket_outlined,
          color: isStriker ? AppColors.woodLight : AppColors.textDarkDisabled,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            '${player.name}${isStriker ? ' *' : ''}',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: isStriker ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildBatsmanValueItem('$runs'),
        _buildBatsmanValueItem('$balls'),
        _buildBatsmanValueItem('$fours'),
        _buildBatsmanValueItem('$sixes'),
        _buildBatsmanValueItem(sr.toStringAsFixed(1), flex: 2),
      ],
    );
  }

  Widget _buildBatsmanValueItem(String value, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildBowlerCard(BuildContext context, CricketMatch match, Team bowlingTeam, AppState appState) {
    final bowler = match.currentBowler;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGreen, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BOWLING', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _showPlayerSelector(context, bowlingTeam.players, (newBowler) {
                    appState.changeBowler(newBowler);
                  }),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Change Bowler', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bowler == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select active bowler', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dividerGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _showPlayerSelector(context, bowlingTeam.players, (newBowler) {
                      appState.changeBowler(newBowler);
                    }),
                    child: const Text('Select', style: TextStyle(color: AppColors.textDark, fontSize: 11)),
                  ),
                ],
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('', style: TextStyle(fontSize: 10)),
                      const SizedBox(height: 2),
                      const Icon(Icons.sports_baseball, color: AppColors.woodLight, size: 18),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('', style: TextStyle(fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          bowler.name,
                          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildBowlerStatItem('O', '${(match.bowlerBallsBowled[bowler.id] ?? 0) ~/ 6}.${(match.bowlerBallsBowled[bowler.id] ?? 0) % 6}'),
                  _buildBowlerStatItem('R', '${match.bowlerRunsConceded[bowler.id] ?? 0}'),
                  _buildBowlerStatItem('W', '${match.bowlerWickets[bowler.id] ?? 0}'),
                  _buildBowlerStatItem('Econ', _calculateEcon(match.bowlerRunsConceded[bowler.id] ?? 0, match.bowlerBallsBowled[bowler.id] ?? 0)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBowlerStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _calculateEcon(int runs, int balls) {
    if (balls == 0) return '0.0';
    return ((runs / balls) * 6).toStringAsFixed(1);
  }

  Widget _buildScoringPad(BuildContext context, CricketMatch match, AppState appState) {
    if (match.status == MatchStatus.completed) {
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
            const Text(
              'MATCH COMPLETED',
              style: TextStyle(
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
        ),
      );
    }

    final hasPlayers = match.striker != null && match.nonStriker != null && match.currentBowler != null;

    // Row 4: OUT button & UNDO button
    final canUndo = match.currentInnings.events.isNotEmpty ||
        (match.currentInningsNum == 2 &&
            match.innings2?.events.isEmpty == true &&
            match.innings1 != null &&
            match.innings1!.events.isNotEmpty);

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: [
            // Row 1: 0, 1, 2, 3
            _buildScoringButton(context, title: '0', subtitle: 'Dot', isEnabled: hasPlayers, color: const Color(0xFF1E2E21), onTap: () {
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
            _buildScoringButton(context, title: '4', subtitle: 'Boundary', isEnabled: hasPlayers, color: Colors.blue.shade900, onTap: () {
              _recordBallEvent(context, match, appState, runs: 4, comment: '${match.striker!.name} hits a boundary!');
            }),
            _buildScoringButton(context, title: '5', subtitle: 'Overthrow', isEnabled: hasPlayers, color: AppColors.primaryTurf, onTap: () {
              _recordBallEvent(context, match, appState, runs: 5, comment: 'Overthrow runs! ${match.striker!.name} scores 5 runs.');
            }),
            _buildScoringButton(context, title: '6', subtitle: 'Maximum', isEnabled: hasPlayers, color: AppColors.accentCrease, textColor: Colors.black, onTap: () {
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
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPlayers ? Colors.red.shade900 : Colors.grey.shade200,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: hasPlayers ? Colors.transparent : AppColors.borderGreen,
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: hasPlayers ? () => _showWicketDialog(context, match, appState) : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select striker, non-striker, and bowler first!')),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_baseball, color: hasPlayers ? Colors.white : Colors.black38, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'OUT (WICKET)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: hasPlayers ? Colors.white : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canUndo ? Colors.blueGrey.shade800 : Colors.grey.shade200,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: canUndo ? Colors.transparent : AppColors.borderGreen,
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: canUndo ? () => _undoLastAction(context, match, appState) : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.undo_rounded,
                        color: canUndo ? Colors.white : Colors.black38,
                        size: 18,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Undo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: canUndo ? Colors.white : Colors.black38,
                        ),
                      ),
                    ],
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
        backgroundColor: isEnabled ? color : Colors.grey.shade200,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isEnabled ? Colors.transparent : AppColors.borderGreen,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      ),
      onPressed: isEnabled ? onTap : () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select striker, non-striker, and bowler first!')),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: finalTextColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Last action undone successfully.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPlayerSelector(BuildContext context, List<Player> players, Function(Player) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.appBarBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Player', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final p = players[index];
                    return ListTile(
                      title: Text(p.name, style: const TextStyle(color: AppColors.textDark)),
                      subtitle: Text(p.role, style: const TextStyle(color: AppColors.textDarkSecondary)),
                      trailing: const Icon(Icons.add, color: AppColors.accentCrease),
                      onTap: () {
                        onSelected(p);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
                      children: ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped'].map((t) {
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
                    
                    // Determine if striker is out BEFORE recordBall resets the innings/strikers
                    final isStrikerOut = match.striker != null && outBatsman.id == match.striker!.id;

                    // Record Wicket event
                    appState.recordBall(match.id, BallEvent(
                      runs: runs,
                      isWicket: true,
                      wicketType: wicketType,
                      batsmanName: outBatsman.name,
                      bowlerName: match.currentBowler!.name,
                      description: desc,
                    ));
                    
                    // Replace out batsman in UI
                    appState.changeStrikerPlayer(null, isStrikerOut);

                    Navigator.pop(context);

                    // Automatically prompt to choose the next batsman of the batting team (if same innings and match still live)
                    final latestMatch = appState.matches.firstWhere((m) => m.id == match.id, orElse: () => match);
                    if (latestMatch.status == MatchStatus.live && latestMatch.currentInningsNum == match.currentInningsNum) {
                      final battingTeam = latestMatch.battingTeam;
                      final availablePlayers = battingTeam.players.where((p) {
                        return !latestMatch.currentInnings.battingOrder.contains(p.id);
                      }).toList();

                      if (availablePlayers.isNotEmpty) {
                        _showPlayerSelector(context, availablePlayers, (newPlayer) {
                          appState.changeStrikerPlayer(newPlayer, isStrikerOut);
                        });
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

  void _showCompleteMatchDialog(BuildContext context, CricketMatch match, AppState appState) {
    final resultController = TextEditingController(text: '${match.battingTeam.name} won');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.appBarBg,
          title: const Text('Complete Cricket Match', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter custom result description to finish this match:', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: resultController,
                style: const TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'e.g. Mumbai Titans won by 15 runs',
                  hintStyle: const TextStyle(color: AppColors.textDarkMuted),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkMuted)),
            ),
            TextButton(
              onPressed: () {
                appState.completeMatch(match.id, resultController.text.trim());
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close LiveScoringScreen
              },
              child: const Text('FINISH MATCH', style: TextStyle(color: AppColors.accentCrease, fontWeight: FontWeight.bold)),
            ),
          ],
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
