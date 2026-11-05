/// Landing DTO per plugin GET /landing (Issue #2 Step 2).
/// All fields optional — WP drives UI with no app code change.
class LandingData {
  final String heroTitle;
  final String heroSubtitle;
  final String heroImage;
  final String ctaText;
  final String ctaUrl;
  final bool showCategories;
  final bool showFeatured;
  final bool showBestsellers;
  final bool showNewArrivals;
  final List<Map<String, dynamic>> featured;
  final List<Map<String, dynamic>> categories;

  const LandingData({
    this.heroTitle = 'روم به دیوار',
    this.heroSubtitle = 'هرچیزی که روتون نمیشه بخرید!',
    this.heroImage = '',
    this.ctaText = 'مشاهده کاتالوگ',
    this.ctaUrl = '/catalog',
    this.showCategories = true,
    this.showFeatured = true,
    this.showBestsellers = false,
    this.showNewArrivals = false,
    this.featured = const [],
    this.categories = const [],
  });

  factory LandingData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    List<Map<String, dynamic>> listOf(dynamic v) {
      if (v is List) {
        return v.whereType<Map<String, dynamic>>().toList();
      }
      return const [];
    }

    bool flag(dynamic v, bool fallback) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return fallback;
    }

    return LandingData(
      heroTitle: (data['hero_title'] ?? data['heroTitle'] ?? 'روم به دیوار').toString(),
      heroSubtitle: (data['hero_subtitle'] ??
              data['heroSubtitle'] ??
              'هرچیزی که روتون نمیشه بخرید!')
          .toString(),
      heroImage: (data['hero_image'] ?? data['heroImage'] ?? '').toString(),
      ctaText: (data['cta_text'] ?? data['ctaText'] ?? 'مشاهده کاتالوگ').toString(),
      ctaUrl: (data['cta_url'] ?? data['ctaUrl'] ?? '/catalog').toString(),
      showCategories: flag(data['show_categories'] ?? data['showCategories'], true),
      showFeatured: flag(data['show_featured'] ?? data['showFeatured'], true),
      showBestsellers:
          flag(data['show_bestsellers'] ?? data['showBestsellers'], false),
      showNewArrivals:
          flag(data['show_new_arrivals'] ?? data['showNewArrivals'], false),
      featured: listOf(data['featured']),
      categories: listOf(data['categories']),
    );
  }
}

/// App-discount banner helper GET /ordering/app-discount?subtotal=
class AppDiscount {
  final String label;
  final double amount;
  const AppDiscount({this.label = '', this.amount = 0});

  factory AppDiscount.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return AppDiscount(
      label: (data['label'] ?? data['message'] ?? '').toString(),
      amount: ((data['amount'] ?? data['discount'] ?? 0) as num?)?.toDouble() ?? 0,
    );
  }
}
