import '../core/api_client.dart';
import '../core/app_error.dart';
import '../models/customer.dart';

/// Orders backend: list, detail, statuses (Issue #2 Step 6).
/// All calls JWT-scoped server-side — user A never sees user B orders.
class OrdersService {
  OrdersService(this._api);
  final ApiClient _api;

  static List<OrderSummary> _parseList(dynamic j) {
    final list = j is List
        ? j
        : (j is Map<String, dynamic>
            ? (j['data'] ?? j['orders'])
            : null);
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(OrderSummary.fromJson)
          .where((o) => o.id != 0)
          .toList();
    }
    return const [];
  }

  Future<List<OrderSummary>> getOrders() async {
    try {
      return _parseList(await _api.get('/orders'));
    } on AppError {
      rethrow;
    }
  }

  Future<OrderDetail?> getOrder(int id) async {
    try {
      final j = await _api.get('/orders/$id');
      if (j is Map<String, dynamic>) return OrderDetail.fromJson(j);
      return null;
    } on AppError {
      rethrow;
    }
  }

  /// GET /orders/statuses -> {slug: label} for human labels.
  Future<Map<String, String>> getStatuses() async {
    try {
      final j = await _api.get('/orders/statuses');
      final map = j is Map<String, dynamic>
          ? (j['data'] is Map ? j['data'] as Map : j)
          : null;
      if (map == null) return const {};
      final out = <String, String>{};
      map.forEach((k, v) {
        if (v is String) {
          out[k.toString()] = v;
        } else if (v is Map && v['label'] != null) {
          out[k.toString()] = v['label'].toString();
        }
      });
      return out;
    } on AppError {
      rethrow;
    }
  }
}

/// Customer backend: GET/PUT /customer (Step 6).
class CustomerService {
  CustomerService(this._api);
  final ApiClient _api;

  Future<Customer?> getCustomer() async {
    try {
      final j = await _api.get('/customer');
      if (j is Map<String, dynamic>) return Customer.fromJson(j);
      return null;
    } on AppError {
      rethrow;
    }
  }

  Future<Customer?> updateCustomer(Customer c) async {
    final j = await _api.put('/customer', c.toUpdate());
    if (j is Map<String, dynamic>) return Customer.fromJson(j);
    return null;
  }

  /// DELETE /customer — account + data deletion (store compliance).
  Future<void> deleteAccount() async {
    await _api.delete('/customer');
  }
}
