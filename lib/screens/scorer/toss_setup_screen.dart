import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/player_model.dart';
import 'live_scoring_screen.dart';
import '../../constants/app_colors.dart';
import '../../constants/custom_snackbar.dart';
import '../main_navigation_screen.dart';

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
  bool _isXISelected = false;

  List<Player> _teamAPlayingXI = [];
  List<Player> _teamBPlayingXI = [];

  @override
  void initState() {
    super.initState();
    _teamAPlayingXI = List.from(widget.match.teamA.players);
    if (_teamAPlayingXI.length > 11) {
      _teamAPlayingXI = _teamAPlayingXI.sublist(0, 11);
    }
    _teamBPlayingXI = List.from(widget.match.teamB.players);
    if (_teamBPlayingXI.length > 11) {
      _teamBPlayingXI = _teamBPlayingXI.sublist(0, 11);
    }
  }

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

    final batPlayingXI = _tossWinner == null ? <Player>[] : (widget.match.teamA.id == battingTeam?.id ? _teamAPlayingXI : _teamBPlayingXI);
    final bowlPlayingXI = _tossWinner == null ? <Player>[] : (widget.match.teamA.id == bowlingTeam?.id ? _teamAPlayingXI : _teamBPlayingXI);

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
              if (_isXISelected) {
                setState(() => _isXISelected = false);
              } else if (_isTossConducted) {
                setState(() => _isTossConducted = false);
              } else {
                Navigator.pop(context);
              }
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
            _isXISelected
                ? 'Select Openers'
                : (_isTossConducted ? 'Pick Playing XI' : 'Conduct Toss'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderWood,
                  width: 1.5,
                ),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Team A Avatar & Name
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(teamA.logoColorHex).withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Color(teamA.logoColorHex).withOpacity(0.5), width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(teamA.logoEmoji, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          teamA.name,
                          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'VS',
                    style: TextStyle(color: AppColors.textDarkMuted, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  // Team B Avatar & Name
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(teamB.logoColorHex).withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Color(teamB.logoColorHex).withOpacity(0.5), width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(teamB.logoEmoji, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          teamB.name,
                          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!_isTossConducted) ...[
              const Text(
                'CONDUCT THE TOSS',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              
              // Select Toss Winner
              const Text('Who won the toss?', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
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
                        label: '🏏 Bat First',
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
                      backgroundColor: AppColors.primaryTurf,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (battingTeam == null || bowlingTeam == null) return;
                      setState(() {
                        _isTossConducted = true;
                        _isXISelected = false;
                      });
                    },
                    child: const Text('CONFIRM TOSS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ] else if (!_isXISelected) ...[
              // Step 2: Pick Playing XI Selection
              const Text('SELECT PLAYING XI SQUAD', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.borderGreen.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.borderGreen),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text(
                  'Toss Winner: ${_tossWinner?.name} elected to $_tossDecision',
                  style: const TextStyle(color: AppColors.primaryTurf, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              const Text('MANAGE PLAYING XI (MAX 11)', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildPlayingXIRow(widget.match.teamA, _teamAPlayingXI, true),
                    const Divider(color: AppColors.dividerGreen, height: 16),
                    _buildPlayingXIRow(widget.match.teamB, _teamBPlayingXI, false),
                  ],
                ),
              ),
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
                        backgroundColor: AppColors.primaryTurf,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _isXISelected = true;
                          // Initialize default openers based on final playing XI squad
                          if (batPlayingXI.isNotEmpty) {
                            _striker = batPlayingXI[0];
                            if (batPlayingXI.length > 1) {
                              _nonStriker = batPlayingXI[1];
                            } else {
                              _nonStriker = null;
                            }
                          } else {
                            _striker = null;
                            _nonStriker = null;
                          }
                          if (bowlPlayingXI.isNotEmpty) {
                            _bowler = bowlPlayingXI.firstWhere((p) => p.role.contains('Bowler'), orElse: () => bowlPlayingXI[0]);
                          } else {
                            _bowler = null;
                          }
                        });
                      },
                      child: const Text('NEXT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Step 3: Select Openers
              const Text('SELECT SQUAD OPENERS', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.borderGreen.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.borderGreen),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text(
                  'Toss Winner: ${_tossWinner?.name} elected to $_tossDecision',
                  style: const TextStyle(color: AppColors.primaryTurf, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Batting Team Header
              Row(
                children: [
                  Text(battingTeam!.logoEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '${battingTeam.name.toUpperCase()} (BATTING)',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Striker Dropdown
              const Text('Opening Batsman (Striker)', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _buildPlayerDropdown(
                batPlayingXI.where((p) => p.id != _nonStriker?.id).toList(),
                _striker,
                (val) => setState(() => _striker = val),
              ),
              const SizedBox(height: 16),

              // Non-Striker Dropdown
              const Text('Secondary Batsman (Non-Striker)', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _buildPlayerDropdown(
                batPlayingXI.where((p) => p.id != _striker?.id).toList(),
                _nonStriker,
                (val) => setState(() => _nonStriker = val),
              ),
              const SizedBox(height: 24),

              // Bowling Team Header
              Row(
                children: [
                  Text(bowlingTeam!.logoEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '${bowlingTeam.name.toUpperCase()} (BOWLING)',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bowler Dropdown
              const Text('Opening Bowler', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              _buildPlayerDropdown(bowlPlayingXI, _bowler, (val) => setState(() => _bowler = val)),
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
                      onPressed: () => setState(() => _isXISelected = false),
                      child: const Text('Back', style: TextStyle(color: AppColors.textDarkSecondary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTurf,
                        foregroundColor: Colors.white,
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
          color: isSelected ? AppColors.primaryTurf.withOpacity(0.12) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTurf : AppColors.borderGreen,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryTurf : AppColors.textDarkSecondary,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGreen, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Player>(
          value: selectedValue,
          isExpanded: true,
          dropdownColor: AppColors.cardBg,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryTurf),
          style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w500),
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
      CustomSnackBar.show(
        context,
        message: 'Please select striker, non-striker, and bowler',
        type: SnackBarType.error,
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    
    // Conduct toss and setup opening players atomically
    appState.startMatch(
      matchId: widget.match.id,
      tossWinnerId: _tossWinner!.id,
      decision: _tossDecision,
      striker: _striker!,
      nonStriker: _nonStriker!,
      bowler: _bowler!,
      teamAPlayingXI: _teamAPlayingXI,
      teamBPlayingXI: _teamBPlayingXI,
    );
    
    CustomSnackBar.show(
      context,
      message: 'Match started successfully!',
      type: SnackBarType.success,
    );

    // Navigate directly to Live Scoring Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LiveScoringScreen(match: widget.match),
      ),
    );
  }

  Widget _buildPlayingXIRow(Team team, List<Player> playingList, bool isTeamA) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.name,
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '${playingList.length} of ${team.players.length} players selected',
                style: TextStyle(
                  color: playingList.length == 11 ? AppColors.primaryTurf : AppColors.woodMahogany,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryTurf,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onPressed: () => _showPlayingXIPicker(context, team, isTeamA),
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: const Text('Pick XI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  void _showPlayingXIPicker(BuildContext context, Team team, bool isTeamA) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final playingList = isTeamA ? _teamAPlayingXI : _teamBPlayingXI;
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Playing XI (${team.name})',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textDarkMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Text(
                      'Selected: ${playingList.length}/11 players',
                      style: TextStyle(
                        color: playingList.length == 11 ? AppColors.primaryTurf : AppColors.woodMahogany,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Divider(color: AppColors.dividerGreen, height: 20),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: team.players.length,
                        itemBuilder: (context, index) {
                          final player = team.players[index];
                          final isSelected = playingList.any((p) => p.id == player.id);
                          return CheckboxListTile(
                            activeColor: AppColors.primaryTurf,
                            checkColor: Colors.white,
                            title: Text(player.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                            subtitle: Text('${player.role} • ${player.battingStyle}', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                            value: isSelected,
                            onChanged: (bool? val) {
                              if (val == true) {
                                if (playingList.length >= 11) {
                                  CustomSnackBar.show(
                                    context,
                                    message: 'You can select a maximum of 11 players!',
                                    type: SnackBarType.warning,
                                  );
                                  return;
                                }
                                setSheetState(() {
                                  setState(() {
                                    if (isTeamA) {
                                      _teamAPlayingXI.add(player);
                                    } else {
                                      _teamBPlayingXI.add(player);
                                    }
                                  });
                                });
                              } else {
                                if (playingList.length <= 1) {
                                  CustomSnackBar.show(
                                    context,
                                    message: 'At least 1 player must be selected!',
                                    type: SnackBarType.warning,
                                  );
                                  return;
                                }
                                setSheetState(() {
                                  setState(() {
                                    if (isTeamA) {
                                      _teamAPlayingXI.removeWhere((p) => p.id == player.id);
                                    } else {
                                      _teamBPlayingXI.removeWhere((p) => p.id == player.id);
                                    }
                                    
                                    // Reset openers if they were unselected
                                    if (_striker?.id == player.id) _striker = null;
                                    if (_nonStriker?.id == player.id) _nonStriker = null;
                                    if (_bowler?.id == player.id) _bowler = null;
                                  });
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTurf,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
