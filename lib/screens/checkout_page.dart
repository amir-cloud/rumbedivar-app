import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_error.dart';
import '../models/order.dart';
import '../providers/app_providers.dart';
import '../providers/cart_provider.dart';
import '../widgets/price.dart';

/// Real COD-only checkout (Issue #2 Step 5).
/// Replaces the fake-door mock: billing + copy-to-shipping, offline
/// gateways, coupon validation, shipping preview, discreet delivery,
/// POST /checkout with JWT + is_app_order=true.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _addr = TextEditingController();
  final _city = TextEditingController();
  final _post = TextEditingController();
  final _shipAddr = TextEditingController();
  final _shipCity = TextEditingController();
  final _shipPost = TextEditingController();
  final _note = TextEditingController();
  final _coupon = TextEditingController();

  bool _copyShipping = true;
  DiscreetDelivery _delivery = DiscreetDelivery.locker;
  String? _gateway;
  String? _shipMethod;
  List<ShippingRate> _rates = const [];
  CouponInfo? _couponInfo;
  String? _ratesError;
  String? _couponError;
  bool _loadingRates = false;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _addr.dispose();
    _city.dispose();
    _post.dispose();
    _shipAddr.dispose();
    _shipCity.dispose();
    _shipPost.dispose();
    _note.dispose();
    _coupon.dispose();
    super.dispose();
  }

  Address get _billing => Address(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        phone: _phone.text.trim(),
        address: _addr.text.trim(),
        city: _city.text.trim(),
        postcode: _post.text.trim(),
      );

  Address get _shipping => _copyShipping
      ? _billing
      : Address(
          firstName: _first.text.trim(),
          lastName: _last.text.trim(),
          phone: _phone.text.trim(),
          address: _shipAddr.text.trim(),
          city: _shipCity.text.trim(),
          postcode: _shipPost.text.trim(),
        );

  Future<void> _previewRates() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loadingRates = true;
      _ratesError = null;
    });
    try {
      final items = ref.read(cartProvider).items;
      final rates = await ref
          .read(checkoutServiceProvider)
          .calculateShipping(_shipping, items);
      if (!mounted) return;
      setState(() {
        _rates = rates;
        if (rates.isNotEmpty && _shipMethod == null) {
          _shipMethod = rates.first.id;
        }
      });
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _ratesError =
          e.code == 'endpoint_disabled' ? 'محاسبه ارسال فعلا غیرفعال است' : e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _ratesError = 'خطا در محاسبه ارسال: $e');
    } finally {
      if (mounted) setState(() => _loadingRates = false);
    }
  }

  Future<void> _validateCoupon() async {
    setState(() {
      _couponError = null;
    });
    try {
      final info = await ref
          .read(checkoutServiceProvider)
          .validateCoupon(_coupon.text);
      if (!mounted) return;
      setState(() => _couponInfo = info);
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _couponError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _couponError = 'کد تخفیف معتبر نیست');
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_gateway == null) {
      setState(() => _submitError = 'روش پرداخت را انتخاب کنید');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final cart = ref.read(cartProvider);
      final order = await ref.read(checkoutServiceProvider).submit(
            billing: _billing,
            shipping: _shipping,
            paymentMethod: _gateway!,
            items: cart.items,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            coupon: _coupon.text.trim().isEmpty ? null : _coupon.text.trim(),
            delivery: _delivery,
            shippingMethod: _shipMethod,
          );
      await ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('سفارش ثبت شد',
              textDirection: TextDirection.rtl),
          content: Text(
            'شماره سفارش: ${order.number}\n'
            'پیامک: «بسته شما رسید» — بدون نام محصول\n'
            '${order.appDiscountApplied ? 'تخفیف اپ اعمال شد ✓\n' : ''}'
            'پیک از محتوای بسته اطلاع ندارد.',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => context.go('/orders'),
              child: const Text('مشاهده سفارش‌ها'),
            ),
          ],
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _submitError =
          e.code == 'endpoint_disabled' ? 'ثبت سفارش فعلا غیرفعال است' : e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = 'ثبت سفارش ناموفق بود: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final boot = ref.watch(bootProvider);
    final gateways = ref.watch(gatewaysProvider);
    final notesOn = boot.maybeWhen(
        data: (b) => b.config.orderNotesEnabled, orElse: () => true);
    final minOrder = boot.maybeWhen(
        data: (b) => b.store.minOrderAmount, orElse: () => 0.0);
    final currency = boot.maybeWhen(
        data: (b) => b.store.currencySymbol, orElse: () => 'تومان');
    final decimals =
        boot.maybeWhen(data: (b) => b.store.numDecimals, orElse: () => 0);
    final blocked = cart.subtotal < minOrder;

    if (!cart.loaded) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('تسویه حساب')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('سبد خالی است',
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/catalog'),
                child: const Text('رفتن به کاتالوگ'),
              ),
            ],
          ),
        ),
      );
    }

    final selectedRate = _rates.where((r) => r.id == _shipMethod).firstOrNull;
    final total = cart.subtotal -
        (_couponInfo?.amount ?? 0) +
        (selectedRate?.cost ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('تسویه حساب محرمانه')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('بدون نام فروشگاه در هیچ مرحله‌ای',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              // Billing
              const Text('مشخصات صورتحساب',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _field(_first, 'نام',
                          validator: _req)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _field(_last, 'نام خانوادگی',
                          validator: _req)),
                ],
              ),
              _field(_phone, 'موبایل',
                  keyboard: TextInputType.phone, validator: _req),
              _field(_addr, 'آدرس', validator: _req),
              Row(
                children: [
                  Expanded(child: _field(_city, 'شهر', validator: _req)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_post, 'کد پستی')),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('آدرس تحویل مثل صورتحساب'),
                value: _copyShipping,
                onChanged: (v) =>
                    setState(() => _copyShipping = v ?? true),
              ),
              if (!_copyShipping) ...[
                const Text('آدرس تحویل',
                    style:
                        TextStyle(fontWeight: FontWeight.w700)),
                _field(_shipAddr, 'آدرس تحویل', validator: _req),
                Row(
                  children: [
                    Expanded(
                        child: _field(_shipCity, 'شهر تحویل',
                            validator: _req)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_shipPost, 'کد پستی')),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Discreet delivery (research fake-door)
              const Text('تحویل محرمانه',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              RadioListTile<DiscreetDelivery>(
                title: Text(DiscreetDelivery.locker.label),
                subtitle: const Text('پارک ملت، کد ۴ رقمی پیامک می‌شود'),
                value: DiscreetDelivery.locker,
                groupValue: _delivery,
                onChanged: (v) =>
                    setState(() => _delivery = v!),
              ),
              RadioListTile<DiscreetDelivery>(
                title: Text(DiscreetDelivery.courierNoLogo.label),
                value: DiscreetDelivery.courierNoLogo,
                groupValue: _delivery,
                onChanged: (v) =>
                    setState(() => _delivery = v!),
              ),
              RadioListTile<DiscreetDelivery>(
                title: Text(DiscreetDelivery.workAddress.label),
                value: DiscreetDelivery.workAddress,
                groupValue: _delivery,
                onChanged: (v) =>
                    setState(() => _delivery = v!),
              ),
              const Text('پیک از محتوای بسته اطلاع ندارد.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              // Shipping preview
              Row(
                children: [
                  const Text('هزینه ارسال',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: _loadingRates ? null : _previewRates,
                    child: Text(
                        _loadingRates ? '...' : 'محاسبه'),
                  ),
                ],
              ),
              if (_ratesError != null)
                Text(_ratesError!,
                    style: const TextStyle(color: Colors.red)),
                for (final r in _rates)
                RadioListTile<String>(
                  title: Text(r.label.isNotEmpty ? r.label : r.id),
                  subtitle: Text(formatPrice(r.cost,
                      currency: currency, decimals: decimals)),
                  value: r.id,
                  groupValue: _shipMethod,
                  onChanged: (v) =>
                      setState(() => _shipMethod = v),
                ),
              const SizedBox(height: 12),
              // Payment (offline only)
              const Text('پرداخت (نقدی/دستی)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              gateways.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Text(
                    e is AppError && e.isDisabled
                        ? 'پرداخت فعلا غیرفعال است'
                        : 'خطا در بارگذاری روش‌ها',
                    style: const TextStyle(color: Colors.red)),
                data: (list) {
                  if (list.isEmpty) {
                    return const Text(
                        'روش پرداخت آفلاینی فعال نیست',
                        style: TextStyle(color: Colors.red));
                  }
                  return DropdownButtonFormField<String>(
                    value: _gateway,
                    items: list
                        .map((g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.title.isNotEmpty
                                ? g.title
                                : g.id)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _gateway = v),
                    decoration: const InputDecoration(
                        labelText: 'روش پرداخت'),
                    validator: (v) =>
                        v == null ? 'انتخاب کنید' : null,
                  );
                },
              ),
              const Text('نام در صورتحساب بانکی: RDV*Services',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              // Coupon
              Row(
                children: [
                  Expanded(
                      child:
                          _field(_coupon, 'کد تخفیف (اختیاری)')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _validateCoupon,
                    child: const Text('اعمال'),
                  ),
                ],
              ),
              if (_couponError != null)
                Text(_couponError!,
                    style: const TextStyle(color: Colors.red)),
              if (_couponInfo != null)
                Text(
                    'تخفیف: ${formatPrice(_couponInfo!.amount, currency: currency, decimals: decimals)}',
                    style: const TextStyle(color: Colors.green)),
              if (notesOn) ...[
                const SizedBox(height: 8),
                _field(_note, 'توضیح سفارش (اختیاری)',
                    maxLines: 2),
              ],
              const Divider(height: 32),
              Text(
                  'جمع سبد: ${formatPrice(cart.subtotal, currency: currency, decimals: decimals)}'),
              if (_couponInfo != null)
                Text(
                    'تخفیف: −${formatPrice(_couponInfo!.amount, currency: currency, decimals: decimals)}',
                    style: const TextStyle(color: Colors.green)),
              Text(
                  'ارسال: ${formatPrice(selectedRate?.cost ?? 0, currency: currency, decimals: decimals)}'),
              Text(
                'قابل پرداخت (تقریبی — مبلغ نهایی سرور): ${formatPrice(total, currency: currency, decimals: decimals)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16),
              ),
              if (blocked)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'حداقل مبلغ سفارش ${formatPrice(minOrder, currency: currency, decimals: decimals)} است',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_submitError!,
                      style:
                          const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_submitting || blocked) ? null : _submit,
                  child: Text(_submitting
                      ? 'در حال ثبت…'
                      : 'ثبت سفارش • ${formatPrice(total, currency: currency, decimals: decimals)}'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'آیکون اپ: «یادداشت‌ها» • اعلان بدون پیش‌نمایش',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'الزامی' : null;

  Widget _field(TextEditingController c, String label,
      {String? Function(String?)? validator,
      TextInputType? keyboard,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        validator: validator,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
