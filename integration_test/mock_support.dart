import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Mock HTTP client for e2e/widget tests. Returns minimal valid JSON for
/// endpoints used by the app. Extend handlers as needed.
MockClient createMockHttpClient({
  String? token = 'test-token',
  bool enableRegistration = true,
}) {
  return MockClient((request) async {
    final path = request.url.path;

    if (path.endsWith('/store')) {
      return http.Response(jsonEncode({
        'success': true,
        'data': {'name': 'روم به دیوار', 'currency': 'IRT'}
      }), 200, headers: {'content-type': 'application/json'});
    }
    if (path.endsWith('/config')) {
      return http.Response(jsonEncode({
        'success': true,
        'data': {'enable_registration': enableRegistration}
      }), 200, headers: {'content-type': 'application/json'});
    }
    if (path.endsWith('/landing')) {
      return http.Response(jsonEncode({
        'success': true,
        'data': {'banners': [], 'sections': []}
      }), 200, headers: {'content-type': 'application/json'});
    }
    if (path.endsWith('/login')) {
      return http.Response(jsonEncode({
        'success': true,
        'token': token,
        'user': {'id': 1, 'username': 'test', 'email': 't@t.com'}
      }), 200, headers: {'content-type': 'application/json'});
    }
    if (path.endsWith('/register')) {
      return http.Response(jsonEncode({
        'success': true,
        'token': token,
        'user': {'id': 2, 'username': 'new', 'email': 'n@n.com'}
      }), 200, headers: {'content-type': 'application/json'});
    }
    if (path.endsWith('/me')) {
      return http.Response(jsonEncode({
        'success': true,
        'user': {'id': 1, 'username': 'test', 'email': 't@t.com'}
      }), 200, headers: {'content-type': 'application/json'});
    }
    if (path.contains('/products')) {
      return http.Response(jsonEncode({
        'success': true,
        'data': []
      }), 200, headers: {'content-type': 'application/json'});
    }
    if (path.contains('/orders') || path.contains('/customer')) {
      return http.Response(jsonEncode({'success': true, 'data': []}), 200,
          headers: {'content-type': 'application/json'});
    }

    return http.Response(jsonEncode({'success': true, 'data': {}}), 200,
        headers: {'content-type': 'application/json'});
  });
}
