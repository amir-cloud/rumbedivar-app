/// Store + Config DTOs per plugin rumbedivar/v1 GET /store, GET /config.
class StoreInfo {
  final String currencySymbol;
  final int numDecimals;
  final double minOrderAmount;
  final int maxQuantityPerItem;
  final bool orderingEnabled;

  const StoreInfo({
    this.currencySymbol = 'تومان',
    this.numDecimals = 0,
    this.minOrderAmount = 0,
    this.maxQuantityPerItem = 99,
    this.orderingEnabled = true,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return StoreInfo(
      currencySymbol:
          (data['currency_symbol'] ?? data['currencySymbol'] ?? 'تومان')
              .toString(),
      numDecimals:
          (data['num_decimals'] ?? data['numDecimals'] ?? 0) is num
              ? ((data['num_decimals'] ?? data['numDecimals'] ?? 0) as num)
                  .toInt()
              : 0,
      minOrderAmount: ((data['min_order_amount'] ??
                  data['minOrderAmount'] ??
                  0) as num?)
              ?.toDouble() ??
          0,
      maxQuantityPerItem: ((data['max_quantity_per_item'] ??
                  data['maxQuantityPerItem'] ??
                  99) as num?)
              ?.toInt() ??
          99,
      orderingEnabled: (data['ordering_enabled'] ??
              data['orderingEnabled'] ??
              true) as bool? ??
          true,
    );
  }
}

class AppConfig {
  final bool enableRegistration;
  final bool orderNotesEnabled;
  final Map<String, bool> apiToggles;
  final Map<String, bool> filterFlags;

  const AppConfig({
    this.enableRegistration = true,
    this.orderNotesEnabled = true,
    this.apiToggles = const {},
    this.filterFlags = const {},
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final toggles = <String, bool>{};
    final rawApi = data['api'];
    if (rawApi is Map<String, dynamic>) {
      rawApi.forEach((k, v) {
        if (v is bool) {
          toggles[k] = v;
        } else if (v is Map && v['enabled'] is bool) {
          toggles[k] = v['enabled'] as bool;
        }
      });
    }
    // woocommerce.filter_* flags drive catalog chips (Step 3).
    final filters = <String, bool>{};
    void absorb(Map? m, [String prefix = '']) {
      m?.forEach((k, v) {
        final key = '$prefix$k'.toString();
        if (v is bool) {
          filters[key] = v;
        } else if (v is Map) {
          absorb(v, '$key.');
        }
      });
    }

    absorb(data['woocommerce'] as Map?);
    absorb(data['filters'] as Map?);
    data.forEach((k, v) {
      if (k.toString().startsWith('filter_') && v is bool) {
        filters[k.toString()] = v;
      }
    });
    return AppConfig(
      enableRegistration:
          (data['enable_registration'] ?? data['enableRegistration'] ?? true)
                  as bool? ??
              true,
      orderNotesEnabled:
          (data['order_notes_enabled'] ?? data['orderNotesEnabled'] ?? true)
                  as bool? ??
              true,
      apiToggles: toggles,
      filterFlags: filters,
    );
  }

  bool isDisabled(String key) => apiToggles[key] == false;

  /// Chip visible unless server explicitly disables filter_*.
  bool filterOn(String name, {bool fallback = true}) {
    for (final e in filterFlags.entries) {
      final k = e.key.toLowerCase();
      if (k == 'filter_$name' ||
          k.endsWith('.$name') ||
          k.endsWith('_$name') ||
          k == name) {
        return e.value;
      }
    }
    return fallback;
  }
}
