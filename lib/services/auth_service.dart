import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/auth_result.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  String get _base => wpBaseUrl.replaceAll(RegExp(r'/+$'), '');
  String get _apiBase => '$_base/wp-json/$wpApiNamespace';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
  }

  Future<AuthResult> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
          final result = AuthResult.fromJson(body);
          if (result.token != null) {
            await saveToken(result.token!);
          }
          return result;
        }
        return AuthResult.failure(body['message']?.toString() ?? 'Login failed');
      }
      return AuthResult.failure('Unexpected response');
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }

  Future<AuthResult> register(String username, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      );
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
          final result = AuthResult.fromJson(body);
          if (result.token != null) {
            await saveToken(result.token!);
          }
          return result;
        }
        return AuthResult.failure(body['message']?.toString() ?? 'Registration failed');
      }
      return AuthResult.failure('Unexpected response');
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }

  Future<User?> getMe() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic> && body['user'] is Map<String, dynamic>) {
          return User.fromJson(body['user'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await clearToken();
  }
}
