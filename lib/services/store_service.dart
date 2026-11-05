import '../core/api_client.dart';
import '../core/app_error.dart';
import '../models/landing.dart';
import '../models/store_config.dart';

/// Boot fetch GET /store + GET /config + GET /landing (Issue #2 Step 0/2).
/// Failures fall back to defaults so splash never blocks offline.
class StoreService {
  StoreService(this._api);
  final ApiClient _api;

  Future<({StoreInfo store, AppConfig config, LandingData landing})>
      loadBoot({bool force = false}) async {
    StoreInfo store = const StoreInfo();
    AppConfig config = const AppConfig();
    LandingData landing = const LandingData();
    try {
      final results = await Future.wait([
        _api.get('/store'),
        _api.get('/config'),
        _api.get('/landing'),
      ]);
      final sJson = results[0];
      final cJson = results[1];
      final lJson = results[2];
      if (sJson is Map<String, dynamic>) {
        store = StoreInfo.fromJson(sJson);
      }
      if (cJson is Map<String, dynamic>) {
        config = AppConfig.fromJson(cJson);
      }
      if (lJson is Map<String, dynamic>) {
        landing = LandingData.fromJson(lJson);
      }
    } on AppError {
      // Keep defaults.
    } catch (_) {
      // Keep defaults.
    }
    return (store: store, config: config, landing: landing);
  }

  /// Banner helper GET /ordering/app-discount?subtotal=
  Future<AppDiscount?> appDiscount(double subtotal) async {
    try {
      final j =
          await _api.get('/ordering/app-discount?subtotal=$subtotal');
      if (j is Map<String, dynamic>) return AppDiscount.fromJson(j);
    } on AppError {
      return null;
    }
    return null;
  }
}
