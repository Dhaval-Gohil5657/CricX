import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys for storage
  static const String _keyEmail = 'biometric_email';
  static const String _keyPassword = 'biometric_password';
  static const String _keyEnabled = 'biometric_enabled';

  /// Check if biometric hardware is available and user has enrolled at least one biometric
  Future<bool> isBiometricHardwareAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric hardware: $e');
      return false;
    }
  }

  /// Get the list of enrolled biometrics (e.g. face, fingerprint)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using local biometrics
  Future<bool> authenticate({String reason = 'Please authenticate to log in'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }

  /// Check if the user has enabled biometric login in the app settings/flow
  Future<bool> isBiometricEnabled() async {
    final String? enabled = await _secureStorage.read(key: _keyEnabled);
    return enabled == 'true';
  }

  /// Enable biometric login and save credentials securely
  Future<void> enableBiometric(String email, String password) async {
    await _secureStorage.write(key: _keyEmail, value: email);
    await _secureStorage.write(key: _keyPassword, value: password);
    await _secureStorage.write(key: _keyEnabled, value: 'true');
  }

  /// Disable biometric login and remove saved credentials
  Future<void> disableBiometric() async {
    await _secureStorage.delete(key: _keyEmail);
    await _secureStorage.delete(key: _keyPassword);
    await _secureStorage.write(key: _keyEnabled, value: 'false');
  }

  /// Get saved credentials if biometric login is enabled
  Future<Map<String, String>?> getSavedCredentials() async {
    final String? email = await _secureStorage.read(key: _keyEmail);
    final String? password = await _secureStorage.read(key: _keyPassword);
    
    if (email != null && password != null) {
      return {
        'email': email,
        'password': password,
      };
    }
    return null;
  }
}
