import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_error.dart';
import '../providers/app_providers.dart';

/// Orders list with status labels + pull-to-refresh (Issue #2 Step 6).
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final statuses = ref.watch(orderStatusesProvider);
    final labels = statuses.maybeWhen(
        data: (m) => m, orElse: () => const <String, String>{});
    return Scaffold(
      appBar: AppBar(title: const Text('سفارش‌ها')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ordersProvider);
            ref.invalidate(orderStatusesProvider);
            await ref.read(ordersProvider.future);
          },
          child: orders.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        e is AppError && e.isDisabled
                            ? 'سفارش‌ها فعلا غیرفعال است'
                            : 'خطا در بارگذاری سفارش‌ها',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(ordersProvider),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            data: (list) {
              if (list.isEmpty) {
                return ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                          child: Text('هنوز سفارشی ثبت نکرده‌اید')),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => context.go('/catalog'),
                        child: const Text('رفتن به کاتالوگ'),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final o = list[i];
                  final label = labels[o.status] ?? o.status;
                  return Card(
                    child: ListTile(
                      title: Text('سفارش ${o.number}'),
                      subtitle: Text(
                          '$label • ${o.itemCount} قلم • ${o.date}'),
                      trailing: Text('${o.total}'),
                      onTap: () => context.go('/orders/${o.id}'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
