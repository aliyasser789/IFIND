import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ── Pending email verification ─────────────────────────────────────────────
  // Saved after register; deleted after successful email verification.
  // Used by SplashScreen to redirect unverified users back to the verify screen.

  static const _pendingEmailKey = 'pending_verification_email';

  Future<String?> getPendingEmail() async {
    return await _storage.read(key: _pendingEmailKey);
  }

  Future<void> savePendingEmail(String email) async {
    await _storage.write(key: _pendingEmailKey, value: email);
  }

  Future<void> deletePendingEmail() async {
    await _storage.delete(key: _pendingEmailKey);
  }
}
