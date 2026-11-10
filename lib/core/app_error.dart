/// Mapped API error per Issue #2 Step 0.
class AppError implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const AppError(this.code, this.message, [this.statusCode]);

  factory AppError.fromResponse(int status, Map<String, dynamic>? body) {
    final msg = body?['message']?.toString() ?? 'Request failed ($status)';
    final code = body?['code']?.toString() ?? 'unknown';
    if (status == 401) return AppError('unauthorized', msg, status);
    if (status == 403 && code == 'endpoint_disabled') {
      return AppError('endpoint_disabled', msg, status);
    }
    if (status == 403 && code == 'registration_disabled') {
      return AppError('registration_disabled', msg, status);
    }
    if (status == 429) return AppError('rate_limited', msg, status);
    if (status == 503) return AppError('wc_inactive', msg, status);
    return AppError(code, msg, status);
  }

  factory AppError.network(Object e) =>
      const AppError('network', 'خطا در اتصال — اینترنت را بررسی کنید');

  bool get isAuth => code == 'unauthorized';
  bool get isDisabled => code == 'endpoint_disabled';

  @override
  String toString() => 'AppError($code): $message';
}
