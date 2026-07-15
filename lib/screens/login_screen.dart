import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/app_colors.dart';
import '../constants/custom_snackbar.dart';
import 'main_navigation_screen.dart';
import '../widgets/dotted_circular_loader.dart';
import '../services/biometric_service.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final UserRole targetRole;

  const LoginScreen({super.key, required this.targetRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _biometricService = BiometricService();
  bool _isBiometricHardwareAvailable = false;
  bool _isBiometricEnabledForUser = false;
  bool _isBiometricAttempt = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final hasHardware = await _biometricService.isBiometricHardwareAvailable();
    final isEnabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricHardwareAvailable = hasHardware;
        _isBiometricEnabledForUser = isEnabled;
      });

      if (isEnabled) {
        final credentials = await _biometricService.getSavedCredentials();
        if (credentials != null && credentials['email'] != null) {
          setState(() {
            _emailController.text = credentials['email']!;
          });
        }
      }
    }
  }

  Future<void> _biometricLogin() async {
    // 1. Authenticate with biometrics
    final authenticated = await _biometricService.authenticate(
      reason: 'Scan your biometric to log into CricX',
    );

    if (!authenticated) {
      return;
    }

    // 2. Fetch credentials
    final credentials = await _biometricService.getSavedCredentials();
    if (credentials == null || credentials['email'] == null || credentials['password'] == null) {
      _showError('No saved biometric credentials. Please log in with email and password first.');
      return;
    }

    // 3. Fill text fields
    setState(() {
      _emailController.text = credentials['email']!;
      _passwordController.text = credentials['password']!;
      _isBiometricAttempt = true;
    });

    // 4. Submit
    _submit();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Handle Authentication (Login / Sign Up)
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (password.isEmpty || password.length < 6) {
      _showError('Password must be at least 6 characters long.');
      return;
    }

    if (_isSignUp) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _showError('Please enter your name.');
        return;
      }
      final confirmPassword = _confirmPasswordController.text.trim();
      if (password != confirmPassword) {
        _showError('Passwords do not match.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isSignUp) {
        final name = _nameController.text.trim();
        success = await AuthService.instance.register(
          name,
          email,
          password,
          role: widget.targetRole.name,
        );
      } else {
        success = await AuthService.instance.login(email, password);
      }

      if (success && AuthService.instance.currentUser != null) {
        if (!mounted) return;

        try {
          await AuthService.instance.updateRole(widget.targetRole.name);
        } catch (e) {
          debugPrint('Failed to save user role: $e');
        }

        if (!mounted) return;

        // Update AppState with the chosen role
        final appState = Provider.of<AppState>(context, listen: false);
        appState.changeRole(widget.targetRole);

        // Save biometric credentials if hardware is available
        if (_isBiometricHardwareAvailable) {
          try {
            await _biometricService.enableBiometric(email, password);
          } catch (e) {
            debugPrint('Failed to save biometric credentials: $e');
          }
        }

        setState(() {
          _isBiometricAttempt = false;
        });

        CustomSnackBar.show(
          context,
          message: _isSignUp 
              ? 'Account created successfully! Welcome to CricX.' 
              : 'Welcome back to CricX!',
          type: SnackBarType.success,
        );

        // Redirect to main navigation dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          _isBiometricAttempt = false;
        });
        _showError('Authentication failed. Please check your credentials.');
      }
    } catch (e) {
      if (_isBiometricAttempt) {
        await _biometricService.disableBiometric();
      }
      setState(() {
        _isLoading = false;
        _isBiometricAttempt = false;
      });
      _showError('An error occurred: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    CustomSnackBar.show(
      context,
      message: message,
      type: SnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top ground design (matching WelcomeScreen)
            Container(
              height: 240,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PitchLoginPainter(
                          groundColorLight: const Color(0xFF2E6B3E),
                          groundColorDark: const Color(0xFF1F4D28),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SafeArea(
                        child: Stack(
                          children: [
                            // Back Button
                            Positioned(
                              left: 8,
                              top: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            // Logo and Title Branding
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.asset(
                                        'assets/CricX_logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.sports_cricket_rounded,
                                          color: Color(0xFF2E6B3E),
                                          size: 38,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'CricX',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Live Cricket. Simplified.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.85),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Input Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isSignUp ? 'Create Account' : 'Welcome Back',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Sign up to start organizing matches and tracking players.'
                        : 'Log in to continue managing matches and viewing stats.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDarkSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (_isSignUp) ...[
                    // Name Text Field
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryTurf),
                        hintText: 'Enter your full name',
                        hintStyle: const TextStyle(color: AppColors.textDarkDisabled),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.borderWood, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primaryTurf, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email Text Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryTurf),
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(color: AppColors.textDarkDisabled),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderWood, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryTurf, width: 2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Text Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryTurf),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textDarkSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      hintText: 'Enter password (min 6 chars)',
                      hintStyle: const TextStyle(color: AppColors.textDarkDisabled),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderWood, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryTurf, width: 2.0),
                      ),
                    ),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 20),
                    // Confirm Password Text Field
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryTurf),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textDarkSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        hintText: 'Confirm password',
                        hintStyle: const TextStyle(color: AppColors.textDarkDisabled),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.borderWood, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primaryTurf, width: 2.0),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? () {} : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTurf,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const DottedCircularLoader()
                                : Text(
                                    _isSignUp ? 'Sign Up' : 'Log In',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (!_isSignUp && _isBiometricHardwareAvailable) ...[
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryTurf.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: _isLoading ? null : _biometricLogin,
                              splashColor: Colors.white.withOpacity(0.2),
                              highlightColor: Colors.white.withOpacity(0.1),
                              child: Ink(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primaryTurf,
                                      Color(0xFF2E6B3E),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.fingerprint_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Switch between Login and Sign Up
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                      });
                    },
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Log In'
                          : 'Don\'t have an account? Sign Up',
                      style: const TextStyle(
                        color: AppColors.primaryTurf,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PitchLoginPainter extends CustomPainter {
  final Color groundColorDark;
  final Color groundColorLight;

  PitchLoginPainter({
    required this.groundColorDark,
    required this.groundColorLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Fill background with a lush green ground gradient (top to bottom)
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

    // Draw lawn turf stripes
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
