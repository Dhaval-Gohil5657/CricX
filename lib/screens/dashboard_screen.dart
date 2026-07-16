import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/match_model.dart';
import 'package:cricx/services/auth_service.dart';
import 'scorecard_screen.dart';
import 'scorer/live_scoring_screen.dart';
import 'scorer/create_match_screen.dart';
import 'scorer/create_team_screen.dart';
import 'scorer/toss_setup_screen.dart';
import 'organizer/create_tournament_screen.dart';
import 'welcome_screen.dart';
import '../constants/app_colors.dart';
import '../widgets/shimmer_card.dart';

class DashboardScreen extends StatelessWidget {
  final GlobalKey? liveMatchesKey;
  final GlobalKey? quickActionsKey;
  final GlobalKey? nextRecentMatchesKey;

  const DashboardScreen({
    super.key,
    this.liveMatchesKey,
    this.quickActionsKey,
    this.nextRecentMatchesKey,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = appState.currentRole;
    final currentUserId = AuthService.instance.currentUser?.uid;
    final searchQuery = appState.searchQuery;

    final allVisibleMatches = appState.filterByCreator && (role == UserRole.scorer || role == UserRole.organizer)
        ? appState.matches.where((m) => m.creatorId == currentUserId).toList()
        : appState.matches;

    final liveMatches = allVisibleMatches.where((m) {
      final isLive = m.status == MatchStatus.live || (m.status == MatchStatus.completed && m.resultString == "Match Tied" && !m.isSuperOverPlayed);
      if (!isLive) return false;
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.trim().toLowerCase();
      return m.teamA.name.toLowerCase().contains(q) ||
             m.teamB.name.toLowerCase().contains(q) ||
             m.venue.toLowerCase().contains(q) ||
             (m.tournamentName != null && m.tournamentName!.toLowerCase().contains(q));
    }).toList();
    
    final completedMatches = allVisibleMatches.where((m) => m.status == MatchStatus.completed && !(m.resultString == "Match Tied" && !m.isSuperOverPlayed)).toList();
    final now = DateTime.now();
    final upcomingMatches = allVisibleMatches.where((m) {
      return m.status == MatchStatus.upcoming &&
             m.matchDate.year == now.year &&
             m.matchDate.month == now.month &&
             m.matchDate.day == now.day;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        color: AppColors.accentCrease,
        backgroundColor: AppColors.appBarBg,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 90.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Matches
                Row(
                  key: liveMatchesKey,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE MATCHES',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    if (liveMatches.isEmpty)
                      const Text(
                        'No matches live',
                        style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
                      )
                  ],
                ),
                const SizedBox(height: 12),
                
                if (appState.isLoadingMatches)
                  LiveMatchSkeleton(
                    showScoringSection: (role == UserRole.scorer || role == UserRole.organizer),
                  )
                else if (liveMatches.isNotEmpty)
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: liveMatches.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildLiveMatchCard(context, liveMatches[index], role, appState, isFullWidth: true),
                      );
                    },
                  )
                else if (searchQuery.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGreen.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          color: AppColors.textDarkMuted,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No live matches found matching "$searchQuery"',
                          style: const TextStyle(
                            color: AppColors.textDarkMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  _buildEmptyLiveCard(context, role),
                // if (role != UserRole.guest) ...[
                if (role == UserRole.scorer || role == UserRole.organizer) ...[
                  const SizedBox(height: 24),
                  Text(
                    key: quickActionsKey,
                    'QUICK ACTIONS',
                    style: const TextStyle(
                      color: AppColors.textDarkSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, role, appState),
                ],
                const SizedBox(height: 24),
                
                // Scorer / Organizer sees Next Matches, Guest / Player sees Recent Matches
                if (role == UserRole.scorer || role == UserRole.organizer) ...[
                  Text(
                    key: nextRecentMatchesKey,
                    'NEXT MATCHES',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (appState.isLoadingMatches)
                    const UpcomingMatchSkeleton(showScoringButton: true)
                  else if (upcomingMatches.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGreen, width: 1.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.textDarkMuted,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No matches scheduled for today',
                            style: TextStyle(
                              color: AppColors.textDarkMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcomingMatches.length > 5 ? 5 : upcomingMatches.length,
                      itemBuilder: (context, index) {
                        return _buildUpcomingMatchCard(context, upcomingMatches[index], appState);
                      },
                    ),
                ] else ...[
                  Text(
                    key: nextRecentMatchesKey,
                    'RECENT MATCHES',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (appState.isLoadingMatches)
                    const RecentMatchSkeleton()
                  else if (completedMatches.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGreen, width: 1.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            color: AppColors.textDarkMuted,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No recent matches played yet',
                            style: TextStyle(
                              color: AppColors.textDarkMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completedMatches.length > 5 ? 5 : completedMatches.length,
                      itemBuilder: (context, index) {
                        return _buildRecentMatchCard(context, completedMatches[index]);
                      },
                    ),
                ],
                if (role == UserRole.guest) ...[
                  const SizedBox(height: 24),
                  _buildGuestPromoCard(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildLiveMatchCard(BuildContext context, CricketMatch match, UserRole role, AppState appState, {bool isFullWidth = false}) {
    final currentUserId = AuthService.instance.currentUser?.uid;
    final isSuperOver = match.currentInningsNum >= 3;
    final isFirstInnings = match.currentInningsNum == 1 || match.currentInningsNum == 3;
    final currentInnings = match.currentInnings;

    final superOverA = match.superOverInnings1?.teamId == match.teamA.id 
        ? match.superOverInnings1 
        : (match.superOverInnings2?.teamId == match.teamA.id ? match.superOverInnings2 : null);

    final superOverB = match.superOverInnings1?.teamId == match.teamB.id 
        ? match.superOverInnings1 
        : (match.superOverInnings2?.teamId == match.teamB.id ? match.superOverInnings2 : null);

    final strikerRuns = isSuperOver && match.striker != null
        ? match.currentInnings.events.where((e) => e.batsmanName == match.striker!.name).fold(0, (sum, e) => sum + e.runsAddedToBatsman)
        : (match.striker != null ? (match.playerRuns[match.striker!.id] ?? 0) : 0);

    final strikerBalls = isSuperOver && match.striker != null
        ? match.currentInnings.events.where((e) => e.batsmanName == match.striker!.name && e.countsAsBall).length
        : (match.striker != null ? (match.playerBallsFaced[match.striker!.id] ?? 0) : 0);

    final nonStrikerRuns = isSuperOver && match.nonStriker != null
        ? match.currentInnings.events.where((e) => e.batsmanName == match.nonStriker!.name).fold(0, (sum, e) => sum + e.runsAddedToBatsman)
        : (match.nonStriker != null ? (match.playerRuns[match.nonStriker!.id] ?? 0) : 0);

    final nonStrikerBalls = isSuperOver && match.nonStriker != null
        ? match.currentInnings.events.where((e) => e.batsmanName == match.nonStriker!.name && e.countsAsBall).length
        : (match.nonStriker != null ? (match.playerBallsFaced[match.nonStriker!.id] ?? 0) : 0);

    final bowlerWickets = isSuperOver && match.currentBowler != null
        ? match.currentInnings.events.where((e) => e.bowlerName == match.currentBowler!.name && e.isWicket && e.wicketType != 'Run Out').length
        : (match.currentBowler != null ? (match.bowlerWickets[match.currentBowler!.id] ?? 0) : 0);

    final bowlerRunsConceded = isSuperOver && match.currentBowler != null
        ? match.currentInnings.events.where((e) => e.bowlerName == match.currentBowler!.name).fold(0, (sum, e) => sum + e.runsAddedToTeam)
        : (match.currentBowler != null ? (match.bowlerRunsConceded[match.currentBowler!.id] ?? 0) : 0);

    final bowlerBallsBowled = isSuperOver && match.currentBowler != null
        ? match.currentInnings.events.where((e) => e.bowlerName == match.currentBowler!.name && e.countsAsBall).length
        : (match.currentBowler != null ? (match.bowlerBallsBowled[match.currentBowler!.id] ?? 0) : 0);

    final targetRuns = isSuperOver
        ? (match.superOverInnings1 != null ? match.superOverInnings1!.runs + 1 : 0)
        : (match.innings1 != null ? match.innings1!.runs + 1 : 0);

    final runsNeeded = targetRuns - currentInnings.runs;

    final maxBalls = isSuperOver ? 6 : (match.totalOvers * 6);
    final ballsRemaining = maxBalls - currentInnings.ballsBowled;

    return Container(
      width: isFullWidth ? double.infinity : MediaQuery.of(context).size.width * 0.85,
      margin: isFullWidth ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderWood,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF4D1A9), // Soft light willow wood edge
            Color(0xFFFCF7F0), // Extra light wood face
            Color(0xFFF4D1A9), // Soft light willow wood edge
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScorecardScreen(match: match),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: LIVE Badge and Venue info
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        match.venue,
                        style: const TextStyle(
                          color: AppColors.textDarkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: match.isOnBreak
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTurf.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.primaryTurf.withOpacity(0.3), width: 0.8),
                                ),
                                child: Text(
                                      match.breakReason == 'Rain Delay'
                                          ? 'RAIN DELAY'
                                          : (match.breakReason == 'Drinks Break' ? 'DRINKS' : 'BREAK'),
                                      style: const TextStyle(
                                        color: AppColors.primaryTurf,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),

                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (match.tournamentId != null && match.tournamentId!.isNotEmpty)
                                ? AppColors.primaryTurf.withOpacity(0.12)
                                : AppColors.woodMahogany.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (match.tournamentId != null && match.tournamentId!.isNotEmpty)
                                ? 'Tournament'
                                : 'Friendly',
                            style: TextStyle(
                              color: (match.tournamentId != null && match.tournamentId!.isNotEmpty)
                                  ? AppColors.primaryTurf
                                  : AppColors.woodMahogany,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Team A Scoring Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(match.teamA.logoColorHex).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(match.teamA.logoEmoji, style: const TextStyle(fontSize: 15)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              match.teamA.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: match.battingTeam.id == match.teamA.id ? FontWeight.bold : FontWeight.w500,
                                color: match.battingTeam.id == match.teamA.id ? AppColors.textDark : AppColors.textDarkSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (match.battingTeam.id == match.teamA.id) ...[
                            const SizedBox(width: 6),
                            const Text('🏏', style: TextStyle(fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  match.teamAInnings != null 
                                      ? '${match.teamAInnings!.runs}/${match.teamAInnings!.wickets}' 
                                      : 'Yet to Bat',
                                  style: TextStyle(
                                    fontSize: match.teamAInnings != null ? 15 : 13,
                                    fontWeight: match.teamAInnings != null ? FontWeight.w800 : FontWeight.w500,
                                    color: match.battingTeam.id == match.teamA.id ? AppColors.woodMahogany : AppColors.textDarkSecondary,
                                  ),
                                ),
                                if (match.teamAInnings != null)
                                  Text(
                                    '(${match.teamAInnings!.oversCompleted}/${match.totalOvers})',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textDarkMuted,
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                              ],
                            ),
                            if (match.isSuperOverPlayed && superOverA != null) ...[
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${superOverA.runs}/${superOverA.wickets}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryTurf,
                                    ),
                                  ),
                                  const Text(
                                    'S.O.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primaryTurf,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Team B Scoring Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(match.teamB.logoColorHex).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(match.teamB.logoEmoji, style: const TextStyle(fontSize: 15)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              match.teamB.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: match.battingTeam.id == match.teamB.id ? FontWeight.bold : FontWeight.w500,
                                color: match.battingTeam.id == match.teamB.id ? AppColors.textDark : AppColors.textDarkSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (match.battingTeam.id == match.teamB.id) ...[
                            const SizedBox(width: 6),
                            const Text('🏏', style: TextStyle(fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  match.teamBInnings != null 
                                      ? '${match.teamBInnings!.runs}/${match.teamBInnings!.wickets}' 
                                      : 'Yet to Bat',
                                  style: TextStyle(
                                    fontSize: match.teamBInnings != null ? 15 : 13,
                                    fontWeight: match.teamBInnings != null ? FontWeight.w800 : FontWeight.w500,
                                    color: match.battingTeam.id == match.teamB.id ? AppColors.woodMahogany : AppColors.textDarkSecondary,
                                  ),
                                ),
                                if (match.teamBInnings != null)
                                  Text(
                                    '(${match.teamBInnings!.oversCompleted}/${match.totalOvers})',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textDarkMuted,
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                              ],
                            ),
                            if (match.isSuperOverPlayed && superOverB != null) ...[
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${superOverB.runs}/${superOverB.wickets}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryTurf,
                                    ),
                                  ),
                                  const Text(
                                    'S.O.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primaryTurf,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Second Innings Target box
                if (!isFirstInnings && (isSuperOver ? match.superOverInnings1 != null : match.innings1 != null)) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTurf.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryTurf.withOpacity(0.15), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        match.resultString == "Match Tied"
                            ? "Match Tied"
                            : 'Target: $targetRuns | Need ${runsNeeded <= 0 ? 0 : runsNeeded} off ${ballsRemaining <= 0 ? 0 : ballsRemaining} balls',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTurf,
                        ),
                      ),
                    ),
                  ),
                ],

                 Divider(color: AppColors.borderWood, height: 20),

                // Footer details: Batsmen & Bowlers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batsmen
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (match.striker != null)
                            Row(
                              children: [
                                const Text('🏏 ', style: TextStyle(fontSize: 10)),
                                Expanded(
                                  child: Text(
                                    '${match.striker!.name} $strikerRuns($strikerBalls)*',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDarkSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              '🏏 Select Batsman',
                              style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                            ),
                          if (match.nonStriker != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    '${match.nonStriker!.name} $nonStrikerRuns($nonStrikerBalls)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDarkSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bowler
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (match.currentBowler != null) ...[
                            Text(
                              '⚾ ${match.currentBowler!.name}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textDarkSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$bowlerWickets/$bowlerRunsConceded (${bowlerBallsBowled ~/ 6}.${bowlerBallsBowled % 6} Ov)',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textDarkSecondary,
                                fontWeight: FontWeight.w500
                                ),
                              textAlign: TextAlign.right,
                            ),
                          ] else
                            const Text(
                              '⚾ Select Bowler',
                              style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                              textAlign: TextAlign.right,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                if ((role == UserRole.scorer || role == UserRole.organizer) &&
                    (match.creatorId == null || match.creatorId == currentUserId)) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTurf,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        appState.setActiveScoringMatch(match);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LiveScoringScreen(match: match),
                          ),
                        );
                      },
                      child: const Text(
                        'CONTINUE SCORING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLiveCard(BuildContext context, UserRole role) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTurf.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.sports_cricket,
            size: 48,
            color: AppColors.textDarkDisabled,
          ),
          const SizedBox(height: 12),
          const Text(
            'No matches are currently live.',
            style: TextStyle(
              color: AppColors.textDarkSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (role == UserRole.scorer || role == UserRole.organizer)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTurf,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateMatchScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Start a Match Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserRole role, AppState appState) {
    final List<Widget> actions = [];

    if (role == UserRole.scorer || role == UserRole.organizer) {
      actions.addAll([
        _buildActionItem(
          context,
          emoji: '🏏',
          label: 'Schedule Match',
          baseColor: AppColors.accentCrease,
          gradientColors: const [
            Color(0xFFF4FBF5),
            Color(0xFFEAF5EB),
          ],
          borderColor: AppColors.accentCrease.withOpacity(0.25),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateMatchScreen()),
            );
          },
        ),
        _buildActionItem(
          context,
          emoji: '👕',
          label: 'Create Team',
          baseColor: AppColors.pitchGold,
          gradientColors: const [
            Color(0xFFFFF9F3),
            Color(0xFFFBEADB),
          ],
          borderColor: Colors.orange.withOpacity(0.25),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTeamScreen()),
            );
          },
        ),
        _buildActionItem(
          context,
          emoji: '🏆',
          label: 'New League',
          baseColor: Colors.amber,
          gradientColors: const [
            Color(0xFFFFFDF5),
            Color(0xFFFFE9AA),
          ],
          borderColor: Colors.amber.withOpacity(0.3),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
            );
          },
        ),
      ]);
    }
    // else {
    //   // Guest / User
    //   actions.addAll([
    //     _buildActionItem(
    //       context,
    //       emoji: '⭐',
    //       label: 'Follow Teams',
    //       baseColor: AppColors.accentCrease,
    //       gradientColors: const [
    //         Color(0xFFF4FBF5),
    //         Color(0xFFEAF5EB),
    //       ],
    //       borderColor: AppColors.accentCrease.withOpacity(0.25),
    //       onTap: () {
    //         CustomSnackBar.show(
    //           context,
    //           message: "Follow team functionality demo: Marked all teams followed",
    //           type: SnackBarType.success,
    //         );
    //       },
    //     ),
    //     _buildActionItem(
    //       context,
    //       emoji: '📊',
    //       label: 'Leaderboard',
    //       baseColor: Colors.purpleAccent,
    //       gradientColors: const [
    //         Color(0xFFFAF5FF),
    //         Color(0xFFF3E8FF),
    //       ],
    //       borderColor: Colors.purple.withOpacity(0.2),
    //       onTap: () {
    //         CustomSnackBar.show(
    //           context,
    //           message: "Leaderboards loading... (Mock UI)",
    //           type: SnackBarType.info,
    //         );
    //       },
    //     ),
    //     _buildActionItem(
    //       context,
    //       emoji: '🔔',
    //       label: 'Alerts',
    //       baseColor: Colors.redAccent,
    //       gradientColors: const [
    //         Color(0xFFFFF5F5),
    //         Color(0xFFFFE3E3),
    //       ],
    //       borderColor: Colors.red.withOpacity(0.2),
    //       onTap: () {
    //         CustomSnackBar.show(
    //           context,
    //           message: "Alert preferences: Scoring alerts enabled",
    //           type: SnackBarType.info,
    //         );
    //       },
    //     ),
    //   ]);
    // }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required String emoji,
    required String label,
    required Color baseColor,
    required List<Color> gradientColors,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: baseColor.withOpacity(0.08),
            highlightColor: baseColor.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: baseColor.withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMatchCard(BuildContext context, CricketMatch match) {
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
            Color(0xFFFDFBF7), // Extremely light wood face
            Color(0xFFFAF2E6), // Light wood face
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScorecardScreen(match: match),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15.0),
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
                    Text(
                      '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}',
                      style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Team A name & score
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(match.teamA.logoColorHex).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(match.teamA.logoEmoji, style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          match.teamA.name,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
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
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Team B name & score
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(match.teamB.logoColorHex).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(match.teamB.logoEmoji, style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          match.teamB.name,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
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
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.dividerGreen, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        match.statusText,
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
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: const Text(
                        'Full Scorecard ➜',
                        style: TextStyle(
                          color: AppColors.primaryTurf,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildUpcomingMatchCard(BuildContext context, CricketMatch match, AppState appState) {
    final currentUserId = AuthService.instance.currentUser?.uid;
    final isCreator = match.creatorId == null || match.creatorId == currentUserId;

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
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScorecardScreen(match: match),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15.0),
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
                    Text(
                      '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year} at ${match.matchDate.hour.toString().padLeft(2, '0')}:${match.matchDate.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Color(match.teamA.logoColorHex).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(match.teamA.logoEmoji, style: const TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  match.teamA.name,
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Color(match.teamB.logoColorHex).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(match.teamB.logoEmoji, style: const TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  match.teamB.name,
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (isCreator)
                      SizedBox(
                        height: 35,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.woodMahogany,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TossSetupScreen(match: match)),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text('START'),
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
                const Divider(color: AppColors.dividerGreen, height: 16),
                Text(
                  'Overs: ${match.totalOvers} Overs Match',
                  style: const TextStyle(
                    color: AppColors.woodMahogany,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestPromoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryTurf.withOpacity(0.2), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFE2EFE4), // Very soft light turf green
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTurf.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryTurf.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_cricket_rounded,
                  color: AppColors.primaryTurf,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Unlock CricX Features!',
                  style: TextStyle(
                    color: AppColors.primaryTurf,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Register or log in to create teams, schedule matches, manage tournament tables, and save your app preferences.',
            style: TextStyle(
              color: AppColors.textDarkSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTurf,
                foregroundColor: Colors.white,
                padding:  EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Log In / Register Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
