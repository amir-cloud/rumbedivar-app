import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/landing.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/store_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../services/checkout_service.dart';
import '../services/store_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>(
    (ref) => AuthService(api: ref.watch(apiClientProvider)));

final tokenProvider = FutureProvider<String?>((ref) async {
  return ref.watch(authServiceProvider).getToken();
});

final meProvider = FutureProvider<User?>((ref) async {
  return ref.watch(authServiceProvider).getMe();
});

final storeServiceProvider =
    Provider<StoreService>((ref) => StoreService(ref.watch(apiClientProvider)));

final bootProvider = FutureProvider<
    ({StoreInfo store, AppConfig config, LandingData landing})>((ref) async {
  return ref.watch(storeServiceProvider).loadBoot();
});

final discountProvider =
    FutureProvider.family<AppDiscount?, double>((ref, subtotal) async {
  return ref.watch(storeServiceProvider).appDiscount(subtotal);
});

final catalogServiceProvider = Provider<CatalogService>(
    (ref) => CatalogService(ref.watch(apiClientProvider)));

final categoriesProvider =
    FutureProvider<List<ProductCategory>>((ref) async {
  return ref.watch(catalogServiceProvider).getCategories();
});

/// Paginated products with infinite scroll (Step 3).
class ProductsState {
  final List<Product> items;
  final bool loading;
  final bool hasMore;
  final String? error;
  final ProductQuery query;
  const ProductsState({
    this.items = const [],
    this.loading = false,
    this.hasMore = true,
    this.error,
    this.query = const ProductQuery(),
  });

  ProductsState copyWith({
    List<Product>? items,
    bool? loading,
    bool? hasMore,
    String? Function()? error,
    ProductQuery? query,
  }) {
    return ProductsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      hasMore: hasMore ?? this.hasMore,
      error: error != null ? error() : this.error,
      query: query ?? this.query,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  ProductsNotifier(this._service) : super(const ProductsState());
  final CatalogService _service;

  Future<void> loadFirst(ProductQuery q) async {
    state = ProductsState(query: q, loading: true);
    try {
      final items = await _service.getProducts(q);
      state = ProductsState(
        items: items,
        query: q,
        hasMore: items.length >= q.perPage,
      );
    } catch (e) {
      state = ProductsState(query: q, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    state = state.copyWith(loading: true);
    try {
      final next = state.query.copyWith(page: state.query.page + 1);
      final items = await _service.getProducts(next);
      state = state.copyWith(
        items: [...state.items, ...items],
        loading: false,
        hasMore: items.length >= next.perPage,
        query: next,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: () => e.toString());
    }
  }

  void setQuery(ProductQuery q) => loadFirst(q);
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>(
        (ref) => ProductsNotifier(ref.watch(catalogServiceProvider)));

final productDetailProvider =
    FutureProvider.family<Product?, int>((ref, id) async {
  return ref.watch(catalogServiceProvider).getProduct(id);
});

final productReviewsProvider =
    FutureProvider.family<List<ProductReview>, int>((ref, id) async {
  return ref.watch(catalogServiceProvider).getReviewsFor(id);
});

final checkoutServiceProvider = Provider<CheckoutService>(
    (ref) => CheckoutService(ref.watch(apiClientProvider)));

final gatewaysProvider =
    FutureProvider<List<PaymentGateway>>((ref) async {
  return ref.watch(checkoutServiceProvider).offlineGateways();
});
