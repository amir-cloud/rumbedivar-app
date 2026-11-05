import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router_support.dart';
import '../models/customer.dart';
import '../providers/app_providers.dart';
import '../widgets/app_nav.dart';

/// Profile: GET/PUT /customer + logout (Issue #2 Step 6).
/// Keeps app-privacy toggles (biometric lock, no-preview) from home.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _init = false;
  bool _saving = false;
  String? _msg;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _fill(Customer c) {
    if (_init) return;
    _init = true;
    _first.text = c.firstName;
    _last.text = c.lastName;
    _email.text = c.email;
    _phone.text = c.phone;
  }

  Future<void> _save(int id, String username) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _msg = null;
    });
    try {
      final updated = await ref
          .read(customerServiceProvider)
          .updateCustomer(Customer(
            id: id,
            username: username,
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
          ));
      ref.invalidate(customerProvider);
      ref.invalidate(meProvider);
      if (!mounted) return;
      setState(() => _msg = updated != null
          ? 'ذخیره شد ✓'
          : 'پاسخی از سرور نیامد');
    } catch (e) {
      if (!mounted) return;
      setState(() => _msg = 'خطا در ذخیره: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).logout();
    appAuthState.setToken(null);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(customerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('پروفایل'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout),
        ],
      ),
      bottomNavigationBar:
          const AppBottomNav(current: '/profile'),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: customer.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('خطا در بارگذاری پروفایل'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(customerProvider),
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
          data: (c) {
            if (c == null) {
              return const Center(
                  child: Text('پروفایل یافت نشد'));
            }
            _fill(c);
            return Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('نام کاربری: ${c.username}',
                      style:
                          const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  _field(_first, 'نام'),
                  _field(_last, 'نام خانوادگی'),
                  _field(_email, 'ایمیل',
                      keyboard: TextInputType.emailAddress),
                  _field(_phone, 'موبایل',
                      keyboard: TextInputType.phone),
                  if (_msg != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 8),
                      child: Text(_msg!),
                    ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () => _save(c.id, c.username),
                      child: Text(
                          _saving ? 'در حال ذخیره…' : 'ذخیره'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/orders'),
                    icon: const Icon(Icons.receipt_long),
                    label:
                        const Text('سفارش‌های من'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }
}
