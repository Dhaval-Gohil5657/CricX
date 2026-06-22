import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/match_model.dart';
import 'create_match_screen.dart';
import 'create_team_screen.dart';
import 'live_scoring_screen.dart';
import 'toss_setup_screen.dart';
import '../../constants/app_colors.dart';

class ScorerDashboard extends StatelessWidget {
  const ScorerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final upcomingMatches = appState.matches.where((m) => m.status == MatchStatus.upcoming).toList();
    final liveMatches = appState.matches.where((m) => m.status == MatchStatus.live).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Actions
              const Text(
                'QUICK CREATORS',
                style: TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCreateCard(
                      context,
                      title: 'Create Team',
                      subtitle: 'Add a new squad & players',
                      icon: Icons.group_add_rounded,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateTeamScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCreateCard(
                      context,
                      title: 'Schedule Match',
                      subtitle: 'Set up teams, venue & overs',
                      icon: Icons.sports_cricket_rounded,
                      color: AppColors.accentCrease,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateMatchScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Match scoring section
              if (liveMatches.isNotEmpty) ...[
                const Text(
                  'RESUME LIVE SCORING',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: liveMatches.length,
                  itemBuilder: (context, index) {
                    final match = liveMatches[index];
                    return _buildScoringMatchTile(context, match, appState, isLive: true);
                  },
                ),
                const SizedBox(height: 20),
              ],

              const Text(
                'UPCOMING MATCHES TO START',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (upcomingMatches.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGreen, width: 1),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: AppColors.textDarkDisabled, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'No upcoming matches found.\nCreate a match to begin scoring.',
                        style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingMatches.length,
                  itemBuilder: (context, index) {
                    final match = upcomingMatches[index];
                    return _buildScoringMatchTile(context, match, appState, isLive: false);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGreen, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoringMatchTile(BuildContext context, CricketMatch match, AppState appState, {required bool isLive}) {
    return Card(
      color: AppColors.appBarBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLive ? AppColors.accentCrease.withOpacity(0.3) : AppColors.borderGreen,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.venue,
                  style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                ),
                if (isLive)
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('LIVE SCORING', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.teamA.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(match.teamB.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLive ? AppColors.accentCrease : Colors.blue,
                    foregroundColor: isLive ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (isLive) {
                      appState.setActiveScoringMatch(match);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LiveScoringScreen(match: match)),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TossSetupScreen(match: match)),
                      );
                    }
                  },
                  child: Text(
                    isLive ? 'SCORE' : 'START',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
