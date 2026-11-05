/// Customer DTO per plugin GET /customer, PUT /customer (Step 6).
class Customer {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;

  const Customer({
    this.id = 0,
    this.username = '',
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
  });

  factory Customer.fromJson(Map<String, dynamic> j) {
    final data = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;
    final c = data['customer'] is Map<String, dynamic>
        ? data['customer'] as Map<String, dynamic>
        : data;
    return Customer(
      id: ((c['id']) as num?)?.toInt() ?? 0,
      username: (c['username'] ?? '').toString(),
      email: (c['email'] ?? '').toString(),
      firstName:
          (c['first_name'] ?? c['firstName'] ?? '').toString(),
      lastName: (c['last_name'] ?? c['lastName'] ?? '').toString(),
      phone: (c['phone'] ?? c['billing_phone'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toUpdate() => {
        if (firstName.isNotEmpty) 'first_name': firstName,
        if (lastName.isNotEmpty) 'last_name': lastName,
        if (email.isNotEmpty) 'email': email,
        if (phone.isNotEmpty) 'phone': phone,
      };
}

/// Order list/detail DTOs per GET /orders, GET /orders/{id} (Step 6).
/// Server scopes rows to the JWT user — user A never sees user B orders.
class OrderSummary {
  final int id;
  final String number;
  final String status;
  final double total;
  final String date;
  final int itemCount;

  const OrderSummary({
    required this.id,
    this.number = '',
    this.status = '',
    this.total = 0,
    this.date = '',
    this.itemCount = 0,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) {
    int items = 0;
    final li = j['line_items'] ?? j['items'];
    if (li is List) items = li.length;
    return OrderSummary(
      id: ((j['id']) as num?)?.toInt() ?? 0,
      number: (j['number'] ?? j['id'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      total: ((j['total']) as num?)?.toDouble() ?? 0,
      date: (j['date_created'] ?? j['date'] ?? '').toString(),
      itemCount: items,
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double total;
  const OrderItem({this.name = '', this.quantity = 0, this.total = 0});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: (j['name'] ?? '').toString(),
        quantity: ((j['quantity']) as num?)?.toInt() ?? 0,
        total: ((j['total']) as num?)?.toDouble() ?? 0,
      );
}

class OrderDetail {
  final int id;
  final String number;
  final String status;
  final double total;
  final String date;
  final String paymentMethod;
  final List<OrderItem> items;
  final bool appDiscountApplied;

  const OrderDetail({
    required this.id,
    this.number = '',
    this.status = '',
    this.total = 0,
    this.date = '',
    this.paymentMethod = '',
    this.items = const [],
    this.appDiscountApplied = false,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> j) {
    final data = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;
    final o = data['order'] is Map<String, dynamic>
        ? data['order'] as Map<String, dynamic>
        : data;
    final li = o['line_items'] ?? o['items'];
    bool appFee = (data['app_discount'] ?? o['app_discount']) != null;
    final fees = o['fee_lines'] ?? o['fees'];
    if (fees is List) {
      for (final f in fees) {
        if (f is Map &&
            (f['name'] ?? '').toString().toLowerCase().contains('app discount')) {
          appFee = true;
          break;
        }
      }
    }
    return OrderDetail(
      id: ((o['id']) as num?)?.toInt() ?? 0,
      number: (o['number'] ?? o['id'] ?? '').toString(),
      status: (o['status'] ?? '').toString(),
      total: ((o['total']) as num?)?.toDouble() ?? 0,
      date: (o['date_created'] ?? o['date'] ?? '').toString(),
      paymentMethod: (o['payment_method_title'] ??
              o['payment_method'] ??
              '')
          .toString(),
      items: li is List
          ? li
              .whereType<Map<String, dynamic>>()
              .map(OrderItem.fromJson)
              .toList()
          : const [],
      appDiscountApplied: appFee,
    );
  }
}
