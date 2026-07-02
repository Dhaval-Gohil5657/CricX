import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../state/app_state.dart';
import '../models/player_model.dart';
import '../constants/app_colors.dart';
import '../constants/custom_snackbar.dart';
import 'scorer/create_team_screen.dart';
import 'main_navigation_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  String _selectedRoleFilter = 'All';
  String _selectedSortBy = 'Runs';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = appState.currentRole;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final players = appState.filterByCreator && (role == UserRole.scorer || role == UserRole.organizer)
        ? (() {
            final myTeamPlayerIds = appState.teams
                .where((t) => t.creatorId == currentUserId)
                .expand((t) => t.players.map((p) => p.id))
                .toSet();
            return appState.players.where((p) => myTeamPlayerIds.contains(p.id)).toList();
          })()
        : appState.players;
    final searchQuery = appState.searchQuery;

    // 1. Filter players by selected role and search query
    final List<Player> filteredPlayers = players.where((p) {
      final matchesRole = _selectedRoleFilter == 'All' || p.role.toLowerCase() == _selectedRoleFilter.toLowerCase();
      if (!matchesRole) return false;
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.trim().toLowerCase();
      return p.name.toLowerCase().contains(q) ||
             p.role.toLowerCase().contains(q) ||
             (p.battingStyle != null && p.battingStyle.toLowerCase().contains(q)) ||
             (p.bowlingStyle != null && p.bowlingStyle.toLowerCase().contains(q));
    }).toList();

    // 2. Sort players based on selection
    if (_selectedSortBy == 'Runs') {
      filteredPlayers.sort((a, b) => b.runsScored.compareTo(a.runsScored));
    } else if (_selectedSortBy == 'Wickets') {
      filteredPlayers.sort((a, b) => b.wicketsTaken.compareTo(a.wicketsTaken));
    } else if (_selectedSortBy == 'Matches') {
      filteredPlayers.sort((a, b) => b.matchesPlayed.compareTo(a.matchesPlayed));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 5, 16, 0),
            child: Text(
              'CRICX PLAYERS DIRECTORY',
              style: TextStyle(
                color: AppColors.textDarkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          // Filter & Sort dropdowns
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 10),
            child: Row(
              children: [
                // Filter Dropdown
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderGreen),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRoleFilter,
                        isExpanded: true,
                        dropdownColor: AppColors.cardBg,
                        icon: const Icon(Icons.filter_list_rounded, color: AppColors.primaryTurf, size: 18),
                        style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold),
                        items: ['All', 'Batsman', 'Bowler', 'All-Rounder', 'Wicketkeeper'].map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role == 'All' ? 'All Roles' : role),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRoleFilter = val;
                              // Auto-adjust sort by type to match role naturally
                              if (val == 'Bowler') {
                                _selectedSortBy = 'Wickets';
                              } else if (val == 'Batsman' || val == 'Wicketkeeper') {
                                _selectedSortBy = 'Runs';
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Sort Dropdown
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderGreen),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSortBy,
                        isExpanded: true,
                        dropdownColor: AppColors.cardBg,
                        icon: const Icon(Icons.sort_rounded, color: AppColors.primaryTurf, size: 18),
                        style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold),
                        items: [
                          const DropdownMenuItem<String>(value: 'Runs', child: Text('Runs Scored')),
                          const DropdownMenuItem<String>(value: 'Wickets', child: Text('Wickets Taken')),
                          const DropdownMenuItem<String>(value: 'Matches', child: Text('Matches Played')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSortBy = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: players.isEmpty
                ? Center(
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
                              Icons.people_outline_rounded,
                              color: AppColors.primaryTurf,
                              size: 64,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No Players Registered',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create teams and add players to see them listed in the directory.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textDarkSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              final role = appState.currentRole;
                              if (role == UserRole.scorer || role == UserRole.organizer) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreateTeamScreen(),
                                  ),
                                );
                              } else {
                                CustomSnackBar.show(
                                  context,
                                  message: 'Please switch your role to Scorer or Organizer to create teams and add players.',
                                  type: SnackBarType.warning,
                                );
                              }
                            },
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            label: const Text('Create Team & Players'),
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
                      ),
                    ),
                  )
                : filteredPlayers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.people_outline_rounded,
                              color: AppColors.textDarkMuted,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'No players found matching "$searchQuery"'
                                  : 'No players matching current filters.',
                              style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 90),
                    itemCount: filteredPlayers.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final player = filteredPlayers[index];
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
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryTurf.withOpacity(0.15),
                              child: Text(
                                player.name[0],
                                style: const TextStyle(color: AppColors.primaryTurf, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              player.name,
                              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${player.role} • ${player.battingStyle}',
                              style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _selectedSortBy == 'Runs'
                                          ? '${player.runsScored} Runs'
                                          : _selectedSortBy == 'Wickets'
                                              ? '${player.wicketsTaken} Wkts'
                                              : '${player.matchesPlayed} Matches',
                                      style: const TextStyle(
                                        color: AppColors.accentCrease,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      player.role,
                                      style: const TextStyle(
                                        color: AppColors.textDarkMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppColors.primaryTurf,
                                  size: 14,
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerDetailScreen(player: player),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          title: Text(
            player.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderWood.withOpacity(0.8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryTurf,
                      child: Text(
                        player.name[0],
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      player.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTurf.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryTurf.withOpacity(0.2), width: 1),
                      ),
                      child: Text(
                        player.role,
                        style: const TextStyle(color: AppColors.primaryTurf, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHeaderSpec('Batting', player.battingStyle),
                        Container(width: 1, height: 30, color: AppColors.dividerGreen),
                        _buildHeaderSpec('Bowling', player.bowlingStyle),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Batting Statistics
              const Text(
                'BATTING CAREER STATS',
                style: TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildStatCard('Matches', '${player.matchesPlayed}', valueColor: AppColors.woodLight, borderColor: AppColors.borderWood),
                  _buildStatCard('Runs', '${player.runsScored}', valueColor: AppColors.woodLight, borderColor: AppColors.borderWood),
                  _buildStatCard('Average', player.battingAverage.toStringAsFixed(1), valueColor: AppColors.woodLight, borderColor: AppColors.borderWood),
                  _buildStatCard('Highest', '${player.highestScore}', valueColor: AppColors.woodLight, borderColor: AppColors.borderWood),
                  _buildStatCard('Balls Faced', '${player.ballsFaced}', valueColor: AppColors.woodLight, borderColor: AppColors.borderWood),
                  _buildStatCard('S/Rate', player.strikeRate.toStringAsFixed(1), valueColor: AppColors.woodLight, borderColor: AppColors.borderWood),
                ],
              ),
              const SizedBox(height: 24),

              // Bowling Statistics
              const Text(
                'BOWLING CAREER STATS',
                style: TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildStatCard('Overs', (player.ballsBowled / 6).toStringAsFixed(1), valueColor: AppColors.accentCrease, borderColor: AppColors.borderGreen),
                  _buildStatCard('Wickets', '${player.wicketsTaken}', valueColor: AppColors.accentCrease, borderColor: AppColors.borderGreen),
                  _buildStatCard('Economy', player.economyRate.toStringAsFixed(2), valueColor: AppColors.accentCrease, borderColor: AppColors.borderGreen),
                  _buildStatCard('Runs Conc.', '${player.runsConceded}', valueColor: AppColors.accentCrease, borderColor: AppColors.borderGreen),
                  _buildStatCard('Best Bowl', player.bestBowling, valueColor: AppColors.accentCrease, borderColor: AppColors.borderGreen),
                  _buildStatCard('Balls Bowl', '${player.ballsBowled}', valueColor: AppColors.accentCrease, borderColor: AppColors.borderGreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSpec(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {required Color valueColor, required Color borderColor}) {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
