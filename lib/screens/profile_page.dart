import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_error.dart';
import '../core/router_support.dart';
import '../models/customer.dart';
import '../providers/app_providers.dart';
import '../providers/cart_provider.dart';

/// Profile: GET/PUT /customer (Issue #2 Step 6).
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
      setState(() => _msg = updated != null ? 'ذخیره شد' : 'پاسخی از سرور نیامد');
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _msg = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _msg = 'خطا در ذخیره');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف حساب', textDirection: TextDirection.rtl),
        content: const Text(
          'حساب و داده‌های شما حذف می‌شود. ادامه می‌دهید؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(authServiceProvider).deleteAccount();
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _msg = e.message;
        _saving = false;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _msg = 'حذف حساب ناموفق بود';
        _saving = false;
      });
      return;
    }
    await ref.read(cartProvider.notifier).clear();
    appAuthState.setToken(null);
    ref.invalidate(customerProvider);
    ref.invalidate(meProvider);
    ref.invalidate(ordersProvider);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(customerProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: customer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('خطا در بارگذاری پروفایل'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(customerProvider),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
        data: (c) {
          if (c == null) {
            return const Center(child: Text('پروفایل یافت نشد'));
          }
          _fill(c);
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('نام کاربری: ${c.username}',
                    style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 12),
                _field(_first, 'نام'),
                _field(_last, 'نام خانوادگی'),
                _field(_email, 'ایمیل',
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'الزامی';
                      if (!v.contains('@')) return 'ایمیل معتبر وارد کنید';
                      return null;
                    }),
                _field(_phone, 'موبایل',
                    keyboard: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'الزامی';
                      if (!RegExp(r'^09\d{9}$').hasMatch(v.trim())) {
                        return 'موبایل معتبر وارد کنید (09...)';
                      }
                      return null;
                    }),
                if (_msg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_msg!),
                  ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(c.id, c.username),
                    child: Text(_saving ? 'در حال ذخیره…' : 'ذخیره'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/orders'),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('سفارش‌های من'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _deleteAccount,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text('حذف حساب و داده‌ها',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: validator ??
            (v) =>
                (v == null || v.trim().isEmpty) ? 'الزامی' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }
}
