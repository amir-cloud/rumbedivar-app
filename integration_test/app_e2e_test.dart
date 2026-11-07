import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rumbedivar/core/router_support.dart';
import 'package:rumbedivar/main.dart';
import 'package:rumbedivar/services/auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: app boots and reaches login when unauthenticated',
      (tester) async {
    final authState = AuthState(AuthService());
    await authState.boot();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: createRouter(authState),
        ),
      ),
    );

    // Splash/boot + redirects may take a moment (and may hit dummy server).
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('ورود به حساب'), findsOneWidget);
  });

  testWidgets('smoke: can navigate to register from login', (tester) async {
    final authState = AuthState(AuthService());
    await authState.boot();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: createRouter(authState),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 10));

    final registerLink = find.text('ثبت نام');
    expect(registerLink, findsOneWidget);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    expect(find.text('ایجاد حساب کاربری'), findsOneWidget);
  });
}
