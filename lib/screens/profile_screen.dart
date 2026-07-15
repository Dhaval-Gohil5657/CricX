import 'package:cricx/widgets/dotted_circular_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cricx/services/auth_service.dart';
import '../state/app_state.dart';
import '../constants/app_colors.dart';
import '../constants/custom_snackbar.dart';
import 'welcome_screen.dart';
import 'main_navigation_screen.dart';
import '../services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String? _userName;
  final _biometricService = BiometricService();
  bool _isBiometricHardwareAvailable = false;
  bool _isBiometricEnabledForUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkBiometrics();
  }

  Future<void> _loadUserProfile() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName;
      });
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

  Future<void> _toggleBiometric(bool enabled) async {
    if (!enabled) {
      await _biometricService.disableBiometric();
      setState(() {
        _isBiometricEnabledForUser = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Biometric login disabled successfully.',
          type: SnackBarType.success,
        );
      }
    } else {
      final user = AuthService.instance.currentUser;
      if (user == null || user.email == null) return;

      final passwordController = TextEditingController();
      bool isVerifying = false;

      final password = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.borderGreen, width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTurf.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    color: AppColors.primaryTurf,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Enable Biometrics',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your password to verify identity and enable biometric login.',
                  style: TextStyle(
                    color: AppColors.textDarkSecondary,
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: AppColors.textDarkSecondary),
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryTurf),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryTurf),
                    ),
                  ),
                ),
                if (isVerifying) ...[
                  const SizedBox(height: 12),
                  const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: DottedCircularLoader(color: AppColors.primaryTurf,)
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textDarkSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTurf,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isVerifying
                    ? null
                    : () async {
                        final pw = passwordController.text.trim();
                        if (pw.isEmpty) return;

                        setDialogState(() {
                          isVerifying = true;
                        });

                        try {
                          final success = await AuthService.instance.login(user.email!, pw);
                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(context, pw);
                            }
                          } else {
                            throw Exception('Incorrect password');
                          }
                        } catch (e) {
                          setDialogState(() {
                            isVerifying = false;
                          });
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context,
                              message: 'Incorrect password. Verification failed.',
                              type: SnackBarType.error,
                            );
                          }
                        }
                      },
                child: const Text('Verify'),
              ),
            ],
          ),
        ),
      );

      if (password != null && password.isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          await _biometricService.enableBiometric(user.email!, password);
          setState(() {
            _isBiometricEnabledForUser = true;
          });
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: 'Biometric login enabled successfully.',
              type: SnackBarType.success,
            );
          }
        } catch (e) {
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: 'Failed to enable biometric login.',
              type: SnackBarType.error,
            );
          }
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Future<void> _showEditNameDialog(BuildContext context, String currentName) async {
    final textController = TextEditingController(text: _userName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderGreen, width: 1.5),
        ),
        title: const Text(
          'Update Profile Name',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textDark),
          decoration: const InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: AppColors.textDarkSecondary),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryTurf),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textDarkSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTurf,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, textController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null) {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        setState(() => _isLoading = true);
        try {
          // Update profile name locally
          setState(() {
            _userName = newName.isEmpty ? null : newName;
          });
          if (context.mounted) {
            CustomSnackBar.show(
              context,
              message: 'Name updated successfully.',
              type: SnackBarType.success,
            );
          }
        } catch (e) {
          if (context.mounted) {
            CustomSnackBar.show(
              context,
              message: 'Failed to update name.',
              type: SnackBarType.error,
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _updateRoleInFirestore(UserRole role) async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        await AuthService.instance.updateRole(role.name);
      } catch (e) {
        debugPrint('Failed to update role: $e');
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context, AppState appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderGreen, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.borderGreen.withOpacity(0.4),
                borderRadius: BorderRadius.circular(15)
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.primaryTurf,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of CricX?',
          style: TextStyle(
            color: AppColors.textDarkSecondary,
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textDarkSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTurf,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await AuthService.instance.logout();
        appState.changeRole(UserRole.guest);
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: 'Logged out successfully.',
            type: SnackBarType.success,
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: 'Sign out failed. Please try again.',
            type: SnackBarType.error,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = AuthService.instance.currentUser;
    final currentRole = appState.currentRole;

    final String fallbackName = _capitalize((user?.email != null) ? user!.email!.split('@')[0].replaceAll('.', ' ') : 'Registered User');
    final String displayName = _userName ?? fallbackName;
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        image: const DecorationImage(
          image: AssetImage('assets/cricx_back.png'),
          fit: BoxFit.cover,
        )
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
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
            title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                    color: AppColors.borderGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)
                ),
                    child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20)),
                onPressed: () => _confirmSignOut(context, appState),
                tooltip: 'Sign Out',
              ),
              SizedBox(width: 5,)
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTurf))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Profile Summary Card
                    Card(
                      elevation: 0,
                      color: AppColors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.borderGreen.withOpacity(0.3), width: 1.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTurf,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.8),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 1,
                                  right: 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.borderGreen,
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
                                      currentRole == UserRole.scorer || currentRole == UserRole.organizer ? Icons.emoji_events_rounded
                                      : Icons.sports_cricket_rounded,
                                      size: 15,
                                      color: AppColors.primaryTurf,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // GestureDetector(
                                      //   onTap: () => _showEditNameDialog(context, displayName),
                                      //   child: Container(
                                      //     padding: const EdgeInsets.all(4),
                                      //     decoration: BoxDecoration(
                                      //       color: AppColors.primaryTurf.withOpacity(0.08),
                                      //       shape: BoxShape.circle,
                                      //     ),
                                      //     child: const Icon(
                                      //       Icons.edit_rounded,
                                      //       color: AppColors.primaryTurf,
                                      //       size: 14,
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(
                                      color: AppColors.textDarkSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTurf.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      currentRole == UserRole.scorer || currentRole == UserRole.organizer
                                          ? 'ORGANIZER & SCORER'
                                          : 'REGISTERED USER',
                                      style: const TextStyle(
                                        color: AppColors.primaryTurf,
                                        fontSize: 10,
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
                    ),
                    const SizedBox(height: 24),

                    // 2. Select Role Card
                    const Text(
                      'SWITCH ACTIVE ROLE',
                      style: TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      color: AppColors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.borderGreen.withOpacity(0.3), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          _buildRoleTile(
                            title: 'Registered User',
                            description: 'View stats and schedules, teams & players profile',
                            role: UserRole.user,
                            currentRole: currentRole,
                            appState: appState,
                            icon: Icons.person_pin,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: const Divider(color: AppColors.dividerGreen, height: 1),
                          ),
                          _buildRoleTile(
                            title: 'Organizer / Scorer',
                            description: 'Create & manage teams, matches and tournaments.',
                            role: UserRole.organizer,
                            currentRole: currentRole,
                            appState: appState,
                            icon: Icons.emoji_events_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),



                    // 3b. My Stats & Details Row (Filtered by creatorId)
                    if (currentRole == UserRole.scorer || currentRole == UserRole.organizer) ...[
                      const Text(
                        'MY STATISTICS',
                        style: TextStyle(
                          color: AppColors.textDarkSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatCard('Teams', '${appState.teams.where((t) => t.creatorId == user?.uid).length}', Icons.group_work_rounded, color: AppColors.pitchGold),
                          const SizedBox(width: 8),
                          _buildStatCard('Matches', '${appState.matches.where((m) => m.creatorId == user?.uid).length}', Icons.sports_cricket_rounded, color: AppColors.pitchGold),
                          const SizedBox(width: 8),
                          _buildStatCard('Tournaments', '${appState.tournaments.where((t) => t.creatorId == user?.uid).length}', Icons.emoji_events_rounded, color: AppColors.pitchGold),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 3. Stats & Details Card (App Wide)
                    const Text(
                      'APP STATISTICS',
                      style: TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      color: AppColors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.borderGreen.withOpacity(0.3), width: 1.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildInlineStat('Teams', '${appState.teams.length}', Icons.group_work_rounded)),
                                Container(height: 40, width: 1, color: AppColors.borderGreen),
                                Expanded(child: _buildInlineStat('Players', '${appState.players.length}', Icons.people_alt_rounded)),
                              ],
                            ),
                            const Divider(color: AppColors.borderGreen, height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildInlineStat('Matches', '${appState.matches.length}', Icons.sports_cricket_rounded)),
                                Container(height: 40, width: 1, color: AppColors.borderGreen),
                                Expanded(child: _buildInlineStat('Tournaments', '${appState.tournaments.length}', Icons.emoji_events_rounded)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isBiometricHardwareAvailable) ...[
                      const Text(
                        'SECURITY SETTINGS',
                        style: TextStyle(
                          color: AppColors.textDarkSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        color: AppColors.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.borderGreen.withOpacity(0.3), width: 1.2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTurf.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.fingerprint_rounded,
                                  color: AppColors.primaryTurf,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Biometric Login',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Use Fingerprint/Face ID for quick access',
                                      style: TextStyle(
                                        color: AppColors.textDarkSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _isBiometricEnabledForUser,
                                activeColor: AppColors.primaryTurf,
                                activeTrackColor: AppColors.primaryTurf.withOpacity(0.2),
                                inactiveThumbColor: AppColors.textDarkSecondary,
                                inactiveTrackColor: AppColors.dividerGreen.withOpacity(0.4),
                                onChanged: _isLoading ? null : _toggleBiometric,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRoleTile({
    required String title,
    required String description,
    required UserRole role,
    required UserRole currentRole,
    required AppState appState,
    required IconData icon,
  }) {
    final bool isSelected = currentRole == role || 
        (role == UserRole.organizer && (currentRole == UserRole.organizer || currentRole == UserRole.scorer));

    return InkWell(
      onTap: () async {
        if (!isSelected) {
          appState.changeRole(role);
          await _updateRoleInFirestore(role);
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: 'Active role updated to $title.',
              type: SnackBarType.success,
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTurf.withOpacity(0.12) : AppColors.dividerGreen.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryTurf : AppColors.textDarkSecondary,
                size: 25,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textDarkSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.verified_rounded,
                color: AppColors.primaryTurf,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineStat(String label, String value, IconData icon, {Color? color}) {
    final activeColor = color ?? AppColors.primaryTurf;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: activeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDarkSecondary,
                    fontSize: 9.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {Color? color}) {
    final activeColor = color ?? AppColors.primaryTurf;
    return Expanded(
      child: Card(
        elevation: 0,
        color: AppColors.cardBg,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.borderGreen.withOpacity(0.3), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: activeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
