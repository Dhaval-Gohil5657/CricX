import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/team_model.dart';
import '../models/player_model.dart';
import '../constants/app_colors.dart';
import '../constants/custom_snackbar.dart';
import 'scorer/create_team_screen.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  String? _expandedTeamId;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teams = appState.teams;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: teams.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTurf.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_cricket_rounded,
                        color: AppColors.primaryTurf,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Teams Created',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a team and add players to start scheduling and scoring matches.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        final role = appState.currentRole;
                        if (role == UserRole.scorer || role == UserRole.organizer) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateTeamScreen(),
                            ),
                          );
                        } else {
                          CustomSnackBar.show(
                            context,
                            message: 'Please switch your role to Scorer or Organizer to create teams.',
                            type: SnackBarType.warning,
                          );
                        }
                      },
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text('Create New Team'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTurf,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
        itemCount: teams.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final team = teams[index];
          final isExpanded = _expandedTeamId == team.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isExpanded ? AppColors.primaryTurf : AppColors.borderWood.withOpacity(0.5),
                width: isExpanded ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFDFBF7),
                  Color(0xFFFAF2E6),
                ],
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(team.logoColorHex).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(team.logoColorHex).withOpacity(0.4), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      team.logoEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  title: Text(
                    team.name,
                    style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Squad Size: ${team.players.length} players • Abb: ${team.abbreviation}',
                    style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.primaryTurf,
                  ),
                  onTap: () {
                    setState(() {
                      _expandedTeamId = isExpanded ? null : team.id;
                    });
                  },
                ),
                if (isExpanded) ...[
                  const Divider(color: AppColors.dividerGreen, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Standings Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatBox('Played', '${team.matchesPlayed}', AppColors.textDarkSecondary),
                            _buildStatBox('Won', '${team.matchesWon}', AppColors.accentCrease),
                            _buildStatBox('Lost', '${team.matchesLost}', Colors.redAccent),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SQUAD PLAYERS',
                              style: TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            if (appState.currentRole == UserRole.scorer || appState.currentRole == UserRole.organizer)
                              TextButton.icon(
                                onPressed: () => _showAddPlayerDialog(context, team, appState),
                                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryTurf),
                                label: const Text(
                                  'Add Player',
                                  style: TextStyle(
                                    color: AppColors.primaryTurf,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Players List
                        if (team.players.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No players added to squad yet.',
                              style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
                            ),
                          )
                        else
                          ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: team.players.length,
                            itemBuilder: (context, pIndex) {
                              final player = team.players[pIndex];
                              final isLast = pIndex == team.players.length - 1;
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: isLast
                                        ? BorderSide.none
                                        : const BorderSide(color: AppColors.dividerGreen, width: 0.5),
                                  ),
                                ),
                                child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.name,
                                        style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        player.role,
                                        style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  // Key Player Metric
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        player.role.contains('Bowler')
                                            ? '${player.wicketsTaken} Wkts'
                                            : '${player.runsScored} Runs',
                                        style: const TextStyle(color: AppColors.accentCrease, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        player.role.contains('Bowler')
                                            ? 'Econ: ${player.economyRate.toStringAsFixed(2)}'
                                            : 'S/R: ${player.strikeRate.toStringAsFixed(1)}',
                                        style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDarkMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showAddPlayerDialog(BuildContext context, Team team, AppState appState) {
    final nameController = TextEditingController();
    String selectedRole = 'Batsman';
    String selectedBatting = 'Right-hand bat';
    String selectedBowling = 'Right-arm medium';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borderWood, width: 1),
              ),
              title: Text(
                'Add Player to ${team.name}',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Player Name',
                        labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderWood),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderWood),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryTurf, width: 1.5),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textDark),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderWood),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderWood),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryTurf, width: 1.5),
                        ),
                      ),
                      dropdownColor: AppColors.cardBg,
                      items: ['Batsman', 'Bowler', 'All-Rounder', 'Wicketkeeper']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: AppColors.textDark))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedRole = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBatting,
                      decoration: InputDecoration(
                        labelText: 'Batting Style',
                        labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderWood),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderWood),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryTurf, width: 1.5),
                        ),
                      ),
                      dropdownColor: AppColors.cardBg,
                      items: ['Right-hand bat', 'Left-hand bat', 'None']
                          .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(color: AppColors.textDark))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedBatting = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBowling,
                      decoration: InputDecoration(
                        labelText: 'Bowling Style',
                        labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderWood),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderWood),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryTurf, width: 1.5),
                        ),
                      ),
                      dropdownColor: AppColors.cardBg,
                      items: [
                        'Right-arm fast',
                        'Right-arm medium',
                        'Right-arm spin',
                        'Left-arm fast',
                        'Left-arm medium',
                        'Left-arm spin',
                        'None',
                      ]
                          .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(color: AppColors.textDark))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedBowling = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      CustomSnackBar.show(
                        context,
                        message: 'Please enter a player name.',
                        type: SnackBarType.error,
                      );
                      return;
                    }
                    
                    final player = Player(
                      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      role: selectedRole,
                      battingStyle: selectedBatting == 'None' ? '-' : selectedBatting,
                      bowlingStyle: selectedBowling == 'None' ? '-' : selectedBowling,
                    );
                    
                    appState.addPlayerToTeam(team.id, player);
                    Navigator.pop(context);
                    
                    CustomSnackBar.show(
                      context,
                      message: '$name added to ${team.name}!',
                      type: SnackBarType.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
