import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/app_lock_service.dart';
import '../services/auth_service.dart';
import 'discreet_checkout_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = AuthService();
  final _lock = AppLockService();
  User? _user;
  bool _loading = true;
  bool _appLock = false;
  bool _noPreview = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _auth.getMe();
    final l = await _lock.isLockEnabled();
    final n = await _lock.isNoPreviewEnabled();
    if (!mounted) return;
    setState(() {
      _user = u;
      _appLock = l;
      _noPreview = n;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('روم به دیوار'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Text(
                      'خوش آمدید ${_user?.displayName ?? _user?.username ?? ''}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Text(_user?.email ?? '',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const DiscreetCheckoutPage()),
                        ),
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('تسویه حساب محرمانه (تست)'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('قفل اپ',
                          textDirection: TextDirection.rtl),
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
    );
  }
}
