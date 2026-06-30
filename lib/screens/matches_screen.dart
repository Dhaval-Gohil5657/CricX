import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';
import 'scorecard_screen.dart';
import 'scorer/live_scoring_screen.dart';
import 'scorer/toss_setup_screen.dart';
import '../constants/app_colors.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String _activeSubTab = 'friendly'; // 'friendly' or 'tournament'
  String? _selectedTournamentId = 'all';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = appState.currentRole;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final allVisibleMatches = (role == UserRole.scorer || role == UserRole.organizer)
        ? appState.matches.where((m) => m.creatorId == null || m.creatorId == currentUserId).toList()
        : appState.matches;

    final allVisibleTournaments = (role == UserRole.scorer || role == UserRole.organizer)
        ? appState.tournaments.where((t) => t.creatorId == null || t.creatorId == currentUserId).toList()
        : appState.tournaments;

    // Reset selected tournament if it's not present in the current appState tournaments list anymore
    if (_selectedTournamentId != 'all' &&
        _selectedTournamentId != null &&
        !allVisibleTournaments.any((t) => t.id == _selectedTournamentId)) {
      _selectedTournamentId = 'all';
    }

    final friendlyMatches = allVisibleMatches
        .where((m) => m.tournamentId == null || m.tournamentId!.isEmpty)
        .toList();
    final tournamentMatches = allVisibleMatches
        .where((m) => m.tournamentId != null && m.tournamentId!.isNotEmpty)
        .toList();

    final filteredTournamentMatches = _selectedTournamentId == 'all' || _selectedTournamentId == null
        ? tournamentMatches
        : tournamentMatches.where((m) => m.tournamentId == _selectedTournamentId).toList();

    final activeMatches = _activeSubTab == 'friendly' ? friendlyMatches : filteredTournamentMatches;

    final live = activeMatches.where((m) => m.status == MatchStatus.live).toList();
    final upcoming = activeMatches.where((m) => m.status == MatchStatus.upcoming).toList();
    final completed = activeMatches.where((m) => m.status == MatchStatus.completed).toList();

    Widget buildSegmentButton(String tab, String label, IconData icon) {
      final isSelected = _activeSubTab == tab;
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() {
              _activeSubTab = tab;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryTurf : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textDarkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDarkSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final switcher = Container(
      margin: const EdgeInsets.fromLTRB(15, 5, 15, 0),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.borderGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          buildSegmentButton('friendly', 'Individual Matches', Icons.sports_cricket_rounded),
          buildSegmentButton('tournament', 'Tournament Matches', Icons.emoji_events_rounded),
        ],
      ),
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            switcher,
            if (_activeSubTab == 'tournament')
              _buildTournamentDropdown(allVisibleTournaments),
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
                  Tab(text: 'LIVE'),
                  Tab(text: 'UPCOMING'),
                  Tab(text: 'COMPLETED'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMatchList(
                    context,
                    live,
                    _activeSubTab == 'friendly'
                        ? 'No live friendly matches right now.'
                        : 'No live tournament matches right now.',
                    role,
                    appState,
                  ),
                  _buildMatchList(
                    context,
                    upcoming,
                    _activeSubTab == 'friendly'
                        ? 'No upcoming friendly matches scheduled.'
                        : 'No upcoming tournament matches scheduled.',
                    role,
                    appState,
                  ),
                  _buildMatchList(
                    context,
                    completed,
                    _activeSubTab == 'friendly'
                        ? 'No completed friendly matches found.'
                        : 'No completed tournament matches found.',
                    role,
                    appState,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentDropdown(List<Tournament> tournaments) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 5, 15, 0),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGreen),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.pitchGold,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTournamentId,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryTurf,
                ),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTournamentId = newValue;
                  });
                },
                items: [
                  const DropdownMenuItem<String>(
                    value: 'all',
                    child: Text('All Tournaments'),
                  ),
                  ...tournaments.map((Tournament tournament) {
                    return DropdownMenuItem<String>(
                      value: tournament.id,
                      child: Text(tournament.name),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(
    BuildContext context,
    List<CricketMatch> matchList,
    String emptyMessage,
    UserRole role,
    AppState appState,
  ) {
    if (matchList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_cricket,
              size: 64,
              color: AppColors.dividerGreen,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 2, bottom: 90),
      itemCount: matchList.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final match = matchList[index];
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
                Color(0xFFFDFBF7), // Extremely light wood
                Color(0xFFFAF2E6), // Light wood
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
                                ? 'Scheduled: ${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year} at ${match.matchDate.hour.toString().padLeft(2, '0')}:${match.matchDate.minute.toString().padLeft(2, '0')}'
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

                        // Role specific quick actions
                        if ((role == UserRole.scorer || role == UserRole.organizer) && match.status == MatchStatus.live)
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTurf,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                appState.setActiveScoringMatch(match);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => LiveScoringScreen(match: match)),
                                );
                              },
                              child: const Text('SCORE'),
                            ),
                          )
                        else if ((role == UserRole.scorer || role == UserRole.organizer) &&
                                 match.status == MatchStatus.upcoming &&
                                 (DateTime(match.matchDate.year, match.matchDate.month, match.matchDate.day)
                                     .isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)) ||
                                 DateTime(match.matchDate.year, match.matchDate.month, match.matchDate.day)
                                     .isAtSameMomentAs(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))))
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.woodMahogany,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => TossSetupScreen(match: match)),
                                );
                              },
                              child: const Text('START'),
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
      },
    );
  }
}
