/// Product / Category / Review DTOs per
/// plugin class-wc-controller.php::format_product (Issue #2 Step 3).
class Product {
  final int id;
  final String name;
  final String slug;
  final String type;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final double rating;
  final int ratingCount;
  final bool inStock;
  final int stockQuantity;
  final List<String> gallery;
  final String image;
  final String description;
  final String shortDescription;

  const Product({
    required this.id,
    this.name = '',
    this.slug = '',
    this.type = 'simple',
    this.price = '',
    this.regularPrice = '',
    this.salePrice = '',
    this.onSale = false,
    this.rating = 0,
    this.ratingCount = 0,
    this.inStock = true,
    this.stockQuantity = 0,
    this.gallery = const [],
    this.image = '',
    this.description = '',
    this.shortDescription = '',
  });

  static List<String> _images(dynamic v) {
    if (v is List) {
      return v
          .map((e) {
            if (e is String) return e;
            if (e is Map && e['src'] != null) {
              return e['src'].toString();
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (v is String && v.isNotEmpty) return [v];
    if (v is Map && v['src'] != null) {
      return [v['src'].toString()];
    }
    return const [];
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final gallery = _images(json['gallery'] ?? json['images']);
    final img = (json['image'] ?? json['image_url'] ?? '').toString();
    final first = gallery.isNotEmpty
        ? gallery.first
        : (img.isNotEmpty
            ? img
            : ((json['images'] is List && (json['images'] as List).isNotEmpty)
                ? _images(json['images']).firstOrNull ?? ''
                : ''));
    return Product(
      id: ((json['id']) as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      type: (json['type'] ?? 'simple').toString(),
      price: (json['price'] ?? '').toString(),
      regularPrice: (json['regular_price'] ?? json['regularPrice'] ?? '').toString(),
      salePrice: (json['sale_price'] ?? json['salePrice'] ?? '').toString(),
      onSale: (json['on_sale'] ?? json['onSale'] ?? false) == true,
      rating: ((json['rating'] ?? json['average_rating'] ?? 0) as num?)?.toDouble() ?? 0,
      ratingCount:
          ((json['rating_count'] ?? json['ratingCount'] ?? 0) as num?)?.toInt() ?? 0,
      inStock: (json['in_stock'] ?? json['inStock'] ?? json['is_in_stock'] ?? true) != false,
      stockQuantity:
          ((json['stock_quantity'] ?? json['stockQuantity'] ?? 0) as num?)?.toInt() ?? 0,
      gallery: gallery,
      image: first,
      description:
          (json['description'] ?? json['long_description'] ?? '').toString(),
      shortDescription:
          (json['short_description'] ?? json['shortDescription'] ?? '').toString(),
    );
  }
}

class ProductCategory {
  final int id;
  final String name;
  final String slug;
  final int count;
  final String image;

  const ProductCategory({
    required this.id,
    this.name = '',
    this.slug = '',
    this.count = 0,
    this.image = '',
  });

  factory ProductCategory.fromJson(Map<String, dynamic> j) {
    dynamic img = j['image'];
    if (img is Map) img = img['src'] ?? '';
    return ProductCategory(
      id: ((j['id']) as num?)?.toInt() ?? 0,
      name: (j['name'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      count: ((j['count']) as num?)?.toInt() ?? 0,
      image: (img ?? '').toString(),
    );
  }
}

class ProductReview {
  final int id;
  final int productId;
  final String reviewer;
  final double rating;
  final String review;
  final String date;

  const ProductReview({
    required this.id,
    required this.productId,
    this.reviewer = '',
    this.rating = 0,
    this.review = '',
    this.date = '',
  });

  factory ProductReview.fromJson(Map<String, dynamic> j) {
    return ProductReview(
      id: ((j['id']) as num?)?.toInt() ?? 0,
      productId:
          ((j['product_id'] ?? j['productId'] ?? 0) as num?)?.toInt() ?? 0,
      reviewer: (j['reviewer'] ?? j['reviewer_name'] ?? '').toString(),
      rating: ((j['rating']) as num?)?.toDouble() ?? 0,
      review: (j['review'] ?? j['comment'] ?? '').toString(),
      date: (j['date_created'] ?? j['date'] ?? '').toString(),
    );
  }
}

/// Query for GET /products — never sends include_hidden (Step 3).
class ProductQuery {
  final int page;
  final int perPage;
  final String? category;
  final String? tag;
  final String? search;
  final String orderby;
  final String order;
  final bool? featured;
  final bool? onSale;
  final double? minPrice;
  final double? maxPrice;

  const ProductQuery({
    this.page = 1,
    this.perPage = 12,
    this.category,
    this.tag,
    this.search,
    this.orderby = 'date',
    this.order = 'desc',
    this.featured,
    this.onSale,
    this.minPrice,
    this.maxPrice,
  });

  ProductQuery copyWith({
    int? page,
    int? perPage,
    String? Function()? category,
    String? Function()? tag,
    String? Function()? search,
    String? orderby,
    String? order,
    bool? Function()? featured,
    bool? Function()? onSale,
    double? Function()? minPrice,
    double? Function()? maxPrice,
  }) {
    return ProductQuery(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      category: category != null ? category() : this.category,
      tag: tag != null ? tag() : this.tag,
      search: search != null ? search() : this.search,
      orderby: orderby ?? this.orderby,
      order: order ?? this.order,
      featured: featured != null ? featured() : this.featured,
      onSale: onSale != null ? onSale() : this.onSale,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    );
  }

  Map<String, String> toParams() {
    final m = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      'orderby': orderby,
      'order': order,
    };
    if (category != null && category!.isNotEmpty) {
      m['category'] = category!;
    }
    if (tag != null && tag!.isNotEmpty) m['tag'] = tag!;
    if (search != null && search!.isNotEmpty) m['search'] = search!;
    if (featured != null) m['featured'] = featured! ? 'true' : 'false';
    if (onSale != null) m['on_sale'] = onSale! ? 'true' : 'false';
    if (minPrice != null) m['min_price'] = '$minPrice';
    if (maxPrice != null) m['max_price'] = '$maxPrice';
    return m;
  }
}
