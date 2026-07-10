import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'state/app_state.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'constants/app_colors.dart';
import 'widgets/global_banner_ad.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  
  // Initialize API auth service
  await AuthService.instance.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CricX: Live Cricket. Simplified.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primaryTurf,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentCrease,
          secondary: AppColors.pitchGold,
          background: AppColors.background,
          surface: AppColors.cardBg,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: AppColors.textDark,
          onSurface: AppColors.textDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBarGreen,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textDark),
          bodyMedium: TextStyle(color: AppColors.textDarkSecondary),
        ),
      ),
      home: const AuthWrapper(),
      builder: (context, child) {
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: child,
          // bottomNavigationBar: isKeyboardOpen
          //     ? const SizedBox.shrink()
          //     : const SafeArea(
          //         top: false,
          //         child: GlobalBannerAd(),
          //       ),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}
class _AuthWrapperState extends State<AuthWrapper> with SingleTickerProviderStateMixin {
  bool _initialized = false;
  bool _isLoggedIn = false;
  UserRole _role = UserRole.guest;
  bool _animationCompleted = false;

  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _radiusAnimation;

  late Animation<double> _logoSizeAnimation;
  late Animation<double> _logoRadiusAnimation;
  late Animation<double> _logoPaddingAnimation;
  late Animation<double> _logoLeftAnimation;
  late Animation<double> _logoTopAnimation;

  late Animation<double> _titleSizeAnimation;
  late Animation<double> _titleTopAnimation;
  late Animation<double> _titleOpacityAnimation;

  late Animation<double> _taglineSizeAnimation;
  late Animation<double> _taglineTopAnimation;
  late Animation<double> _taglineOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _role = UserRole.values.firstWhere(
        (r) => r.name.toLowerCase() == user.role.toLowerCase(),
        orElse: () => UserRole.user,
      );
      _isLoggedIn = true;
    }

    if (mounted) {
      if (_isLoggedIn) {
        Provider.of<AppState>(context, listen: false).changeRole(_role);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startTransition();
        }
      });
    }
  }

  void _startTransition() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    final isDashboard = _isLoggedIn &&
        (_role == UserRole.user ||
            _role == UserRole.organizer ||
            _role == UserRole.scorer);

    final targetHeight = isDashboard ? (50.0 + topPadding) : 240.0;
    final targetRadius = isDashboard ? 20.0 : 28.0;

    _heightAnimation = Tween<double>(begin: screenHeight, end: targetHeight).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _radiusAnimation = Tween<double>(begin: 0.0, end: targetRadius).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.08, curve: Curves.easeOut),
      ),
    );

    // Logo size, radius, padding, position tweens
    final double logoSizeStart = 96.0;
    final double logoSizeEnd = isDashboard ? 38.0 : 72.0;
    final double logoRadiusStart = 24.0;
    final double logoRadiusEnd = isDashboard ? 12.0 : 20.0;
    final double logoPaddingStart = 12.0;
    final double logoPaddingEnd = 0.0;

    final double logoLeftStart = (screenWidth - logoSizeStart) / 2;
    final double logoTopStart = (screenHeight - logoSizeStart - 80.0) / 2;

    final double logoLeftEnd = isDashboard ? 16.0 : (screenWidth - logoSizeEnd) / 2;
    final double logoTopEnd = isDashboard 
        ? (topPadding + (50.0 - logoSizeEnd) / 2) 
        : (topPadding + (240.0 - topPadding - logoSizeEnd - 70.0) / 2);

    _logoSizeAnimation = Tween<double>(begin: logoSizeStart, end: logoSizeEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _logoRadiusAnimation = Tween<double>(begin: logoRadiusStart, end: logoRadiusEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _logoPaddingAnimation = Tween<double>(begin: logoPaddingStart, end: logoPaddingEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _logoLeftAnimation = Tween<double>(begin: logoLeftStart, end: logoLeftEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _logoTopAnimation = Tween<double>(begin: logoTopStart, end: logoTopEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // Title Size, Position, Opacity Tweens
    final double titleSizeStart = 40.0;
    final double titleSizeEnd = isDashboard ? 40.0 : 32.0;
    final double titleTopStart = logoTopStart + logoSizeStart + 20.0;
    final double titleTopEnd = isDashboard 
        ? titleTopStart - 20.0 
        : (logoTopEnd + logoSizeEnd + 12.0);

    _titleSizeAnimation = Tween<double>(begin: titleSizeStart, end: titleSizeEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _titleTopAnimation = Tween<double>(begin: titleTopStart, end: titleTopEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _titleOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: isDashboard ? 0.0 : 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: isDashboard 
            ? const Interval(0.0, 0.4, curve: Curves.easeOut) 
            : const Interval(0.0, 1.0),
      ),
    );

    // Tagline Size, Position, Opacity Tweens
    final double taglineSizeStart = 16.0;
    final double taglineSizeEnd = isDashboard ? 16.0 : 14.0;
    final double titleHeightStart = 52.0;
    final double titleHeightEnd = isDashboard ? 52.0 : 42.0;
    final double taglineTopStart = titleTopStart + titleHeightStart + 4.0;
    final double taglineTopEnd = isDashboard 
        ? taglineTopStart - 20.0 
        : (titleTopEnd + titleHeightEnd + 2.0);

    _taglineSizeAnimation = Tween<double>(begin: taglineSizeStart, end: taglineSizeEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _taglineTopAnimation = Tween<double>(begin: taglineTopStart, end: taglineTopEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _taglineOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: isDashboard ? 0.0 : 0.85,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: isDashboard 
            ? const Interval(0.0, 0.4, curve: Curves.easeOut) 
            : const Interval(0.0, 1.0),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _animationCompleted = true;
        });
      }
    });

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final mediaQuery = MediaQuery.of(context);
      final screenWidth = mediaQuery.size.width;
      final screenHeight = mediaQuery.size.height;
      final logoSizeStart = 96.0;
      final logoLeftStart = (screenWidth - logoSizeStart) / 2;
      final logoTopStart = (screenHeight - logoSizeStart - 80.0) / 2;
      final titleTopStart = logoTopStart + logoSizeStart + 20.0;
      final taglineTopStart = titleTopStart + 52.0 + 4.0;

      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: PitchWelcomePainter(
                  groundColorLight: const Color(0xFF2E6B3E),
                  groundColorDark: const Color(0xFF1F4D28),
                ),
              ),
            ),
            Positioned(
              left: logoLeftStart,
              top: logoTopStart,
              width: logoSizeStart,
              height: logoSizeStart,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/CricX_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.sports_cricket_rounded,
                        color: Color(0xFF2E6B3E),
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: titleTopStart,
              child: const Center(
                child: Text(
                  'CricX',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: taglineTopStart,
              child: Center(
                child: Text(
                  'Live Cricket. Simplified.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_animationCompleted) {
      return Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _heightAnimation.value,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(_radiusAnimation.value),
                    ),
                    child: CustomPaint(
                      painter: PitchWelcomePainter(
                        groundColorLight: const Color(0xFF2E6B3E),
                        groundColorDark: const Color(0xFF1F4D28),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _logoLeftAnimation.value,
                  top: _logoTopAnimation.value,
                  width: _logoSizeAnimation.value,
                  height: _logoSizeAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_logoRadiusAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15 * _titleOpacityAnimation.value),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_logoRadiusAnimation.value),
                      child: Padding(
                        padding: EdgeInsets.all(_logoPaddingAnimation.value),
                        child: Image.asset(
                          'assets/CricX_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.sports_cricket_rounded,
                            color: const Color(0xFF2E6B3E),
                            size: _logoSizeAnimation.value * 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: _titleTopAnimation.value,
                  child: Opacity(
                    opacity: _titleOpacityAnimation.value,
                    child: Center(
                      child: Text(
                        'CricX',
                        style: TextStyle(
                          fontSize: _titleSizeAnimation.value,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: _taglineTopAnimation.value,
                  child: Opacity(
                    opacity: _taglineOpacityAnimation.value,
                    child: Center(
                      child: Text(
                        'Live Cricket. Simplified.',
                        style: TextStyle(
                          fontSize: _taglineSizeAnimation.value,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    final isDashboard = _isLoggedIn &&
        (_role == UserRole.user ||
            _role == UserRole.organizer ||
            _role == UserRole.scorer);

    if (isDashboard) {
      return const MainNavigationScreen();
    }

    return const WelcomeScreen();
  }
}
