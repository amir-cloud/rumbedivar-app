import 'user.dart';

class AuthResult {
  final bool success;
  final String? token;
  final int expiresIn;
  final User? user;
  final String? error;

  AuthResult({
    required this.success,
    this.token,
    this.expiresIn = 0,
    this.user,
    this.error,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return AuthResult(
      success: json['success'] == true,
      token: json['token']?.toString(),
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      user: userJson is Map<String, dynamic> ? User.fromJson(userJson) : null,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult(success: false, error: error);
  }
}
