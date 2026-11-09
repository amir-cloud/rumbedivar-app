import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/page_transitions.dart';
import 'core/router_support.dart';
import 'screens/cart_page.dart';
import 'screens/catalog_page.dart';
import 'screens/category_products_page.dart';
import 'screens/checkout_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/onboarding_page.dart';
import 'screens/order_detail_page.dart';
import 'screens/orders_page.dart';
import 'screens/product_detail_page.dart';
import 'screens/profile_page.dart';
import 'screens/register_page.dart';
import 'screens/search_page.dart';
import 'screens/splash_page.dart';
import 'widgets/app_nav.dart';
import 'widgets/shell_app_bar.dart';

GoRouter createRouter(AuthState authState, {String initialLocation = '/splash'}) {
  final router = GoRouter(
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
        pageBuilder: (context, state) => directionalSlidePage(
          state: state,
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => directionalSlidePage(
          state: state,
          child: const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => directionalSlidePage(
          state: state,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => directionalSlidePage(
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
            pageBuilder: (context, state) => directionalSlidePage(
              state: state,
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: '/catalog',
            pageBuilder: (context, state) => directionalSlidePage(
              state: state,
              child: const CatalogPage(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => directionalSlidePage(
              state: state,
              child: const SearchPage(),
            ),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => directionalSlidePage(
              state: state,
              child: const CartPage(),
            ),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => directionalSlidePage(
              state: state,
              child: const OrdersPage(),
            ),
          ),
          GoRoute(
            path: '/category/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final name = state.extra is String ? state.extra as String : null;
              return directionalSlidePage(
                state: state,
                child: CategoryProductsPage(categoryId: id, categoryName: name),
              );
            },
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => directionalSlidePage(
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
          return directionalSlidePage(
            state: state,
            child: ProductDetailPage(id: id),
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) => directionalSlidePage(
          state: state,
          child: const CheckoutPage(),
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return directionalSlidePage(
            state: state,
            child: OrderDetailPage(id: id),
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => directionalSlidePage(
      state: state,
      child: FriendlyErrorPage(message: state.error?.toString() ?? 'خطا'),
    ),
  );
  watchRouterForDirection(router);
  return router;
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
