import '../models/product.dart';

/// Local cart item — price snapshot from catalog at add time.
/// Server totals remain authoritative at POST /checkout (Step 5).
class CartItem {
  final int productId;
  final String name;
  final String image;
  final String priceRaw;
  final double unitPrice;
  final int quantity;

  const CartItem({
    required this.productId,
    this.name = '',
    this.image = '',
    this.priceRaw = '',
    this.unitPrice = 0,
    this.quantity = 1,
  });

  static double _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  factory CartItem.fromProduct(Product p, {int qty = 1}) {
    final raw = p.salePrice.isNotEmpty
        ? p.salePrice
        : (p.price.isNotEmpty ? p.price : p.regularPrice);
    return CartItem(
      productId: p.id,
      name: p.name,
      image: p.image,
      priceRaw: raw,
      unitPrice: _parsePrice(raw),
      quantity: qty,
    );
  }

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        name: name,
        image: image,
        priceRaw: priceRaw,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
      );

  double get total => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'image': image,
        'priceRaw': priceRaw,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        productId: ((j['product_id'] ?? j['productId'] ?? 0) as num?)?.toInt() ?? 0,
        name: (j['name'] ?? '').toString(),
        image: (j['image'] ?? '').toString(),
        priceRaw: (j['priceRaw'] ?? '').toString(),
        unitPrice: ((j['unitPrice'] ?? 0) as num?)?.toDouble() ?? 0,
        quantity: ((j['quantity'] ?? 1) as num?)?.toInt() ?? 1,
      );

  /// Payload shape for POST /checkout and POST /orders {items[]}.
  Map<String, dynamic> toOrderItem() => {
        'product_id': productId,
        'quantity': quantity,
      };
}
