import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router_support.dart';
import '../providers/app_providers.dart';
import '../providers/cart_provider.dart';

/// Route-aware AppBar for tab shell — stays fixed outside page transitions.
class ShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ShellAppBar({super.key, this.location});
  final String? location;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).logout();
    await ref.read(cartProvider.notifier).clear();
    ref.invalidate(customerProvider);
    ref.invalidate(meProvider);
    ref.invalidate(ordersProvider);
    appAuthState.setToken(null);
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = location ?? GoRouterState.of(context).uri.path;
    if (loc.startsWith('/category/')) {
      final state = GoRouterState.of(context);
      final name = state.extra is String ? state.extra as String : 'محصولات';
      return AppBar(
        leading: IconButton(
          tooltip: 'بازگشت',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/catalog');
            }
          },
        ),
        title: Text(name),
      );
    }
    switch (loc) {
      case '/home':
        return AppBar(
          title: const Text('روم به دیوار'),
          actions: [
            IconButton(
              tooltip: 'پروفایل',
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.person),
            ),
            IconButton(
              tooltip: 'خروج',
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
            ),
          ],
        );
      case '/catalog':
        return AppBar(title: const Text('دسته بندی ها'));
      case '/search':
        return AppBar(title: const Text('جستجو'));
      case '/cart':
        final cart = ref.watch(cartProvider);
        return AppBar(
          title: const Text('سبد خرید'),
          actions: [
            if (cart.items.isNotEmpty)
              IconButton(
                tooltip: 'پاک کردن سبد',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(cartProvider.notifier).clear(),
              ),
          ],
        );
      case '/orders':
        return AppBar(title: const Text('سفارش‌ها'));
      case '/profile':
        return AppBar(
          title: const Text('پروفایل'),
          actions: [
            IconButton(
              tooltip: 'خروج',
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context, ref),
            ),
          ],
        );
      default:
        return AppBar();
    }
  }
}
