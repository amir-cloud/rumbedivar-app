import '../core/api_client.dart';
import '../core/app_error.dart';
import '../models/auth_result.dart';
import '../models/user.dart';

/// Auth backed by ApiClient (secure storage + 401->refresh retry).
/// Keeps old public API so Login/Home keep compiling during migration.
class AuthService {
  AuthService({ApiClient? api}) : _api = api ?? ApiClient();
  final ApiClient _api;

  Future<String?> getToken() => _api.readToken();

  Future<void> saveToken(String token) => _api.saveToken(token);

  Future<void> clearToken() => _api.clearToken();

  Future<AuthResult> login(String username, String password) async {
    try {
      final body = await _api.post(
        '/login',
        {'username': username, 'password': password},
        auth: false,
      );
      if (body is Map<String, dynamic>) {
        if (body['success'] == true) {
          final result = AuthResult.fromJson(body);
          if (result.token != null) await saveToken(result.token!);
          return result;
        }
        return AuthResult.failure(
            body['message']?.toString() ?? 'Login failed');
      }
      return AuthResult.failure('Unexpected response');
    } on AppError catch (e) {
      if (e.code == 'rate_limited') {
        return AuthResult.failure(
            'تلاش زیاد — لطفا چند دقیقه بعد دوباره امتحان کنید');
      }
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }

  Future<AuthResult> register(
      String username, String email, String password) async {
    try {
      final body = await _api.post(
        '/register',
        {'username': username, 'email': email, 'password': password},
        auth: false,
      );
      if (body is Map<String, dynamic>) {
        if (body['success'] == true) {
          final result = AuthResult.fromJson(body);
          if (result.token != null) await saveToken(result.token!);
          return result;
        }
        return AuthResult.failure(
            body['message']?.toString() ?? 'Registration failed');
      }
      return AuthResult.failure('Unexpected response');
    } on AppError catch (e) {
      if (e.code == 'registration_disabled') {
        return AuthResult.failure('ثبت‌نام فعلا غیرفعال است');
      }
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }

  Future<User?> getMe() async {
    try {
      final body = await _api.get('/me');
      if (body is Map<String, dynamic>) {
        final u = body['user'] ?? body['data']?['user'];
        if (u is Map<String, dynamic>) return User.fromJson(u);
        if (body['id'] != null) return User.fromJson(body);
      }
      return null;
    } on AppError {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() => clearToken();
}
