import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/skeleton.dart';

/// Products for a single category (opened from catalog category list).
class CategoryProductsPage extends ConsumerStatefulWidget {
  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    this.categoryName,
  });
  final String categoryId;
  final String? categoryName;

  @override
  ConsumerState<CategoryProductsPage> createState() =>
      _CategoryProductsPageState();
}

class _CategoryProductsPageState extends ConsumerState<CategoryProductsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(categoryProductsProvider(widget.categoryId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryProductsProvider(widget.categoryId));
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: () async => ref
            .read(categoryProductsProvider(widget.categoryId).notifier)
            .loadFirst(ProductQuery(category: widget.categoryId)),
        child: _body(state),
      ),
    );
  }

  Widget _body(ProductsState state) {
    if (state.loading && state.items.isEmpty) {
      return const SkeletonGrid();
    }
    if (state.error != null && state.items.isEmpty) {
      final msg = state.error!.contains('endpoint_disabled')
          ? 'این بخش فعلا غیرفعال است'
          : 'خطا در بارگذاری — دوباره تلاش کنید';
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(msg, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref
                      .read(categoryProductsProvider(widget.categoryId).notifier)
                      .loadFirst(ProductQuery(category: widget.categoryId)),
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('محصولی در این دسته یافت نشد')),
          ),
        ],
      );
    }
    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= state.items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _card(state.items[i]);
      },
    );
  }

  Widget _card(Product p) {
    return InkWell(
      onTap: () => context.push('/product/${p.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  p.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: p.image,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.image),
                        )
                      : const Icon(Icons.image),
                  if (p.onSale)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('حراج',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    p.price.isNotEmpty ? '${p.price}' : '—',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: p.onSale ? Colors.red : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
