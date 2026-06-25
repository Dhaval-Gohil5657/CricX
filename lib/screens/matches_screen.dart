import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/match_model.dart';
import 'scorecard_screen.dart';
import 'scorer/live_scoring_screen.dart';
import 'scorer/toss_setup_screen.dart';
import '../constants/app_colors.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final matches = appState.matches;
    final role = appState.currentRole;

    final live = matches.where((m) => m.status == MatchStatus.live).toList();
    final upcoming = matches.where((m) => m.status == MatchStatus.upcoming).toList();
    final completed = matches.where((m) => m.status == MatchStatus.completed).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(38.0),
          child: Container(
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
        ),
        body: TabBarView(
          children: [
            _buildMatchList(context, live, 'No live matches right now.', role, appState),
            _buildMatchList(context, upcoming, 'No upcoming matches scheduled.', role, appState),
            _buildMatchList(context, completed, 'No completed matches found.', role, appState),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
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
                            color:AppColors.woodMahogany.withOpacity(0.1),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        match.tournamentName != null && match.tournamentName!.isNotEmpty
                            ? Icons.emoji_events_rounded
                            : Icons.handshake_rounded,
                        size: 13,
                        color: match.tournamentName != null && match.tournamentName!.isNotEmpty
                            ? AppColors.pitchGold
                            : AppColors.textDarkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.tournamentName != null && match.tournamentName!.isNotEmpty
                            ? match.tournamentName!
                            : 'Friendly Match',
                        style: TextStyle(
                          color: match.tournamentName != null && match.tournamentName!.isNotEmpty
                              ? AppColors.textDarkSecondary
                              : AppColors.textDarkMuted,
                          fontSize: 11,
                          fontWeight: match.tournamentName != null && match.tournamentName!.isNotEmpty
                              ? FontWeight.bold
                              : FontWeight.normal,
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
                               match.matchDate.year == DateTime.now().year &&
                               match.matchDate.month == DateTime.now().month &&
                               match.matchDate.day == DateTime.now().day)
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
