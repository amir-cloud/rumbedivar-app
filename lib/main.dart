import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router_support.dart';
import 'screens/cart_page.dart';
import 'screens/catalog_page.dart';
import 'screens/checkout_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/onboarding_page.dart';
import 'screens/order_detail_page.dart';
import 'screens/orders_page.dart';
import 'screens/product_detail_page.dart';
import 'screens/profile_page.dart';
import 'screens/register_page.dart';
import 'screens/splash_page.dart';
import 'widgets/app_nav.dart';
import 'widgets/shell_app_bar.dart';

CustomTransitionPage<void> _slideRightPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final enterCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final exitCurve = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInOutCubic,
      );

      final slideTween = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      );
      final fadeTween = Tween<double>(begin: 0.92, end: 1.0);

      // Incoming page slides from right with a soft fade.
      Widget page = FadeTransition(
        opacity: fadeTween.animate(enterCurve),
        child: SlideTransition(
          position: slideTween.animate(enterCurve),
          child: child,
        ),
      );

      // When this page is being covered by a new one, blur and ease it back.
      page = AnimatedBuilder(
        animation: exitCurve,
        child: page,
        builder: (context, child) {
          final v = exitCurve.value;
          if (v <= 0) return child!;
          final blur = v * 5.5;
          return Transform.scale(
            scale: 1 - (v * 0.03),
            child: Opacity(
              opacity: 1 - (v * 0.08),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: child,
              ),
            ),
          );
        },
      );

      return ColoredBox(
        color: const Color(0xFFC30960),
        child: page,
      );
    },
  );
}

GoRouter createRouter(AuthState authState, {String initialLocation = '/splash'}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authState,
    redirect: (context, state) {
      if (!authState.ready) return null;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';
      if (!authState.loggedIn && !loggingIn) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const RegisterPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            appBar: ShellAppBar(location: state.uri.path),
            body: child,
            bottomNavigationBar: const AppBottomNav(),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _slideRightPage(
              state: state,
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: '/catalog',
            pageBuilder: (context, state) => _slideRightPage(
              state: state,
              child: const CatalogPage(),
            ),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => _slideRightPage(
              state: state,
              child: const CartPage(),
            ),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => _slideRightPage(
              state: state,
              child: const OrdersPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _slideRightPage(
              state: state,
              child: const ProfilePage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return _slideRightPage(
            state: state,
            child: ProductDetailPage(id: id),
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const CheckoutPage(),
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return _slideRightPage(
            state: state,
            child: OrderDetailPage(id: id),
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => _slideRightPage(
      state: state,
      child: FriendlyErrorPage(message: state.error?.toString() ?? 'خطا'),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appAuthState.boot();
  runApp(ProviderScope(child: MainApp(router: createRouter(appAuthState))));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'IRANSans',
        scaffoldBackgroundColor: const Color(0xFFC30960),
        canvasColor: const Color(0xFFC30960),
      ),
    );
  }
}
