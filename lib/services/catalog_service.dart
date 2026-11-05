import '../core/api_client.dart';
import '../core/app_error.dart';
import '../models/product.dart';

/// Catalog backed by rumbedivar/v1 (Issue #2 Step 3).
/// Never sends include_hidden — WP pre-filters hidden products server-side.
class CatalogService {
  CatalogService(this._api);
  final ApiClient _api;

  List<Product> _parseProducts(dynamic j) {
    final list = j is List
        ? j
        : (j is Map<String, dynamic>
            ? (j['data'] ?? j['products'] ?? j['items'])
            : null);
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .where((p) => p.id != 0)
          .toList();
    }
    return const [];
  }

  Future<List<Product>> getProducts(ProductQuery q) async {
    final params = q.toParams();
    final qs = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    try {
      final j = await _api.get('/products?$qs');
      return _parseProducts(j);
    } on AppError {
      rethrow;
    }
  }

  Future<Product?> getProduct(int id) async {
    try {
      final j = await _api.get('/products/$id');
      final map = j is Map<String, dynamic>
          ? (j['data'] is Map<String, dynamic>
              ? j['data'] as Map<String, dynamic>
              : j)
          : null;
      if (map == null) return null;
      return Product.fromJson(map);
    } on AppError {
      rethrow;
    }
  }

  Future<List<ProductCategory>> getCategories() async {
    try {
      final j = await _api.get('/product_categories');
      final list = j is List
          ? j
          : (j is Map<String, dynamic> ? (j['data'] ?? j['categories']) : null);
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(ProductCategory.fromJson)
            .toList();
      }
      return const [];
    } on AppError {
      rethrow;
    }
  }

  /// GET /reviews then client-filter by product (plugin has no per-product
  /// reviews route in MVP contract).
  Future<List<ProductReview>> getReviewsFor(int productId) async {
    try {
      final j = await _api.get('/reviews');
      final list = j is List
          ? j
          : (j is Map<String, dynamic> ? (j['data'] ?? j['reviews']) : null);
      if (list is! List) return const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ProductReview.fromJson)
          .where((r) => r.productId == productId)
          .toList();
    } on AppError {
      rethrow;
    }
  }
}
