import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';

/// Placeholder scaffold for routes not yet built (Steps 2-6).
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              const Text('به‌زودی در این نسخه',
                  style: TextStyle(color: Colors.black87)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('بازگشت به خانه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FriendlyErrorPage extends StatelessWidget {
  const FriendlyErrorPage(
      {super.key, required this.message, this.code});
  final String message;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final fa = switch (code) {
      'endpoint_disabled' => 'این بخش فعلا غیرفعال است',
      'wc_inactive' => 'فروشگاه موقتا در دسترس نیست',
      'not_found' => 'محصول یا سفارش یافت نشد',
      'unauthorized' => 'نشست منقضی شد — لطفا دوباره وارد شوید',
      'network' => 'خطا در اتصال — اینترنت را بررسی کنید',
      _ => message.startsWith('AppError') || message.contains('Exception')
          ? 'خطایی رخ داد — دوباره تلاش کنید'
          : message,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('خطا')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(fa, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('بازگشت به خانه'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal auth state for router redirect (Step 0).
class AuthState extends ChangeNotifier {
  AuthState(this._auth);
  final AuthService _auth;
  String? _token;
  bool _ready = false;

  bool get ready => _ready;
  bool get loggedIn => _token != null && _token!.isNotEmpty;

  Future<void> boot() async {
    _token = await _auth.getToken();
    _ready = true;
    notifyListeners();
  }

  /// For tests: mark auth resolution complete without reading storage.
  void markReady({String? token}) {
    _token = token;
    _ready = true;
    notifyListeners();
  }

  void setToken(String? t) {
    _token = t;
    notifyListeners();
  }
}

/// Global singleton so login/logout can refresh go_router redirect.
final appAuthState = AuthState(AuthService());
