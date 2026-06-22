import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/team_model.dart';
import '../constants/app_colors.dart';

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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teams.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final team = teams[index];
          final isExpanded = _expandedTeamId == team.id;

          return Card(
            color: AppColors.cardBg,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isExpanded ? AppColors.accentCrease : AppColors.borderGreen,
                width: 1,
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
                    color: AppColors.accentCrease,
                  ),
                  onTap: () {
                    setState(() {
                      _expandedTeamId = isExpanded ? null : team.id;
                    });
                  },
                ),
                if (isExpanded) ...[
                  const Divider(color: AppColors.borderGreen, height: 1),
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
                            _buildStatBox('Points', '${team.points}', AppColors.pitchGold),
                            _buildStatBox('NRR', team.netRunRate.toStringAsFixed(2), Colors.blueAccent),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Squad Header
                        const Text(
                          'SQUAD PLAYERS',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Players List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: team.players.length,
                          itemBuilder: (context, pIndex) {
                            final player = team.players[pIndex];
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.dividerGreen, width: 0.5)),
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
}
