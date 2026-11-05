import 'package:shared_preferences/shared_preferences.dart';

// Minimal app-privacy settings. Biometric goes through OS later (TODO: local_auth);
// for MVP we store lock + no-preview toggles only — no new deps.
class AppLockService {
  static const String _lockKey = 'privacy_app_lock';
  static const String _noPreviewKey = 'privacy_no_preview_notif';

  Future<bool> isLockEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_lockKey) ?? false;
  }

  Future<void> setLockEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_lockKey, v);
  }

  Future<bool> isNoPreviewEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_noPreviewKey) ?? true;
  }

  Future<void> setNoPreviewEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_noPreviewKey, v);
  }
}
