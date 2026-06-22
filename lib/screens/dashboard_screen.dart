import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/match_model.dart';
import 'scorecard_screen.dart';
import 'scorer/live_scoring_screen.dart';
import 'scorer/create_match_screen.dart';
import 'scorer/create_team_screen.dart';
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
                  liveMatches.length == 1
                      ? _buildLiveMatchCard(context, liveMatches[0], role, appState, isFullWidth: true)
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: liveMatches.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return _buildLiveMatchCard(context, liveMatches[index], role, appState);
                            },
                          ),
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
                
                // Recent Matches (Completed)
                const Text(
                  'RECENT MATCHES',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedMatches.length > 5 ? 5 : completedMatches.length,
                  itemBuilder: (context, index) {
                    return _buildRecentMatchCard(context, completedMatches[index]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildLiveMatchCard(BuildContext context, CricketMatch match, UserRole role, AppState appState, {bool isFullWidth = false}) {
    final innings1 = match.innings1;
    final innings2 = match.innings2;

    // Determine currently batting team score
    final currentInnings = match.currentInnings;
    final isFirstInnings = match.currentInningsNum == 1;
    final currentBattingTeam = match.battingTeam;
    final currentBowlingTeam = match.bowlingTeam;
    
    final runs = currentInnings.runs;
    final wickets = currentInnings.wickets;
    final overs = currentInnings.oversCompleted;

    return Container(
      width: isFullWidth ? double.infinity : MediaQuery.of(context).size.width * 0.82,
      height: 190,
      margin: isFullWidth ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentCrease.withOpacity(0.3),
          width: 1,
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentCrease.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Overs: ${match.totalOvers}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.accentCrease,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Score Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentBattingTeam.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$runs/$wickets',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentCrease,
                          ),
                        ),
                        Text(
                          'Overs: $overs',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDarkDisabled,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currentBowlingTeam.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDarkSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (!isFirstInnings && innings1 != null) ...[
                          Text(
                            'Target: ${innings1.runs + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.pitchGold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Need ${innings1.runs + 1 - runs} off ${(match.totalOvers * 6) - currentInnings.ballsBowled} balls',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textDarkSecondary,
                            ),
                          )
                        ] else ...[
                          const Text(
                            'Yet to Bat',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textDarkMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                
                // Batsman & Bowler footer info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        match.striker != null 
                            ? '🏏 ${match.striker!.name} ${match.playerRuns[match.striker!.id] ?? 0}(${match.playerBallsFaced[match.striker!.id] ?? 0})*'
                            : '🏏 Select Batsman',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDarkSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.currentBowler != null
                            ? '⚾ ${match.currentBowler!.name} ${match.bowlerWickets[match.currentBowler!.id] ?? 0}/${match.bowlerRunsConceded[match.currentBowler!.id] ?? 0}'
                            : '⚾ Select Bowler',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDarkSecondary,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Action Button (Scoring or View Scorecard)
                if (role == UserRole.scorer)
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCrease,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
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
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
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
          if (role == UserRole.scorer)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCrease,
                foregroundColor: Colors.black,
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
          icon: Icons.add_circle_outline_rounded,
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
      child: Card(
        color: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderWood, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMatchCard(BuildContext context, CricketMatch match) {
    return Card(
      color: AppColors.appBarBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.dividerGreen, width: 1),
      ),
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
                    match.innings1 != null ? '${match.innings1!.runs}/${match.innings1!.wickets}' : '-',
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
                    match.innings2 != null ? '${match.innings2!.runs}/${match.innings2!.wickets}' : '-',
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
                      style: TextStyle(
                        color: AppColors.pitchGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(
                    'Full Scorecard ➜',
                    style: TextStyle(
                      color: AppColors.accentCrease,
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
    );
  }
}
