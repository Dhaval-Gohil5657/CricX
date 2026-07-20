import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cricx/services/auth_service.dart';
import '../state/app_state.dart';
import 'dashboard_screen.dart';
import 'matches_screen.dart';
import 'directory_screen.dart';
import 'scorer/scorer_dashboard.dart';
import 'organizer/organizer_dashboard.dart';
import 'profile_screen.dart';
import '../constants/app_colors.dart';
import '../constants/custom_snackbar.dart';
import '../widgets/interactive_tour.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final int initialMatchesTab;
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialMatchesTab = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;
  final List<bool> _activatedTabs = [true, false, false, false, false];
  UserRole? _lastRole;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Feature Tour Keys
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _avatarKey = GlobalKey();
  final Map<String, GlobalKey> _tabKeys = {
    'Home': GlobalKey(),
    'Matches': GlobalKey(),
    'Tournaments': GlobalKey(),
    'Manage': GlobalKey(),
    'Directory': GlobalKey(),
  };

  // Inside Sub-Screen Tour Keys
  final GlobalKey _homeLiveMatchesKey = GlobalKey();
  final GlobalKey _homeQuickActionsKey = GlobalKey();
  final GlobalKey _homeNextRecentMatchesKey = GlobalKey();
  final GlobalKey _matchesSubTabKey = GlobalKey();
  final GlobalKey _matchesStatusTabKey = GlobalKey();
  final GlobalKey _tournamentsCreateBtnKey = GlobalKey();
  final GlobalKey _manageQuickCreatorsKey = GlobalKey();
  final GlobalKey _directoryTabsKey = GlobalKey();

  bool _showTour = false;
  List<TourStep> _tourSteps = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    if (_selectedIndex >= 0 && _selectedIndex < _activatedTabs.length) {
      _activatedTabs[_selectedIndex] = true;
    }
    _checkTourStatus();
  }

  Future<void> _checkTourStatus() async {
    const storage = FlutterSecureStorage();
    final tourCompleted = await storage.read(key: 'feature_tour_completed');
    final restartTour = await storage.read(key: 'restart_feature_tour');

    if (tourCompleted != 'true' || restartTour == 'true') {
      await storage.delete(key: 'restart_feature_tour');
      
      // Wait for UI layout to settle so keys have contexts
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          _initializeTourSteps(appState.currentRole, _getNavItems(appState.currentRole));
          setState(() {
            _showTour = true;
          });
        }
      });
    }
  }

  List<Map<String, dynamic>> _getNavItems(UserRole role) {
    final List<Map<String, dynamic>> navItems = [];
    
    navItems.add({
      'icon': Icons.dashboard_rounded,
      'label': 'Home',
    });
    navItems.add({
      'icon': Icons.sports_cricket_rounded,
      'label': 'Matches',
    });
    navItems.add({
      'icon': Icons.emoji_events_rounded,
      'label': 'Tournaments',
    });

    if (role == UserRole.scorer || role == UserRole.organizer) {
      navItems.add({
        'icon': Icons.scoreboard_rounded,
        'label': 'Manage',
      });
    }

    if (role != UserRole.guest) {
      navItems.add({
        'icon': Icons.people_alt_rounded,
        'label': 'Directory',
      });
    }
    
    return navItems;
  }

  void _initializeTourSteps(UserRole role, List<Map<String, dynamic>> navItems) {
    _tourSteps = [];
    
    int getTabIndex(String label) {
      return navItems.indexWhere((item) => item['label'] == label);
    }

    final homeIndex = getTabIndex('Home');
    final matchesIndex = getTabIndex('Matches');
    final tournamentsIndex = getTabIndex('Tournaments');
    final manageIndex = getTabIndex('Manage');
    final directoryIndex = getTabIndex('Directory');

    // 1. Home Tab & Inside Home Screen
    if (homeIndex != -1) {
      final key = _tabKeys['Home'];
      if (key != null) {
        _tourSteps.add(TourStep(
          targetKey: key,
          title: 'Home Dashboard',
          description: 'Explore active live matches, today\'s upcoming match schedules, and recent match results.',
          tabIndex: homeIndex,
        ));
      }
      _tourSteps.add(TourStep(
        targetKey: _homeLiveMatchesKey,
        title: 'Live Matches Section',
        description: 'Stay updated in real-time with ongoing live match scores and key details.',
        tabIndex: homeIndex,
      ));
      if (role == UserRole.scorer || role == UserRole.organizer) {
        _tourSteps.add(TourStep(
          targetKey: _homeQuickActionsKey,
          title: 'Quick Actions',
          description: 'Quickly access common tools like creating teams, scheduling matches, or starting scorer consoles.',
          tabIndex: homeIndex,
        ));
      }
      _tourSteps.add(TourStep(
        targetKey: _homeNextRecentMatchesKey,
        title: role == UserRole.scorer || role == UserRole.organizer ? 'Upcoming Matches' : 'Recent Matches',
        description: role == UserRole.scorer || role == UserRole.organizer
            ? 'Track upcoming match schedules, times, and venues planned for today.'
            : 'Explore completed match results, highlights, and final scorecards.',
        tabIndex: homeIndex,
      ));
    }

    // 2. Matches Tab & Inside Matches Screen
    if (matchesIndex != -1) {
      final key = _tabKeys['Matches'];
      if (key != null) {
        _tourSteps.add(TourStep(
          targetKey: key,
          title: 'Match Center',
          description: 'Browse matches or tournament fixtures. View categorized lists of live, upcoming, and completed matches.',
          tabIndex: matchesIndex,
        ));
      }
      _tourSteps.add(TourStep(
        targetKey: _matchesSubTabKey,
        title: 'Individual & Tournament Matches',
        description: 'Toggle between friendly individual matches and organized tournament matches.',
        tabIndex: matchesIndex,
      ));
      _tourSteps.add(TourStep(
        targetKey: _matchesStatusTabKey,
        title: 'Match Status Filter',
        description: 'Filter matches by their current state: Live, Upcoming, or Completed.',
        tabIndex: matchesIndex,
      ));
    }

    // 3. Tournaments Tab & Inside Tournaments Screen
    if (tournamentsIndex != -1) {
      final key = _tabKeys['Tournaments'];
      if (key != null) {
        _tourSteps.add(TourStep(
          targetKey: key,
          title: 'Tournaments',
          description: 'Explore tournaments, group standings, fixtures, points tables, and detailed tournament brackets.',
          tabIndex: tournamentsIndex,
        ));
      }
      _tourSteps.add(TourStep(
        targetKey: _tournamentsCreateBtnKey,
        title: 'Tournaments Management',
        description: 'Manage current tournaments or create a new one to begin tracking tournament fixtures and standing tables.',
        tabIndex: tournamentsIndex,
      ));
    }

    // 4. Manage Tab & Inside Manage Screen
    if (manageIndex != -1) {
      final key = _tabKeys['Manage'];
      if (key != null) {
        _tourSteps.add(TourStep(
          targetKey: key,
          title: 'Manage Console',
          description: 'Access scorer tools to create teams, schedule matches, set up toss rules, and score matches ball-by-ball.',
          tabIndex: manageIndex,
        ));
      }
      _tourSteps.add(TourStep(
        targetKey: _manageQuickCreatorsKey,
        title: 'Quick Creators',
        description: 'Create teams, schedule matches, or launch tournaments directly from here.',
        tabIndex: manageIndex,
      ));
    }

    // 5. Directory Tab & Inside Directory Screen
    if (directoryIndex != -1) {
      final key = _tabKeys['Directory'];
      if (key != null) {
        _tourSteps.add(TourStep(
          targetKey: key,
          title: 'Rosters & Stats',
          description: 'Explore registered teams and player profiles. View squad rosters and individual player career statistics.',
          tabIndex: directoryIndex,
        ));
      }
      _tourSteps.add(TourStep(
        targetKey: _directoryTabsKey,
        title: 'Teams & Players Directory',
        description: 'Switch between the Teams directory and Players list to explore rosters, bios, and career statistics.',
        tabIndex: directoryIndex,
      ));
    }

    // 6. Header Icons / profile
    if (role != UserRole.guest) {
      _tourSteps.add(TourStep(
        targetKey: _avatarKey,
        title: 'User Profile & Roles',
        description: 'Manage user details, toggle biometric settings, and switch active roles dynamically.',
      ));
    }

    _tourSteps.add(TourStep(
      targetKey: _searchKey,
      title: 'Smart Search',
      description: 'Quickly find matches, tournaments, teams, or players based on your active tab.',
    ));

    if (role == UserRole.scorer || role == UserRole.organizer) {
      _tourSteps.add(TourStep(
        targetKey: _filterKey,
        title: 'My Creations Filter',
        description: 'Toggle to filter lists to display only the matches, teams, or tournaments created by you.',
      ));
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final List<Map<String, dynamic>> navItems = _getNavItems(role);
    final List<Widget> screens = [];

    for (final item in navItems) {
      final label = item['label'] as String;
      if (label == 'Home') {
        screens.add(DashboardScreen(
          liveMatchesKey: _homeLiveMatchesKey,
          quickActionsKey: _homeQuickActionsKey,
          nextRecentMatchesKey: _homeNextRecentMatchesKey,
        ));
      } else if (label == 'Matches') {
        screens.add(MatchesScreen(
          subTabKey: _matchesSubTabKey,
          statusTabKey: _matchesStatusTabKey,
          initialTab: widget.initialMatchesTab,
        ));
      } else if (label == 'Tournaments') {
        screens.add(OrganizerDashboard(
          tournamentsMainKey: _tournamentsCreateBtnKey,
        ));
      } else if (label == 'Manage') {
        screens.add(ScorerDashboard(
          quickCreatorsKey: _manageQuickCreatorsKey,
        ));
      } else if (label == 'Directory') {
        screens.add(DirectoryScreen(
          directoryTabsKey: _directoryTabsKey,
        ));
      }
    }

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

    final String label = navItems[_selectedIndex]['label'] as String;
    String hintPlaceholder = 'matches...';
    if (label == 'Home') {
      hintPlaceholder = 'live matches...';
    } else if (label == 'Matches') {
      hintPlaceholder = 'matches...';
    } else if (label == 'Tournaments') {
      hintPlaceholder = 'tournaments...';
    } else if (label == 'Directory') {
      hintPlaceholder = 'teams or players...';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        image: const DecorationImage(
          image: AssetImage('assets/cricx_back.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
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
          title: _isSearching
              ? Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    key: const ValueKey('search_field'),
                    controller: _searchController,
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                    onChanged: (val) {
                      appState.setSearchQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search $hintPlaceholder',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13.5),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(left: 12, right: 8, bottom: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 20,
                      ),
                      suffixIcon: appState.searchQuery.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  appState.clearSearchQuery();
                                },
                                child: const Icon(
                                  Icons.clear_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    role != UserRole.guest
                        ? UserProfileAvatar(
                            key: _avatarKey,
                            role: role,
                            onProfileReturned: _checkTourStatus,
                          )
                        : Container(
                            key: _avatarKey,
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
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
            actions: [
              if (label != 'Manage')
                _isSearching
                    ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                      });
                      appState.clearSearchQuery();
                      _searchController.clear();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(Icons.close_rounded, color: Colors.white),
                    ))
                    : Padding(
                  padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      key: _searchKey,
                      onTap: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                      child: const Icon(
                        Icons.search_rounded, color: Colors.white, size: 22,),
                    ),
                ),
              if ((label == 'Home' || label == 'Matches' || label == 'Tournaments' || label == 'Directory') &&
                  (role == UserRole.scorer || role == UserRole.organizer) && !_isSearching)
                 Padding(
                   padding: const EdgeInsets.only(right: 15),
                   child: GestureDetector(
                      key: _filterKey,
                      onTap: () {
                        appState.toggleFilterByCreator();

                        String activeMsg = '';
                        if (label == 'Home') {
                          activeMsg = appState.filterByCreator
                              ? 'Showing only your scheduled matches'
                              : 'Showing all matches';
                        } else if (label == 'Matches') {
                          activeMsg = appState.filterByCreator
                              ? 'Showing only your scheduled matches'
                              : 'Showing all matches';
                        } else if (label == 'Tournaments') {
                          activeMsg = appState.filterByCreator
                              ? 'Showing only your scheduled tournaments'
                              : 'Showing all tournaments';
                        } else if (label == 'Directory') {
                          activeMsg = appState.filterByCreator
                              ? 'Showing only your created teams & roster players'
                              : 'Showing all teams & players';
                        } else {
                          activeMsg = appState.filterByCreator
                              ? 'Filter active: showing your scheduled items'
                              : 'Filter cleared: showing all items';
                        }

                        CustomSnackBar.show(
                          context,
                          message: activeMsg,
                          type: SnackBarType.info,
                        );
                      },
                      child: Tooltip(
                        message: appState.filterByCreator ? 'Showing My Created' : 'Showing All',
                        child: Icon(
                          appState.filterByCreator ? Icons.how_to_reg_rounded : Icons.group_outlined,
                          color: appState.filterByCreator ? AppColors.borderGreen : Colors.white,
                        ),
                      ),
                    ),
                 ),

            ],
        ),
      ),
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(screens.length, (index) {
            if (index < _activatedTabs.length && _activatedTabs[index]) {
              return screens[index];
            } else {
              return const SizedBox.shrink();
            }
          }),
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
                  padding: const EdgeInsets.only(left: 20, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(navItems.length, (index) {
                      final item = navItems[index];
                      final isSelected = _selectedIndex == index;
                      return GestureDetector(
                        key: _tabKeys[item['label']],
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                            _isSearching = false;
                          });
                          appState.clearSearchQuery();
                          _searchController.clear();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
      ),
      if (_showTour && _tourSteps.isNotEmpty)
        InteractiveTourOverlay(
          steps: _tourSteps,
          onComplete: () async {
            const storage = FlutterSecureStorage();
            await storage.write(key: 'feature_tour_completed', value: 'true');
            if (mounted) {
              setState(() {
                _showTour = false;
              });
              CustomSnackBar.show(
                context,
                message: 'Tour completed! Enjoy using CricX!',
                type: SnackBarType.success,
              );
            }
          },
          onSkip: () async {
            const storage = FlutterSecureStorage();
            await storage.write(key: 'feature_tour_completed', value: 'true');
            if (mounted) {
              setState(() {
                _showTour = false;
              });
            }
          },
          onStepChanged: (stepIndex) {
            final step = _tourSteps[stepIndex];
            if (step.tabIndex != null && step.tabIndex != _selectedIndex) {
              setState(() {
                _selectedIndex = step.tabIndex!;
                _isSearching = false;
              });
              appState.clearSearchQuery();
              _searchController.clear();
            } else {
              for (final entry in _tabKeys.entries) {
                if (entry.value == step.targetKey) {
                  final targetIndex = navItems.indexWhere((item) => item['label'] == entry.key);
                  if (targetIndex != -1) {
                    setState(() {
                      _selectedIndex = targetIndex;
                      _isSearching = false;
                    });
                    appState.clearSearchQuery();
                    _searchController.clear();
                  }
                  break;
                }
              }
            }
          },
        ),
    ],
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

class UserProfileAvatar extends StatefulWidget {
  final UserRole role;
  final VoidCallback? onProfileReturned;
  const UserProfileAvatar({super.key, required this.role, this.onProfileReturned});

  @override
  State<UserProfileAvatar> createState() => _UserProfileAvatarState();
}

class _UserProfileAvatarState extends State<UserProfileAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        if (widget.onProfileReturned != null) {
          widget.onProfileReturned!();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ListenableBuilder(
          listenable: AuthService.instance,
          builder: (context, _) {
            final String? userName = AuthService.instance.currentUser?.displayName;
            final String email = user.email ?? 'U';
            final String fallbackName = email.split('@')[0].replaceAll('.', ' ').toUpperCase();
            final String nameToUse = userName ?? fallbackName;
            final String initial = nameToUse.isNotEmpty ? nameToUse[0].toUpperCase() : 'U';

            // Premium gradient based on role (Same turf green brand colors for both)
            final List<Color> gradientColors = [AppColors.primaryTurf, const Color(0xFF339C4D)];

            // Outer border glow
            final Color borderColor = Colors.white;

            // Initial text color
            final Color textColor = Colors.white;

            final IconData badgeIcon = widget.role == UserRole.scorer || widget.role == UserRole.organizer
                ? Icons.emoji_events_rounded
                : Icons.sports_cricket_rounded;

            final Color badgeBgColor = Colors.white;

            final Color badgeIconColor = const Color(0xFF2E6B3E);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Main Avatar Container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    border: Border.all(
                      color: borderColor.withOpacity(0.85),
                      width: 1.8,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _buildInitialText(initial, textColor),
                ),
                // Small Role Badge Overlay
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      badgeIcon,
                      size: 10,
                      color: badgeIconColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInitialText(String initial, Color textColor) {
    return Text(
      initial,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        letterSpacing: 0.2,
        shadows: textColor == Colors.white
            ? const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ]
            : const [
                Shadow(
                  color: Colors.white24,
                  offset: Offset(0, 0.5),
                  blurRadius: 1,
                ),
              ],
      ),
    );
  }
}

