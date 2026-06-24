import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/tournament_model.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../scorecard_screen.dart';
import '../../constants/app_colors.dart';
import '../main_navigation_screen.dart';

class TournamentDetailScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // Find the latest state of this tournament from appState
    final currentTour = appState.tournaments.firstWhere((t) => t.id == tournament.id, orElse: () => tournament);
    
    // Sort points table
    currentTour.updatePointsTable();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
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
            title: Text(currentTour.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
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
                  Tab(text: 'STANDINGS'),
                  Tab(text: 'FIXTURES'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPointsTableTab(context, currentTour),
                  _buildFixturesTab(context, currentTour, appState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsTableTab(BuildContext context, Tournament tour) {
    final standings = tour.pointsTable;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            color: AppColors.appBarBg,
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('Pos', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 6, child: Text('Team', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('P', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('W', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('L', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Pts', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('NRR', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: standings.length,
            itemBuilder: (context, index) {
              final entry = standings[index];
              final isTopTwo = index < 2;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.dividerGreen, width: 1)),
                ),
                child: Row(
                  children: [
                    // Position Indicator
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isTopTwo ? AppColors.accentCrease : AppColors.textDarkMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Team Name
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          Text(entry.team.logoEmoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.team.name,
                              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Matches Played
                    Expanded(
                      child: Text('${entry.played}', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.center),
                    ),
                    // Won
                    Expanded(
                      child: Text('${entry.won}', style: const TextStyle(color: AppColors.accentCrease, fontSize: 13), textAlign: TextAlign.center),
                    ),
                    // Lost
                    Expanded(
                      child: Text('${entry.lost}', style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                    ),
                    // Points
                    Expanded(
                      child: Text('${entry.points}', style: TextStyle(color: AppColors.pitchGold, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                    ),
                    // Net Run Rate
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.netRunRate.toStringAsFixed(2),
                        style: TextStyle(
                          color: entry.netRunRate >= 0 ? Colors.blueAccent : Colors.redAccent,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          
          // Qualification notes
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderWood),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.accentCrease, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Top 2 teams will qualify directly for the final match.',
                    style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixturesTab(BuildContext context, Tournament tour, AppState appState) {
    final matches = tour.matches;

    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month_outlined, color: AppColors.textDarkDisabled, size: 64),
              const SizedBox(height: 16),
              const Text(
                'No fixtures scheduled yet.',
                style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (appState.currentRole == UserRole.organizer)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () => _generateFixtures(context, tour, appState),
                  icon: const Icon(Icons.flash_on, size: 20),
                  label: const Text('GENERATE LEAGUE FIXTURES', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${match.teamA.name} vs ${match.teamB.name}',
                      style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildMatchBadge(match.status),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  match.status == MatchStatus.completed 
                      ? match.resultString 
                      : 'Venue: ${match.venue} • Overs: ${match.totalOvers}',
                  style: TextStyle(
                    color: match.status == MatchStatus.completed ? AppColors.woodMahogany : AppColors.textDarkMuted,
                    fontSize: 12,
                  ),
                  softWrap: true,
                  maxLines: null,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.primaryTurf, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScorecardScreen(match: match),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchBadge(MatchStatus status) {
    Color color = Colors.blue;
    String text = 'UPCOMING';

    if (status == MatchStatus.live) {
      color = Colors.red;
      text = 'LIVE';
    } else if (status == MatchStatus.completed) {
      color = Colors.amber;
      text = 'COMPLETED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _generateFixtures(BuildContext context, Tournament tour, AppState appState) {
    final registeredTeams = tour.teams;
    if (registeredTeams.length < 2) return;
    
    int matchIdCounter = 1;
    // Round robin pairing generator
    for (int i = 0; i < registeredTeams.length; i++) {
      for (int j = i + 1; j < registeredTeams.length; j++) {
        final match = CricketMatch(
          id: 'tour_m_${tour.id}_${matchIdCounter++}',
          teamA: registeredTeams[i],
          teamB: registeredTeams[j],
          totalOvers: 10,
          venue: 'CricX Turf Arena ${matchIdCounter - 1}',
          matchDate: DateTime.now().add(Duration(days: matchIdCounter)),
        );
        appState.addTournamentMatch(tour.id, match);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generated ${matchIdCounter - 1} matches/fixtures for this league!')),
    );
  }
}
