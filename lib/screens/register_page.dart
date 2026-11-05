import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_error.dart';
import '../providers/app_providers.dart';

/// Register gated by enable_registration / 403 registration_disabled (Step 1).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _u = TextEditingController();
  final _e = TextEditingController();
  final _p = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _u.dispose();
    _e.dispose();
    _p.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await ref
        .read(authServiceProvider)
        .register(_u.text.trim(), _e.text.trim(), _p.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.success) {
      context.go('/home');
    } else {
      setState(() => _error = r.error ?? 'ثبت‌نام ناموفق بود');
    }
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(bootProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ثبت‌نام')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: boot.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            if (e is AppError && e.isDisabled) {
              return const Center(
                  child: Text('ثبت‌نام فعلا غیرفعال است'));
            }
            return _formBody(allow: true);
          },
          data: (b) {
            if (!b.config.enableRegistration) {
              return const Center(
                  child: Text('ثبت‌نام فعلا غیرفعال است'));
            }
            return _formBody(allow: true);
          },
        ),
      ),
    );
  }

  Widget _formBody({required bool allow}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _form,
        child: Column(
          children: [
            if (_error != null) ...[
              Text(_error!,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _u,
              decoration:
                  const InputDecoration(labelText: 'نام کاربری'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الزامی' : null,
            ),
            TextFormField(
              controller: _e,
              decoration: const InputDecoration(labelText: 'ایمیل'),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'ایمیل معتبر' : null,
            ),
            TextFormField(
              controller: _p,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'رمز عبور'),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'حداقل ۶ کاراکتر' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? '...' : 'ثبت‌نام'),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('حساب دارم — ورود'),
            ),
          ],
        ),
      ),
    );
  }
}
