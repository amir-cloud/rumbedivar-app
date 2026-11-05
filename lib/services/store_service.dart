import '../core/api_client.dart';
import '../core/app_error.dart';
import '../models/store_config.dart';

/// Boot fetch GET /store + GET /config (Issue #2 Step 0/2).
/// 24h cache is handled upstream by bootProvider memoization;
/// network failures fall back to defaults so splash never blocks.
class StoreService {
  StoreService(this._api);
  final ApiClient _api;

  Future<({StoreInfo store, AppConfig config})> loadBoot(
      {bool force = false}) async {
    StoreInfo store = const StoreInfo();
    AppConfig config = const AppConfig();
    try {
      final sJson = await _api.get('/store') as dynamic;
      if (sJson is Map<String, dynamic>) {
        store = StoreInfo.fromJson(sJson);
      }
    } on AppError {
      // Keep defaults; UI renders friendly disabled message upstream.
    }
    try {
      final cJson = await _api.get('/config') as dynamic;
      if (cJson is Map<String, dynamic>) {
        config = AppConfig.fromJson(cJson);
      }
    } on AppError {
      // Keep defaults.
    }
    return (store: store, config: config);
  }
}
