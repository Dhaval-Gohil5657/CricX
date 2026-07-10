import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../constants/custom_snackbar.dart';
import 'main_navigation_screen.dart';
import 'organizer/tournament_detail_screen.dart';
import 'package:cricx/services/auth_service.dart';
import 'scorer/live_scoring_screen.dart';

class ScorecardScreen extends StatefulWidget {
  final CricketMatch match;

  const ScorecardScreen({super.key, required this.match});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  String _activeViewTab = 'overview';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // Find the latest state of the match from appState list
    final currentUserId = AuthService.instance.currentUser?.uid;
    final currentMatch = appState.matches.firstWhere((m) => m.id == widget.match.id, orElse: () => widget.match);
    
    // Determine the teams for Innings 1 and Innings 2
    final team1 = currentMatch.innings1 != null 
        ? appState.teams.firstWhere((t) => t.id == currentMatch.innings1!.teamId) 
        : currentMatch.teamA;
        
    final team2 = currentMatch.innings2 != null 
        ? appState.teams.firstWhere((t) => t.id == currentMatch.innings2!.teamId) 
        : (currentMatch.innings1 != null 
            ? (currentMatch.innings1!.teamId == currentMatch.teamA.id ? currentMatch.teamB : currentMatch.teamA) 
            : currentMatch.teamB);

    final role = appState.currentRole;
    final isMatchCreator = currentMatch.creatorId == null || currentMatch.creatorId == currentUserId;
    final canEditMatch = (role == UserRole.scorer || role == UserRole.organizer) && 
        isMatchCreator && 
        currentMatch.status == MatchStatus.upcoming;

    final isSuperOverPlayed = currentMatch.isSuperOverPlayed;

    return DefaultTabController(
      length: isSuperOverPlayed ? 4 : 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
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
            title: const Text(
              'Match Scorecard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (canEditMatch)
                GestureDetector(
                    onTap: () => _showEditMatchSheet(context, currentMatch, appState),
                      child: Tooltip(
                          message: 'Edit Match Details',
                          child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 20))),

              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                tooltip: 'Share Scorecard',
                onPressed: () => _shareScorecardText(context, currentMatch, appState),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (currentMatch.status == MatchStatus.completed) ...[
              // Completed Match: Google-Style segment switcher
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 5),
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
                        alignment: _activeViewTab == 'overview' ? Alignment.centerLeft : Alignment.centerRight,
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
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _activeViewTab = 'overview';
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
                                      end: _activeViewTab == 'overview' ? Colors.white : AppColors.textDarkMuted,
                                    ),
                                    builder: (context, color, child) {
                                      return Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: color,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    style: TextStyle(
                                      color: _activeViewTab == 'overview' ? Colors.white : AppColors.textDarkSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    child: const Text('Overview'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _activeViewTab = 'scorecard';
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
                                      end: _activeViewTab == 'scorecard' ? Colors.white : AppColors.textDarkMuted,
                                    ),
                                    builder: (context, color, child) {
                                      return Icon(
                                        Icons.analytics_outlined,
                                        size: 16,
                                        color: color,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    style: TextStyle(
                                      color: _activeViewTab == 'scorecard' ? Colors.white : AppColors.textDarkSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    child: const Text('Scorecard'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _activeViewTab == 'overview'
                    ? ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (currentMatch.tournamentId != null && currentMatch.tournamentId!.isNotEmpty)
                            _buildTournamentBanner(context, currentMatch, appState),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: _buildMatchOverviewCard(context, currentMatch, appState),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildPlayerOfTheMatchCard(context, currentMatch, appState),
                          ),
                          _buildBestPerformersCard(context, currentMatch),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(40, 10, 40, 24),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.borderGreen.withOpacity(0.4),
                                foregroundColor: AppColors.primaryTurf,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _activeViewTab = 'scorecard';
                                });
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.analytics_rounded, size: 18, color: AppColors.primaryTurf),
                                  SizedBox(width: 8),
                                  Text(
                                    'VIEW FULL SCORECARD',
                                    style: TextStyle(
                                      color: AppColors.primaryTurf,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.double_arrow_outlined, size: 16, color: AppColors.primaryTurf),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildInningsTabBar(team1, team2, isSuperOverPlayed),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildInningsTabContent(context, currentMatch, 1, appState),
                                _buildInningsTabContent(context, currentMatch, 2, appState),
                                if (isSuperOverPlayed) ...[
                                  _buildInningsTabContent(context, currentMatch, 3, appState),
                                  _buildInningsTabContent(context, currentMatch, 4, appState),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ] else ...[
              // Live / Upcoming Match: Original fully stacked view
              if (currentMatch.tournamentId != null && currentMatch.tournamentId!.isNotEmpty)
                _buildTournamentBanner(context, currentMatch, appState),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  currentMatch.tournamentId != null && currentMatch.tournamentId!.isNotEmpty ? 12 : 16,
                  16,
                  8,
                ),
                child: _buildMatchOverviewCard(context, currentMatch, appState),
              ),
              _buildInningsTabBar(team1, team2, isSuperOverPlayed),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInningsTabContent(context, currentMatch, 1, appState),
                    _buildInningsTabContent(context, currentMatch, 2, appState),
                    if (isSuperOverPlayed) ...[
                      _buildInningsTabContent(context, currentMatch, 3, appState),
                      _buildInningsTabContent(context, currentMatch, 4, appState),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: ((currentMatch.status == MatchStatus.completed || currentMatch.resultString == "Match Tied") &&
                !currentMatch.isSuperOverPlayed &&
                (role == UserRole.scorer || role == UserRole.organizer) &&
                isMatchCreator)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTurf,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            appState.completeMatch(currentMatch.id, forceComplete: true);
                          },
                          icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 16),
                          label: const Text(
                            'MARK COMPLETE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _showStartSuperOverDialog(context, currentMatch, appState);
                          },
                          icon: const Icon(Icons.bolt, color: Colors.white, size: 16),
                          label: const Text(
                            'START SUPER OVER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTournamentBanner(BuildContext context, CricketMatch currentMatch, AppState appState) {
    return GestureDetector(
      onTap: () {
        try {
          final tour = appState.tournaments.firstWhere((t) => t.id == currentMatch.tournamentId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentDetailScreen(tournament: tour),
            ),
          );
        } catch (_) {
          CustomSnackBar.show(
            context,
            message: 'Tournament details not found.',
            type: SnackBarType.error,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryTurf.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryTurf.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.pitchGold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentMatch.tournamentName ?? 'Tournament Match',
                style: const TextStyle(
                  color: AppColors.primaryTurf,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryTurf, size: 13),
          ],
        ),
      ),
    );
  }

  void _showStartSuperOverDialog(BuildContext context, CricketMatch match, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Start Super Over?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will re-open the match in Live Scoring mode for a 1-over tie-breaker. Are you sure you want to proceed?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              appState.startSuperOver(match.id);
              // Navigate directly to LiveScoringScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveScoringScreen(match: match),
                ),
              );
            },
            child: const Text('PROCEED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInningsTabBar(Team team1, Team team2, [bool isSuperOver = false]) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderGreen, width: 1),
        ),
      ),
      child: TabBar(
        isScrollable: false,
        indicatorColor: AppColors.primaryTurf,
        indicatorWeight: 3,
        labelColor: AppColors.primaryTurf,
        unselectedLabelColor: AppColors.textDarkSecondary,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isSuperOver ? 11.5 : 13.5),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: isSuperOver ? 11.0 : 13.0),
        tabs: [
          Tab(
            child: Text(
              isSuperOver ? team1.abbreviation.toUpperCase() : team1.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tab(
            child: Text(
              isSuperOver ? team2.abbreviation.toUpperCase() : team2.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSuperOver) ...[
            Tab(
              child: Text(
                'SO-${team2.abbreviation.toUpperCase()}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Tab(
              child: Text(
                'SO-${team1.abbreviation.toUpperCase()}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _shareScorecardText(BuildContext context, CricketMatch match, AppState appState) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('🏏 *CricX Match Update* 🏏');
    if (match.tournamentName != null && match.tournamentName!.isNotEmpty) {
      buffer.writeln('🏆 Tournament: ${match.tournamentName}');
    }
    buffer.writeln('📍 Venue: ${match.venue}');
    buffer.writeln('📅 Date: ${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}');
    buffer.writeln('----------------------------------');
    buffer.writeln('*${match.teamA.name}* vs *${match.teamB.name}*');
    buffer.writeln('📢 Status: ${match.statusText}');
    buffer.writeln('----------------------------------');

    void formatInnings(MatchTeamInnings? innings, String teamName, Team team, Team oppTeam) {
      if (innings == null || (innings.events.isEmpty && match.status == MatchStatus.upcoming)) {
        buffer.writeln('🏏 *$teamName*: Yet to bat\n');
        return;
      }
      final overs = innings.oversCompleted;
      final displayOversLimit = match.currentInningsNum >= 3 ? 1 : match.totalOvers;
      buffer.writeln('🏏 *$teamName*: ${innings.runs}/${innings.wickets} ($overs/$displayOversLimit ov)');

      final battedPlayers = team.players.where((player) {
        final isCurrentBatsman = (match.status == MatchStatus.live && match.currentInnings == innings) &&
            (player.id == match.striker?.id || player.id == match.nonStriker?.id);
        return innings.events.any((e) => e.batsmanName == player.name) || isCurrentBatsman;
      }).toList();

      final battingOrder = innings.battingOrder;
      battedPlayers.sort((a, b) {
        final indexA = battingOrder.indexOf(a.id);
        final indexB = battingOrder.indexOf(b.id);
        if (indexA == -1 && indexB == -1) return 0;
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

      if (battedPlayers.isNotEmpty) {
        buffer.writeln('  *Batting:*');
        for (var i = 0; i < battedPlayers.length && i < 3; i++) {
          final player = battedPlayers[i];
          final runs = innings.events.where((e) => e.batsmanName == player.name).fold(0, (sum, e) => sum + e.runsAddedToBatsman);
          final balls = innings.events.where((e) => e.batsmanName == player.name && e.countsAsBall).length;
          final isOut = innings.events.any((e) => e.isWicket && e.batsmanName == player.name);
          final isCurrentBatsman = (match.status == MatchStatus.live && match.currentInnings == innings) &&
              (player.id == match.striker?.id || player.id == match.nonStriker?.id);
          final star = (!isOut && isCurrentBatsman) ? '*' : '';
          buffer.writeln('  • ${player.name}: $runs$star ($balls)');
        }
      }

      final activeBowlers = oppTeam.players.where((player) {
        final isCurrentBowler = (match.status == MatchStatus.live && match.currentInnings == innings) &&
            (player.id == match.currentBowler?.id);
        return innings.events.any((e) => e.bowlerName == player.name) || isCurrentBowler;
      }).toList();
      activeBowlers.sort((a, b) {
        final wicketsA = innings.events.where((e) => e.bowlerName == a.name && e.isWicket && e.wicketType != 'Run Out').length;
        final wicketsB = innings.events.where((e) => e.bowlerName == b.name && e.isWicket && e.wicketType != 'Run Out').length;
        final runsA = innings.events.where((e) => e.bowlerName == a.name).fold(0, (sum, e) => sum + e.runsAddedToTeam);
        final runsB = innings.events.where((e) => e.bowlerName == b.name).fold(0, (sum, e) => sum + e.runsAddedToTeam);
        
        if (wicketsA != wicketsB) {
          return wicketsB.compareTo(wicketsA);
        }
        return runsA.compareTo(runsB);
      });

      if (activeBowlers.isNotEmpty) {
        buffer.writeln('  *Bowling:*');
        for (var i = 0; i < activeBowlers.length && i < 2; i++) {
          final bowler = activeBowlers[i];
          final balls = innings.events.where((e) => e.bowlerName == bowler.name && e.countsAsBall).length;
          final runs = innings.events.where((e) => e.bowlerName == bowler.name).fold(0, (sum, e) => sum + e.runsAddedToTeam);
          final wickets = innings.events.where((e) => e.bowlerName == bowler.name && e.isWicket && e.wicketType != 'Run Out').length;
          final ov = (balls ~/ 6) + (balls % 6) / 10;
          buffer.writeln('  • ${bowler.name}: $wickets/$runs ($ov ov)');
        }
      }
      buffer.writeln('');
    }

    final team1 = match.innings1 != null 
        ? appState.teams.firstWhere((t) => t.id == match.innings1!.teamId) 
        : match.teamA;
    final team2 = match.innings2 != null 
        ? appState.teams.firstWhere((t) => t.id == match.innings2!.teamId) 
        : (match.innings1 != null 
            ? (match.innings1!.teamId == match.teamA.id ? match.teamB : match.teamA) 
            : match.teamB);

    final opp1 = team1.id == match.teamA.id ? match.teamB : match.teamA;
    final opp2 = team2.id == match.teamA.id ? match.teamB : match.teamA;

    formatInnings(match.innings1, team1.name, team1, opp1);
    formatInnings(match.innings2, team2.name, team2, opp2);
    
    if (match.isSuperOverPlayed) {
      buffer.writeln('⚡ *SUPER OVER* ⚡');
      formatInnings(match.superOverInnings1, 'S.O. - ${team2.name}', team2, team1);
      formatInnings(match.superOverInnings2, 'S.O. - ${team1.name}', team1, team2);
    }

    buffer.writeln('----------------------------------');
    buffer.writeln('Scored live on *CricX* app! 🏏');

    SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: '${match.teamA.abbreviation} vs ${match.teamB.abbreviation} Scorecard',
      ),
    );
  }

  Widget _buildInningsTabContent(BuildContext context, CricketMatch match, int inningsNum, AppState appState) {
    final MatchTeamInnings? innings;
    if (inningsNum == 1) {
      innings = match.innings1;
    } else if (inningsNum == 2) {
      innings = match.innings2;
    } else if (inningsNum == 3) {
      innings = match.superOverInnings1;
    } else {
      innings = match.superOverInnings2;
    }

    if (innings == null) {
      final team1 = match.innings1 != null 
          ? appState.teams.firstWhere((t) => t.id == match.innings1!.teamId) 
          : match.teamA;
      final team2 = match.innings2 != null 
          ? appState.teams.firstWhere((t) => t.id == match.innings2!.teamId) 
          : (match.innings1 != null 
              ? (match.innings1!.teamId == match.teamA.id ? match.teamB : match.teamA) 
              : match.teamB);
      
      final Team team;
      if (inningsNum == 1) {
        team = team1;
      } else if (inningsNum == 2) {
        team = team2;
      } else if (inningsNum == 3) {
        team = team2;
      } else {
        team = team1;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGreen.withOpacity(0.5), width: 1.5),
                ),
                child: Text(team.logoEmoji, style: const TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 16),
              Text(
                '${team.name} has not batted yet',
                style: const TextStyle(
                  color: AppColors.textDarkMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                match.status == MatchStatus.upcoming 
                    ? 'Scorecard will be available when the match starts.' 
                    : 'Wait for the first innings to complete or start scoring.',
                style: const TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _buildInningsTable(context, match, innings, appState),
      ),
    );
  }

  Widget _buildMatchOverviewCard(BuildContext context, CricketMatch match, AppState appState) {
    final runsA = match.teamAInnings?.runs;
    final wicketsA = match.teamAInnings?.wickets;
    final oversA = match.teamAInnings?.oversCompleted;
    final scoreAStr = runsA != null ? '$runsA/$wicketsA' : 'Yet to Bat';
    final oversAStr = oversA != null ? '($oversA/${match.totalOvers})' : '';

    final runsB = match.teamBInnings?.runs;
    final wicketsB = match.teamBInnings?.wickets;
    final oversB = match.teamBInnings?.oversCompleted;
    final scoreBStr = runsB != null ? '$runsB/$wicketsB' : 'Yet to Bat';
    final oversBStr = oversB != null ? '($oversB/${match.totalOvers})' : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderWood, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.venue,
                style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10),
              ),
              Text(
                '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}',
                style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team A (Left aligned completely)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(match.teamA.logoColorHex).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(match.teamA.logoEmoji, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          match.teamA.abbreviation.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scoreAStr,
                          style: TextStyle(
                            color: runsA != null ? AppColors.woodMahogany : AppColors.textDarkMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: runsA != null ? 15 : 11,
                          ),
                        ),
                        if (oversAStr.isNotEmpty)
                          Text(
                            oversAStr,
                            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        if (match.isSuperOverPlayed && match.superOverInnings2 != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'S.O. ${match.superOverInnings2!.runs}/${match.superOverInnings2!.wickets}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primaryTurf,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  match.status == MatchStatus.live 
                      ? (match.isOnBreak ? (match.breakReason == 'Rain Delay' ? 'RAIN DELAY' : 'BREAK') : 'LIVE')
                      : 'VS',
                  style: TextStyle(
                    color: match.status == MatchStatus.live 
                        ? (match.isOnBreak ? AppColors.primaryTurf : Colors.redAccent)
                        : AppColors.textDarkDisabled,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              // Team B (Right aligned completely)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scoreBStr,
                          style: TextStyle(
                            color: runsB != null ? AppColors.woodMahogany : AppColors.textDarkMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: runsB != null ? 15 : 11,
                          ),
                        ),
                        if (oversBStr.isNotEmpty)
                          Text(
                            oversBStr,
                            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        if (match.isSuperOverPlayed && match.superOverInnings1 != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'S.O. ${match.superOverInnings1!.runs}/${match.superOverInnings1!.wickets}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primaryTurf,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(match.teamB.logoColorHex).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(match.teamB.logoEmoji, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          match.teamB.abbreviation.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (match.status == MatchStatus.upcoming) ...[
            Text(
              '${match.totalOvers} Overs',
              style: const TextStyle(
                color: AppColors.primaryTurf,
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
              ),
            ),
          ],
          if (match.status == MatchStatus.completed) ...[
            const SizedBox(height: 10),
            Text(
              match.resultString,
              style: const TextStyle(color: AppColors.woodMahogany, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ] else if (match.tossWinnerId != null) ...[
            const SizedBox(height: 10),
            Text(
              '${appState.teams.firstWhere((t) => t.id == match.tossWinnerId).name} won toss & elected to ${match.tossDecision}',
              style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInningsTable(BuildContext context, CricketMatch match, MatchTeamInnings innings, AppState appState) {
    final team = appState.teams.firstWhere((t) => t.id == innings.teamId);
    final oppTeamId = team.id == match.teamA.id ? match.teamB.id : match.teamA.id;
    final oppTeam = appState.teams.firstWhere((t) => t.id == oppTeamId);
    
    final hasStarted = match.status == MatchStatus.live || match.status == MatchStatus.completed || innings.events.isNotEmpty;
    final activeBowlers = hasStarted 
        ? oppTeam.players.where((player) {
            final isCurrentBowler = (match.status == MatchStatus.live && match.currentInnings == innings) &&
                (player.id == match.currentBowler?.id);
            return innings.events.any((e) => e.bowlerName == player.name) || isCurrentBowler;
          }).toList()
        : oppTeam.players.take(2).toList();

    // Separate batted players (in batting order) from yet-to-bat players
    final battedPlayers = team.players.where((player) {
      if (!hasStarted) return true;
      final isCurrentBatsman = (match.status == MatchStatus.live && match.currentInnings == innings) &&
          (player.id == match.striker?.id || player.id == match.nonStriker?.id);
      return innings.battingOrder.contains(player.id) || 
             innings.events.any((e) => e.batsmanName == player.name) || 
             isCurrentBatsman;
    }).toList();

    if (hasStarted) {
      final battingOrder = innings.battingOrder;
      battedPlayers.sort((a, b) {
        final indexA = battingOrder.indexOf(a.id);
        final indexB = battingOrder.indexOf(b.id);
        if (indexA == -1 && indexB == -1) return 0;
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    }

    final yetToBatPlayers = hasStarted
        ? team.players.where((player) => !battedPlayers.contains(player)).toList()
        : <Player>[];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Batting Card
        Card(
          elevation: 0,
          color: AppColors.cardBg,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.borderGreen.withOpacity(0.3), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Batting Table Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F6F2), // Very soft turf green tint
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text('Batsman', style: TextStyle(color: AppColors.textDark, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                    ),
                    Expanded(
                      child: Text('R', style: TextStyle(color: AppColors.textDark, fontSize: 11.5, fontWeight: FontWeight.w900), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text('B', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text('4s', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text('6s', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('SR', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
              
              // Batting Entries
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: battedPlayers.length,
                itemBuilder: (context, index) {
                  final player = battedPlayers[index];
                  
                  int runs = hasStarted
                      ? innings.events.where((e) => e.batsmanName == player.name).fold(0, (sum, e) => sum + e.runsAddedToBatsman)
                      : (index == 0 ? 34 : (index == 1 ? 21 : 5));
                  int balls = hasStarted
                      ? innings.events.where((e) => e.batsmanName == player.name && e.countsAsBall).length
                      : (index == 0 ? 22 : (index == 1 ? 16 : 8));
                  
                  int fours = hasStarted 
                      ? innings.events.where((e) => e.batsmanName == player.name && e.runs == 4 && !e.isWide && (e.isNoBall ? e.isRunsOffBat : true)).length
                      : ((runs * 0.4).toInt() ~/ 4);
                  int sixes = hasStarted 
                      ? innings.events.where((e) => e.batsmanName == player.name && e.runs == 6 && !e.isWide && (e.isNoBall ? e.isRunsOffBat : true)).length
                      : ((runs * 0.2).toInt() ~/ 6);
                  double sr = balls > 0 ? (runs / balls) * 100 : 0.0;

                  final isOut = hasStarted && innings.events.any((e) => e.isWicket && e.batsmanName == player.name);
                  final isCurrentBatsman = hasStarted && (match.status == MatchStatus.live && match.currentInnings == innings) && (player.id == match.striker?.id || player.id == match.nonStriker?.id);
                  final hasBatted = hasStarted && (innings.battingOrder.contains(player.id) || innings.events.any((e) => e.batsmanName == player.name) || isCurrentBatsman);

                  String statusStr = 'yet to bat';
                  if (!hasStarted) {
                    statusStr = index < 2 ? 'not out' : 'c. sub b. bowler';
                  } else if (isOut) {
                    final wicketEvent = innings.events.firstWhere((e) => e.isWicket && e.batsmanName == player.name);
                    statusStr = wicketEvent.wicketType.isNotEmpty
                        ? '${wicketEvent.wicketType} b. ${wicketEvent.bowlerName}'
                        : 'out';
                  } else if (isCurrentBatsman) {
                    statusStr = 'not out*';
                  } else if (hasBatted) {
                    statusStr = 'not out';
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(bottom: BorderSide(color: AppColors.dividerGreen.withOpacity(0.5), width: 1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Row(
                                children: [
                                  if (isCurrentBatsman) ...[
                                    const Icon(Icons.sports_cricket, size: 12, color: AppColors.primaryTurf),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      '${player.name}${player.id == team.captainId && player.role == 'Wicketkeeper' ? ' (C)(Wk)' : player.id == team.captainId ? ' (C)' : player.role == 'Wicketkeeper' ? ' (Wk)' : ''}',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 13,
                                        fontWeight: isCurrentBatsman ? FontWeight.bold : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '$runs',
                                style: TextStyle(
                                  color: isCurrentBatsman ? AppColors.woodMahogany : AppColors.textDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text('$balls', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                            ),
                            Expanded(
                              child: Text('$fours', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                            ),
                            Expanded(
                              child: Text('$sixes', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                sr.toStringAsFixed(1),
                                style: const TextStyle(color: AppColors.primaryTurf, fontSize: 13, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isCurrentBatsman
                                ? Colors.transparent
                                : AppColors.borderGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrentBatsman
                                  ? Colors.transparent
                                  : AppColors.borderGreen.withOpacity(0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            statusStr,
                            style: TextStyle(
                              color: isCurrentBatsman
                                  ? AppColors.primaryTurf
                                  : (isOut ? AppColors.textDarkSecondary : AppColors.primaryTurf),
                              fontSize: 10.5,
                              fontWeight: isCurrentBatsman || isOut ? FontWeight.w500 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Extras Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.dividerGreen.withOpacity(0.5), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Extras',
                      style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    Text(
                      '${innings.totalExtras} (wd ${innings.wideExtras}, nb ${innings.noBallExtras}, lb ${innings.legByeExtras}, b ${innings.byeExtras})',
                      style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Total Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FBF9), // Extremely light greyish green
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      '${innings.runs}/${innings.wickets} (${innings.oversCompleted} Ov, RR: ${innings.runRate.toStringAsFixed(2)})',
                      style: const TextStyle(color: AppColors.primaryTurf, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (hasStarted && yetToBatPlayers.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.borderGreen.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGreen.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yet to bat: ',
                  style: TextStyle(
                    color: AppColors.textDarkSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    yetToBatPlayers.map((p) => p.name).join(', '),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Bowling Card
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: AppColors.cardBg,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.borderGreen.withOpacity(0.3), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bowling Table Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F6F2), // Very soft turf green tint
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text('Bowler', style: TextStyle(color: AppColors.textDark, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                    ),
                    Expanded(
                      child: Text('O', style: TextStyle(color: AppColors.textDark, fontSize: 11.5, fontWeight: FontWeight.w900), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text('M', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text('R', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text('W', style: TextStyle(color: AppColors.textDark, fontSize: 11.5, fontWeight: FontWeight.w900), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Econ', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),

              // Bowling Entries (Opposition team bowlers)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeBowlers.length,
                itemBuilder: (context, index) {
                  final player = activeBowlers[index];
                  
                  int balls = hasStarted
                      ? innings.events.where((e) => e.bowlerName == player.name && e.countsAsBall).length
                      : (index == 0 ? 12 : 6);
                  int runs = hasStarted
                      ? innings.events.where((e) => e.bowlerName == player.name).fold(0, (sum, e) => sum + e.runsAddedToTeam)
                      : (index == 0 ? 14 : 9);
                  int wickets = hasStarted
                      ? innings.events.where((e) => e.bowlerName == player.name && e.isWicket && e.wicketType != 'Run Out').length
                      : (index == 0 ? 2 : 0);
                  
                  double overs = (balls ~/ 6) + (balls % 6) / 10;
                  double econ = balls > 0 ? (runs / balls) * 6 : 0.0;

                  final isCurrentBowler = hasStarted && (match.status == MatchStatus.live && match.currentInnings == innings) && (player.id == match.currentBowler?.id);

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(bottom: BorderSide(color: AppColors.dividerGreen.withOpacity(0.5), width: index == activeBowlers.length - 1 ? 0 : 1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              if (isCurrentBowler) ...[
                                const Icon(Icons.sports_baseball, size: 12, color: AppColors.primaryTurf),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  '${player.name}${player.id == oppTeam.captainId && player.role == 'Wicketkeeper' ? ' (C)(Wk)' : player.id == oppTeam.captainId ? ' (C)' : player.role == 'Wicketkeeper' ? ' (Wk)' : ''}',
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 13,
                                    fontWeight: isCurrentBowler ? FontWeight.bold : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(overs.toStringAsFixed(1), style: const TextStyle(color: AppColors.textDark, fontSize: 13), textAlign: TextAlign.right),
                        ),
                        Expanded(
                          child: const Text('0', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                        ),
                        Expanded(
                          child: Text('$runs', style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
                        ),
                        Expanded(
                          child: Text(
                            '$wickets',
                            style: const TextStyle(color: AppColors.woodMahogany, fontSize: 13, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            econ.toStringAsFixed(2),
                            style: const TextStyle(color: AppColors.primaryTurf, fontSize: 13, fontWeight: FontWeight.w500),
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
        if (innings.events.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'BALL BY BALL TIMELINE',
            style: TextStyle(
              color: AppColors.primaryTurf,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildOversTimelineList(innings),
        ],
      ],
    );
  }

  Widget _buildOversTimelineList(MatchTeamInnings innings) {
    final List<List<BallEvent>> oversList = [];
    List<BallEvent> currentOver = [];
    int legalBalls = 0;
    
    for (var event in innings.events) {
      currentOver.add(event);
      if (event.countsAsBall) {
        legalBalls++;
        if (legalBalls == 6) {
          oversList.add(currentOver);
          currentOver = [];
          legalBalls = 0;
        }
      }
    }
    if (currentOver.isNotEmpty) {
      oversList.add(currentOver);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGreen, width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: oversList.length,
        separatorBuilder: (context, index) => const Divider(color: AppColors.dividerGreen, height: 12),
        itemBuilder: (context, index) {
          final overEvents = oversList[index];
          final runs = overEvents.fold<int>(0, (sum, ev) => sum + ev.runsAddedToTeam);
          final wickets = overEvents.where((ev) => ev.isWicket).length;
          
          String overSummary = '$runs run${runs != 1 ? 's' : ''}';
          if (wickets > 0) {
            overSummary += ', $wickets Wkt${wickets != 1 ? 's' : ''}';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Over ${index + 1}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        overSummary,
                        style: const TextStyle(
                          color: AppColors.textDarkSecondary,
                          fontSize: 10,
                          // fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: overEvents.map((ev) => _buildOverBallCircle(ev)).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverBallCircle(BallEvent event) {
    Color bg = AppColors.logoBg;
    Color textCol = Colors.black;
    String text = '${event.runs}';

    if (event.isWicket) {
      bg = Colors.red;
      text = event.runs > 0 ? 'W+${event.runs}' : 'W';
      textCol = Colors.white;
    } else if (event.isWide) {
      bg = Colors.amber.shade900;
      text = event.runs > 0 ? 'Wd+${event.runs}' : 'Wd';
      textCol = Colors.white;
    } else if (event.isNoBall) {
      bg = Colors.orange.shade800;
      text = event.runs > 0 ? 'Nb+${event.runs}' : 'Nb';
      textCol = Colors.white;
    } else if (event.isLegBye) {
      bg = Colors.teal.shade800;
      text = event.runs > 0 ? 'Lb+${event.runs}' : 'Lb';
      textCol = Colors.white;
    } else if (event.isBye) {
      bg = Colors.cyan.shade800;
      text = event.runs > 0 ? 'B+${event.runs}' : 'B';
      textCol = Colors.white;
    } else if (event.isPenalty) {
      bg = Colors.deepPurple.shade800;
      text = 'Pen+${event.runs}';
      textCol = Colors.white;
    } else if (event.runs == 4) {
      bg = AppColors.woodLight;
      text = '4';
      textCol = Colors.black;
    } else if (event.runs == 6) {
      bg = AppColors.accentCrease;
      text = '6';
      textCol = Colors.black;
    } else if (event.runs == 0) {
      bg = AppColors.leatherWhite;
      text = '•';
      textCol = Colors.black;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: bg == AppColors.leatherWhite 
            ? Border.all(color: AppColors.borderGreen, width: 1) 
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontWeight: FontWeight.bold,
          fontSize: text.length > 3 ? 7 : (text.length > 2 ? 8 : 10),
        ),
      ),
    );
  }

  Widget _buildPlayerOfTheMatchCard(BuildContext context, CricketMatch match, AppState appState) {
    final role = appState.currentRole;
    final isPOMDeclared = match.playerOfTheMatchId != null;
    final currentUserId = AuthService.instance.currentUser?.uid;
    final isCreator = match.creatorId == null || match.creatorId == currentUserId;
    final canDeclare = (role == UserRole.scorer || role == UserRole.organizer) && isCreator;

    if (!isPOMDeclared && !canDeclare) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPOMDeclared ? AppColors.pitchGold.withOpacity(0.5) : AppColors.borderGreen.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPOMDeclared
              ? [const Color(0xFFFFFDF5), const Color(0xFFFFF9E6)]
              : [const Color(0xFFFDFBF7), const Color(0xFFFAF2E6)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: isPOMDeclared
              ? (() {
                  final pomPlayer = [...match.teamA.players, ...match.teamB.players].firstWhere(
                    (p) => p.id == match.playerOfTheMatchId,
                    orElse: () => Player(
                      id: match.playerOfTheMatchId!,
                      name: match.playerOfTheMatchName!,
                      role: 'Batsman',
                      battingStyle: 'Right-hand bat',
                      bowlingStyle: 'N/A',
                    ),
                  );

                  final runs = match.playerRuns[pomPlayer.id] ?? 0;
                  final balls = match.playerBallsFaced[pomPlayer.id] ?? 0;
                  final sr = balls > 0 ? (runs / balls * 100).toStringAsFixed(1) : '0.0';

                  final wickets = match.bowlerWickets[pomPlayer.id] ?? 0;
                  final runsConceded = match.bowlerRunsConceded[pomPlayer.id] ?? 0;
                  final ballsBowled = match.bowlerBallsBowled[pomPlayer.id] ?? 0;
                  final overs = ballsBowled > 0 ? '${ballsBowled ~/ 6}.${ballsBowled % 6}' : '0.0';
                  final econ = ballsBowled > 0 ? (runsConceded / ballsBowled * 6).toStringAsFixed(2) : '0.00';

                  final hasBattingStats = balls > 0;
                  final hasBowlingStats = ballsBowled > 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.pitchGold.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: AppColors.pitchGold,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pomPlayer.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pomPlayer.role} • Player of the Match',
                                    style: const TextStyle(
                                      color: AppColors.textDarkSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (canDeclare)
                            IconButton(
                              onPressed: () => _showPlayerOfTheMatchSelector(context, match, appState),
                              icon: const Icon(Icons.edit_rounded, color: AppColors.primaryTurf, size: 20),
                              tooltip: 'Change Player of the Match',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.borderGreen, height: 1),
                      const SizedBox(height: 12),
                      
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (hasBattingStats || (!hasBattingStats && !hasBowlingStats)) ...[
                            _buildStatColumn('Runs', '$runs'),
                            _buildStatColumn('Balls', '$balls'),
                            _buildStatColumn('S/R', sr),
                          ],
                          if (hasBowlingStats) ...[
                            _buildStatColumn('Wickets', '$wickets'),
                            _buildStatColumn('Overs', overs),
                            _buildStatColumn('Econ', econ),
                          ],
                        ],
                      ),
                    ],
                  );
                })()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTurf.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: AppColors.primaryTurf,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Player of the Match',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Not declared yet',
                              style: TextStyle(
                                color: AppColors.textDarkMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTurf,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                      ),
                      onPressed: () => _showPlayerOfTheMatchSelector(context, match, appState),
                      icon: const Icon(Icons.stars_rounded, size: 16),
                      label: const Text(
                        'DECLARE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.woodMahogany,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDarkMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showPlayerOfTheMatchSelector(BuildContext context, CricketMatch match, AppState appState) {
    final allPlayers = [...match.teamA.players, ...match.teamB.players];
    
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
                'Select Player of the Match 🌟',
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
                          'No players registered in these teams.',
                          style: TextStyle(color: AppColors.textDarkSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: allPlayers.length,
                      itemBuilder: (context, index) {
                        final player = allPlayers[index];
                        final isTeamA = match.teamA.players.any((p) => p.id == player.id);
                        final teamName = isTeamA ? match.teamA.name : match.teamB.name;
                        
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
                            '${player.role} • $teamName',
                            style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11),
                          ),
                          onTap: () {
                            appState.declarePlayerOfTheMatch(match.id, player.id, player.name);
                            Navigator.pop(context);
                            CustomSnackBar.show(
                              context,
                              message: '${player.name} declared Player of the Match!',
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

  Widget _buildBestPerformersCard(BuildContext context, CricketMatch match) {
    final topBatter = _getTopBatsman(match);
    final topBowler = _getTopBowler(match);
    
    if (topBatter == null && topBowler == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGreen.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: AppColors.primaryTurf, size: 18),
                SizedBox(width: 8),
                Text(
                  'Best Performers',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.borderGreen, height: 20),
            if (topBatter != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTurf.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_cricket_rounded, color: AppColors.primaryTurf, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topBatter['name'],
                          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Top Batsman • ${topBatter['team']}',
                          style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${topBatter['runs']}',
                        style: const TextStyle(color: AppColors.woodMahogany, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      Text(
                        '${topBatter['balls']} balls',
                        style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            if (topBatter != null && topBowler != null) const SizedBox(height: 12),
            if (topBowler != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTurf.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_baseball_rounded, color: AppColors.primaryTurf, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topBowler['name'],
                          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Top Bowler • ${topBowler['team']}',
                          style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${topBowler['wickets']}/${topBowler['runs']}',
                        style: const TextStyle(color: AppColors.woodMahogany, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      Text(
                        '${topBowler['overs']} ov',
                        style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getTopBatsman(CricketMatch match) {
    if (match.playerRuns.isEmpty) return null;
    
    String? bestBatterId;
    int maxRuns = -1;
    int ballsFaced = 0;
    
    match.playerRuns.forEach((playerId, runs) {
      if (runs > maxRuns) {
        maxRuns = runs;
        bestBatterId = playerId;
        ballsFaced = match.playerBallsFaced[playerId] ?? 0;
      } else if (runs == maxRuns && bestBatterId != null) {
        final currentBalls = match.playerBallsFaced[playerId] ?? 0;
        final bestBalls = match.playerBallsFaced[bestBatterId!] ?? 0;
        if (currentBalls < bestBalls) {
          bestBatterId = playerId;
          ballsFaced = currentBalls;
        }
      }
    });
    
    if (bestBatterId == null) return null;
    
    final player = [...match.teamA.players, ...match.teamB.players].firstWhere(
      (p) => p.id == bestBatterId,
      orElse: () => Player(id: bestBatterId!, name: 'Unknown', role: 'Batsman', battingStyle: 'N/A', bowlingStyle: 'N/A'),
    );
    
    final isTeamA = match.teamA.players.any((p) => p.id == bestBatterId);
    final teamName = isTeamA ? match.teamA.abbreviation : match.teamB.abbreviation;
    
    return {
      'name': player.name,
      'team': teamName,
      'runs': maxRuns,
      'balls': ballsFaced,
    };
  }

  Map<String, dynamic>? _getTopBowler(CricketMatch match) {
    if (match.bowlerWickets.isEmpty && match.bowlerRunsConceded.isEmpty) return null;
    
    String? bestBowlerId;
    int maxWickets = -1;
    int runsConceded = 999;
    int ballsBowled = 0;
    
    match.bowlerWickets.forEach((playerId, wickets) {
      final currentRuns = match.bowlerRunsConceded[playerId] ?? 0;
      if (wickets > maxWickets) {
        maxWickets = wickets;
        bestBowlerId = playerId;
        runsConceded = currentRuns;
        ballsBowled = match.bowlerBallsBowled[playerId] ?? 0;
      } else if (wickets == maxWickets && bestBowlerId != null) {
        if (currentRuns < runsConceded) {
          bestBowlerId = playerId;
          runsConceded = currentRuns;
          ballsBowled = match.bowlerBallsBowled[playerId] ?? 0;
        }
      }
    });
    
    if (bestBowlerId == null && match.bowlerBallsBowled.isNotEmpty) {
      match.bowlerBallsBowled.forEach((playerId, balls) {
        if (balls > 0) {
          final runs = match.bowlerRunsConceded[playerId] ?? 0;
          if (runs < runsConceded) {
            runsConceded = runs;
            bestBowlerId = playerId;
            maxWickets = 0;
            ballsBowled = balls;
          }
        }
      });
    }
    
    if (bestBowlerId == null) return null;
    
    final player = [...match.teamA.players, ...match.teamB.players].firstWhere(
      (p) => p.id == bestBowlerId,
      orElse: () => Player(id: bestBowlerId!, name: 'Unknown', role: 'Bowler', battingStyle: 'N/A', bowlingStyle: 'N/A'),
    );
    
    final isTeamA = match.teamA.players.any((p) => p.id == bestBowlerId);
    final teamName = isTeamA ? match.teamA.abbreviation : match.teamB.abbreviation;
    
    return {
      'name': player.name,
      'team': teamName,
      'wickets': maxWickets,
      'runs': runsConceded,
      'overs': '${ballsBowled ~/ 6}.${ballsBowled % 6}',
    };
  }

  void _showEditMatchSheet(BuildContext context, CricketMatch match, AppState appState) {
    final venueController = TextEditingController(text: match.venue);
    final oversController = TextEditingController(text: match.totalOvers.toString());
    DateTime selectedDateTime = match.matchDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final initialDate = selectedDateTime.isBefore(today) ? today : selectedDateTime;
              final date = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: today,
                lastDate: today.add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primaryTurf,
                        onPrimary: Colors.white,
                        onSurface: AppColors.textDark,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setSheetState(() {
                  selectedDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    selectedDateTime.hour,
                    selectedDateTime.minute,
                  );
                });
              }
            }

            Future<void> pickTime() async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primaryTurf,
                        onPrimary: Colors.white,
                        onSurface: AppColors.textDark,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                setSheetState(() {
                  selectedDateTime = DateTime(
                    selectedDateTime.year,
                    selectedDateTime.month,
                    selectedDateTime.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Match Details ✏️',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textDarkMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerGreen),
                    const SizedBox(height: 12),

                    // Venue TextField
                    const Text(
                      'MATCH VENUE',
                      style: TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: venueController,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter venue name',
                        filled: true,
                        fillColor: AppColors.cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.borderGreen.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primaryTurf, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date & Time Picker side-by-side in Row
                    Row(
                      children: [
                        // Date picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DATE',
                                style: TextStyle(
                                  color: AppColors.textDarkSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: pickDate,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.borderGreen.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year}',
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_month_rounded, color: AppColors.primaryTurf, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Time picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TIME',
                                style: TextStyle(
                                  color: AppColors.textDarkSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: pickTime,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.borderGreen.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(Icons.access_time_rounded, color: AppColors.primaryTurf, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Manual Overs text input field
                    const Text(
                      'TOTAL OVERS',
                      style: TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: oversController,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter total overs (e.g. 5, 20)',
                        filled: true,
                        fillColor: AppColors.cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.borderGreen.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primaryTurf, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTurf,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (venueController.text.trim().isEmpty) {
                            CustomSnackBar.show(
                              context,
                              message: 'Please enter a venue name.',
                              type: SnackBarType.error,
                            );
                            return;
                          }
                          final oversStr = oversController.text.trim();
                          final parsedOvers = int.tryParse(oversStr);
                          if (parsedOvers == null || parsedOvers <= 0) {
                            CustomSnackBar.show(
                              context,
                              message: 'Please enter a valid number of overs (minimum 1).',
                              type: SnackBarType.error,
                            );
                            return;
                          }
                          appState.updateMatchDetails(
                            match.id,
                            venueController.text.trim(),
                            selectedDateTime,
                            parsedOvers,
                          );
                          Navigator.pop(context);
                          CustomSnackBar.show(
                            context,
                            message: 'Match details updated successfully!',
                            type: SnackBarType.success,
                          );
                        },
                        child: const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
