import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_model.dart';
import '../../state/app_state.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../constants/app_colors.dart';

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

    // Retrieve events in the current over
    final recentEvents = innings.events.reversed.take(6).toList().reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            appState.setActiveScoringMatch(null);
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Live Scoring – Overs: ${currentMatch.totalOvers}',
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.accentCrease),
            tooltip: 'Complete Match',
            onPressed: () => _showCompleteMatchDialog(context, currentMatch, appState),
          ),
        ],
      ),
      body: Column(
        children: [
          // Match Header Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.appBarBg,
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
                          style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold),
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
                          style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                        ),
                        if (isSecondInnings && target != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Target: $target',
                            style: TextStyle(color: AppColors.pitchGold, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Need ${target - innings.runs} from ${(currentMatch.totalOvers * 6) - innings.ballsBowled} balls',
                            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderGreen, height: 24),
                
                // Current Over Tracker
                Row(
                  children: [
                    const Text(
                      'This Over: ',
                      style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recentEvents.length,
                          itemBuilder: (context, idx) {
                            return _buildOverBallCircle(recentEvents[idx]);
                          },
                        ),
                      ),
                    ),
                    if (currentMatch.currentBowler == null)
                      const Text(
                        'Select Bowler ➜',
                        style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      )
                    else if (innings.ballsBowled > 0 && innings.ballsBowled % 6 == 0 && currentOverBalls == 0)
                      const Text(
                        'Over Complete! Select New Bowler',
                        style: TextStyle(color: AppColors.pitchGold, fontSize: 11, fontWeight: FontWeight.bold),
                      )
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Batsmen
                  _buildBatsmenCard(context, currentMatch, battingTeam, appState),
                  const SizedBox(height: 16),
                  
                  // Active Bowler
                  _buildBowlerCard(context, currentMatch, bowlingTeam, appState),
                  const SizedBox(height: 24),
                  
                  // Scoring Control Pad Header
                  const Text(
                    'SCORING PAD',
                    style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 10),
                  
                  // Scoring Buttons Grid
                  _buildScoringPad(context, currentMatch, appState),
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
    Color textCol = Colors.white;
    String text = '${event.runs}';

    if (event.isWicket) {
      bg = Colors.red;
      text = 'W';
    } else if (event.isWide) {
      bg = Colors.amber.shade700;
      text = 'Wd';
    } else if (event.isNoBall) {
      bg = Colors.orange.shade800;
      text = 'Nb';
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
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildBatsmenCard(BuildContext context, CricketMatch match, Team battingTeam, AppState appState) {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderWood, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            
            // Striker Row
            _buildBatsmanRow(context, match, match.striker, true, battingTeam, appState),
            const Divider(color: AppColors.borderWood, height: 16),
            // Non-Striker Row
            _buildBatsmanRow(context, match, match.nonStriker, false, battingTeam, appState),
          ],
        ),
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
    if (player == null) {
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
            onPressed: () => _showPlayerSelector(context, battingTeam.players, (newPlayer) {
              appState.changeStrikerPlayer(newPlayer, isStriker);
            }),
            child: const Text('Select', style: TextStyle(color: AppColors.textDark, fontSize: 11)),
          ),
        ],
      );
    }

    final runs = match.playerRuns[player.id] ?? 0;
    final balls = match.playerBallsFaced[player.id] ?? 0;
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
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            '$runs (${balls}b)',
            style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          child: Text(
            'SR: ${sr.toStringAsFixed(1)}',
            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textDarkDisabled, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _showPlayerSelector(context, battingTeam.players, (newPlayer) {
            appState.changeStrikerPlayer(newPlayer, isStriker);
          }),
        ),
      ],
    );
  }

  Widget _buildBowlerCard(BuildContext context, CricketMatch match, Team bowlingTeam, AppState appState) {
    final bowler = match.currentBowler;

    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderWood, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                children: [
                  const Icon(Icons.sports_baseball, color: AppColors.leatherWhite, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      bowler.name,
                      style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
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
          Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 9)),
        ],
      ),
    );
  }

  String _calculateEcon(int runs, int balls) {
    if (balls == 0) return '0.0';
    return ((runs / balls) * 6).toStringAsFixed(1);
  }

  Widget _buildScoringPad(BuildContext context, CricketMatch match, AppState appState) {
    final hasPlayers = match.striker != null && match.nonStriker != null && match.currentBowler != null;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        // Dots
        _buildScoringButton(context, label: '0 runs (Dot)', isEnabled: hasPlayers, color: const Color(0xFF1E2E21), onTap: () {
          _recordBallEvent(context, match, appState, runs: 0);
        }),
        _buildScoringButton(context, label: '1 Run', isEnabled: hasPlayers, color: AppColors.primaryTurf, onTap: () {
          _recordBallEvent(context, match, appState, runs: 1);
        }),
        _buildScoringButton(context, label: '2 Runs', isEnabled: hasPlayers, color: AppColors.primaryTurf, onTap: () {
          _recordBallEvent(context, match, appState, runs: 2);
        }),
        
        _buildScoringButton(context, label: '3 Runs', isEnabled: hasPlayers, color: AppColors.primaryTurf, onTap: () {
          _recordBallEvent(context, match, appState, runs: 3);
        }),
        _buildScoringButton(context, label: '4 (BOUNDARY)', isEnabled: hasPlayers, color: Colors.blue.shade900, labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), onTap: () {
          _recordBallEvent(context, match, appState, runs: 4, comment: '${match.striker!.name} hits a boundary!');
        }),
        _buildScoringButton(context, label: '6 (MAXIMUM)', isEnabled: hasPlayers, color: AppColors.accentCrease, labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), onTap: () {
          _recordBallEvent(context, match, appState, runs: 6, comment: 'MASSIVE SIX! ${match.striker!.name} launches it!');
        }),
        
        _buildScoringButton(context, label: 'Wide (+1)', isEnabled: hasPlayers, color: Colors.amber.shade900, onTap: () {
          appState.recordBall(match.id, BallEvent(
            runs: 0,
            isWide: true,
            batsmanName: match.striker!.name,
            bowlerName: match.currentBowler!.name,
            description: 'Wide ball.',
          ));
        }),
        _buildScoringButton(context, label: 'No Ball (+1)', isEnabled: hasPlayers, color: Colors.orange.shade800, onTap: () {
          appState.recordBall(match.id, BallEvent(
            runs: 0,
            isNoBall: true,
            batsmanName: match.striker!.name,
            bowlerName: match.currentBowler!.name,
            description: 'No ball delivered.',
          ));
        }),
        _buildScoringButton(context, label: 'Wicket OUT 🔴', isEnabled: hasPlayers, color: Colors.red.shade900, labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark), onTap: () {
          _showWicketDialog(context, match, appState);
        }),
      ],
    );
  }

  Widget _buildScoringButton(
    BuildContext context, {
    required String label,
    required bool isEnabled,
    required Color color,
    TextStyle? labelStyle,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? color : Colors.grey.shade200,
        foregroundColor: isEnabled ? Colors.white : Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isEnabled ? AppColors.dividerGreen : AppColors.borderGreen, width: 1),
        ),
        padding: const EdgeInsets.all(8),
      ),
      onPressed: isEnabled ? onTap : () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select striker, non-striker, and bowler first!')),
        );
      },
      child: Text(
        label,
        style: labelStyle ?? TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isEnabled ? null : Colors.black38),
        textAlign: TextAlign.center,
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

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.appBarBg,
              title: const Text('Out! Record Wicket', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wicket Type:', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                  DropdownButton<String>(
                    dropdownColor: AppColors.appBarBg,
                    isExpanded: true,
                    value: wicketType,
                    style: const TextStyle(color: AppColors.textDark),
                    onChanged: (String? val) {
                      if (val != null) setState(() => wicketType = val);
                    },
                    items: ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped'].map((String opt) {
                      return DropdownMenuItem<String>(value: opt, child: Text(opt));
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Batsman Out:', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                  ListTile(
                    title: Text(match.striker!.name, style: const TextStyle(color: AppColors.textDark)),
                    leading: Radio<Player>(
                      value: match.striker!,
                      groupValue: outBatsman,
                      activeColor: AppColors.accentCrease,
                      onChanged: (Player? val) => setState(() => outBatsman = val!),
                    ),
                  ),
                  ListTile(
                    title: Text(match.nonStriker!.name, style: const TextStyle(color: AppColors.textDark)),
                    leading: Radio<Player>(
                      value: match.nonStriker!,
                      groupValue: outBatsman,
                      activeColor: AppColors.accentCrease,
                      onChanged: (Player? val) => setState(() => outBatsman = val!),
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
                    // Record Wicket event
                    appState.recordBall(match.id, BallEvent(
                      runs: 0,
                      isWicket: true,
                      wicketType: wicketType,
                      batsmanName: outBatsman.name,
                      bowlerName: match.currentBowler!.name,
                      description: 'WICKET! ${outBatsman.name} is out ($wicketType) bowled by ${match.currentBowler!.name}.',
                    ));
                    
                    // Replace out batsman in UI
                    final isStrikerOut = outBatsman.id == match.striker!.id;
                    appState.changeStrikerPlayer(Player(id: 'dummy', name: 'Select Batsman', role: '-', battingStyle: '-', bowlingStyle: '-'), isStrikerOut);

                    Navigator.pop(context);
                  },
                  child: const Text('RECORD WICKET', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
}
