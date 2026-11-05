import 'package:flutter_test/flutter_test.dart';
import 'package:rumbedivar/models/cart.dart';
import 'package:rumbedivar/models/customer.dart';
import 'package:rumbedivar/models/order.dart';
import 'package:rumbedivar/models/product.dart';
import 'package:rumbedivar/models/store_config.dart';

void main() {
  group('ProductQuery', () {
    test('defaults to page 1, per_page 12', () {
      final p = const ProductQuery().toParams();
      expect(p['page'], '1');
      expect(p['per_page'], '12');
    });

    test('never sends include_hidden', () {
      final p = const ProductQuery(
              search: 'x', featured: true, onSale: true)
          .toParams();
      expect(p.containsKey('include_hidden'), isFalse);
      expect(p['search'], 'x');
      expect(p['featured'], 'true');
      expect(p['on_sale'], 'true');
    });
  });

  group('CartItem', () {
    Product prod() => const Product(
          id: 7,
          name: 't',
          price: '100',
          salePrice: '80',
          regularPrice: '100',
        );

    test('prefers sale price snapshot', () {
      final item = CartItem.fromProduct(prod(), qty: 2);
      expect(item.unitPrice, 80);
      expect(item.total, 160);
    });

    test('toOrderItem shape for checkout', () {
      final m = CartItem.fromProduct(prod()).toOrderItem();
      expect(m, {'product_id': 7, 'quantity': 1});
    });

    test('round-trips through json', () {
      final item = CartItem.fromProduct(prod(), qty: 3);
      final back = CartItem.fromJson(item.toJson());
      expect(back.productId, 7);
      expect(back.quantity, 3);
      expect(back.total, 240);
    });
  });

  group('PaymentGateway', () {
    test('only cod/bacs/cheque are offline', () {
      expect(
          const PaymentGateway(id: 'cod').isOffline, isTrue);
      expect(
          const PaymentGateway(id: 'bacs').isOffline, isTrue);
      expect(
          const PaymentGateway(id: 'cheque').isOffline, isTrue);
      expect(const PaymentGateway(id: 'paypal').isOffline,
          isFalse);
    });
  });

  group('AppConfig.filterOn', () {
    test('defaults to visible', () {
      const c = AppConfig();
      expect(c.filterOn('featured'), isTrue);
    });

    test('explicit false hides', () {
      const c = AppConfig(filterFlags: {'filter_featured': false});
      expect(c.filterOn('featured'), isFalse);
      expect(c.filterOn('on_sale'), isTrue);
    });
  });

  group('StoreInfo', () {
    test('defaults keep app bootable offline', () {
      const s = StoreInfo();
      expect(s.currencySymbol.isNotEmpty, isTrue);
      expect(s.maxQuantityPerItem, greaterThan(0));
    });
  });

  group('OrderSummary', () {
    test('drops rows with id 0 (hidden products)', () {
      final o = OrderSummary.fromJson({'id': 0, 'status': 'x'});
      expect(o.id, 0);
    });
  });
}
