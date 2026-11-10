import '../core/api_client.dart';
import '../core/app_error.dart';
import '../models/cart.dart';
import '../models/order.dart';

/// Checkout backend: gateways, shipping preview, coupon, submit (Step 5).
class CheckoutService {
  CheckoutService(this._api);
  final ApiClient _api;

  /// GET /payment-gateways filtered to offline IDs (cod/bacs/cheque).
  Future<List<PaymentGateway>> offlineGateways() async {
    try {
      final j = await _api.get('/payment-gateways');
      final list = j is List
          ? j
          : (j is Map<String, dynamic>
              ? (j['data'] ?? j['gateways'])
              : null);
      if (list is! List) return const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(PaymentGateway.fromJson)
          .where((g) => g.isOffline && g.enabled)
          .toList();
    } on AppError {
      rethrow;
    }
  }

  /// POST /shipping/calculate rate preview.
  Future<List<ShippingRate>> calculateShipping(
      Address shipping, List<CartItem> items) async {
    try {
      final j = await _api.post('/shipping/calculate', {
        'shipping': shipping.toJson(),
        'items': items.map((e) => e.toOrderItem()).toList(),
      });
      final list = j is List
          ? j
          : (j is Map<String, dynamic>
              ? (j['data'] ?? j['rates'] ?? j['shipping'])
              : null);
      if (list is! List) return const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ShippingRate.fromJson)
          .toList();
    } on AppError {
      rethrow;
    }
  }

  /// GET /coupons/{code} validation.
  Future<CouponInfo?> validateCoupon(String code) async {
    final c = code.trim();
    if (c.isEmpty) return null;
    try {
      final j = await _api.get('/coupons/${Uri.encodeComponent(c)}');
      if (j is Map<String, dynamic>) return CouponInfo.fromJson(j, c);
      return null;
    } on AppError {
      rethrow;
    }
  }

  /// POST /checkout — JWT required, is_app_order=true.
  Future<PlacedOrder> submit({
    required Address billing,
    required Address shipping,
    required String paymentMethod,
    required List<CartItem> items,
    String? note,
    String? coupon,
    DiscreetDelivery delivery = DiscreetDelivery.locker,
    String? shippingMethod,
  }) async {
    final body = {
      'billing': billing.toJson(),
      'shipping': shipping.toJson(),
      'payment_method': paymentMethod,
      'items': items.map((e) => e.toOrderItem()).toList(),
      'is_app_order': true,
      'delivery_method': delivery.apiValue,
      if (note != null && note.isNotEmpty) 'note': note,
      if (coupon != null && coupon.isNotEmpty) 'coupon': coupon,
      if (shippingMethod != null && shippingMethod.isNotEmpty)
        'shipping_method': shippingMethod,
    };
    final j = await _api.post('/checkout', body);
    if (j is Map<String, dynamic>) return PlacedOrder.fromJson(j);
    throw const AppError('checkout_failed', 'ثبت سفارش ناموفق بود');
  }
}
