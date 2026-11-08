import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../providers/cart_provider.dart';
import '../widgets/price.dart';

/// Local cart page (Issue #2 Step 4).
/// Kill-restart safe, clamped by max_quantity_per_item,
/// gated by min_order_amount with Persian message.
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final boot = ref.watch(bootProvider);
    final minOrder = boot.maybeWhen(
        data: (b) => b.store.minOrderAmount, orElse: () => 0.0);
    final currency = boot.maybeWhen(
        data: (b) => b.store.currencySymbol, orElse: () => 'تومان');
    final decimals =
        boot.maybeWhen(data: (b) => b.store.numDecimals, orElse: () => 0);
    final blocked = cart.subtotal < minOrder && cart.items.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: !cart.loaded
          ? const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('سبد خالی است'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/catalog'),
                        child: const Text('رفتن به دسته بندی ها'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final it = cart.items[i];
                          return Card(
                            child: ListTile(
                              leading: it.image.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: it.image,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            const Icon(Icons.image),
                                      ),
                                    )
                                  : const Icon(Icons.image),
                              title: Text(it.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: PriceText(it.unitPrice,
                                  currency: currency, decimals: decimals),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .setQty(it.productId, it.quantity - 1),
                                  ),
                                  Text('${it.quantity}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .setQty(it.productId, it.quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PriceText(
                            cart.subtotal,
                            currency: currency,
                            decimals: decimals,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          if (blocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'حداقل مبلغ سفارش ${formatPrice(minOrder, currency: currency, decimals: decimals)} است',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed:
                                  blocked ? null : () => context.go('/checkout'),
                              child: const Text('ادامه به تسویه'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
