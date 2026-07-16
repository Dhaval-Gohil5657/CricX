import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'logged_http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_endpoints.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String role;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.role,
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();

  factory AuthService() {
    return instance;
  }

  void _notifyListenersSafe() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  AuthService._internal();

  final _storage = const FlutterSecureStorage();

  AppUser? _currentUser;
  String? _token;

  AppUser? get currentUser => _currentUser;
  String? get token => _token;

  Future<void> initialize() async {
    final cachedUid = await _storage.read(key: 'user_uid');
    final cachedEmail = await _storage.read(key: 'user_email');
    final cachedName = await _storage.read(key: 'user_name');
    final cachedRole = await _storage.read(key: 'user_role');
    _token = await _storage.read(key: 'accessToken');

    if (cachedUid != null && _token != null) {
      _currentUser = AppUser(
        uid: cachedUid,
        email: cachedEmail,
        displayName: cachedName,
        role: cachedRole ?? 'User',
      );
      _notifyListenersSafe();
    } else {
      await logout();
      return;
    }

    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken != null && cachedRole?.toLowerCase() != 'guest') {
      // Trigger background session validation without awaiting it to keep app startup instant!
      refreshSessionInBackground(refreshToken);
    }
  }

  Future<void> refreshSessionInBackground(String refreshToken) async {
    try {
      final success = await refreshSession(refreshToken);
      if (!success) {
        await logout();
      }
    } catch (e) {
      debugPrint('Background session refresh error: $e');
    }
  }

  Future<AppUser?> fetchProfile() async {
    return _currentUser;
  }

  Future<bool> refreshSession(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.refresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['accessToken'] ?? data['token'];
        final newRefreshToken = data['refreshToken'];
        if (_token != null) {
          await _storage.write(key: 'accessToken', value: _token);
        }
        if (newRefreshToken != null) {
          await _storage.write(key: 'refreshToken', value: newRefreshToken);
        }

        final userMap = data['user'];
        if (userMap != null) {
          final uid = userMap['_id'] ?? userMap['id'] ?? '';
          final email = userMap['email'];
          final name = userMap['name'];
          final role = userMap['role'] ?? 'User';

          _currentUser = AppUser(
            uid: uid,
            email: email,
            displayName: name,
            role: role,
          );

          await _storage.write(key: 'user_uid', value: uid);
          await _storage.write(key: 'user_email', value: email ?? '');
          await _storage.write(key: 'user_name', value: name ?? '');
          await _storage.write(key: 'user_role', value: role);
        }
        _notifyListenersSafe();
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return false;
      }
    } catch (e) {
      debugPrint('Refresh session error: $e');
    }
    return true; // Keep cached session on connection/server failures
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'];
        if (_token != null) {
          await _storage.write(key: 'accessToken', value: _token);
        }
        if (refreshToken != null) {
          await _storage.write(key: 'refreshToken', value: refreshToken);
        }

        final userMap = data['user'];
        if (userMap != null) {
          final uid = userMap['_id'] ?? userMap['id'] ?? '';
          final email = userMap['email'];
          final name = userMap['name'];
          final role = userMap['role'] ?? 'User';

          _currentUser = AppUser(
            uid: uid,
            email: email,
            displayName: name,
            role: role,
          );

          await _storage.write(key: 'user_uid', value: uid);
          await _storage.write(key: 'user_email', value: email ?? '');
          await _storage.write(key: 'user_name', value: name ?? '');
          await _storage.write(key: 'user_role', value: role);
          await _storage.write(key: 'active_user_role', value: role);
        }
        _notifyListenersSafe();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  Future<bool> register(String name, String email, String password, {String role = 'User'}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role.toLowerCase(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'];
        if (_token != null) {
          await _storage.write(key: 'accessToken', value: _token);
        }
        if (refreshToken != null) {
          await _storage.write(key: 'refreshToken', value: refreshToken);
        }

        final userMap = data['user'];
        if (userMap != null) {
          final uid = userMap['_id'] ?? userMap['id'] ?? '';
          final email = userMap['email'];
          final name = userMap['name'];
          final role = userMap['role'] ?? 'User';

          _currentUser = AppUser(
            uid: uid,
            email: email,
            displayName: name,
            role: role,
          );

          await _storage.write(key: 'user_uid', value: uid);
          await _storage.write(key: 'user_email', value: email ?? '');
          await _storage.write(key: 'user_name', value: name ?? '');
          await _storage.write(key: 'user_role', value: role);
          await _storage.write(key: 'active_user_role', value: role);
        }
        _notifyListenersSafe();
        return true;
      }
    } catch (e) {
      debugPrint('Register error: $e');
    }
    return false;
  }

  Future<bool> loginGuest() async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.guest),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'];
        if (_token != null) {
          await _storage.write(key: 'accessToken', value: _token);
        }
        if (refreshToken != null) {
          await _storage.write(key: 'refreshToken', value: refreshToken);
        }

        final userMap = data['user'];
        final uid = userMap?['_id'] ?? userMap?['id'] ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
        final email = userMap?['email'] ?? 'guest@cricx.com';
        final name = userMap?['name'] ?? 'Guest User';
        final role = userMap?['role'] ?? 'guest';

        _currentUser = AppUser(
          uid: uid,
          email: email,
          displayName: name,
          role: role,
        );

        await _storage.write(key: 'user_uid', value: uid);
        await _storage.write(key: 'user_email', value: email);
        await _storage.write(key: 'user_name', value: name);
        await _storage.write(key: 'user_role', value: role);
        await _storage.write(key: 'active_user_role', value: role);
        _notifyListenersSafe();
        return true;
      }
    } catch (e) {
      debugPrint('Guest login error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'user_uid');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'active_user_role');
    _notifyListenersSafe();
  }

  Future<bool> updateRole(String role) async {
    // Write locally first so user selection is stored instantly
    await _storage.write(key: 'active_user_role', value: role);
    
    if (_token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse(ApiEndpoints.updateRole),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': role.toLowerCase()}),
      );

      if (response.statusCode == 200) {
        if (_currentUser != null) {
          _currentUser = AppUser(
            uid: _currentUser!.uid,
            email: _currentUser!.email,
            displayName: _currentUser!.displayName,
            role: role,
          );
          await _storage.write(key: 'user_role', value: role);
          _notifyListenersSafe();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Update role error: $e');
    }
    return false;
  }

  void updateInMemoryToken(String token) {
    _token = token;
  }

  void updateInMemoryUser(AppUser user) {
    _currentUser = user;
    _notifyListenersSafe();
  }
}
