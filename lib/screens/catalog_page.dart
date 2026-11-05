import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../providers/app_providers.dart';

/// Catalog with infinite scroll, server-driven filters (Issue #2 Step 3).
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  String? _category;
  bool? _featured;
  bool? _onSale;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(
        () => ref.read(productsProvider.notifier).loadFirst(const ProductQuery()));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  void _apply() {
    ref.read(productsProvider.notifier).loadFirst(ProductQuery(
          category: _category,
          search: _search.text.trim().isEmpty ? null : _search.text.trim(),
          featured: _featured,
          onSale: _onSale,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    final cats = ref.watch(categoriesProvider);
    final boot = ref.watch(bootProvider);
    final showFeatured =
        boot.maybeWhen(data: (b) => b.config.filterOn('featured'), orElse: () => true);
    final showOnSale =
        boot.maybeWhen(data: (b) => b.config.filterOn('on_sale'), orElse: () => true);
    final showCategory =
        boot.maybeWhen(data: (b) => b.config.filterOn('category'), orElse: () => true);

    return Scaffold(
      appBar: AppBar(title: const Text('کاتالوگ')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'جستجو…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (showFeatured)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: const Text('ویژه'),
                        selected: _featured == true,
                        onSelected: (v) {
                          setState(() => _featured = v ? true : null);
                          _apply();
                        },
                      ),
                    ),
                  if (showOnSale)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: const Text('حراج'),
                        selected: _onSale == true,
                        onSelected: (v) {
                          setState(() => _onSale = v ? true : null);
                          _apply();
                        },
                      ),
                    ),
                  if (showCategory)
                    ...cats.maybeWhen(
                      data: (list) => list
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: Text(c.name),
                                  selected: _category == '${c.id}',
                                  onSelected: (v) {
                                    setState(() => _category =
                                        v ? '${c.id}' : null);
                                    _apply();
                                  },
                                ),
                              ))
                          .toList(),
                      orElse: () => const <Widget>[],
                    ),
                  if (_category != null ||
                      _featured != null ||
                      _onSale != null ||
                      _search.text.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _category = null;
                          _featured = null;
                          _onSale = null;
                          _search.clear();
                        });
                        _apply();
                      },
                      child: const Text('حذف فیلتر'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _apply(),
                child: _body(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(ProductsState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      final msg = state.error!.contains('endpoint_disabled')
          ? 'این بخش فعلا غیرفعال است'
          : 'خطا در بارگذاری — بکشید تا تازه شود';
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(msg, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: _apply, child: const Text('تلاش مجدد')),
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
            child: Center(child: Text('محصولی یافت نشد')),
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
        final p = state.items[i];
        return _card(p);
      },
    );
  }

  Widget _card(Product p) {
    return InkWell(
      onTap: () => context.go('/product/${p.id}'),
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
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.image),
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
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
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
                  Text(p.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    p.price.isNotEmpty ? '${p.price}' : '—',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: p.onSale ? Colors.red : null,
                    ),
                  ),
                  if (p.ratingCount > 0)
                    Text('★ ${p.rating} (${p.ratingCount})',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
