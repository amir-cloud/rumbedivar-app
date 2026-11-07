import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rumbedivar/core/api_client.dart';
import 'package:rumbedivar/core/router_support.dart';
import 'package:rumbedivar/main.dart';
import 'package:rumbedivar/providers/app_providers.dart';
import 'package:rumbedivar/services/auth_service.dart';

import 'mock_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mocked e2e: unauthenticated user redirected to login',
      (tester) async {
    final mockClient = createMockHttpClient();
    final api = ApiClient(httpClient: mockClient);
    final authService = AuthService(api: api);
    final authState = AuthState(authService)..markReady(token: null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          authServiceProvider.overrideWithValue(authService),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: createRouter(authState),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('ورود به حساب'), findsOneWidget);
  });

  testWidgets('mocked e2e: login to register navigation', (tester) async {
    final mockClient = createMockHttpClient();
    final api = ApiClient(httpClient: mockClient);
    final authService = AuthService(api: api);
    final authState = AuthState(authService)..markReady(token: null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          authServiceProvider.overrideWithValue(authService),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: createRouter(authState),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('ثبت نام'), findsOneWidget);

    await tester.tap(find.text('ثبت نام'));
    await tester.pumpAndSettle();

    expect(find.text('ایجاد حساب کاربری'), findsOneWidget);
  });
}
