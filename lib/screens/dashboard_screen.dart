import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/match_model.dart';
import 'scorecard_screen.dart';
import 'scorer/live_scoring_screen.dart';
import 'scorer/create_match_screen.dart';
import 'scorer/create_team_screen.dart';
import 'scorer/toss_setup_screen.dart';
import 'organizer/create_tournament_screen.dart';
import '../constants/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = appState.currentRole;
    final liveMatches = appState.matches.where((m) => m.status == MatchStatus.live).toList();
    final completedMatches = appState.matches.where((m) => m.status == MatchStatus.completed).toList();
    final upcomingMatches = appState.matches.where((m) => m.status == MatchStatus.upcoming).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        color: AppColors.accentCrease,
        backgroundColor: AppColors.appBarBg,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Matches
                Row(
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
                
                if (liveMatches.isNotEmpty)
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
                else
                  _buildEmptyLiveCard(context, role),
                
                const SizedBox(height: 24),
                
                // Quick Actions based on Role
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    color: AppColors.textDarkSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(context, role, appState),
                const SizedBox(height: 24),
                
                // Scorer / Organizer sees Next Matches, Guest / Player sees Recent Matches
                if (role == UserRole.scorer || role == UserRole.organizer) ...[
                  const Text(
                    'NEXT MATCHES',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (upcomingMatches.isEmpty)
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
                            'No matches scheduled yet',
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
                  const Text(
                    'RECENT MATCHES',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (completedMatches.isEmpty)
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
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildLiveMatchCard(BuildContext context, CricketMatch match, UserRole role, AppState appState, {bool isFullWidth = false}) {
    final innings1 = match.innings1;
    final isFirstInnings = match.currentInningsNum == 1;
    final currentInnings = match.currentInnings;

    return Container(
      width: isFullWidth ? double.infinity : MediaQuery.of(context).size.width * 0.82,
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
            padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Team A
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  match.teamA.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: match.battingTeam.id == match.teamA.id ? FontWeight.bold : FontWeight.w500,
                                    color: match.battingTeam.id == match.teamA.id ? AppColors.textDark : AppColors.textDarkSecondary,
                                  ),
                                ),
                              ),
                              if (match.battingTeam.id == match.teamA.id) ...[
                                const SizedBox(width: 4),
                                const Text('🏏', style: TextStyle(fontSize: 12)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            match.teamAInnings != null 
                                ? '${match.teamAInnings!.runs}/${match.teamAInnings!.wickets}' 
                                : 'Yet to Bat',
                            style: TextStyle(
                              fontSize: match.battingTeam.id == match.teamA.id ? 22 : 14,
                              fontWeight: FontWeight.bold,
                              color: match.battingTeam.id == match.teamA.id ? AppColors.primaryTurf : AppColors.textDarkSecondary,
                            ),
                          ),
                          if (match.teamAInnings != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Overs: ${match.teamAInnings!.oversCompleted}/${match.totalOvers}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textDarkSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // VS with Live Indication above it
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                                  fontSize: 9,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDarkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Team B
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (match.battingTeam.id == match.teamB.id) ...[
                                const Text('🏏', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  match.teamB.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: match.battingTeam.id == match.teamB.id ? FontWeight.bold : FontWeight.w500,
                                    color: match.battingTeam.id == match.teamB.id ? AppColors.textDark : AppColors.textDarkSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            match.teamBInnings != null 
                                ? '${match.teamBInnings!.runs}/${match.teamBInnings!.wickets}' 
                                : 'Yet to Bat',
                            style: TextStyle(
                              fontSize: match.battingTeam.id == match.teamB.id ? 22 : 14,
                              fontWeight: FontWeight.bold,
                              color: match.battingTeam.id == match.teamB.id ? AppColors.primaryTurf : AppColors.textDarkSecondary,
                            ),
                          ),
                          if (match.teamBInnings != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Overs: ${match.teamBInnings!.oversCompleted}/${match.totalOvers}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textDarkSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                if (!isFirstInnings && innings1 != null) ...[
                  SizedBox(height: 3),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.woodMahogany.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Target: ${innings1.runs + 1} | Need ${(innings1.runs + 1 - currentInnings.runs) <= 0 ? 0 : (innings1.runs + 1 - currentInnings.runs)} off ${(match.totalOvers * 6) - currentInnings.ballsBowled} balls',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.woodMahogany,
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 8),
                
                // Batsman & Bowler footer info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (match.striker != null)
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  child: Text('🏏', style: TextStyle(fontSize: 11)),
                                ),
                                Expanded(
                                  child: Text(
                                    '${match.striker!.name} ${match.playerRuns[match.striker!.id] ?? 0}(${match.playerBallsFaced[match.striker!.id] ?? 0})*',
                                    style: const TextStyle(
                                      fontSize: 10.5,
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
                              style: TextStyle(fontSize: 10.5, color: AppColors.textDarkSecondary),
                            ),
                          if (match.nonStriker != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    '${match.nonStriker!.name} ${match.playerRuns[match.nonStriker!.id] ?? 0}(${match.playerBallsFaced[match.nonStriker!.id] ?? 0})',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textDarkSecondary,
                                      fontWeight: FontWeight.bold,
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
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (match.currentBowler != null) ...[
                            Text(
                              '⚾ ${match.currentBowler!.name}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textDarkSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${match.bowlerWickets[match.currentBowler!.id] ?? 0}/${match.bowlerRunsConceded[match.currentBowler!.id] ?? 0} (${(match.bowlerBallsBowled[match.currentBowler!.id] ?? 0) ~/ 6}.${(match.bowlerBallsBowled[match.currentBowler!.id] ?? 0) % 6} Ov)',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.textDarkSecondary,
                              ),
                            ),
                          ] else
                            const Text(
                              '⚾ Select Bowler',
                              style: TextStyle(fontSize: 10.5, color: AppColors.textDarkSecondary),
                              textAlign: TextAlign.right,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (role == UserRole.scorer) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTurf,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        )));
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
          if (role == UserRole.scorer)
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

    if (role == UserRole.scorer) {
      actions.addAll([
        _buildActionItem(
          context,
          icon: Icons.sports_cricket_rounded,
          label: 'Create Match',
          color: AppColors.accentCrease,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateMatchScreen()),
            );
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.group_add_rounded,
          label: 'Create Team',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTeamScreen()),
            );
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.flash_on_rounded,
          label: 'Quick Score',
          color: AppColors.pitchGold,
          onTap: () {
            // Find first live match if exists, or show snackbar
            final live = appState.matches.firstWhere(
              (m) => m.status == MatchStatus.live,
              orElse: () => appState.matches[0],
            );
            appState.setActiveScoringMatch(live);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LiveScoringScreen(match: live)),
            );
          },
        ),
      ]);
    } else if (role == UserRole.organizer) {
      actions.addAll([
        _buildActionItem(
          context,
          icon: Icons.emoji_events_outlined,
          label: 'New League',
          color: AppColors.pitchGold,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
            );
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.calendar_month_rounded,
          label: 'Schedule Fixtures',
          color: Colors.blue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Fixtures scheduler available in Tournament Management")),
            );
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.table_chart_rounded,
          label: 'Points Table',
          color: Colors.teal,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Points tables reside inside each tournament page")),
            );
          },
        ),
      ]);
    } else {
      // Guest / User
      actions.addAll([
        _buildActionItem(
          context,
          icon: Icons.star_border_rounded,
          label: 'Follow Teams',
          color: AppColors.accentCrease,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Follow team functionality demo: Marked all teams followed")),
            );
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.analytics_outlined,
          label: 'Leaderboard',
          color: Colors.purpleAccent,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Leaderboards loading... (Mock UI)")),
            );
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.notifications_none_rounded,
          label: 'Alerts',
          color: Colors.redAccent,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Alert preferences: Scoring alerts enabled")),
            );
          },
        ),
      ]);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderWood.withOpacity(0.7),
            width: 1.2,
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
              Color(0xFFFAF0E3), // Soft warm golden cream (Cricket bat willow)
              Color(0xFFF2DFCB), // Warm light stump/willow tan
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 22),
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
                        match.resultString,
                        style: const TextStyle(
                          color: AppColors.woodMahogany,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      'Full Scorecard ➜',
                      style: TextStyle(
                        color: AppColors.primaryTurf,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
    );
  }
}
