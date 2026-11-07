import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_providers.dart';
import '../widgets/animated_brand_background.dart';

const String _kOnboardingSeenKey = 'onboarding_seen_v1';

/// Splash boots token + store/config, then routes (Step 0).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_kOnboardingSeenKey) ?? false;
      final token = await ref.read(authServiceProvider).getToken();
      // Warm boot cache (best-effort, ignore failures offline).
      dynamic boot;
      try {
        boot = await ref.read(bootProvider.future);
      } catch (_) {}
      if (!mounted) return;
      if (!seen && boot != null) {
        final landing = boot.landing;
        if (landing.onboardingEnabled && landing.onboardingSlides.isNotEmpty) {
          context.go('/onboarding');
          return;
        }
      }
      if (token != null && token.isNotEmpty) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } catch (_) {
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBrandBackground(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/images/logo.png',
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 32),
            const Text('روم به دیوار',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
                textDirection: TextDirection.rtl),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text('هرچیزی که روتون نمیشه بخرید!',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textDirection: TextDirection.rtl),
            ),
          ],
        ),
      ),
    );
  }
}
