import 'package:flutter/material.dart';

import '../models/discreet_order.dart';

// Fake-door Card A/B as working MVP UI — RTL, neutral (no pink branding on purpose).
// No backend: pay shows local confirmation with locker code + neutral SMS preview.
class DiscreetCheckoutPage extends StatefulWidget {
  const DiscreetCheckoutPage({super.key});

  @override
  State<DiscreetCheckoutPage> createState() => _DiscreetCheckoutPageState();
}

class _DiscreetCheckoutPageState extends State<DiscreetCheckoutPage> {
  DiscreetOrderDraft _draft = const DiscreetOrderDraft();
  bool _variantB = false;

  void _pay() {
    final code = (1000 + DateTime.now().millisecond % 9000).toString();
    final isLocker = _draft.delivery == DeliveryMethod.locker;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('سفارش ثبت شد', textDirection: TextDirection.rtl),
        content: Text(
          isLocker
              ? 'کد لاکر پارک ملت: $code\nپیامک: «${DiscreetOrderDraft.smsPreview}» — بدون نام محصول\nصورتحساب: ${DiscreetOrderDraft.bankDescriptor}'
              : 'پیامک: «${DiscreetOrderDraft.smsPreview}» — بدون نام محصول\nصورتحساب: ${DiscreetOrderDraft.bankDescriptor}',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _draft;
    return Scaffold(
      appBar: AppBar(title: const Text('تسویه حساب محرمانه')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('بدون نام فروشگاه در هیچ مرحله‌ای',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📦 بسته خنثی بدون لوگو',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text(
                        'جعبه کرافت ساده، بدون نام «روم به دیوار». فاکتور داخل بسته، بدون اسم محصول روی لیبل.'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(_variantB
                              ? 'رایگان بالای ۳۰۰ هزار تومان'
                              : '+ ۱۵ هزار تومان'),
                          selected: d.packaging == Packaging.neutralPaid,
                          onSelected: (_) => setState(() => _draft = d.copyWith(
                              packaging: Packaging.neutralPaid)),
                        ),
                        ChoiceChip(
                          label: const Text('تست رایگان'),
                          selected: d.packaging == Packaging.neutralFree,
                          onSelected: (_) => setState(() => _draft = d.copyWith(
                              packaging: Packaging.neutralFree)),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('نسخه B (رایگان + محل کار)',
                          style: TextStyle(fontSize: 13)),
                      value: _variantB,
                      onChanged: (v) => setState(() {
                        _variantB = v;
                        _draft = d.copyWith(freePackPromo: v);
                        if (v == false &&
                            d.delivery == DeliveryMethod.workAddress) {
                          _draft = _draft.copyWith(
                              delivery: DeliveryMethod.locker);
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تحویل',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    RadioListTile<DeliveryMethod>(
                      title: const Text('لاکر نزدیک شما — بدون دیدار با پیک'),
                      subtitle:
                          const Text('پارک ملت، کد ۴ رقمی پیامک می‌شود'),
                      value: DeliveryMethod.locker,
                      groupValue: d.delivery,
                      onChanged: (v) =>
                          setState(() => _draft = d.copyWith(delivery: v)),
                    ),
                    RadioListTile<DeliveryMethod>(
                      title: const Text('پیک بدون لوگو'),
                      subtitle:
                          const Text('تماس با عنوان «بسته پستی»'),
                      value: DeliveryMethod.courierNoLogo,
                      groupValue: d.delivery,
                      onChanged: (v) =>
                          setState(() => _draft = d.copyWith(delivery: v)),
                    ),
                    if (_variantB)
                      RadioListTile<DeliveryMethod>(
                        title: const Text('محل کار / آدرس آشنا'),
                        value: DeliveryMethod.workAddress,
                        groupValue: d.delivery,
                        onChanged: (v) =>
                            setState(() => _draft = d.copyWith(delivery: v)),
                      ),
                    const Text('پیک از محتوای بسته اطلاع ندارد.',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('پرداخت و پیامک',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                        'نام در صورتحساب: ${DiscreetOrderDraft.bankDescriptor}',
                        textDirection: TextDirection.rtl),
                    Text('پیامک: «${DiscreetOrderDraft.smsPreview}»'),
                    const Divider(),
                    Text('جمع: ${DiscreetOrderDraft.subtotal} تومان'),
                    Text('بسته: ${d.packagingFee} تومان'),
                    Text(
                        'قابل پرداخت: ${d.total} تومان',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _pay,
                child: Text('پرداخت ${d.total} تومان'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'آیکون اپ در گوشی: «یادداشت‌ها» • اعلان بدون پیش‌نمایش',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
