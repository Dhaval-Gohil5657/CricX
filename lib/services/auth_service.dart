import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  
  AppUser? _currentUser;
  String? _token;

  AppUser? get currentUser => _currentUser;
  String? get token => _token;

  Future<void> initialize() async {
    _token = await _storage.read(key: 'accessToken');
    if (_token != null) {
      try {
        final profile = await fetchProfile();
        if (profile != null) {
          _currentUser = profile;
        } else {
          await logout();
        }
      } catch (e) {
        debugPrint('Auth initialization error: $e');
      }
    }
    notifyListeners();
  }

  Future<AppUser?> fetchProfile() async {
    if (_token == null) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.profile),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userMap = data['user'] ?? data;
        return AppUser(
          uid: userMap['_id'] ?? userMap['id'] ?? '',
          email: userMap['email'],
          displayName: userMap['name'],
          role: userMap['role'] ?? 'User',
        );
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
    return null;
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
        if (_token != null) {
          await _storage.write(key: 'accessToken', value: _token);
        }
        
        final userMap = data['user'];
        if (userMap != null) {
          _currentUser = AppUser(
            uid: userMap['_id'] ?? userMap['id'] ?? '',
            email: userMap['email'],
            displayName: userMap['name'],
            role: userMap['role'] ?? 'User',
          );
        }
        notifyListeners();
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
          'role': role,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['accessToken'] ?? data['token'];
        if (_token != null) {
          await _storage.write(key: 'accessToken', value: _token);
        }
        
        final userMap = data['user'];
        if (userMap != null) {
          _currentUser = AppUser(
            uid: userMap['_id'] ?? userMap['id'] ?? '',
            email: userMap['email'],
            displayName: userMap['name'],
            role: userMap['role'] ?? 'User',
          );
        }
        notifyListeners();
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
        if (_token != null) {
          await _storage.write(key: 'accessToken', value: _token);
        }
        
        final userMap = data['user'];
        if (userMap != null) {
          _currentUser = AppUser(
            uid: userMap['_id'] ?? userMap['id'] ?? '',
            email: userMap['email'] ?? 'guest@cricx.com',
            displayName: userMap['name'] ?? 'Guest User',
            role: userMap['role'] ?? 'Guest',
          );
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Guest login error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse(ApiEndpoints.logout),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      debugPrint('Logout request error: $e');
    } finally {
      _token = null;
      _currentUser = null;
      await _storage.delete(key: 'accessToken');
      notifyListeners();
    }
  }

  Future<bool> updateRole(String role) async {
    if (_token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse(ApiEndpoints.updateRole),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        if (_currentUser != null) {
          _currentUser = AppUser(
            uid: _currentUser!.uid,
            email: _currentUser!.email,
            displayName: _currentUser!.displayName,
            role: role,
          );
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Update role error: $e');
    }
    return false;
  }
}
