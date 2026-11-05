import 'package:flutter_test/flutter_test.dart';
import 'package:rumbedivar/core/app_error.dart';

void main() {
  group('AppError.fromResponse', () {
    test('maps 401 to unauthorized', () {
      final e = AppError.fromResponse(401, {'message': 'no'});
      expect(e.code, 'unauthorized');
      expect(e.isAuth, isTrue);
    });

    test('maps 403 endpoint_disabled', () {
      final e = AppError.fromResponse(
          403, {'code': 'endpoint_disabled', 'message': 'off'});
      expect(e.code, 'endpoint_disabled');
      expect(e.isDisabled, isTrue);
    });

    test('maps 403 registration_disabled distinctly', () {
      final e = AppError.fromResponse(
          403, {'code': 'registration_disabled', 'message': 'off'});
      expect(e.code, 'registration_disabled');
      expect(e.isDisabled, isFalse);
    });

    test('maps 429 rate-limit', () {
      final e = AppError.fromResponse(429, {'message': 'slow'});
      expect(e.code, 'rate_limited');
    });

    test('maps 503 wc inactive', () {
      final e = AppError.fromResponse(503, {'message': 'down'});
      expect(e.code, 'wc_inactive');
    });

    test('falls back to unknown code', () {
      final e = AppError.fromResponse(500, {'message': 'boom'});
      expect(e.code, 'unknown');
    });

    test('handles null body', () {
      final e = AppError.fromResponse(400, null);
      expect(e.statusCode, 400);
    });
  });
}
