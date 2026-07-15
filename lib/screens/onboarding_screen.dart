import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Real-time Live Matches',
      description: 'Follow grassroots cricket matches live with instant updates. View runs, wickets, and partnerships as they happen.',
      type: OnboardingType.liveMatch,
    ),
    OnboardingPageData(
      title: 'Detailed Scorecards',
      description: 'Dive deep into batting strike rates, bowling economy, fall of wickets, and over-by-over progress reports.',
      type: OnboardingType.scorecard,
    ),
    OnboardingPageData(
      title: 'Unified Manager Console',
      description: 'Configure squad rosters, team profiles, match fixtures, and local tournaments all in one centralized console page.',
      type: OnboardingType.manage,
    ),
    OnboardingPageData(
      title: 'Intuitive Live Scoring',
      description: 'A complete scoring pad at your fingertips. Log boundaries, extras, and wickets instantly with automated striker rotations.',
      type: OnboardingType.scoringPad,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        image: DecorationImage(
          image: AssetImage('assets/cricx_back.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar (Skip Button)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo tag
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.borderGreen.withOpacity(0.5),
                              width: 0.8,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Image.asset(
                                'assets/CricX_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.sports_cricket_rounded,
                                  color: Color(0xFF2E6B3E),
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'CricX',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // Skip button
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            _pages.length - 1,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child:  Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      SizedBox(height: 48)
                  ],
                ),
              ),

              // PageView content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Bottom Navigation Area
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Indicators
                    Row(
                      children: List.generate(
                        _pages.length,
                        (index) => _buildIndicator(index),
                      ),
                    ),

                    // Next / Get Started button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            widget.onComplete();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTurf,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 6.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryTurf : AppColors.borderGreen,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Visual Container Card (Clean / No Green Ground Card!)
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: _buildMockup(pageData.type),
                  ),
                ),
              ),
            ),
          ),

          // Text Container
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pageData.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    pageData.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDarkSecondary,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockup(OnboardingType type) {
    switch (type) {
      case OnboardingType.liveMatch:
        return _buildLiveMatchMock();
      case OnboardingType.scorecard:
        return _buildScorecardMock();
      case OnboardingType.manage:
        return _buildManageMock();
      case OnboardingType.scoringPad:
        return _buildScoringPadMock();
    }
  }

  // 1. Live Matches Mockup (Shows 2 stacked cards using the exact original layout)
  Widget _buildLiveMatchMock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSingleLiveMatchCard(
          venue: 'Wankhede Stadium, Mumbai',
          teamAEmoji: '🦁',
          teamAColor: const Color(0xFF1E3A8A),
          teamAName: 'Mumbai Mavericks',
          teamAScore: '184/4',
          teamAOvers: '20.0',
          teamBEmoji: '🦅',
          teamBColor: const Color(0xFFB45309),
          teamBName: 'Delhi Dynamos',
          teamBScore: '162/5',
          teamBOvers: '18.2',
          statusText: 'Delhi Dynamos need 23 runs in 10 balls.',
          isLive: true,
        ),
        const SizedBox(height: 14),
        _buildSingleLiveMatchCard(
          venue: 'Eden Gardens, Kolkata',
          teamAEmoji: '🐯',
          teamAColor: const Color(0xFF6B21A8),
          teamAName: 'Kolkata Knights',
          teamAScore: '145/6',
          teamAOvers: '20.0',
          teamBEmoji: '⚡',
          teamBColor: const Color(0xFFF59E0B),
          teamBName: 'Chennai Chargers',
          teamBScore: '110/3',
          teamBOvers: '15.1',
          statusText: 'Chennai Chargers need 36 runs in 29 balls.',
          isLive: true,
        ),
      ],
    );
  }

  Widget _buildSingleLiveMatchCard({
    required String venue,
    required String teamAEmoji,
    required Color teamAColor,
    required String teamAName,
    required String teamAScore,
    required String teamAOvers,
    required String teamBEmoji,
    required Color teamBColor,
    required String teamBName,
    required String teamBScore,
    required String teamBOvers,
    required String statusText,
    required bool isLive,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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
            Color(0xFFFDFBF7), // Extremely light wood
            Color(0xFFFAF2E6), // Light wood
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue & Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  venue,
                  style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                ),
                if (isLive)
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
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Team A
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: teamAColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(teamAEmoji, style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      teamAName,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teamAScore,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($teamAOvers ov)',
                      style: const TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Team B
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: teamBColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(teamBEmoji, style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      teamBName,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teamBScore,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($teamBOvers ov)',
                      style: const TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(color: AppColors.borderGreen, height: 24),

            // Status Text
            Text(
              statusText,
              style: const TextStyle(
                color: AppColors.primaryTurf,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Scorecard Mockup (Uses the exact original list/card structure from scorecard_screen.dart)
  Widget _buildScorecardMock() {
    return Card(
      elevation: 0,
      color: AppColors.cardBg,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderGreen.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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

          // Batted Entries
          _buildBatterRow('Rohit Sharma', 'c sub b Rashid', 84, 42, 6, 5, 200.0, false),
          _buildBatterRow('Virat Kohli *', 'not out', 45, 30, 4, 1, 150.0, true),
          _buildBatterRow('MS Dhoni', 'not out', 12, 5, 1, 1, 240.0, false),

          // Bowler Header Row
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F6F2),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
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
                  child: Text('W', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11), textAlign: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Econ', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11), textAlign: TextAlign.right),
                ),
              ],
            ),
          ),

          // Bowler Entries
          _buildBowlerRow('Jasprit Bumrah', '4.0', '1', '18', '2', '4.50', false),
          _buildBowlerRow('Rashid Khan', '3.0', '0', '24', '1', '8.00', true),
        ],
      ),
    );
  }

  Widget _buildBatterRow(String name, String dismissal, int runs, int balls, int fours, int sixes, double sr, bool isActive) {
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
                    if (isActive) ...[
                      const Icon(Icons.sports_cricket, size: 12, color: AppColors.primaryTurf),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
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
                    color: isActive ? AppColors.woodMahogany : AppColors.textDark,
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
          Text(
            dismissal,
            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(String name, String o, String m, String r, String w, String econ, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: isLast ? null : Border(bottom: BorderSide(color: AppColors.dividerGreen.withOpacity(0.5), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(o, style: const TextStyle(color: AppColors.textDark, fontSize: 13), textAlign: TextAlign.right),
          ),
          Expanded(
            child: Text(m, style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
          ),
          Expanded(
            child: Text(r, style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
          ),
          Expanded(
            child: Text(w, style: const TextStyle(color: AppColors.primaryTurf, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text(econ, style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // 3. Manage Dashboard Mockup (Welcome Banner + 2 side-by-side Creator cards + 1 full-width Creator card matching ScorerDashboard)
  Widget _buildManageMock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ QUICK CREATORS',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 12),

        // Create Team & Schedule Match cards in a Row side-by-side
        Row(
          children: [
            Expanded(
              child: _buildCreateCard(
                title: 'Create Team',
                titleColor: AppColors.woodMahogany,
                subtitle: 'Add squad & players',
                emoji: '👕',
                baseColor: AppColors.pitchGold,
                gradientColors: const [
                  Color(0xFFFFF9F3),
                  Color(0xFFFBEADB),
                ],
                borderColor: Colors.orange.withOpacity(0.25),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCreateCard(
                title: 'Schedule Match',
                titleColor: AppColors.primaryTurf,
                subtitle: 'Set up teams & overs',
                emoji: '🏏',
                baseColor: AppColors.accentCrease,
                gradientColors: const [
                  Color(0xFFF4FBF5),
                  Color(0xFFEAF5EB),
                ],
                borderColor: AppColors.accentCrease.withOpacity(0.25),
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // Create Tournament card (Full-Width, below them)
        _buildFullWidthCreateCard(
          title: 'Create Tournament',
          subtitle: 'Launch a new round-robin league and points table',
          emoji: '🏆',
          baseColor: Colors.amber,
          gradientColors: const [
            Color(0xFFFFF9F3),
            Color(0xFFFFE9AA),
          ],
          borderColor: Colors.amber.withOpacity(0.3),
        ),
      ],
    );
  }

  // Vertical card (used side-by-side in Row)
  Widget _buildCreateCard({
    required String title,
    required Color titleColor,
    required String subtitle,
    required String emoji,
    required Color baseColor,
    required List<Color> gradientColors,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: baseColor.withOpacity(0.18),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: baseColor,
                    size: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textDarkSecondary,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Horizontal card (used full width below Row)
  Widget _buildFullWidthCreateCard({
    required String title,
    required String subtitle,
    required String emoji,
    required Color baseColor,
    required List<Color> gradientColors,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: baseColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.woodMahogany,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textDarkSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.woodMahogany.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.woodMahogany,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Scoring Page Mockup (Shows ONLY the scoring pad card with all buttons with exact colors)
  Widget _buildScoringPadMock() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderGreen.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryTurf.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'SCORING PAD',
                style: TextStyle(
                  color: AppColors.primaryTurf,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Grid Buttons (0, 1, 2, 3, 4, 5, 6, Wd, Nb, Lb, B, Pen)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.6,
              children: [
                _buildScoringButtonMock('0', 'Dot', const Color(0xFF4A5D4E)),
                _buildScoringButtonMock('1', 'Run', AppColors.primaryTurf),
                _buildScoringButtonMock('2', 'Runs', AppColors.primaryTurf),
                _buildScoringButtonMock('3', 'Runs', AppColors.primaryTurf),
                _buildScoringButtonMock('4', 'Four', AppColors.woodMahogany),
                _buildScoringButtonMock('5', 'Overthrow', AppColors.primaryTurf),

                // Highlighted 6 with active glow shadow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCrease.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                  child: _buildScoringButtonMock('6', 'Six', AppColors.accentCrease),
                ),

                _buildScoringButtonMock('Wd', 'Wide', Colors.amber.shade900),
                _buildScoringButtonMock('Nb', 'No Ball', Colors.orange.shade800),
                _buildScoringButtonMock('Lb', 'Leg Bye', Colors.teal.shade800),
                _buildScoringButtonMock('B', 'Byes', Colors.cyan.shade800),
                _buildScoringButtonMock('Pen', 'Penalty', Colors.deepPurple.shade800),
              ],
            ),

            const SizedBox(height: 10),

            // Bottom Action Rows (Out, Retire, Undo)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 42,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_baseball, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('OUT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 42,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.airline_seat_flat_angled_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          const Text('RETIRE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 42,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.undo_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          const Text('UNDO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildScoringButtonMock(String label, String subtitle, Color color) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 7.5, color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }
}

enum OnboardingType {
  liveMatch,
  scorecard,
  manage,
  scoringPad,
}

class OnboardingPageData {
  final String title;
  final String description;
  final OnboardingType type;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.type,
  });
}
