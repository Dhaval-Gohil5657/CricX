import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/tournament_model.dart';
import 'package:cricx/services/auth_service.dart';
import 'tournament_detail_screen.dart';
import 'create_tournament_screen.dart';
import '../../constants/custom_snackbar.dart';
import '../../constants/app_colors.dart';

class OrganizerDashboard extends StatelessWidget {
  final GlobalKey? tournamentsMainKey;

  const OrganizerDashboard({
    super.key,
    this.tournamentsMainKey,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = appState.currentRole;
    final currentUserId = AuthService.instance.currentUser?.uid;
    final searchQuery = appState.searchQuery;
    final tournaments = appState.filterByCreator && (role == UserRole.scorer || role == UserRole.organizer)
        ? appState.tournaments.where((t) => t.creatorId == currentUserId).toList()
        : appState.tournaments;

    final filteredTournaments = tournaments.where((t) {
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.trim().toLowerCase();
      return t.name.toLowerCase().contains(q) ||
             t.venue.toLowerCase().contains(q);
    }).toList();

    final showPlaceholder = tournaments.isEmpty && searchQuery.isEmpty;

    if (showPlaceholder) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
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
                    Icons.emoji_events_rounded,
                    color: AppColors.primaryTurf,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  (role == UserRole.scorer || role == UserRole.organizer)
                      ? 'No Tournaments Created'
                      : 'No Tournaments Available',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (role == UserRole.scorer || role == UserRole.organizer)
                      ? 'Create a tournament and add teams to start scheduling fixtures and tracking points.'
                      : 'No active or upcoming tournaments available at the moment. Please check back later!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textDarkSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (role == UserRole.scorer || role == UserRole.organizer) ...[
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    key: tournamentsMainKey,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateTournamentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Create Tournament'),
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
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Container(
              color: Colors.transparent,
              height: 38,
              child: TabBar(
                key: tournamentsMainKey,
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
                    filteredTournaments.where((t) => t.status == 'Ongoing').toList(), 
                    'No active tournaments found.'
                  ),
                  _buildTournamentsList(
                    context, 
                    filteredTournaments.where((t) => t.status == 'Upcoming').toList(), 
                    'No upcoming tournaments found.'
                  ),
                  _buildTournamentsList(
                    context, 
                    filteredTournaments.where((t) => t.status == 'Completed').toList(), 
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
    final appState = Provider.of<AppState>(context, listen: false);
    final searchQuery = appState.searchQuery;
    if (list.isEmpty) {
      final isSearching = searchQuery.isNotEmpty;
      if (isSearching) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: AppColors.textDarkMuted,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'No tournaments found matching "$searchQuery"',
                style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Center(
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
                  Icons.emoji_events_rounded,
                  color: AppColors.primaryTurf,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                emptyMessage,
                style: const TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tour = list[index];
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final dateStr = '${tour.startDate.day} ${months[tour.startDate.month - 1]} ${tour.startDate.year}';
        
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
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 13,
                              color: AppColors.woodMahogany,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Starts: $dateStr',
                              style: const TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          tour.status.toUpperCase(),
                          style: TextStyle(
                            color: tour.status == 'Ongoing' 
                                ? AppColors.primaryTurf 
                                : (tour.status == 'Completed' ? AppColors.woodMahogany : AppColors.textDarkMuted),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tour.name,
                      style: const TextStyle(color: AppColors.primaryTurf, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatChip(Icons.people_alt_rounded, '${tour.teams.length} Teams'),
                        const SizedBox(width: 16),
                        _buildStatChip(Icons.sports_cricket_rounded, '${tour.matches.length} Matches'),
                        const SizedBox(width: 16),
                        _buildStatChip(Icons.adjust_rounded, '${tour.defaultOvers} Overs'),
                      ],
                    ),
                    if (tour.status == 'Completed') ...[
                      ...() {
                        final winnerTeamList = tour.teams.where((t) => t.id == tour.winnerTeamId);
                        if (winnerTeamList.isEmpty) return <Widget>[];
                        return <Widget>[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 5),
                              Text(
                                'Winner: ${winnerTeamList.first.name}',
                                style: const TextStyle(
                                  color: AppColors.primaryTurf,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ];
                      }(),
                      if (tour.playerOfTheTournamentName != null && tour.playerOfTheTournamentName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            SizedBox(width: 2,),
                            const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Player of the Tournament: ${tour.playerOfTheTournamentName}',
                              style: const TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    const Divider(color: AppColors.dividerGreen, height: 16),
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

  Widget _buildStatChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: AppColors.primaryTurf,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDarkSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
