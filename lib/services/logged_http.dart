import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as raw_http;

// Export everything from http package except the functions we override
export 'package:http/http.dart' hide get, post, put, patch;

Future<raw_http.Response> get(Uri url, {Map<String, String>? headers}) async {
  debugPrint('[HTTP GET] Request: $url');
  try {
    final res = await raw_http.get(url, headers: headers);
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
    final res = await raw_http.post(url, headers: headers, body: body, encoding: encoding);
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
    final res = await raw_http.put(url, headers: headers, body: body, encoding: encoding);
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
    final res = await raw_http.patch(url, headers: headers, body: body, encoding: encoding);
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
