import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/tournament_model.dart';
import 'create_tournament_screen.dart';
import 'tournament_detail_screen.dart';
import '../../constants/app_colors.dart';

class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final tournaments = appState.tournaments;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament Actions
              const Text(
                'TOURNAMENT MANAGER',
                style: TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                color: AppColors.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderGreen, width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 30),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Tournament',
                                style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create leagues, points tables & schedules',
                                style: TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.add_circle, color: AppColors.accentCrease, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'ACTIVE TOURNAMENTS',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (tournaments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGreen, width: 1),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.emoji_events_outlined, color: AppColors.textDarkDisabled, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No tournaments created yet.\nTap above to launch your first league!',
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
                  itemCount: tournaments.length,
                  itemBuilder: (context, index) {
                    final tour = tournaments[index];
                    return Card(
                      color: AppColors.appBarBg,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.borderGreen, width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TournamentDetailScreen(tournament: tour),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tour.type.toUpperCase(),
                                      style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    tour.status.toUpperCase(),
                                    style: TextStyle(
                                      color: tour.status == 'Ongoing' ? AppColors.accentCrease : AppColors.textDarkMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tour.name,
                                style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Teams: ${tour.teams.length} participating • Matches Scheduled: ${tour.matches.length}',
                                style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                              ),
                              const Divider(color: AppColors.borderGreen, height: 24),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('View Points Table & Fixtures', style: TextStyle(color: AppColors.accentCrease, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Icon(Icons.arrow_forward_ios, color: AppColors.accentCrease, size: 14),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
