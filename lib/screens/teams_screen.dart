import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../state/app_state.dart';
import '../models/team_model.dart';
import '../models/player_model.dart';
import '../constants/app_colors.dart';
import '../constants/custom_snackbar.dart';
import 'scorer/create_team_screen.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
              itemCount: teams.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final team = teams[index];
          final isExpanded = _expandedTeamId == team.id;
          final isCreator = team.creatorId == null || team.creatorId == currentUserId;

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
                             if ((appState.currentRole == UserRole.scorer || appState.currentRole == UserRole.organizer) && isCreator)
                               Row(
                                 children: [
                                   TextButton.icon(
                                     onPressed: () => _showEditTeamDialog(context, team, appState),
                                     icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryTurf),
                                     label: const Text(
                                       'Edit Team',
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
                                   const SizedBox(width: 3),
                                   TextButton.icon(
                                     onPressed: () => _showAddPlayerDialog(context, team, appState),
                                     icon: const Icon(Icons.add_rounded, size: 14, color: AppColors.primaryTurf),
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
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                   '${player.name}${team.captainId == player.id && player.role == 'Wicketkeeper' ? ' (C)(Wk)' : team.captainId == player.id ? ' (C)' : player.role == 'Wicketkeeper' ? ' (Wk)' : ''}',
                                                   style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                                                   overflow: TextOverflow.ellipsis,
                                                   maxLines: 1,
                                                 ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${player.role} • ${player.battingStyle}',
                                                  style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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
                                    ),
                                    if ((appState.currentRole == UserRole.scorer || appState.currentRole == UserRole.organizer) && isCreator) ...[
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => _showEditPlayerDialog(context, player, appState),
                                        behavior: HitTestBehavior.opaque,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textDarkSecondary),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _showRemovePlayerConfirm(context, team, player, appState),
                                        behavior: HitTestBehavior.opaque,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          child: Icon(Icons.remove_circle_outline_rounded, size: 16, color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
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

  void _showEditTeamDialog(BuildContext context, Team team, AppState appState) {
    final nameController = TextEditingController(text: team.name);
    final abbController = TextEditingController(text: team.abbreviation);
    String selectedEmoji = team.logoEmoji;
    int selectedColorHex = team.logoColorHex;
    String? selectedCaptainId = team.captainId;

    final List<String> emojis = ['🔥', '⚡', '🌪️', '🦁', '🦅', '🦈', '⚔️', '🛡️', '👑', '⭐️'];
    final List<String> flags = [
      '🇮🇳', '🇦🇺', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', '🇳🇿', '🇿🇦',
      '🇵🇰', '🇱🇰', '🇧🇩', '🇦🇫', '🇿🇼',
      '🇮🇪', '🇳🇵', '🇳🇱', '🇺🇸', '🇨🇦',
      '🏴󠁧󠁢󠁳󠁣󠁴󠁿', '🇦🇪', '🇴🇲', '🇳🇦'
    ];
    bool showFlags = flags.contains(selectedEmoji);
    final List<int> colors = [0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFFE91E63, 0xFF9C27B0, 0xFF00BCD4, 0xFFF44336, 0xFFFFEB3B];

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
              title: const Text(
                'Edit Team Details',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Team Name',
                        labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: const TextStyle(color: AppColors.textDark),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: abbController,
                      decoration: InputDecoration(
                        labelText: 'Abbreviation',
                        labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: const TextStyle(color: AppColors.textDark),
                      maxLength: 5,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCaptainId,
                      decoration: InputDecoration(
                        labelText: 'Team Captain',
                        labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: AppColors.cardBg,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Captain Selected', style: TextStyle(color: AppColors.textDarkMuted)),
                        ),
                        ...team.players.map((p) => DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(p.name, style: const TextStyle(color: AppColors.textDark)),
                        )),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCaptainId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Logo Emoji', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setDialogState(() => showFlags = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: !showFlags ? Color(selectedColorHex).withOpacity(0.12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: !showFlags ? Color(selectedColorHex) : AppColors.borderGreen.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Symbols',
                                  style: TextStyle(
                                    color: !showFlags ? Color(selectedColorHex) : AppColors.textDarkSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setDialogState(() => showFlags = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: showFlags ? Color(selectedColorHex).withOpacity(0.12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: showFlags ? Color(selectedColorHex) : AppColors.borderGreen.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'ICC Flags',
                                  style: TextStyle(
                                    color: showFlags ? Color(selectedColorHex) : AppColors.textDarkSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (showFlags ? flags : emojis).map((emoji) {
                        final isSelected = selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedEmoji = emoji),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? Color(selectedColorHex).withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isSelected ? Color(selectedColorHex) : AppColors.borderGreen,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 18)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Theme Color', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...colors.map((colorHex) {
                          final isSelected = selectedColorHex == colorHex;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedColorHex = colorHex),
                            child: Container(
                              width: 32,
                              height: 32,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Color(colorHex) : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(colorHex),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: colorHex == 0xFFFFEB3B ? Colors.black87 : Colors.white,
                                        size: 14,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }),
                        Builder(
                          builder: (context) {
                            final isCustomSelected = !colors.contains(selectedColorHex);
                            return GestureDetector(
                              onTap: () {
                                _showCustomColorPicker(context, selectedColorHex, (selectedHex) {
                                  setDialogState(() {
                                    selectedColorHex = selectedHex;
                                  });
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCustomSelected ? Color(selectedColorHex) : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCustomSelected ? Color(selectedColorHex) : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCustomSelected ? Colors.transparent : AppColors.borderGreen,
                                      width: isCustomSelected ? 0 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    isCustomSelected ? Icons.check_rounded : Icons.colorize_rounded,
                                    color: isCustomSelected
                                        ? (((selectedColorHex >> 16) & 0xFF) * 0.299 + ((selectedColorHex >> 8) & 0xFF) * 0.587 + (selectedColorHex & 0xFF) * 0.114 > 186 ? Colors.black87 : Colors.white)
                                        : AppColors.textDarkSecondary,
                                    size: 14,
                                  ),
                                ),
                              ),
                            );
                          }
                        ),
                      ],
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
                    final abb = abbController.text.trim().toUpperCase();
                    if (name.isEmpty || abb.isEmpty) {
                      CustomSnackBar.show(
                        context,
                        message: 'Name and abbreviation are required.',
                        type: SnackBarType.error,
                      );
                      return;
                    }

                    final updatedTeam = Team(
                      id: team.id,
                      name: name,
                      abbreviation: abb,
                      logoEmoji: selectedEmoji,
                      logoColorHex: selectedColorHex,
                      players: team.players,
                      matchesPlayed: team.matchesPlayed,
                      matchesWon: team.matchesWon,
                      matchesLost: team.matchesLost,
                      netRunRate: team.netRunRate,
                      creatorId: team.creatorId,
                      captainId: selectedCaptainId,
                    );

                    appState.updateTeam(updatedTeam);
                    Navigator.pop(context);

                    CustomSnackBar.show(
                      context,
                      message: 'Team details updated successfully!',
                      type: SnackBarType.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPlayerDialog(BuildContext context, Player player, AppState appState) {
    final nameController = TextEditingController(text: player.name);
    String selectedRole = player.role;
    String selectedBatting = player.battingStyle == '-' ? 'None' : player.battingStyle;
    String selectedBowling = player.bowlingStyle == '-' ? 'None' : player.bowlingStyle;

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
                'Edit Player: ${player.name}',
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: const TextStyle(color: AppColors.textDark),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        message: 'Player name cannot be empty.',
                        type: SnackBarType.error,
                      );
                      return;
                    }

                    final updatedPlayer = Player(
                      id: player.id,
                      name: name,
                      role: selectedRole,
                      battingStyle: selectedBatting == 'None' ? '-' : selectedBatting,
                      bowlingStyle: selectedBowling == 'None' ? '-' : selectedBowling,
                      matchesPlayed: player.matchesPlayed,
                      runsScored: player.runsScored,
                      wicketsTaken: player.wicketsTaken,
                      ballsFaced: player.ballsFaced,
                      ballsBowled: player.ballsBowled,
                      runsConceded: player.runsConceded,
                      highestScore: player.highestScore,
                      bestBowling: player.bestBowling,
                    );

                    appState.updatePlayer(updatedPlayer);
                    Navigator.pop(context);

                    CustomSnackBar.show(
                      context,
                      message: 'Player info updated successfully!',
                      type: SnackBarType.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRemovePlayerConfirm(BuildContext context, Team team, Player player, AppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderWood, width: 1),
          ),
          title: const Text(
            'Confirm Removal',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            'Are you sure you want to remove ${player.name} from ${team.name}?',
            style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                appState.removePlayerFromTeam(team.id, player.id);
                Navigator.pop(context);

                CustomSnackBar.show(
                  context,
                  message: '${player.name} removed from ${team.name}.',
                  type: SnackBarType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomColorPicker(BuildContext context, int initialColor, Function(int) onColorSelected) {
    Color selectedColor = Color(initialColor);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderWood, width: 1),
          ),
          title: const Text(
            'Select Custom Color',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              colorPickerWidth: 280.0,
              pickerAreaHeightPercent: 0.6,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
              pickerAreaBorderRadius: BorderRadius.circular(12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                onColorSelected(selectedColor.value);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTurf,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Select', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
