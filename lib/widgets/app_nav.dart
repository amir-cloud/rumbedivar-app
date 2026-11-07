import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';

/// Bottom nav derived from GET /config api toggles (Issue #2 Step 7).
/// A destination hides only when the server explicitly disables its key
/// (403 endpoint_disabled yields the same friendly message in-page).
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key, this.current});
  final String? current;

  static const _catalogKeys = [
    'products',
    'product_get',
    'catalog',
    'product_categories'
  ];
  static const _checkoutKeys = ['checkout', 'orders_create', 'cart'];
  static const _ordersKeys = ['orders', 'orders_get'];
  static const _profileKeys = ['customer', 'customer_get', 'me'];

  bool _visible(Map<String, bool> toggles, List<String> keys) {
    for (final k in keys) {
      if (toggles[k] == false) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = current ?? GoRouterState.of(context).uri.path;
    final boot = ref.watch(bootProvider);
    final toggles = boot.maybeWhen(
        data: (b) => b.config.apiToggles,
        orElse: () => const <String, bool>{});
    final items = <({String route, IconData icon, String label})>[
      (route: '/home', icon: Icons.home_outlined, label: 'خانه'),
      if (_visible(toggles, _catalogKeys))
        (route: '/catalog', icon: Icons.grid_view_outlined, label: 'کاتالوگ'),
      if (_visible(toggles, _checkoutKeys))
        (route: '/cart', icon: Icons.shopping_cart_outlined, label: 'سبد'),
      if (_visible(toggles, _ordersKeys))
        (route: '/orders', icon: Icons.receipt_long_outlined, label: 'سفارش‌ها'),
      if (_visible(toggles, _profileKeys))
        (route: '/profile', icon: Icons.person_outline, label: 'پروفایل'),
    ];
    if (items.length < 2) return const SizedBox.shrink();
    var index = items.indexWhere((e) => e.route == location);
    if (index < 0) index = 0;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => context.go(items[i].route),
        items: items
            .map((e) => BottomNavigationBarItem(
                icon: Icon(e.icon), label: e.label))
            .toList(),
      ),
    );
  }
}
