import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/custom_snackbar.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../state/app_state.dart';
import '../screens/welcome_screen.dart';
import 'dotted_circular_loader.dart';

class ReloginDialog extends StatefulWidget {
  const ReloginDialog({super.key});

  @override
  State<ReloginDialog> createState() => _ReloginDialogState();
}

class _ReloginDialogState extends State<ReloginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _biometricService = BiometricService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricHardwareAvailable = false;
  bool _isBiometricEnabledForUser = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _checkBiometrics();
  }

  Future<void> _loadSavedEmail() async {
    final user = AuthService.instance.currentUser;
    if (user?.email != null && user!.email!.isNotEmpty) {
      setState(() {
        _emailController.text = user.email!;
      });
    } else {
      final savedEmail = await _storage.read(key: 'user_email');
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        setState(() {
          _emailController.text = savedEmail;
        });
      }
    }
  }

  Future<void> _checkBiometrics() async {
    final hasHardware = await _biometricService.isBiometricHardwareAvailable();
    final isEnabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricHardwareAvailable = hasHardware;
        _isBiometricEnabledForUser = isEnabled;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await _biometricService.authenticate(
      reason: 'Authenticate to restore your session',
    );

    if (!authenticated) return;

    final credentials = await _biometricService.getSavedCredentials();
    if (credentials == null || credentials['email'] == null || credentials['password'] == null) {
      setState(() {
        _errorMessage = 'No saved biometric credentials found.';
      });
      return;
    }

    setState(() {
      _emailController.text = credentials['email']!;
      _passwordController.text = credentials['password']!;
    });

    _handleReLogin();
  }

  Future<void> _handleReLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService.instance.login(email, password);
      if (!mounted) return;

      if (success && AuthService.instance.currentUser != null) {
        // Sync role with AppState if context is valid
        final activeRoleStr = await _storage.read(key: 'active_user_role');
        final roleToUse = activeRoleStr ?? AuthService.instance.currentUser!.role;
        final userRole = UserRole.values.firstWhere(
          (r) => r.name.toLowerCase() == roleToUse.toLowerCase(),
          orElse: () => UserRole.user,
        );

        if (mounted) {
          try {
            Provider.of<AppState>(context, listen: false).changeRole(userRole);
          } catch (_) {}

          CustomSnackBar.show(
            context,
            message: 'Session restored successfully!',
            type: SnackBarType.success,
          );
          Navigator.of(context).pop(); // Dismiss relogin dialog
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid credentials. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.background,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderGreen, width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Icon Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: Colors.amber.shade900,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Session Expired',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              const Text(
                'Your login session or authentication token has expired. Please re-enter your password to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textDarkSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Error Banner (if any)
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryTurf, size: 20),
                  hintText: 'Enter your email',
                  hintStyle: const TextStyle(color: AppColors.textDarkDisabled, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderWood, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryTurf, width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryTurf, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textDarkSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  hintText: 'Enter your password',
                  hintStyle: const TextStyle(color: AppColors.textDarkDisabled, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderWood, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryTurf, width: 2.0),
                  ),
                ),
                onSubmitted: (_) => _handleReLogin(),
              ),
              const SizedBox(height: 24),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleReLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTurf,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const DottedCircularLoader()
                            : const Text(
                                'Re-login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (_isBiometricHardwareAvailable && _isBiometricEnabledForUser) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _isLoading ? null : _handleBiometricLogin,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTurf.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryTurf.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppColors.primaryTurf,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Logout Option
              TextButton(
                onPressed: _isLoading ? null : _handleLogout,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Sign in with another account',
                  style: TextStyle(
                    color: AppColors.textDarkSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
