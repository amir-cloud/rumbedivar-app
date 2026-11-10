import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart.dart';
import '../models/product.dart';
import 'app_providers.dart';

/// Local cart (Issue #2 Step 4 decision).
/// Riverpod + encrypted storage — survives kill-restart, excluded from
/// Auto Backup, never in plaintext prefs (discreet-commerce PII).
class CartState {
  final List<CartItem> items;
  final bool loaded;
  const CartState({this.items = const [], this.loaded = false});

  double get subtotal =>
      items.fold<double>(0, (s, i) => s + i.total);
  int get count => items.fold<int>(0, (s, i) => s + i.quantity);

  CartState copyWith({List<CartItem>? items, bool? loaded}) =>
      CartState(items: items ?? this.items, loaded: loaded ?? this.loaded);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._ref, [FlutterSecureStorage? storage])
      : _secure = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                  accessibility: KeychainAccessibility.first_unlock_this_device),
            ),
        super(const CartState()) {
    _restore();
  }
  final Ref _ref;
  final FlutterSecureStorage _secure;
  static const _key = 'local_cart_v1';

  int get _maxQty {
    try {
      final boot = _ref.read(bootProvider).maybeWhen(
            data: (b) => b.store.maxQuantityPerItem,
            orElse: () => 99,
          );
      return boot <= 0 ? 99 : boot;
    } catch (_) {
      return 99;
    }
  }

  Future<void> _restore() async {
    try {
      final raw = await _secure.read(key: _key);
      if (raw == null || raw.isEmpty) {
        // Best-effort: wipe legacy plaintext prefs cart if present.
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_key);
        } catch (_) {}
        state = state.copyWith(loaded: true);
        return;
      }
      final list = (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .where((i) => i.productId != 0 && i.quantity > 0)
          .toList();
      state = CartState(items: list, loaded: true);
    } catch (_) {
      state = state.copyWith(loaded: true);
    }
  }

  Future<void> _persist() async {
    try {
      await _secure.write(
          key: _key,
          value: jsonEncode(state.items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  int _clamp(int qty) {
    if (qty < 1) return 1;
    if (qty > _maxQty) return _maxQty;
    return qty;
  }

  Future<void> add(Product p, {int qty = 1}) async {
    final q = _clamp(qty);
    final idx = state.items.indexWhere((e) => e.productId == p.id);
    if (idx >= 0) {
      final cur = state.items[idx];
      final next = List<CartItem>.from(state.items);
      next[idx] = cur.copyWith(quantity: _clamp(cur.quantity + q));
      state = state.copyWith(items: next, loaded: true);
    } else {
      state = state.copyWith(
          items: [...state.items, CartItem.fromProduct(p, qty: q)],
          loaded: true);
    }
    await _persist();
  }

  Future<void> setQty(int productId, int qty) async {
    if (qty <= 0) {
      await remove(productId);
      return;
    }
    final next = state.items
        .map((e) => e.productId == productId
            ? e.copyWith(quantity: _clamp(qty))
            : e)
        .toList();
    state = state.copyWith(items: next, loaded: true);
    await _persist();
  }

  Future<void> remove(int productId) async {
    state = state.copyWith(
        items:
            state.items.where((e) => e.productId != productId).toList(),
        loaded: true);
    await _persist();
  }

  Future<void> clear() async {
    state = const CartState(items: [], loaded: true);
    await _persist();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>(
        (ref) => CartNotifier(ref));
