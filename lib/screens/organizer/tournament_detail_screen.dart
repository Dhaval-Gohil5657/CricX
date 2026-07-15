import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/tournament_model.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../scorecard_screen.dart';
import '../../constants/app_colors.dart';
import '../../constants/custom_snackbar.dart';
import '../main_navigation_screen.dart';
import 'fixture_draft_screen.dart';
import '../scorer/toss_setup_screen.dart';
import '../scorer/live_scoring_screen.dart';
import 'package:cricx/services/auth_service.dart';

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
          // Points Table Card Wrapper
          Card(
            elevation: 0,
            color: AppColors.cardBg,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.borderGreen.withOpacity(0.3), width: 1.2),
            ),
            child: Column(
              children: [
                // Header Row
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F6F2), // Soft green tint
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: const Row(
                    children: [
                      Expanded(flex: 1, child: Text('Pos', style: TextStyle(color: AppColors.textDark, fontSize: 11, fontWeight: FontWeight.w800))),
                      Expanded(flex: 6, child: Text('Team', style: TextStyle(color: AppColors.textDark, fontSize: 11, fontWeight: FontWeight.w800))),
                      Expanded(child: Text('P', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(child: Text('W', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(child: Text('L', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(child: Text('Pts', style: TextStyle(color: AppColors.textDark, fontSize: 11, fontWeight: FontWeight.w800), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('NRR', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                
                // Standings List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: standings.length,
                  itemBuilder: (context, index) {
                    final entry = standings[index];
                    final leagueMatches = tour.matches.where((m) => m.id.contains('_league_')).toList();
                    final allLeagueCompleted = leagueMatches.isNotEmpty && leagueMatches.every((m) => m.status == MatchStatus.completed);
                    final isQualified = allLeagueCompleted && (tour.playoffType == 'Semifinals & Final' ? index < 4 : index < 2);

                    final nrrSign = entry.netRunRate > 0 ? '+' : '';
                    final isLastRow = index == standings.length - 1;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isQualified ? AppColors.primaryTurf.withOpacity(0.04) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.dividerGreen.withOpacity(0.5),
                            width: isLastRow ? 0 : 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Position Indicator
                          Expanded(
                            flex: 1,
                            child: Text(
                              isQualified ? 'Q' : '${index + 1}',
                              style: TextStyle(
                                color: isQualified ? AppColors.primaryTurf : AppColors.textDarkMuted,
                                fontWeight: FontWeight.w800,
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
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.team.name,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Played
                          Expanded(
                            child: Text('${entry.played}', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12.5), textAlign: TextAlign.center),
                          ),
                          // Won
                          Expanded(
                            child: Text('${entry.won}', style: const TextStyle(color: AppColors.accentCrease, fontSize: 12.5, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                          ),
                          // Lost
                          Expanded(
                            child: Text('${entry.lost}', style: const TextStyle(color: Colors.redAccent, fontSize: 12.5), textAlign: TextAlign.center),
                          ),
                          // Points
                          Expanded(
                            child: Text(
                              '${entry.points}',
                              style: const TextStyle(
                                color: AppColors.woodMahogany,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Net Run Rate
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$nrrSign${entry.netRunRate.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: entry.netRunRate >= 0 ? AppColors.primaryTurf : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Qualification notes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryTurf.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryTurf.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primaryTurf, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tour.playoffType == 'Semifinals & Final'
                        ? 'Qualifying Zone: Top 4 teams will qualify for the semi-finals.'
                        : 'Qualifying Zone: Top 2 teams will qualify directly for the final match.',
                    style: const TextStyle(
                      color: AppColors.primaryTurf,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
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
    final role = appState.currentRole;
    final currentUserId = AuthService.instance.currentUser?.uid;
    final isCreator = tour.creatorId == null || tour.creatorId == currentUserId;
    final canDeclarePOT = (appState.currentRole == UserRole.scorer || appState.currentRole == UserRole.organizer) && isCreator;

    if (matches.isEmpty) {
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
                  Icons.calendar_month_outlined,
                  color: AppColors.primaryTurf,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Fixtures Scheduled',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate fixtures to schedule round-robin matches for all registered teams.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
               if ((role == UserRole.organizer || role == UserRole.scorer) &&
                (tour.creatorId == null || tour.creatorId == AuthService.instance.currentUser?.uid))
                 ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primaryTurf,
                     foregroundColor: Colors.white,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

    final leagueMatches = matches.where((m) => (m.stage?.toLowerCase().contains('league') ?? false) || m.id.contains('_league_')).toList();
    final playoffMatches = matches.where((m) => (m.stage?.toLowerCase().contains('semi') ?? false) || (m.stage?.toLowerCase().contains('final') ?? false) || m.id.contains('_sf') || m.id.contains('_final')).toList();

    final allLeagueCompleted = leagueMatches.isNotEmpty && leagueMatches.every((m) => m.status == MatchStatus.completed);
    final hasPlayoffs = playoffMatches.isNotEmpty;
    
    // Check if both Semifinals are completed but Final is not yet generated
    final sfMatches = playoffMatches.where((m) => (m.stage?.toLowerCase().contains('semi') ?? false) || m.id.contains('_sf')).toList();
    final finalGenerated = playoffMatches.any((m) => (m.stage?.toLowerCase().contains('final') ?? false) || m.id.contains('_final'));
    final sfCompleted = sfMatches.length == 2 && sfMatches.every((m) => m.status == MatchStatus.completed);

    // Check if Final is completed to show Champion banner
    CricketMatch? finalMatch;
    try {
      finalMatch = playoffMatches.firstWhere((m) => (m.stage?.toLowerCase().contains('final') ?? false) || m.id.contains('_final'));
    } catch (_) {}
    final tournamentCompleted = finalMatch != null && finalMatch.status == MatchStatus.completed;

    CricketMatch? sf1Match;
    CricketMatch? sf2Match;
    if (sfMatches.isNotEmpty) {
      sf1Match = sfMatches[0];
      if (sfMatches.length > 1) {
        sf2Match = sfMatches[1];
      }
    }

    // Build the Playoff widgets list (Actual matches or placeholders)
    final List<Widget> semifinalWidgets = [];
    final List<Widget> finalWidgets = [];
    if (leagueMatches.isNotEmpty) {
      if (hasPlayoffs) {
        CricketMatch? sf1Match;
        CricketMatch? sf2Match;
        CricketMatch? finalMatchObject;
        
        final localSfMatches = playoffMatches.where((m) => (m.stage?.toLowerCase().contains('semi') ?? false) || m.id.contains('_sf')).toList();
        if (localSfMatches.isNotEmpty) {
          sf1Match = localSfMatches[0];
          if (localSfMatches.length > 1) {
            sf2Match = localSfMatches[1];
          }
        }
        try {
          finalMatchObject = playoffMatches.firstWhere((m) => (m.stage?.toLowerCase().contains('final') ?? false) || m.id.contains('_final'));
        } catch (_) {}

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

    // Default to playoffs sub-tab if playoffs are already generated or all league matches are completed,
    // otherwise default to league matches.
    String activeSubTab = (hasPlayoffs || allLeagueCompleted) ? 'playoffs' : 'league';

    return StatefulBuilder(
      builder: (context, setState) {
        Widget _buildSegmentButton(String tab, String label, IconData icon) {
          final isSelected = activeSubTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  activeSubTab = tab;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<Color?>(
                      duration: const Duration(milliseconds: 250),
                      tween: ColorTween(
                        end: isSelected ? Colors.white : AppColors.textDarkMuted,
                      ),
                      builder: (context, color, child) {
                        return Icon(
                          icon,
                          size: 16,
                          color: color,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDarkSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final switcher = Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.borderGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGreen.withOpacity(0.3)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: activeSubTab == 'league' ? Alignment.centerLeft : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryTurf,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildSegmentButton('league', 'League Stage', Icons.sports_cricket_rounded),
                  _buildSegmentButton('playoffs', 'Playoffs', Icons.emoji_events),
                ],
              ),
            ],
          ),
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
              child: switcher,
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                children: [
            
            if (activeSubTab == 'league') ...[
              // League Stage Header & Fixtures
              if (leagueMatches.isNotEmpty) ...[
                ...leagueMatches.map((m) => _buildMatchCard(context, m)),
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No league stage matches generated yet.',
                      style: TextStyle(color: AppColors.textDarkMuted, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],

            if (activeSubTab == 'playoffs') ...[
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
                        finalMatch!.resultString.split(' won').first,
                        style: const TextStyle(color: AppColors.primaryTurf, fontWeight: FontWeight.w900, fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        finalMatch.resultString,
                        style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.amber, height: 1),
                      const SizedBox(height: 12),
                      if (tour.playerOfTheTournamentId != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Player of the Tournament: ${tour.playerOfTheTournamentName}',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (canDeclarePOT) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showPlayerOfTheTournamentSelector(context, tour, appState),
                                  child: const Icon(Icons.edit_rounded, color: AppColors.primaryTurf, size: 14),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else if (canDeclarePOT) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTurf,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            elevation: 0,
                          ),
                          onPressed: () => _showPlayerOfTheTournamentSelector(context, tour, appState),
                          icon: const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                          label: const Text(
                            'DECLARE PLAYER OF THE TOURNAMENT',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Playoff Actions & Status
               if (allLeagueCompleted && !hasPlayoffs) ...[
                if (appState.currentRole == UserRole.organizer &&
                    (tour.creatorId == null || tour.creatorId == AuthService.instance.currentUser?.uid)) ...[
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
                if (appState.currentRole == UserRole.organizer &&
                    (tour.creatorId == null || tour.creatorId == AuthService.instance.currentUser?.uid)) ...[
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
          ],
        ),
      ),
    ],
  );
      },
    );
  }

   Widget _buildMatchCard(BuildContext context, CricketMatch match) {
    final appState = Provider.of<AppState>(context, listen: false);
    final role = appState.currentRole;
    final currentUserId = AuthService.instance.currentUser?.uid;

    // Format match date and time
    final date = match.matchDate;
    final String amPm = date.hour >= 12 ? 'PM' : 'AM';
    final int displayHour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final String formattedDateTime = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${displayHour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(match.matchDate.year, match.matchDate.month, match.matchDate.day);
    final bool canStart = match.status == MatchStatus.live ||
        (match.status == MatchStatus.upcoming && (matchDay.isBefore(today) || matchDay.isAtSameMomentAs(today)));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: match.status == MatchStatus.live
              ? AppColors.primaryTurf.withOpacity(0.4)
              : AppColors.borderWood.withOpacity(0.5),
          width: match.status == MatchStatus.live ? 1.5 : 1,
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
                builder: (context) => ScorecardScreen(match: match),
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
                    Text(
                      match.venue,
                      style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                    ),
                    if (match.status == MatchStatus.live)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (match.status == MatchStatus.completed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.dividerGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FINISHED',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.woodMahogany.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'UPCOMING',
                          style: TextStyle(
                            color: AppColors.woodMahogany,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Team A row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(match.teamA.logoColorHex).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(match.teamA.logoEmoji, style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          match.teamA.name,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      match.teamAInnings != null ? '${match.teamAInnings!.runs}/${match.teamAInnings!.wickets}' : '-',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Team B row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(match.teamB.logoColorHex).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(match.teamB.logoEmoji, style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          match.teamB.name,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      match.teamBInnings != null ? '${match.teamBInnings!.runs}/${match.teamBInnings!.wickets}' : '-',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                
                const Divider(color: AppColors.borderGreen, height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        match.status == MatchStatus.upcoming
                            ? 'Scheduled: $formattedDateTime'
                            : match.statusText,
                        style: TextStyle(
                          color: match.status == MatchStatus.completed
                              ? AppColors.woodMahogany
                              : (match.status == MatchStatus.live
                                  ? AppColors.primaryTurf
                                  : AppColors.textDarkSecondary),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                     if ((role == UserRole.scorer || role == UserRole.organizer) &&
                        canStart &&
                        (match.creatorId == null || match.creatorId == currentUserId))
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: match.status == MatchStatus.live ? AppColors.primaryTurf : AppColors.woodMahogany,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            if (match.status == MatchStatus.live) {
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
                          child: Text(match.status == MatchStatus.live ? 'SCORE' : 'START'),
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.woodMahogany,
                        size: 14,
                      ),
                  ],
                ),
              ],
            ),
          ),
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

  List<CricketMatch> _reorderMatchesToAvoidConsecutive(List<CricketMatch> matches) {
    if (matches.length <= 2) return matches;
    
    final List<CricketMatch> pool = List.from(matches);
    final List<CricketMatch> result = [];
    
    // Start with the first match
    result.add(pool.removeAt(0));
    
    while (pool.isNotEmpty) {
      int bestIndex = 0;
      int bestPenalty = 999;
      
      final lastMatch = result.last;
      final lastTeams = {lastMatch.teamA.id, lastMatch.teamB.id};
      
      final secondLastTeams = result.length >= 2
          ? {result[result.length - 2].teamA.id, result[result.length - 2].teamB.id}
          : <String>{};
          
      for (int i = 0; i < pool.length; i++) {
        final candidate = pool[i];
        final candTeams = {candidate.teamA.id, candidate.teamB.id};
        
        int penalty = 0;
        final overlapLast = candTeams.intersection(lastTeams).length;
        penalty += overlapLast * 10;
        
        final overlapSecondLast = candTeams.intersection(secondLastTeams).length;
        penalty += overlapSecondLast * 2;
        
        if (penalty < bestPenalty) {
          bestPenalty = penalty;
          bestIndex = i;
        }
      }
      result.add(pool.removeAt(bestIndex));
    }
    return result;
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
          creatorId: tour.creatorId,
        );
        newMatches.add(match);
      }
    }

    // Reorder matches to minimize consecutive matches for any single team
    final reorderedMatches = _reorderMatchesToAvoidConsecutive(newMatches);

    // Transition to the Fixture Draft Screen to pick date/time
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FixtureDraftScreen(
          tournament: tour,
          matches: reorderedMatches,
        ),
      ),
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
        creatorId: tour.creatorId,
      );
      playoffMatches.add(match);
    } else if (tour.playoffType == 'Semifinals & Final') {
      if (standings.length < 4) {
        CustomSnackBar.show(
          context,
          message: 'At least 4 teams are required to generate semi-finals',
          type: SnackBarType.error,
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
        creatorId: tour.creatorId,
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
        creatorId: tour.creatorId,
      );

      playoffMatches.addAll([sf1, sf2]);
    }

    // Launch FixtureDraftScreen to let creator choose date/time/venue for playoffs
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FixtureDraftScreen(
          tournament: tour,
          matches: playoffMatches,
        ),
      ),
    );
  }

  void _generateFinalFromSemis(BuildContext context, Tournament tour, AppState appState) {
    CricketMatch? sf1;
    CricketMatch? sf2;
    try {
      sf1 = tour.matches.firstWhere((m) => m.id.endsWith('_sf1') || m.id.contains('_sf1'));
      sf2 = tour.matches.firstWhere((m) => m.id.endsWith('_sf2') || m.id.contains('_sf2'));
    } catch (_) {
      final sfMatches = tour.matches.where((m) => (m.stage?.toLowerCase().contains('semi') ?? false) || m.id.contains('_sf')).toList();
      if (sfMatches.isNotEmpty) {
        sf1 = sfMatches[0];
        if (sfMatches.length > 1) {
          sf2 = sfMatches[1];
        }
      }
    }

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
      CustomSnackBar.show(
        context,
        message: 'Could not determine winners from semi-finals. Make sure matches have a clear winner.',
        type: SnackBarType.error,
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
      creatorId: tour.creatorId,
    );

    // Launch FixtureDraftScreen to let creator choose date/time/venue for Final
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FixtureDraftScreen(
          tournament: tour,
          matches: [finalMatch],
        ),
      ),
    );
  }

  void _showPlayerOfTheTournamentSelector(BuildContext context, Tournament tour, AppState appState) {
    final allPlayers = tour.teams.expand((t) => t.players).toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                'Select Player of the Tournament 🏆',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: AppColors.dividerGreen),
            Expanded(
              child: allPlayers.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No players registered in tournament teams.',
                          style: TextStyle(color: AppColors.textDarkSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: allPlayers.length,
                      itemBuilder: (context, index) {
                        final player = allPlayers[index];
                        final team = tour.teams.firstWhere((t) => t.players.any((p) => p.id == player.id), orElse: () => tour.teams.first);
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryTurf.withOpacity(0.1),
                            child: Text(
                              player.name[0],
                              style: const TextStyle(color: AppColors.primaryTurf, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          subtitle: Text(
                            '${player.role} • ${team.name}',
                            style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11),
                          ),
                          onTap: () {
                            appState.declarePlayerOfTheTournament(tour.id, player.id, player.name);
                            Navigator.pop(context);
                            CustomSnackBar.show(
                              context,
                              message: '${player.name} declared Player of the Tournament!',
                              type: SnackBarType.success,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
