import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../state/app_state.dart';
import 'dashboard_screen.dart';
import 'matches_screen.dart';
import 'directory_screen.dart';
import 'scorer/scorer_dashboard.dart';
import 'organizer/organizer_dashboard.dart';
import 'welcome_screen.dart';
import '../constants/app_colors.dart';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<bool> _activatedTabs = [true, false, false, false, false];
  UserRole? _lastRole;
  String _matchesView = 'matches'; // 'matches' or 'tournaments'

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = appState.currentRole;

    if (_lastRole != role) {
      _lastRole = role;
      for (int i = 1; i < _activatedTabs.length; i++) {
        _activatedTabs[i] = false;
      }
    }

    // Define items and screens based on role
    final List<Widget> screens = [];
    final List<Map<String, dynamic>> navItems = [];

    // Add Home tab
    screens.add(const DashboardScreen());
    navItems.add({
      'icon': Icons.dashboard_rounded,
      'label': 'Home',
    });

    // Add Matches tab
    if (_matchesView == 'matches') {
      screens.add(const MatchesScreen());
      navItems.add({
        'icon': Icons.sports_cricket_rounded,
        'label': 'Matches',
      });
    } else {
      screens.add(const OrganizerDashboard());
      navItems.add({
        'icon': Icons.emoji_events_rounded,
        'label': 'Tournaments',
      });
    }

    // Manage tab for unified role (Tournaments tab removed as it is mixed with Matches tab)
    if (role == UserRole.scorer || role == UserRole.organizer) {
      // Manage Tab
      screens.add(const ScorerDashboard());
      navItems.add({
        'icon': Icons.scoreboard_rounded,
        'label': 'Manage',
      });
    }

    // Directory Tab (Combined Teams & Players)
    screens.add(const DirectoryScreen());
    navItems.add({
      'icon': Icons.people_alt_rounded,
      'label': 'Directory',
    });

    // Safeguard index out of bounds and update activated tabs
    if (_selectedIndex >= screens.length) {
      _selectedIndex = screens.length - 1;
    }
    if (_selectedIndex < 0) {
      _selectedIndex = 0;
    }

    if (_selectedIndex < screens.length) {
      while (_activatedTabs.length < screens.length) {
        _activatedTabs.add(false);
      }
      _activatedTabs[_selectedIndex] = true;
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
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
            const SizedBox(width: 15),
            Text(
              navItems[_selectedIndex]['label'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (navItems[_selectedIndex]['label'] == 'Matches' || navItems[_selectedIndex]['label'] == 'Tournaments')
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: PopupMenuButton<String>(
                  tooltip: 'Switch Feed',
                  onSelected: (String newView) {
                    setState(() {
                      _matchesView = newView;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.borderWood, width: 1.5),
                  ),
                  color: AppColors.cardBg,
                  offset: const Offset(0, 46),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'matches',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accentCrease.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🏏', style: TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Individual Matches',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'tournaments',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🏆', style: TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Tournaments',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          _matchesView == 'matches' ? '🏏' : '🏆',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _matchesView == 'matches' ? 'Matches' : 'Tournaments',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
          if (_selectedIndex == screens.length - 1)
            IconButton(
              icon: Icon(
                FirebaseAuth.instance.currentUser != null
                    ? Icons.logout_rounded
                    : Icons.login_rounded,
                color: Colors.white,
              ),
              tooltip: FirebaseAuth.instance.currentUser != null ? 'Sign Out' : 'Sign In / Switch Role',
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  if (FirebaseAuth.instance.currentUser != null) {
                    await FirebaseAuth.instance.signOut();
                  }
                  appState.changeRole(UserRole.guest);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(FirebaseAuth.instance.currentUser != null
                          ? 'Logged out successfully.'
                          : 'Returning to role selection.'),
                      backgroundColor: AppColors.accentCrease,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                      ),
                    );
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Action failed: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
        ],
      ),
    ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: IndexedStack(
          index: _selectedIndex,
          children: List.generate(screens.length, (index) {
            if (index < _activatedTabs.length && _activatedTabs[index]) {
              return screens[index];
            } else {
              return const SizedBox.shrink();
            }
          }),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 0.0, right: 16.0, bottom: 12.0),
          child: CustomPaint(
            painter: BatPainter(
              woodColorDark: const Color(0xFFE6C397),
              woodColorLight: const Color(0xFFFAF2E6),
              gripColor: AppColors.primaryTurf,
              borderColor: AppColors.borderWood,
            ),
            child: SizedBox(
              height: 58,
              child: Padding(
                padding: const EdgeInsets.only(left: 30, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    final isSelected = _selectedIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected 
                                  ? AppColors.primaryTurf.withOpacity(0.12)
                                  : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: isSelected
                                    ? AppColors.primaryTurf
                                    : AppColors.textDarkSecondary.withOpacity(0.7),
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              item['label'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryTurf
                                    : AppColors.textDarkSecondary.withOpacity(0.7),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


}

class BatPainter extends CustomPainter {
  final Color woodColorDark;
  final Color woodColorLight;
  final Color gripColor;
  final Color borderColor;

  BatPainter({
    required this.woodColorDark,
    required this.woodColorLight,
    required this.gripColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Define the bat path (reversed horizontal bat shape attached to left)
    final Path batPath = Path();
    
    // Start at top-left edge flush with screen
    batPath.moveTo(0, h * 0.35);
    
    // Draw flat left edge (handle cut off by screen border)
    batPath.lineTo(0, h * 0.65);
    
    // Bottom shoulder curves out to full height
    batPath.quadraticBezierTo(
      10, h * 0.65,
      16, h * 0.78,
    );
    batPath.quadraticBezierTo(
      24, h,
      35, h,
    );
    
    // Bottom edge to the toe
    batPath.lineTo(w - 15, h);
    
    // Toe bottom-right rounded corner (reduced curve radius 12)
    batPath.quadraticBezierTo(
      w, h,
      w, h - 15,
    );
    
    // Flat vertical toe end
    batPath.lineTo(w, 15);
    
    // Toe top-right rounded corner (reduced curve radius 12)
    batPath.quadraticBezierTo(
      w, 0,
      w - 15, 0,
    );
    
    // Top edge to the shoulder
    batPath.lineTo(35, 0);
    
    // Top shoulder curves in to the handle base
    batPath.quadraticBezierTo(
      24, 0,
      16, h * 0.22,
    );
    batPath.quadraticBezierTo(
      10, h * 0.35,
      0, h * 0.35,
    );
    batPath.close();

    // 2. Draw Shadow
    canvas.drawShadow(
      batPath.shift(const Offset(0, 4)), 
      Colors.black.withOpacity(0.15), 
      4.0, 
      true
    );

    // 3. Draw wood gradient fill (spine effect)
    final Paint woodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          woodColorDark,
          woodColorLight,
          woodColorDark,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(batPath, woodPaint);

    // 4. Draw subtle wood grains
    final Paint grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.035)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(35, h * 0.3), Offset(w - 20, h * 0.3), grainPaint);
    canvas.drawLine(Offset(45, h * 0.5), Offset(w - 15, h * 0.5), grainPaint);
    canvas.drawLine(Offset(35, h * 0.7), Offset(w - 20, h * 0.7), grainPaint);

    // 5. Draw the rubber grip collar at the handle stub (left end, flush with screen)
    canvas.save();
    canvas.clipPath(batPath);
    
    final Path gripPath = Path();
    gripPath.moveTo(0, 0);
    gripPath.lineTo(18, 0);
    gripPath.lineTo(18, h);
    gripPath.lineTo(0, h);
    gripPath.close();

    final Paint gripPaint = Paint()
      ..color = gripColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(gripPath, gripPaint);

    // Draw grip grooves
    final Paint groovePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(6, 0), Offset(6, h), groovePaint);
    canvas.drawLine(Offset(12, 0), Offset(12, h), groovePaint);

    canvas.restore();

    // 6. Draw bat outline border
    final Paint borderPaint = Paint()
      ..color = borderColor.withOpacity(0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(batPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PitchCreasePainter extends CustomPainter {
  final Color groundColorDark;
  final Color groundColorLight;

  PitchCreasePainter({
    required this.groundColorDark,
    required this.groundColorLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Fill background with a lush green ground gradient (top to bottom)
    final Paint groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          groundColorLight,
          groundColorDark,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), groundPaint);

    // 2. Draw subtle lawn turf stripes (vertical stripes across the ground)
    final Paint stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    
    final double stripeWidth = w / 5;
    for (int i = 0; i < 5; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, h),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

