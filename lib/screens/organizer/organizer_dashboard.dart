import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/tournament_model.dart';
import 'tournament_detail_screen.dart';
import '../../constants/app_colors.dart';

class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final tournaments = appState.tournaments;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              color: Colors.transparent,
              height: 38,
              child: const TabBar(
                indicatorColor: AppColors.primaryTurf,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorPadding: EdgeInsets.only(bottom: 4),
                labelColor: AppColors.primaryTurf,
                unselectedLabelColor: AppColors.textDarkMuted,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(text: 'ACTIVE'),
                  Tab(text: 'UPCOMING'),
                  Tab(text: 'COMPLETED'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTournamentsList(
                    context, 
                    tournaments.where((t) => t.status == 'Ongoing').toList(), 
                    'No active tournaments found.'
                  ),
                  _buildTournamentsList(
                    context, 
                    tournaments.where((t) => t.status == 'Upcoming').toList(), 
                    'No upcoming tournaments found.'
                  ),
                  _buildTournamentsList(
                    context, 
                    tournaments.where((t) => t.status == 'Completed').toList(), 
                    'No completed tournaments found.'
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentsList(BuildContext context, List<Tournament> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_outlined, color: AppColors.textDarkDisabled, size: 48),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tour = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderWood.withOpacity(0.5),
              width: 1,
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
          child: Material(
            color: Colors.transparent,
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
                            color: AppColors.woodMahogany.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.woodMahogany.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tour.type.toUpperCase(),
                            style: const TextStyle(color: AppColors.woodMahogany, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          tour.status.toUpperCase(),
                          style: TextStyle(
                            color: tour.status == 'Ongoing' ? AppColors.primaryTurf : AppColors.textDarkMuted,
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
                    const Divider(color: AppColors.dividerGreen, height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('View Points Table & Fixtures', style: TextStyle(color: AppColors.primaryTurf, fontSize: 12, fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_forward_ios, color: AppColors.primaryTurf, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
