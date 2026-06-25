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
              final isQualified = tour.playoffType == 'Semifinals & Final' ? index < 4 : index < 2;

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
                          color: isQualified ? AppColors.accentCrease : AppColors.textDarkMuted,
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
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.accentCrease, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tour.playoffType == 'Semifinals & Final'
                        ? 'Top 4 teams will qualify for the semi-finals.'
                        : 'Top 2 teams will qualify directly for the final match.',
                    style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11),
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

    final leagueMatches = matches.where((m) => m.id.contains('_league_')).toList();
    final playoffMatches = matches.where((m) => m.id.contains('_sf') || m.id.contains('_final')).toList();

    final allLeagueCompleted = leagueMatches.isNotEmpty && leagueMatches.every((m) => m.status == MatchStatus.completed);
    final hasPlayoffs = playoffMatches.isNotEmpty;
    
    // Check if both Semifinals are completed but Final is not yet generated
    final sfMatches = playoffMatches.where((m) => m.id.contains('_sf')).toList();
    final finalGenerated = playoffMatches.any((m) => m.id.contains('_final'));
    final sfCompleted = sfMatches.length == 2 && sfMatches.every((m) => m.status == MatchStatus.completed);

    // Check if Final is completed to show Champion banner
    CricketMatch? finalMatch;
    try {
      finalMatch = playoffMatches.firstWhere((m) => m.id.contains('_final'));
    } catch (_) {}
    final tournamentCompleted = finalMatch != null && finalMatch.status == MatchStatus.completed;

    // Build the Playoff widgets list (Actual matches or placeholders)
    final List<Widget> semifinalWidgets = [];
    final List<Widget> finalWidgets = [];
    if (leagueMatches.isNotEmpty) {
      if (hasPlayoffs) {
        CricketMatch? sf1Match;
        CricketMatch? sf2Match;
        CricketMatch? finalMatchObject;
        for (var m in playoffMatches) {
          if (m.id.endsWith('_sf1')) sf1Match = m;
          if (m.id.endsWith('_sf2')) sf2Match = m;
          if (m.id.endsWith('_final')) finalMatchObject = m;
        }

        if (tour.playoffType == 'Semifinals & Final') {
          if (sf1Match != null) semifinalWidgets.add(_buildMatchCard(context, sf1Match));
          if (sf2Match != null) semifinalWidgets.add(_buildMatchCard(context, sf2Match));
          
          if (finalMatchObject != null) {
            finalWidgets.add(_buildMatchCard(context, finalMatchObject));
          } else {
            finalWidgets.add(_buildLockedPlayoffCard(
              'Final: Winner of SF1 vs Winner of SF2',
              'LOCKED • Will unlock when Semi-Finals are completed',
            ));
          }
        } else {
          // Direct Final
          if (finalMatchObject != null) {
            finalWidgets.add(_buildMatchCard(context, finalMatchObject));
          }
        }
      } else {
        // Show placeholders
        if (tour.playoffType == 'Direct Final') {
          finalWidgets.add(_buildLockedPlayoffCard(
            'Final: Rank 1 vs Rank 2',
            'LOCKED • Will unlock after all league stage matches',
          ));
        } else if (tour.playoffType == 'Semifinals & Final') {
          semifinalWidgets.add(_buildLockedPlayoffCard(
            'Semi-Final 1: Rank 1 vs Rank 2',
            'LOCKED • Will unlock after all league stage matches',
          ));
          semifinalWidgets.add(_buildLockedPlayoffCard(
            'Semi-Final 2: Rank 3 vs Rank 4',
            'LOCKED • Will unlock after all league stage matches',
          ));
          finalWidgets.add(_buildLockedPlayoffCard(
            'Final: Winner of SF1 vs Winner of SF2',
            'LOCKED • Will unlock when Semi-Finals are completed',
          ));
        }
      }
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Champion Banner
        if (tournamentCompleted) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 48),
                const SizedBox(height: 8),
                const Text(
                  '🏆 TOURNAMENT CHAMPION 🏆',
                  style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  finalMatch.resultString.split(' won').first,
                  style: const TextStyle(color: AppColors.primaryTurf, fontWeight: FontWeight.w900, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  finalMatch.resultString,
                  style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],

        // Playoff Actions & Status
        if (allLeagueCompleted && !hasPlayoffs) ...[
          if (appState.currentRole == UserRole.organizer) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryTurf.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryTurf.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'League matches completed! Ready for playoffs.',
                    style: TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTurf,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _generatePlayoffs(context, tour, appState),
                    icon: const Icon(Icons.auto_awesome),
                    label: Text('GENERATE PLAYOFFS (${tour.playoffType})'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryTurf.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryTurf.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primaryTurf, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All league matches are completed. Playoff matches are generated automatically.',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else if (hasPlayoffs && sfCompleted && !finalGenerated && tour.playoffType == 'Semifinals & Final') ...[
          if (appState.currentRole == UserRole.organizer) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryTurf.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryTurf.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Semi-Final matches completed! Ready for Final.',
                    style: TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTurf,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _generateFinalFromSemis(context, tour, appState),
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('GENERATE FINAL MATCH'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryTurf.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryTurf.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.primaryTurf, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Semi-Final matches are completed. The Final match is generated automatically.',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        // League Stage Header & Fixtures
        if (leagueMatches.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.format_list_bulleted, color: AppColors.primaryTurf, size: 16),
              SizedBox(width: 6),
              Text(
                'LEAGUE STAGE',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...leagueMatches.map((m) => _buildMatchCard(context, m)),
          const SizedBox(height: 20),
        ],

        // Semifinals Header & Fixtures (only show if tour has Semifinals & Final playoff type)
        if (tour.playoffType == 'Semifinals & Final' && semifinalWidgets.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.flash_on, color: Colors.amber, size: 16),
              SizedBox(width: 6),
              Text(
                'SEMI-FINALS',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...semifinalWidgets,
          const SizedBox(height: 20),
        ],

        // Final Header & Fixtures
        if (finalWidgets.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 16),
              SizedBox(width: 6),
              Text(
                'FINAL',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...finalWidgets,
        ],
      ],
    );
  }

  Widget _buildMatchCard(BuildContext context, CricketMatch match) {
    String prefix = '';
    if (match.id.contains('_sf1')) prefix = 'Semi-Final 1: ';
    if (match.id.contains('_sf2')) prefix = 'Semi-Final 2: ';
    if (match.id.contains('_final')) prefix = 'Final: ';

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
                  '$prefix${match.teamA.name} vs ${match.teamB.name}',
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
                fontWeight: FontWeight.w500
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
  }

  Widget _buildLockedPlayoffCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderGreen.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline, color: AppColors.textDarkMuted, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textDarkMuted, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBadge(MatchStatus status) {
    Color color = Colors.blue;
    String text = 'UPCOMING';

    if (status == MatchStatus.live) {
      color = Colors.red;
      text = 'LIVE';
    } else if (status == MatchStatus.completed) {
      color = AppColors.primaryTurf;
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
    
    // Circle Method Round-Robin scheduling algorithm
    final List<Team?> tempTeams = List.from(registeredTeams);
    if (tempTeams.length % 2 != 0) {
      tempTeams.add(null); // Add a null entry representing a 'BYE'
    }

    final int numTeams = tempTeams.length;
    final int rounds = numTeams - 1;
    final int matchesPerRound = numTeams ~/ 2;
    final List<CricketMatch> newMatches = [];
    int matchIdCounter = 1;

    for (int round = 0; round < rounds; round++) {
      for (int i = 0; i < matchesPerRound; i++) {
        final int homeIndex = (round + i) % (numTeams - 1);
        int awayIndex = (round + numTeams - 1 - i) % (numTeams - 1);

        // Position 0 is fixed for home team when i == 0, away index is fixed at last index
        if (i == 0) {
          awayIndex = numTeams - 1;
        }

        final Team? homeTeam = tempTeams[homeIndex];
        final Team? awayTeam = tempTeams[awayIndex];

        // Skip matches involving a BYE (null)
        if (homeTeam == null || awayTeam == null) {
          continue;
        }

        final match = CricketMatch(
          id: 'tour_m_${tour.id}_league_${matchIdCounter++}',
          teamA: homeTeam,
          teamB: awayTeam,
          totalOvers: tour.defaultOvers,
          venue: '${tour.venue} #${matchIdCounter - 1}',
          matchDate: tour.startDate.add(Duration(days: round)),
          tournamentId: tour.id,
          tournamentName: tour.name,
        );
        newMatches.add(match);
      }
    }

    appState.addTournamentMatches(tour.id, newMatches);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generated ${newMatches.length} league matches sorted by round!')),
    );
  }

  void _generatePlayoffs(BuildContext context, Tournament tour, AppState appState) {
    tour.updatePointsTable();
    final standings = tour.pointsTable;
    if (standings.length < 2) return;

    final List<CricketMatch> playoffMatches = [];

    if (tour.playoffType == 'Direct Final') {
      final top1 = standings[0].team;
      final top2 = standings[1].team;

      final match = CricketMatch(
        id: 'tour_m_${tour.id}_final',
        teamA: top1,
        teamB: top2,
        totalOvers: tour.defaultOvers,
        venue: tour.venue.isNotEmpty ? '${tour.venue} (Final)' : 'Final Venue',
        matchDate: DateTime.now().add(const Duration(days: 1)),
        tournamentId: tour.id,
        tournamentName: tour.name,
      );
      playoffMatches.add(match);

      appState.addTournamentMatches(tour.id, playoffMatches);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated Final Match: ${top1.name} vs ${top2.name}!')),
      );
    } else if (tour.playoffType == 'Semifinals & Final') {
      if (standings.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least 4 teams are required to generate semi-finals')),
        );
        return;
      }
      final top1 = standings[0].team;
      final top2 = standings[1].team;
      final top3 = standings[2].team;
      final top4 = standings[3].team;

      // SF1: Top 1 vs Top 2
      final sf1 = CricketMatch(
        id: 'tour_m_${tour.id}_sf1',
        teamA: top1,
        teamB: top2,
        totalOvers: tour.defaultOvers,
        venue: tour.venue.isNotEmpty ? '${tour.venue} (Semi-Final 1)' : 'SF1 Venue',
        matchDate: DateTime.now().add(const Duration(days: 1)),
        tournamentId: tour.id,
        tournamentName: tour.name,
      );

      // SF2: Top 3 vs Top 4
      final sf2 = CricketMatch(
        id: 'tour_m_${tour.id}_sf2',
        teamA: top3,
        teamB: top4,
        totalOvers: tour.defaultOvers,
        venue: tour.venue.isNotEmpty ? '${tour.venue} (Semi-Final 2)' : 'SF2 Venue',
        matchDate: DateTime.now().add(const Duration(days: 2)),
        tournamentId: tour.id,
        tournamentName: tour.name,
      );

      playoffMatches.addAll([sf1, sf2]);
      appState.addTournamentMatches(tour.id, playoffMatches);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated Semi-Finals: ${top1.name} vs ${top2.name} & ${top3.name} vs ${top4.name}!')),
      );
    }
  }

  void _generateFinalFromSemis(BuildContext context, Tournament tour, AppState appState) {
    CricketMatch? sf1;
    CricketMatch? sf2;
    try {
      sf1 = tour.matches.firstWhere((m) => m.id.endsWith('_sf1'));
      sf2 = tour.matches.firstWhere((m) => m.id.endsWith('_sf2'));
    } catch (_) {}

    if (sf1 == null || sf2 == null) return;
    if (sf1.status != MatchStatus.completed || sf2.status != MatchStatus.completed) return;

    Team? winner1;
    if (sf1.resultString.contains(sf1.teamA.name)) {
      winner1 = sf1.teamA;
    } else if (sf1.resultString.contains(sf1.teamB.name)) {
      winner1 = sf1.teamB;
    }

    Team? winner2;
    if (sf2.resultString.contains(sf2.teamA.name)) {
      winner2 = sf2.teamA;
    } else if (sf2.resultString.contains(sf2.teamB.name)) {
      winner2 = sf2.teamB;
    }

    if (winner1 == null || winner2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine winners from semi-finals. Make sure matches have a clear winner.')),
      );
      return;
    }

    final finalMatch = CricketMatch(
      id: 'tour_m_${tour.id}_final',
      teamA: winner1,
      teamB: winner2,
      totalOvers: tour.defaultOvers,
      venue: tour.venue.isNotEmpty ? '${tour.venue} (Final)' : 'Final Venue',
      matchDate: DateTime.now().add(const Duration(days: 1)),
      tournamentId: tour.id,
      tournamentName: tour.name,
    );
    appState.addTournamentMatch(tour.id, finalMatch);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated Final Match: ${winner1.name} vs ${winner2.name}!'),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
