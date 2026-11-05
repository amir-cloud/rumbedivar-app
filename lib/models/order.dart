/// Checkout DTOs per plugin rumbedivar/v1 (Issue #2 Step 5, COD-only MVP).
/// Server totals authoritative; app sends is_app_order=true.

/// Offline payment gateway IDs allowed in MVP.
const List<String> offlineGatewayIds = ['cod', 'bacs', 'cheque'];

class PaymentGateway {
  final String id;
  final String title;
  final bool enabled;
  const PaymentGateway(
      {required this.id, this.title = '', this.enabled = true});

  factory PaymentGateway.fromJson(Map<String, dynamic> j) =>
      PaymentGateway(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? j['method_title'] ?? j['id'] ?? '').toString(),
        enabled: (j['enabled'] ?? true) != false,
      );

  bool get isOffline => offlineGatewayIds.contains(id);
}

class Address {
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String city;
  final String postcode;
  const Address({
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.address = '',
    this.city = '',
    this.postcode = '',
  });

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'address_1': address,
        'city': city,
        'postcode': postcode,
      };
}

enum DiscreetDelivery { locker, courierNoLogo, workAddress }

extension DiscreetDeliveryX on DiscreetDelivery {
  String get label {
    switch (this) {
      case DiscreetDelivery.locker:
        return 'تحویل در لاکر — بدون دیدار با پیک';
      case DiscreetDelivery.courierNoLogo:
        return 'پیک بدون لوگو (تماس با عنوان «بسته پستی»)';
      case DiscreetDelivery.workAddress:
        return 'محل کار / آدرس آشنا';
    }
  }

  String get apiValue {
    switch (this) {
      case DiscreetDelivery.locker:
        return 'locker';
      case DiscreetDelivery.courierNoLogo:
        return 'courier_no_logo';
      case DiscreetDelivery.workAddress:
        return 'work_address';
    }
  }
}

class ShippingRate {
  final String id;
  final String label;
  final double cost;
  const ShippingRate({required this.id, this.label = '', this.cost = 0});

  factory ShippingRate.fromJson(Map<String, dynamic> j) => ShippingRate(
        id: (j['id'] ?? j['method_id'] ?? '').toString(),
        label: (j['label'] ?? j['method_title'] ?? '').toString(),
        cost: ((j['cost'] ?? j['total'] ?? 0) as num?)?.toDouble() ?? 0,
      );
}

class CouponInfo {
  final String code;
  final double amount;
  final String label;
  const CouponInfo({required this.code, this.amount = 0, this.label = ''});

  factory CouponInfo.fromJson(Map<String, dynamic> j, String code) {
    final data = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;
    return CouponInfo(
      code: code,
      amount:
          ((data['amount'] ?? data['discount'] ?? 0) as num?)?.toDouble() ??
              0,
      label: (data['label'] ?? data['message'] ?? code).toString(),
    );
  }
}

class PlacedOrder {
  final int id;
  final String number;
  final String status;
  final double total;
  final bool appDiscountApplied;
  const PlacedOrder({
    required this.id,
    this.number = '',
    this.status = '',
    this.total = 0,
    this.appDiscountApplied = false,
  });

  factory PlacedOrder.fromJson(Map<String, dynamic> j) {
    final data = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;
    final order = data['order'] is Map<String, dynamic>
        ? data['order'] as Map<String, dynamic>
        : data;
    bool appFee = false;
    final fees = order['fee_lines'] ?? order['fees'];
    if (fees is List) {
      for (final f in fees) {
        if (f is Map) {
          final name = (f['name'] ?? '').toString().toLowerCase();
          if (name.contains('app discount')) {
            appFee = true;
            break;
          }
        }
      }
    }
    if (data['app_discount'] != null) appFee = true;
    return PlacedOrder(
      id: ((order['id']) as num?)?.toInt() ?? 0,
      number: (order['number'] ?? order['id'] ?? '').toString(),
      status: (order['status'] ?? '').toString(),
      total: ((order['total']) as num?)?.toDouble() ?? 0,
      appDiscountApplied: appFee,
    );
  }
}
