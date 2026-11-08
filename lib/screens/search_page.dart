import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/skeleton.dart';

/// Product search page (moved from catalog).
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(searchProductsProvider.notifier).loadMore();
    }
  }

  void _apply() {
    final q = _search.text.trim();
    if (q.isEmpty) {
      ref.read(searchProductsProvider.notifier).loadFirst(const ProductQuery());
      return;
    }
    ref.read(searchProductsProvider.notifier).loadFirst(ProductQuery(search: q));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProductsProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'جستجوی محصول…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _apply();
                          setState(() {});
                        },
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _apply(),
            ),
          ),
          Expanded(child: _body(state)),
        ],
      ),
    );
  }

  Widget _body(ProductsState state) {
    final hasQuery = _search.text.trim().isNotEmpty;
    if (!hasQuery && state.items.isEmpty && !state.loading && state.error == null) {
      return const Center(child: Text('برای جستجو، نام محصول را وارد کنید'));
    }
    if (state.loading && state.items.isEmpty) {
      return const SkeletonGrid();
    }
    if (state.error != null && state.items.isEmpty) {
      final msg = state.error!.contains('endpoint_disabled')
          ? 'این بخش فعلا غیرفعال است'
          : 'خطا در جستجو — دوباره تلاش کنید';
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _apply, child: const Text('تلاش مجدد')),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return const Center(child: Text('محصولی یافت نشد'));
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
              child: p.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: p.image,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.image),
                    )
                  : const Icon(Icons.image),
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
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
