import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/landing.dart';
import '../models/store_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/store_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>(
    (ref) => AuthService(api: ref.watch(apiClientProvider)));

final tokenProvider = FutureProvider<String?>((ref) async {
  return ref.watch(authServiceProvider).getToken();
});

final meProvider = FutureProvider<User?>((ref) async {
  return ref.watch(authServiceProvider).getMe();
});

final storeServiceProvider =
    Provider<StoreService>((ref) => StoreService(ref.watch(apiClientProvider)));

final bootProvider = FutureProvider<
    ({StoreInfo store, AppConfig config, LandingData landing})>((ref) async {
  return ref.watch(storeServiceProvider).loadBoot();
});

final discountProvider =
    FutureProvider.family<AppDiscount?, double>((ref, subtotal) async {
  return ref.watch(storeServiceProvider).appDiscount(subtotal);
});
