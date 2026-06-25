import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/player_model.dart';
import '../constants/app_colors.dart';
import 'main_navigation_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final players = appState.players;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: players.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final player = players[index];
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
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primaryTurf,
                        size: 14,
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
