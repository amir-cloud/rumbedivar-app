import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

/// Central price formatting (Issue #2 Step 7).
/// Uses store currency_symbol + num_decimals, Persian locale.
String formatPrice(num value, {String currency = '', int decimals = 0}) {
  try {
    final f = intl.NumberFormat.decimalPattern('fa');
    f.minimumFractionDigits = decimals;
    f.maximumFractionDigits = decimals;
    final n = f.format(value);
    return currency.isEmpty ? n : '$n $currency';
  } catch (_) {
    return currency.isEmpty ? '$value' : '$value $currency';
  }
}

class PriceText extends StatelessWidget {
  const PriceText(this.value,
      {super.key, this.currency = '', this.decimals = 0, this.style});
  final num value;
  final String currency;
  final int decimals;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatPrice(value, currency: currency, decimals: decimals),
      style: style,
      textDirection: TextDirection.rtl,
    );
  }
}

/// Raw server price string + currency (catalog PDP style).
class RawPriceText extends StatelessWidget {
  const RawPriceText(this.raw,
      {super.key, this.currency = '', this.style, this.lineThrough = false});
  final String raw;
  final String currency;
  final TextStyle? style;
  final bool lineThrough;

  @override
  Widget build(BuildContext context) {
    final text = raw.isEmpty
        ? '—'
        : (currency.isEmpty ? raw : '$raw $currency');
    return Text(
      text,
      style: lineThrough
          ? (style ?? const TextStyle()).copyWith(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            )
          : style,
      textDirection: TextDirection.rtl,
    );
  }
}
