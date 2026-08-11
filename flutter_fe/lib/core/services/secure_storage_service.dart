import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan terenkripsi untuk data sensitif (token & face embedding).
///
/// Menggunakan Keychain (iOS) dan EncryptedSharedPreferences/Keystore (Android),
/// menggantikan SharedPreferences yang menyimpan data dalam bentuk plaintext.
///
/// Menyediakan migrasi otomatis satu-kali dari SharedPreferences lama agar
/// user yang sudah login tidak ter-logout setelah update aplikasi.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _faceEmbeddingKey = 'face_embedding';
  static const String _deviceIdKey = 'app_device_id';

  // --- Token -----------------------------------------------------------------

  Future<String?> getToken() => _readWithMigration(_tokenKey);

  Future<void> setToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> removeToken() => _storage.delete(key: _tokenKey);

  // --- Face embedding (biometric PII) ----------------------------------------

  Future<String?> getFaceEmbedding() => _readWithMigration(_faceEmbeddingKey);

  Future<void> setFaceEmbedding(String value) =>
      _storage.write(key: _faceEmbeddingKey, value: value);

  Future<void> removeFaceEmbedding() => _storage.delete(key: _faceEmbeddingKey);

  // --- Device ID (stable per app install; used server-side to bind a
  //     device to one employee so it can't be shared to clock in for
  //     several people — see DeviceBindingService on the backend) ----------

  /// Returns the app's device id, generating and persisting a new random one
  /// on first use. Stable across app restarts, reset only on reinstall.
  Future<String> getOrCreateDeviceId() async {
    final existing = await _readWithMigration(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _generateDeviceId();
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // --- Generic helpers -------------------------------------------------------

  Future<void> clear() => _storage.deleteAll();

  /// Baca dari secure storage. Jika kosong tapi nilai legacy masih ada di
  /// SharedPreferences, pindahkan ke secure storage lalu hapus yang lama.
  Future<String?> _readWithMigration(String key) async {
    final secured = await _storage.read(key: key);
    if (secured != null) return secured;

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(key);
    if (legacy != null && legacy.isNotEmpty) {
      await _storage.write(key: key, value: legacy);
      await prefs.remove(key);
      return legacy;
    }
    return null;
  }
}
