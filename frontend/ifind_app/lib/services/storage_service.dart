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

  // ── ID verification status ─────────────────────────────────────────────────
  // Saved after login; used by SplashScreen to redirect users who have a valid
  // token but have not yet completed ID verification.

  static const _idVerifiedKey = 'id_verified';

  Future<bool> getIdVerified() async {
    final value = await _storage.read(key: _idVerifiedKey);
    return value == 'true';
  }

  Future<void> saveIdVerified(bool value) async {
    await _storage.write(key: _idVerifiedKey, value: value ? 'true' : 'false');
  }

  Future<void> deleteIdVerified() async {
    await _storage.delete(key: _idVerifiedKey);
  }

  // ── Logged-in user email ───────────────────────────────────────────────────
  // Saved after login; used by SplashScreen to pass the email to
  // IdVerificationScreen when id_verified=false on relaunch.

  static const _userEmailKey = 'user_email';

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  Future<void> deleteUserEmail() async {
    await _storage.delete(key: _userEmailKey);
  }
}
