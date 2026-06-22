import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'main_navigation_screen.dart';
import '../constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.topGradient,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                // Logo or Icon Header
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      'assets/CricX_logo.png',
                      height: 80,
                      width: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback emoji icon if image is not loaded yet
                        return const Icon(
                          Icons.sports_cricket,
                          size: 70,
                          color: AppColors.accentCrease,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'CricX',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Live Cricket. Simplified.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textMint,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Select a role to preview the app experience:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDarkSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Role Selection Cards
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildRoleCard(
                        context,
                        title: 'Guest Viewer',
                        description: 'Browse live match scores, detailed scorecards, and schedules.',
                        emoji: '👀',
                        role: UserRole.guest,
                        appState: appState,
                        cardColor: AppColors.guestCardBg,
                      ),
                      _buildRoleCard(
                        context,
                        title: 'Registered User',
                        description: 'Follow teams, view player profiles, career statistics, and history.',
                        emoji: '👤',
                        role: UserRole.user,
                        appState: appState,
                        cardColor: AppColors.userCardBg,
                      ),
                      _buildRoleCard(
                        context,
                        title: 'Match Scorer',
                        description: 'Create teams & matches, conduct toss, and score matches live ball-by-ball.',
                        emoji: '✏️',
                        role: UserRole.scorer,
                        appState: appState,
                        cardColor: AppColors.scorerCardBg,
                      ),
                      _buildRoleCard(
                        context,
                        title: 'Tournament Organizer',
                        description: 'Create tournaments, schedule fixtures, and manage the live points table.',
                        emoji: '🏆',
                        role: UserRole.organizer,
                        appState: appState,
                        cardColor: AppColors.organizerCardBg,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required String emoji,
    required UserRole role,
    required AppState appState,
    required Color cardColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.borderWood,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            appState.changeRole(role);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigationScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDarkSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.accentCrease,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
