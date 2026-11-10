import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'app_error.dart';

/// Central HTTP client per Issue #2 Step 0:
/// Bearer inject, {success,message/code} mapping, 401-once -> POST /refresh retry.
class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? storage})
      : _http = httpClient ?? http.Client(),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                  accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  static const Duration _timeout = Duration(seconds: 15);

  static const String _tokenKey = 'auth_token';

  final http.Client _http;
  final FlutterSecureStorage _storage;

  String get _apiBase {
    final base = wpBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/wp-json/$wpApiNamespace';
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = await _storage.read(key: _tokenKey);
      if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    return _send(() async {
      final res = await _http
          .get(
            Uri.parse('$_apiBase$path'),
            headers: await _headers(auth: auth),
          )
          .timeout(_timeout);
      return res;
    }, auth: auth);
  }

  Future<dynamic> post(String path, Map<String, dynamic>? body,
      {bool auth = true}) async {
    return _send(() async {
      final res = await _http
          .post(
            Uri.parse('$_apiBase$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);
      return res;
    }, auth: auth);
  }

  Future<dynamic> put(String path, Map<String, dynamic>? body,
      {bool auth = true}) async {
    return _send(() async {
      final res = await _http
          .put(
            Uri.parse('$_apiBase$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);
      return res;
    }, auth: auth);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    return _send(() async {
      final res = await _http
          .delete(
            Uri.parse('$_apiBase$path'),
            headers: await _headers(auth: auth),
          )
          .timeout(_timeout);
      return res;
    }, auth: auth);
  }

  Future<dynamic> _send(Future<http.Response> Function() call,
      {bool auth = true, bool retried = false}) async {
    late http.Response res;
    try {
      res = await call();
    } on TimeoutException {
      throw const AppError('network', 'اتصال کند است — دوباره تلاش کنید');
    } catch (_) {
      throw const AppError('network', 'خطا در اتصال — اینترنت را بررسی کنید');
    }
    dynamic decoded;
    try {
      decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

    // 401 -> try refresh once
    if (res.statusCode == 401 && auth && !retried) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _send(call, auth: auth, retried: true);
      }
    }

    final body = decoded is Map<String, dynamic> ? decoded : null;
    throw AppError.fromResponse(res.statusCode, body);
  }

  Future<bool> _tryRefresh() async {
    try {
      // Do not attach expired bearer to refresh call.
      final h = <String, String>{'Content-Type': 'application/json'};
      final res = await _http
          .post(
            Uri.parse('$_apiBase/refresh'),
            headers: h,
            body: jsonEncode({}),
          )
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          final token = (body['token'] ?? body['data']?['token'])?.toString();
          if (token != null && token.isNotEmpty) {
            await _storage.write(key: _tokenKey, value: token);
            return true;
          }
        }
      }
    } catch (_) {
      // ignore, caller maps to 401
    }
    return false;
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
