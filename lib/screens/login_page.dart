import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router_support.dart';
import '../providers/app_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref.read(authServiceProvider).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      final token = await ref.read(authServiceProvider).getToken();
      appAuthState.setToken(token);
      if (!mounted) return;
      context.go('/home');
    } else {
      setState(() => _error = result.error ?? 'ورود ناموفق بود');
    }
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(bootProvider);
    final registrationEnabled = boot.maybeWhen(
      data: (b) => b.config.enableRegistration,
      orElse: () => true,
    );
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
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
                            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ورود به حساب',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'به حساب خود وارد شوید',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.white),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _usernameController,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('نام کاربری', Icons.person_outline),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'نام کاربری را وارد کنید' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('رمز عبور', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              tooltip: 'نمایش رمز',
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'رمز عبور را وارد کنید' : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFC30960),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  )
                                : const Text('ورود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (registrationEnabled) ...[
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.35))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'یا',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.35))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => context.go('/register'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.4),
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text(
                                'ایجاد حساب کاربری',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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