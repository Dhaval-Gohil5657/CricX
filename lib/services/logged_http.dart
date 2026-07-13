import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as raw_http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_endpoints.dart';
import 'auth_service.dart';

// Export everything from http package except the functions we override
export 'package:http/http.dart' hide get, post, put, patch;

Future<raw_http.Response> get(Uri url, {Map<String, String>? headers}) async {
  debugPrint('[HTTP GET] Request: $url');
  try {
    final res = await _executeWithRetry(
      (h) => raw_http.get(url, headers: h),
      url,
      headers,
    );
    debugPrint('[HTTP GET] Response ($url): Status ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('[HTTP GET] Error response: ${res.body}');
    }
    return res;
  } catch (e) {
    debugPrint('[HTTP GET] Exception: $e');
    rethrow;
  }
}

Future<raw_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  debugPrint('[HTTP POST] Request: $url\nBody: $body');
  try {
    final res = await _executeWithRetry(
      (h) => raw_http.post(url, headers: h, body: body, encoding: encoding),
      url,
      headers,
    );
    debugPrint('[HTTP POST] Response ($url): Status ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('[HTTP POST] Error response: ${res.body}');
    }
    return res;
  } catch (e) {
    debugPrint('[HTTP POST] Exception: $e');
    rethrow;
  }
}

Future<raw_http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  debugPrint('[HTTP PUT] Request: $url\nBody: $body');
  try {
    final res = await _executeWithRetry(
      (h) => raw_http.put(url, headers: h, body: body, encoding: encoding),
      url,
      headers,
    );
    debugPrint('[HTTP PUT] Response ($url): Status ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('[HTTP PUT] Error response: ${res.body}');
    }
    return res;
  } catch (e) {
    debugPrint('[HTTP PUT] Exception: $e');
    rethrow;
  }
}

Future<raw_http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  debugPrint('[HTTP PATCH] Request: $url\nBody: $body');
  try {
    final res = await _executeWithRetry(
      (h) => raw_http.patch(url, headers: h, body: body, encoding: encoding),
      url,
      headers,
    );
    debugPrint('[HTTP PATCH] Response ($url): Status ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('[HTTP PATCH] Error response: ${res.body}');
    }
    return res;
  } catch (e) {
    debugPrint('[HTTP PATCH] Exception: $e');
    rethrow;
  }
}

Future<raw_http.Response> _executeWithRetry(
  Future<raw_http.Response> Function(Map<String, String>? headers) requestFn,
  Uri url,
  Map<String, String>? headers,
) async {
  final res = await requestFn(headers);

  // Auto-refresh token if 401 Unauthorized is returned, except on auth-related requests
  if (res.statusCode == 401 && 
      !url.path.contains('/refresh') && 
      !url.path.contains('/login') && 
      !url.path.contains('/register')) {
    debugPrint('[HTTP] Unauthorized (401) on $url. Attempting session refresh...');
    
    final success = await _attemptSessionRefresh();
    if (success) {
      debugPrint('[HTTP] Session refreshed successfully. Retrying request to $url...');
      const storage = FlutterSecureStorage();
      final newToken = await storage.read(key: 'accessToken');

      final updatedHeaders = Map<String, String>.from(headers ?? {});
      if (newToken != null) {
        updatedHeaders['Authorization'] = 'Bearer $newToken';
      }

      return await requestFn(updatedHeaders);
    } else {
      debugPrint('[HTTP] Session refresh failed. Logging out...');
      await AuthService.instance.logout();
    }
  }

  return res;
}

Future<bool> _attemptSessionRefresh() async {
  const storage = FlutterSecureStorage();
  final refreshToken = await storage.read(key: 'refreshToken');
  if (refreshToken == null) return false;

  try {
    final response = await raw_http.post(
      Uri.parse(ApiEndpoints.refresh),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': refreshToken}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newToken = data['accessToken'] ?? data['token'];
      final newRefreshToken = data['refreshToken'];
      if (newToken != null) {
        await storage.write(key: 'accessToken', value: newToken);
        AuthService.instance.updateInMemoryToken(newToken);
      }
      if (newRefreshToken != null) {
        await storage.write(key: 'refreshToken', value: newRefreshToken);
      }

      final userMap = data['user'];
      if (userMap != null) {
        final uid = userMap['_id'] ?? userMap['id'] ?? '';
        final email = userMap['email'];
        final name = userMap['name'];
        final role = userMap['role'] ?? 'User';

        await storage.write(key: 'user_uid', value: uid);
        await storage.write(key: 'user_email', value: email ?? '');
        await storage.write(key: 'user_name', value: name ?? '');
        await storage.write(key: 'user_role', value: role);

        AuthService.instance.updateInMemoryUser(AppUser(
          uid: uid,
          email: email,
          displayName: name,
          role: role,
        ));
      }
      return true;
    }
  } catch (e) {
    debugPrint('[HTTP] Error refreshing token: $e');
  }
  return false;
}
