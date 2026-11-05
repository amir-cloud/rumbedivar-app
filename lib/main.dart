import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router_support.dart';
import 'screens/cart_page.dart';
import 'screens/catalog_page.dart';
import 'screens/checkout_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/product_detail_page.dart';
import 'screens/register_page.dart';
import 'screens/splash_page.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: appAuthState,
    redirect: (context, state) {
      if (!appAuthState.ready) return null;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';
      if (!appAuthState.loggedIn && !loggingIn) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(
          path: '/catalog',
          builder: (_, __) => const CatalogPage()),
      GoRoute(
          path: '/product/:id',
          builder: (_, s) {
            final id =
                int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
            return ProductDetailPage(id: id);
          }),
      GoRoute(
          path: '/cart', builder: (_, __) => const CartPage()),
      GoRoute(
          path: '/checkout',
          builder: (_, __) => const CheckoutPage()),
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
  await appAuthState.boot();
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
