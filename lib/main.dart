import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router_support.dart';
import 'screens/discreet_checkout_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/splash_page.dart';
import 'services/auth_service.dart';

final _authState = AuthState(AuthService());

GoRouter _router() {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _authState,
    redirect: (context, state) {
      if (!_authState.ready) return null;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';
      if (!_authState.loggedIn && !loggingIn) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(
          path: '/catalog',
          builder: (_, __) =>
              const PlaceholderPage(title: 'کاتالوگ')),
      GoRoute(
          path: '/product/:id',
          builder: (_, s) => PlaceholderPage(
              title: 'محصول ${s.pathParameters['id']}')),
      GoRoute(
          path: '/cart',
          builder: (_, __) => const PlaceholderPage(title: 'سبد خرید')),
      GoRoute(
          path: '/checkout',
          builder: (_, __) => const DiscreetCheckoutPage()),
      GoRoute(
          path: '/orders',
          builder: (_, __) => const PlaceholderPage(title: 'سفارش‌ها')),
      GoRoute(
          path: '/orders/:id',
          builder: (_, s) => PlaceholderPage(
              title: 'سفارش ${s.pathParameters['id']}')),
      GoRoute(
          path: '/profile',
          builder: (_, __) => const PlaceholderPage(title: 'پروفایل')),
    ],
    errorBuilder: (_, s) =>
        FriendlyErrorPage(message: s.error?.toString() ?? 'خطا'),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _authState.boot();
  runApp(ProviderScope(child: MainApp(router: _router())));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(useMaterial3: true),
    );
  }
}
