import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../widgets/price.dart';

/// Order detail with items + App Discount flag (Step 6).
class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailProvider(id));
    final statuses = ref.watch(orderStatusesProvider);
    final boot = ref.watch(bootProvider);
    final currency = boot.maybeWhen(
        data: (b) => b.store.currencySymbol, orElse: () => '');
    final decimals =
        boot.maybeWhen(data: (b) => b.store.numDecimals, orElse: () => 0);
    final labels = statuses.maybeWhen(
        data: (m) => m, orElse: () => const <String, String>{});
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات سفارش'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders'),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(orderDetailProvider(id));
            await ref.read(orderDetailProvider(id).future);
          },
          child: detail.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('خطا در بارگذاری سفارش')),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(orderDetailProvider(id)),
                    child: const Text('تلاش مجدد'),
                  ),
                ),
              ],
            ),
            data: (o) {
              if (o == null) {
                return ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                          child: Text('سفارش یافت نشد')),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('سفارش ${o.number}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(
                              'وضعیت: ${labels[o.status] ?? o.status}'),
                          Text('تاریخ: ${o.date}'),
                          if (o.paymentMethod.isNotEmpty)
                            Text('پرداخت: ${o.paymentMethod}'),
                          PriceText(o.total,
                              currency: currency,
                              decimals: decimals,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          if (o.appDiscountApplied)
                            const Text('تخفیف اپ اعمال شد ✓',
                                style: TextStyle(
                                    color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('اقلام',
                      style: TextStyle(
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  for (final it in o.items)
                    Card(
                      child: ListTile(
                        title: Text(it.name),
                        subtitle:
                            Text('تعداد: ${it.quantity}'),
                        trailing: PriceText(it.total,
                            currency: currency,
                            decimals: decimals),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
