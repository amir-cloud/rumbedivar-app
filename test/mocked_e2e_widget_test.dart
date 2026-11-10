import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumbedivar/core/api_client.dart';
import 'package:rumbedivar/core/router_support.dart';
import 'package:rumbedivar/main.dart';
import 'package:rumbedivar/models/landing.dart';
import 'package:rumbedivar/models/store_config.dart';
import 'package:rumbedivar/providers/app_providers.dart';
import 'package:rumbedivar/services/auth_service.dart';

import '../integration_test/mock_support.dart';

Widget _buildTestApp({
  required AuthState authState,
  required ApiClient api,
  required AuthService authService,
  String initialLocation = '/login',
}) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      authServiceProvider.overrideWithValue(authService),
      bootProvider.overrideWith((ref) async => (
            store: const StoreInfo(),
            config: const AppConfig(),
            landing: const LandingData(),
          )),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: createRouter(authState, initialLocation: initialLocation),
    ),
  );
}

void main() {
  testWidgets('mocked e2e: unauthenticated user sees login',
      (tester) async {
    final mockClient = createMockHttpClient();
    final api = ApiClient(httpClient: mockClient);
    final authService = AuthService(api: api);
    final authState = AuthState(authService)..markReady(token: null);

    await tester.pumpWidget(_buildTestApp(
      authState: authState,
      api: api,
      authService: authService,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ورود به حساب'), findsOneWidget);
  });

  testWidgets('mocked e2e: navigate from login to register', (tester) async {
    final mockClient = createMockHttpClient();
    final api = ApiClient(httpClient: mockClient);
    final authService = AuthService(api: api);
    final authState = AuthState(authService)..markReady(token: null);

    await tester.pumpWidget(_buildTestApp(
      authState: authState,
      api: api,
      authService: authService,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ایجاد حساب کاربری'), findsOneWidget);
    await tester.tap(find.text('ایجاد حساب کاربری'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ایجاد حساب کاربری'), findsOneWidget);
  });
}
