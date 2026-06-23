import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/player_model.dart';
import 'live_scoring_screen.dart';
import '../../constants/app_colors.dart';

class TossSetupScreen extends StatefulWidget {
  final CricketMatch match;

  const TossSetupScreen({super.key, required this.match});

  @override
  State<TossSetupScreen> createState() => _TossSetupScreenState();
}

class _TossSetupScreenState extends State<TossSetupScreen> {
  Team? _tossWinner;
  String _tossDecision = 'Bat'; // 'Bat' or 'Bowl'
  
  Player? _striker;
  Player? _nonStriker;
  Player? _bowler;

  bool _isTossConducted = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teamA = widget.match.teamA;
    final teamB = widget.match.teamB;

    // Determine batting & bowling teams after toss decision
    Team? battingTeam;
    Team? bowlingTeam;
    if (_tossWinner != null) {
      if (_tossDecision == 'Bat') {
        battingTeam = _tossWinner;
        bowlingTeam = _tossWinner!.id == teamA.id ? teamB : teamA;
      } else {
        bowlingTeam = _tossWinner;
        battingTeam = _tossWinner!.id == teamA.id ? teamB : teamA;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Conduct Toss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match Title Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGreen),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(teamA.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text('VS', style: TextStyle(color: AppColors.textDarkMuted, fontWeight: FontWeight.bold)),
                  Text(teamB.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!_isTossConducted) ...[
              const Text('CONDUCT THE TOSS', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Select Toss Winner
              const Text('Who won the toss?', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectionTile(
                      label: teamA.name,
                      isSelected: _tossWinner?.id == teamA.id,
                      onTap: () => setState(() => _tossWinner = teamA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSelectionTile(
                      label: teamB.name,
                      isSelected: _tossWinner?.id == teamB.id,
                      onTap: () => setState(() => _tossWinner = teamB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Select Decision
              if (_tossWinner != null) ...[
                const Text('What did they elect to do?', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectionTile(
                        label: '👀 Bat First',
                        isSelected: _tossDecision == 'Bat',
                        onTap: () => setState(() => _tossDecision = 'Bat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSelectionTile(
                        label: '⚾ Bowl First',
                        isSelected: _tossDecision == 'Bowl',
                        onTap: () => setState(() => _tossDecision = 'Bowl'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentCrease,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final batTeam = battingTeam;
                      final bowlTeam = bowlingTeam;
                      if (batTeam == null || bowlTeam == null) return;
                      setState(() {
                        _isTossConducted = true;
                        // Select default openers from batting/bowling lists
                        if (batTeam.players.isNotEmpty) {
                          _striker = batTeam.players[0];
                          if (batTeam.players.length > 1) {
                            _nonStriker = batTeam.players[1];
                          }
                        }
                        if (bowlTeam.players.isNotEmpty) {
                          // Find bowler or take first
                          _bowler = bowlTeam.players.firstWhere((p) => p.role.contains('Bowler'), orElse: () => bowlTeam.players[0]);
                        }
                      });
                    },
                    child: const Text('CONFIRM TOSS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ] else ...[
              // Opening Squad Selection
              const Text('SELECT SQUAD OPENERS', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Toss Winner: ${_tossWinner?.name} elected to $_tossDecision',
                style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // Striker Dropdown
              const Text('Opening Batsman (Striker)', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _buildPlayerDropdown(battingTeam!.players, _striker, (val) => setState(() => _striker = val)),
              const SizedBox(height: 16),

              // Non-Striker Dropdown
              const Text('Secondary Batsman (Non-Striker)', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _buildPlayerDropdown(
                battingTeam!.players.where((p) => p.id != _striker?.id).toList(),
                _nonStriker,
                (val) => setState(() => _nonStriker = val),
              ),
              const SizedBox(height: 16),

              // Bowler Dropdown
              const Text('Opening Bowler', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _buildPlayerDropdown(bowlingTeam!.players, _bowler, (val) => setState(() => _bowler = val)),
              const SizedBox(height: 36),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => setState(() => _isTossConducted = false),
                      child: const Text('Back to Toss', style: TextStyle(color: AppColors.textDarkSecondary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCrease,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _startMatchScoring,
                      child: const Text('START SCORING', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCrease.withOpacity(0.15) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentCrease : AppColors.borderGreen,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accentCrease : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPlayerDropdown(List<Player> players, Player? selectedValue, ValueChanged<Player?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGreen),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Player>(
          value: selectedValue,
          isExpanded: true,
          dropdownColor: AppColors.appBarBg,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentCrease),
          style: const TextStyle(color: AppColors.textDark, fontSize: 14),
          onChanged: onChanged,
          items: players.map((player) {
            return DropdownMenuItem(
              value: player,
              child: Text('${player.name} (${player.role})'),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _startMatchScoring() {
    if (_striker == null || _nonStriker == null || _bowler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select striker, non-striker, and bowler')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    
    // Conduct toss
    appState.updateMatchToss(widget.match.id, _tossWinner!.id, _tossDecision);
    
    // Set up players
    appState.setupLiveScoringPlayers(widget.match.id, _striker!, _nonStriker!, _bowler!);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Match started successfully!')),
    );

    // Navigate directly to Live Scoring Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LiveScoringScreen(match: widget.match),
      ),
    );
  }
}
