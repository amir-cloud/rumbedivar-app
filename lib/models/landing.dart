class OnboardingSlide {
  final String image;
  final String title;
  final String content;

  const OnboardingSlide({
    this.image = '',
    this.title = '',
    this.content = '',
  });

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) {
    return OnboardingSlide(
      image: (json['image'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
    );
  }

  bool get hasContent =>
      image.trim().isNotEmpty || title.trim().isNotEmpty || content.trim().isNotEmpty;
}

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
  final bool onboardingEnabled;
  final List<OnboardingSlide> onboardingSlides;
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
    this.onboardingEnabled = false,
    this.onboardingSlides = const [],
    this.featured = const [],
    this.categories = const [],
  });

  factory LandingData.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final settings = root['landing'] is Map<String, dynamic>
        ? root['landing'] as Map<String, dynamic>
        : root;

    List<Map<String, dynamic>> listOf(dynamic v) {
      if (v is List) {
        return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return const [];
    }

    List<OnboardingSlide> slidesOf(dynamic v) {
      if (v is! List) return const [];
      return v
          .whereType<Map>()
          .map((e) => OnboardingSlide.fromJson(Map<String, dynamic>.from(e)))
          .where((s) => s.hasContent)
          .toList();
    }

    bool flag(dynamic v, bool fallback) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return fallback;
    }

    return LandingData(
      heroTitle: (settings['hero_title'] ?? settings['heroTitle'] ?? 'روم به دیوار').toString(),
      heroSubtitle: (settings['hero_subtitle'] ??
              settings['heroSubtitle'] ??
              'هرچیزی که روتون نمیشه بخرید!')
          .toString(),
      heroImage: (settings['hero_image'] ?? settings['heroImage'] ?? '').toString(),
      ctaText: (settings['cta_text'] ?? settings['ctaText'] ?? 'مشاهده کاتالوگ').toString(),
      ctaUrl: (settings['cta_url'] ?? settings['ctaUrl'] ?? '/catalog').toString(),
      showCategories: flag(settings['show_categories'] ?? settings['showCategories'], true),
      showFeatured: flag(settings['show_featured'] ?? settings['showFeatured'], true),
      showBestsellers:
          flag(settings['show_bestsellers'] ?? settings['showBestsellers'], false),
      showNewArrivals:
          flag(settings['show_new_arrivals'] ?? settings['showNewArrivals'], false),
      onboardingEnabled:
          flag(settings['onboarding_enabled'] ?? settings['onboardingEnabled'], false),
      onboardingSlides: slidesOf(
          settings['onboarding_slides'] ?? settings['onboardingSlides']),
      featured: listOf(root['featured']),
      categories: listOf(root['categories']),
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
