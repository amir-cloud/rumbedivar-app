import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_error.dart';
import '../core/router_support.dart';
import '../models/customer.dart';
import '../providers/app_providers.dart';
import '../providers/cart_provider.dart';
import '../widgets/animated_brand_background.dart';

/// Profile: GET/PUT /customer (Issue #2 Step 6).
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
  bool _msgOk = false;

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
      final updated =
          await ref.read(customerServiceProvider).updateCustomer(Customer(
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
      setState(() {
        _msgOk = updated != null;
        _msg = updated != null ? 'ذخیره شد' : 'پاسخی از سرور نیامد';
      });
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _msgOk = false;
        _msg = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _msgOk = false;
        _msg = 'خطا در ذخیره';
      });
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
          'حساب و داده‌های شما حذف می‌شوند. ادامه می‌دهید؟',
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
        _msgOk = false;
        _saving = false;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _msg = 'حذف حساب ناموفق بود';
        _msgOk = false;
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
      child: AnimatedBrandBackground(
        child: customer.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (_, __) => _centerBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('خطا در بارگذاری پروفایل',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(customerProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFC30960),
                  ),
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
          data: (c) {
            if (c == null) {
              return _centerBox(
                child: const Text('پروفایل یافت نشد',
                    style: TextStyle(color: Colors.white)),
              );
            }
            _fill(c);
            return _centerBox(
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.png',
                            fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'پروفایل کاربری',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'نام کاربری: ${c.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_msg != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_msgOk ? Colors.green : Colors.red)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          _msg!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _field(_first, 'نام', Icons.person_outline),
                    const SizedBox(height: 12),
                    _field(_last, 'نام خانوادگی', Icons.person_outline),
                    const SizedBox(height: 12),
                    _field(_email, 'ایمیل', Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'الزامی';
                      if (!v.contains('@')) return 'ایمیل معتبر وارد کنید';
                      return null;
                    }),
                    const SizedBox(height: 12),
                    _field(_phone, 'موبایل', Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'الزامی';
                      if (!RegExp(r'^09\d{9}$').hasMatch(v.trim())) {
                        return 'موبایل معتبر وارد کنید (09...)';
                      }
                      return null;
                    }),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _saving ? null : () => _save(c.id, c.username),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFC30960),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text('ذخیره',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: Colors.white.withValues(alpha: 0.35))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'یا',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color: Colors.white.withValues(alpha: 0.35))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/orders'),
                        icon: const Icon(Icons.receipt_long),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 1.4),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        label: const Text('سفارش‌های من',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _deleteAccount,
                        icon: const Icon(Icons.delete_forever),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFE5E5),
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.4),
                          backgroundColor:
                              Colors.red.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        label: const Text('حذف حساب و داده‌ها',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _centerBox({required Widget child}) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
    TextDirection textDirection = TextDirection.rtl,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      textDirection: textDirection,
      style: const TextStyle(color: Colors.white),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'الزامی' : null,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.95)),
      floatingLabelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      errorStyle: const TextStyle(
        color: Color(0xFFFFF1F1),
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFFD6D6), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 1.4),
      ),
    );
  }
}