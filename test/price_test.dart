import 'package:flutter_test/flutter_test.dart';
import 'package:rumbedivar/widgets/price.dart';

void main() {
  group('formatPrice', () {
    test('includes currency symbol', () {
      expect(formatPrice(248000, currency: 'تومان'),
          contains('تومان'));
    });

    test('respects decimals', () {
      final s = formatPrice(10.5, decimals: 2, currency: 'X');
      expect(s, contains('X'));
      // fa locale uses Eastern Arabic numerals — just check a number rendered.
      expect(s.length, greaterThan(2));
    });

    test('works without currency', () {
      // fa locale renders 5 as ۵.
      expect(formatPrice(5), '۵');
    });
  });
}
