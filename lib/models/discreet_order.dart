// MVP discreet-order model — mirrors fake-door Card A/B, no backend yet.
enum DeliveryMethod { locker, courierNoLogo, workAddress }

enum Packaging { neutralPaid, neutralFree }

class DiscreetOrderDraft {
  static const int subtotal = 248000;
  static const int neutralPackFee = 15000;
  static const int freePackThreshold = 300000;
  static const String bankDescriptor = 'RDV*Services';
  static const String smsPreview = 'بسته شما رسید';
  static const String lockerLocation = 'پارک ملت';
  static const String discreetAppLabel = 'یادداشت‌ها';

  final Packaging packaging;
  final DeliveryMethod delivery;
  final bool freePackPromo;

  const DiscreetOrderDraft({
    this.packaging = Packaging.neutralPaid,
    this.delivery = DeliveryMethod.locker,
    this.freePackPromo = false,
  });

  int get packagingFee {
    if (packaging == Packaging.neutralFree) return 0;
    if (freePackPromo && subtotal >= freePackThreshold) return 0;
    return neutralPackFee;
  }

  int get total => subtotal + packagingFee;

  String get deliveryLabel {
    switch (delivery) {
      case DeliveryMethod.locker:
        return 'تحویل در لاکر ($lockerLocation، کد ۴ رقمی)';
      case DeliveryMethod.courierNoLogo:
        return 'پیک بدون لوگو (تماس با عنوان «بسته پستی»)';
      case DeliveryMethod.workAddress:
        return 'محل کار / آدرس آشنا';
    }
  }

  Map<String, dynamic> toJson() => {
        'subtotal': subtotal,
        'packagingFee': packagingFee,
        'total': total,
        'packaging': packaging.name,
        'delivery': delivery.name,
        'bankDescriptor': bankDescriptor,
      };

  DiscreetOrderDraft copyWith({
    Packaging? packaging,
    DeliveryMethod? delivery,
    bool? freePackPromo,
  }) {
    return DiscreetOrderDraft(
      packaging: packaging ?? this.packaging,
      delivery: delivery ?? this.delivery,
      freePackPromo: freePackPromo ?? this.freePackPromo,
    );
  }
}
