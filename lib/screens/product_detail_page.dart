import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';

/// Product detail + reviews (Issue #2 Step 3).
class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(id));
    final reviews = ref.watch(productReviewsProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات محصول'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/catalog'),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productDetailProvider(id));
            ref.invalidate(productReviewsProvider(id));
          },
          child: detail.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Text('خطا در بارگذاری محصول'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(productDetailProvider(id)),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            data: (p) {
              if (p == null) {
                return ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('محصول یافت نشد')),
                    ),
                  ],
                );
              }
              final gallery =
                  p.gallery.isNotEmpty ? p.gallery : [p.image];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (gallery.first.isNotEmpty)
                    SizedBox(
                      height: 240,
                      child: PageView.builder(
                        itemCount: gallery.length,
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: gallery[i],
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.image, size: 64),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        p.price.isNotEmpty ? p.price : '—',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: p.onSale ? Colors.red : null,
                        ),
                      ),
                      if (p.onSale && p.regularPrice.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          p.regularPrice,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (p.ratingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('★ ${p.rating} (${p.ratingCount} نظر)',
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      p.inStock ? 'موجود' : 'ناموجود',
                      style: TextStyle(
                          color: p.inStock ? Colors.green : Colors.red),
                    ),
                  ),
                  if (p.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(p.shortDescription),
                  ],
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(p.description),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: p.inStock
                          ? () => context.go('/cart')
                          : null,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('افزودن به سبد (Step 4)'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('نظرها',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  reviews.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const Text(
                        'خطا در بارگذاری نظرها',
                        style: TextStyle(color: Colors.grey)),
                    data: (list) => list.isEmpty
                        ? const Text('هنوز نظری ثبت نشده',
                            style: TextStyle(color: Colors.grey))
                        : Column(
                            children: list
                                .map((r) => Card(
                                      child: ListTile(
                                        title: Text(r.reviewer.isNotEmpty
                                            ? r.reviewer
                                            : 'ناشناس'),
                                        subtitle: Text(r.review),
                                        trailing: Text('★ ${r.rating}'),
                                      ),
                                    ))
                                .toList(),
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
