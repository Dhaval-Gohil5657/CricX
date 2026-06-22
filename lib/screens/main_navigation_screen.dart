import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'dashboard_screen.dart';
import 'matches_screen.dart';
import 'teams_screen.dart';
import 'profile_screen.dart';
import 'scorer/scorer_dashboard.dart';
import 'organizer/organizer_dashboard.dart';
import '../constants/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = appState.currentRole;

    // Define items and screens based on role
    final List<Widget> screens = [];
    final List<BottomNavigationBarItem> navItems = [];

    // Add Home tab
    screens.add(const DashboardScreen());
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'Home',
    ));

    // Add Matches tab
    screens.add(const MatchesScreen());
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.sports_cricket_rounded),
      label: 'Matches',
    ));

    if (role == UserRole.organizer) {
      // Tournaments Tab
      screens.add(const OrganizerDashboard());
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.emoji_events_rounded),
        label: 'Tournaments',
      ));
    }

    if (role == UserRole.scorer || role == UserRole.organizer) {
      // Manage Tab
      screens.add(const ScorerDashboard());
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.edit_note_rounded),
        label: 'Manage',
      ));
    }

    if (role == UserRole.guest || role == UserRole.user || role == UserRole.scorer) {
      // Teams Tab
      screens.add(const TeamsScreen());
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.people_alt_rounded),
        label: 'Teams',
      ));
    }

    // Add Profile tab
    screens.add(const ProfileScreen());
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.account_circle_rounded),
      label: 'Profile',
    ));

    // Safeguard index out of bounds when changing roles
    if (_selectedIndex >= screens.length) {
      _selectedIndex = screens.length - 1;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.logoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderWood,
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/CricX_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sports_cricket_rounded,
                    color: AppColors.accentCrease,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CricX',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // Premium Dynamic Role Switcher Badge in App Bar
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: PopupMenuButton<UserRole>(
                tooltip: 'Switch Role',
                onSelected: (UserRole newRole) {
                  appState.changeRole(newRole);
                  setState(() {
                    _selectedIndex = 0; // Reset index to home when switching roles
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderWood, width: 1.5),
                ),
                color: AppColors.cardBg,
                offset: const Offset(0, 46),
                itemBuilder: (context) => [
                  _buildPopupItem(UserRole.guest, 'Guest Viewer', '👀', Colors.blue),
                  _buildPopupItem(UserRole.user, 'Registered User', '👤', AppColors.accentCrease),
                  _buildPopupItem(UserRole.scorer, 'Match Scorer', '✏️', Colors.orange),
                  _buildPopupItem(UserRole.organizer, 'Organizer', '🏆', Colors.amber),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderWood,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getRoleEmoji(role),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        role.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textDarkSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.appBarBg,
          selectedItemColor: AppColors.accentCrease,
          unselectedItemColor: AppColors.textDarkMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 10,
          items: navItems,
        ),
      ),
    );
  }

  PopupMenuItem<UserRole> _buildPopupItem(UserRole role, String title, String emoji, Color color) {
    return PopupMenuItem<UserRole>(
      value: role,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleEmoji(UserRole role) {
    switch (role) {
      case UserRole.guest:
        return '👀';
      case UserRole.user:
        return '👤';
      case UserRole.scorer:
        return '✏️';
      case UserRole.organizer:
        return '🏆';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.guest:
        return Colors.blue;
      case UserRole.user:
        return AppColors.accentCrease;
      case UserRole.scorer:
        return Colors.orange;
      case UserRole.organizer:
        return Colors.amber;
    }
  }
}
