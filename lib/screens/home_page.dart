import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router_support.dart';
import '../providers/app_providers.dart';
import '../services/app_lock_service.dart';
import '../widgets/app_nav.dart';

/// Home / Landing (Issue #2 Step 2).
/// Driven by GET /landing + GET /store + GET /config — no app change needed
/// when WP Landing settings change. Preserves discreet entry + app-privacy.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _lock = AppLockService();
  bool _appLock = false;
  bool _noPreview = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final l = await _lock.isLockEnabled();
    final n = await _lock.isNoPreviewEnabled();
    if (!mounted) return;
    setState(() {
      _appLock = l;
      _noPreview = n;
    });
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).logout();
    appAuthState.setToken(null);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final boot = ref.watch(bootProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('روم به دیوار'),
        actions: [
          IconButton(onPressed: () => context.go('/profile'), icon: const Icon(Icons.person)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(current: '/home'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bootProvider);
          ref.invalidate(meProvider);
          await ref.read(bootProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              me.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (u) => Text(
                  'خوش آمدید ${u?.displayName ?? u?.username ?? ''}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 16),
              boot.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text(
                  'فروشگاه موقتا در دسترس نیست — دوباره بکشید',
                  textDirection: TextDirection.rtl,
                ),
                data: (b) => _landingBody(b.landing, b.store.currencySymbol),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/checkout'),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('تسویه حساب محرمانه'),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('قفل اپ', textDirection: TextDirection.rtl),
                subtitle: const Text('TODO: biometric via local_auth',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 11)),
                value: _appLock,
                onChanged: (v) async {
                  await _lock.setLockEnabled(v);
                  if (!mounted) return;
                  setState(() => _appLock = v);
                },
              ),
              SwitchListTile(
                title: const Text('اعلان بدون پیش‌نمایش',
                    textDirection: TextDirection.rtl),
                value: _noPreview,
                onChanged: (v) async {
                  await _lock.setNoPreviewEnabled(v);
                  if (!mounted) return;
                  setState(() => _noPreview = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _landingBody(dynamic landing, String currency) {
    final featured = landing.featured as List;
    final categories = landing.categories as List;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero — WP-driven
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(landing.heroTitle,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(landing.heroSubtitle,
                      style: const TextStyle(color: Colors.grey)),
                  if ((landing.heroImage as String).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: landing.heroImage as String,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/catalog'),
                    child: Text(landing.ctaText as String),
                  ),
                ],
              ),
            ),
          ),
          // App-discount banner helper
          Consumer(builder: (context, ref, _) {
            final d = ref.watch(discountProvider(248000));
            return d.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (v) => (v == null || v.label.isEmpty)
                  ? const SizedBox.shrink()
                  : Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(v.label,
                          style: const TextStyle(color: Colors.green)),
                    ),
            );
          }),
          if (landing.showCategories && categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('دسته‌بندی‌ها',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = categories[i] as Map;
                  return ActionChip(
                    label: Text('${c['name'] ?? ''}'),
                    onPressed: () => context.go('/catalog'),
                  );
                },
              ),
            ),
          ],
          if (landing.showFeatured) ...[
            const SizedBox(height: 16),
            const Text('پیشنهاد ویژه',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (featured.isEmpty)
              const Text('به‌زودی — از تنظیمات لندینگ WP اضافه کنید',
                  style: TextStyle(color: Colors.grey))
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: featured.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final p = featured[i] as Map;
                    final img = (p['image'] ?? p['images'])?.toString() ?? '';
                    return SizedBox(
                      width: 140,
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: img.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: img,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.image),
                                    )
                                  : const Icon(Icons.image),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text('${p['name'] ?? ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
          if (landing.showBestsellers)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('پرفروش‌ترین‌ها (به‌زودی: Step 3 کاتالوگ)',
                  style: TextStyle(color: Colors.grey)),
            ),
          if (landing.showNewArrivals)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('جدیدترین‌ها (به‌زودی: Step 3 کاتالوگ)',
                  style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
