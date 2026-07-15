import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'state/app_state.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'constants/app_colors.dart';
import 'widgets/global_banner_ad.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/auth_service.dart';
import 'screens/onboarding_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  bool _showWalkthrough = false;

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
      duration: const Duration(milliseconds: 1200),
    );
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isVersionLessThan(String current, String target) {
    try {
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final targetParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      for (int i = 0; i < targetParts.length; i++) {
        if (i >= currentParts.length) {
          return true;
        }
        if (currentParts[i] < targetParts[i]) {
          return true;
        } else if (currentParts[i] > targetParts[i]) {
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  void _showUpdateDialog(String latestVersion) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissal by clicking outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevents dismissal by back button
          child: Dialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.borderGreen, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTurf.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: AppColors.primaryTurf,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text(
                    'Update Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    'A newer and more stable version of CricX is available on Google Play. Please update the app to version $latestVersion to continue scoring and playing.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDarkSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTurf,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=karma.cricx');
                        try {
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            await launchUrl(url);
                          }
                        } catch (e) {
                          debugPrint('Error launching Play Store url: $e');
                        }
                      },
                      icon: const Icon(Icons.shop_two_rounded, size: 18),
                      label: const Text(
                        'UPDATE NOW',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      debugPrint('CricX Installed Version: $currentVersion');

      final response = await http.get(
        Uri.parse('https://play.google.com/store/apps/details?id=karma.cricx&hl=en'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final versionRegex = RegExp(r',\[\[\["([0-9,\.]*)"]]],');
        final match = versionRegex.firstMatch(response.body);
        String? playStoreVersion;
        
        if (match != null) {
          playStoreVersion = match.group(1);
        } else {
          final fallbackRegex = RegExp(r'\["([0-9]+\.[0-9]+\.[0-9]+)"\]');
          final match2 = fallbackRegex.firstMatch(response.body);
          if (match2 != null) {
            playStoreVersion = match2.group(1);
          }
        }

        if (playStoreVersion != null && playStoreVersion.isNotEmpty) {
          debugPrint('CricX Play Store Version: $playStoreVersion');
          if (_isVersionLessThan(currentVersion, playStoreVersion)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showUpdateDialog(playStoreVersion!);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to check Play Store app version: $e');
    }
  }

  Future<void> _checkAuth() async {
    try {
      _checkVersion();
      
      // Check if walkthrough has been shown
      final storage = const FlutterSecureStorage();
      final walkthroughShown = await storage.read(key: 'walkthrough_shown');
      _showWalkthrough = walkthroughShown != 'true';

      final user = AuthService.instance.currentUser;
      if (user != null) {
        final activeRoleStr = await storage.read(key: 'active_user_role');
        final roleToUse = activeRoleStr ?? user.role;
        _role = UserRole.values.firstWhere(
          (r) => r.name.toLowerCase() == roleToUse.toLowerCase(),
          orElse: () => UserRole.user,
        );
        _isLoggedIn = true;
      }
    } catch (e, stack) {
      debugPrint('Error in checkAuth: $e\n$stack');
      _showWalkthrough = false;
    } finally {
      if (mounted) {
        Future.delayed(Duration.zero, () {
          if (mounted) {
            if (_isLoggedIn) {
              Provider.of<AppState>(context, listen: false).changeRole(_role);
            }
            _startTransition();
          }
        });
      }
    }
  }

  void _transitionFromWalkthroughToWelcome() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final topPadding = mediaQuery.padding.top;

    final isDashboard = _isLoggedIn &&
        (_role == UserRole.user ||
            _role == UserRole.organizer ||
            _role == UserRole.scorer);

    final targetHeight = isDashboard ? (50.0 + topPadding) : 240.0;
    final targetRadius = isDashboard ? 20.0 : 28.0;

    setState(() {
      _showWalkthrough = false;
      _animationCompleted = false;
    });

    _controller.reset();

    // Height slides down from 0.0 to 240.0 (or dashboard height)
    _heightAnimation = Tween<double>(begin: 0.0, end: targetHeight).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Radius transitions from 36.0 to targetRadius
    _radiusAnimation = Tween<double>(begin: 36.0, end: targetRadius).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // Logo size, radius, padding, position tweens
    final double logoSizeEnd = isDashboard ? 38.0 : 72.0;
    final double logoRadiusEnd = isDashboard ? 12.0 : 20.0;

    final double logoLeftEnd = isDashboard ? 16.0 : (screenWidth - logoSizeEnd) / 2;
    final double logoTopEnd = isDashboard 
        ? (topPadding + (50.0 - logoSizeEnd) / 2) 
        : (topPadding + (240.0 - topPadding - logoSizeEnd - 70.0) / 2);

    _logoSizeAnimation = Tween<double>(begin: 72.0, end: logoSizeEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _logoRadiusAnimation = Tween<double>(begin: 20.0, end: logoRadiusEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _logoPaddingAnimation = ConstantTween<double>(0.0).animate(_controller);
    _logoLeftAnimation = Tween<double>(begin: logoLeftEnd, end: logoLeftEnd).animate(_controller);
    _logoTopAnimation = Tween<double>(begin: -100.0, end: logoTopEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Title Size, Position, Opacity Tweens
    final double titleSizeEnd = isDashboard ? 40.0 : 32.0;
    final double titleTopEnd = isDashboard 
        ? (logoTopEnd + 20.0) 
        : (logoTopEnd + logoSizeEnd + 12.0);

    _titleSizeAnimation = Tween<double>(begin: 32.0, end: titleSizeEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _titleTopAnimation = Tween<double>(begin: -150.0, end: titleTopEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _titleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: isDashboard ? 0.0 : 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Tagline Size, Position, Opacity Tweens
    final double taglineSizeEnd = isDashboard ? 16.0 : 14.0;
    final double titleHeightEnd = isDashboard ? 52.0 : 42.0;
    final double taglineTopEnd = isDashboard 
        ? (titleTopEnd + 24.0) 
        : (titleTopEnd + titleHeightEnd + 2.0);

    _taglineSizeAnimation = Tween<double>(begin: 14.0, end: taglineSizeEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _taglineTopAnimation = Tween<double>(begin: -200.0, end: taglineTopEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _taglineOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: isDashboard ? 0.0 : 0.85,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _animationCompleted = true;
        });
      }
    });
  }

  void _startTransition() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    final isDashboard = _isLoggedIn &&
        (_role == UserRole.user ||
            _role == UserRole.organizer ||
            _role == UserRole.scorer) && !_showWalkthrough;

    final double targetHeight;
    final double targetRadius;
    if (_showWalkthrough) {
      targetHeight = 0.0;
      targetRadius = 36.0; // Maintain rounded corners during slide up
    } else if (isDashboard) {
      targetHeight = 50.0 + topPadding;
      targetRadius = 20.0;
    } else {
      targetHeight = 240.0;
      targetRadius = 28.0;
    }

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
    final double logoTopEnd = _showWalkthrough
        ? -100.0
        : (isDashboard 
            ? (topPadding + (50.0 - logoSizeEnd) / 2) 
            : (topPadding + (240.0 - topPadding - logoSizeEnd - 70.0) / 2));

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
    final double titleTopEnd = _showWalkthrough
        ? -150.0
        : (isDashboard 
            ? titleTopStart - 20.0 
            : (logoTopEnd + logoSizeEnd + 12.0));

    _titleSizeAnimation = Tween<double>(begin: titleSizeStart, end: titleSizeEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _titleTopAnimation = Tween<double>(begin: titleTopStart, end: titleTopEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _titleOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: (isDashboard || _showWalkthrough) ? 0.0 : 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: (isDashboard || _showWalkthrough) 
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
    final double taglineTopEnd = _showWalkthrough
        ? -200.0
        : (isDashboard 
            ? taglineTopStart - 20.0 
            : (titleTopEnd + titleHeightEnd + 2.0));

    _taglineSizeAnimation = Tween<double>(begin: taglineSizeStart, end: taglineSizeEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _taglineTopAnimation = Tween<double>(begin: taglineTopStart, end: taglineTopEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _taglineOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: (isDashboard || _showWalkthrough) ? 0.0 : 0.85,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: (isDashboard || _showWalkthrough) 
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
        body: Stack(
          children: [
            if (_showWalkthrough)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    image: DecorationImage(
                      image: AssetImage('assets/cricx_back.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            AnimatedBuilder(
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
          ],
        ),
      );
    }

    final isDashboard = _isLoggedIn &&
        (_role == UserRole.user ||
            _role == UserRole.organizer ||
            _role == UserRole.scorer) && !_showWalkthrough;

    if (_showWalkthrough) {
      return OnboardingScreen(
        onComplete: () async {
          try {
            const storage = FlutterSecureStorage();
            await storage.write(key: 'walkthrough_shown', value: 'true');
          } catch (e) {
            debugPrint('Error saving walkthrough status: $e');
          }
          _transitionFromWalkthroughToWelcome();
        },
      );
    }

    if (isDashboard) {
      return const MainNavigationScreen();
    }

    return const WelcomeScreen();
  }
}
