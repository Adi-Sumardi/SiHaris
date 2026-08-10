import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan biometric unlock (Face ID / Fingerprint) berbasis `local_auth`.
///
/// Status "aktif/nonaktif" disimpan sebagai preferensi non-sensitif di
/// SharedPreferences. Token tetap di [SecureStorageService] — biometric hanya
/// berperan sebagai gerbang lokal sebelum membuka aplikasi.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  static const String _enabledKey = 'biometric_enabled';
  final LocalAuthentication _auth = LocalAuthentication();

  /// Apakah perangkat punya hardware biometric yang siap dipakai.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      final enrolled = await _auth.getAvailableBiometrics();
      return canCheck && enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Apakah user sudah mengaktifkan biometric unlock di aplikasi.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Aktifkan biometric unlock — wajib lolos autentikasi dulu agar tidak bisa
  /// diaktifkan oleh orang lain.
  Future<bool> enable() async {
    final ok = await authenticate(reason: 'Verifikasi untuk mengaktifkan kunci biometrik');
    if (!ok) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    return true;
  }

  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }

  /// Tampilkan prompt biometric. Mengembalikan `true` jika lolos.
  Future<bool> authenticate({
    String reason = 'Verifikasi identitas Anda untuk masuk',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // izinkan fallback PIN/pola perangkat
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
