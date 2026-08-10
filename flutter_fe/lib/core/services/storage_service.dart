import 'package:shared_preferences/shared_preferences.dart';

/// Abstract interface for storage operations
abstract class StorageService {
  /// Get stored authentication token
  Future<String?> getToken();

  /// Store authentication token
  Future<bool> setToken(String token);

  /// Remove authentication token
  Future<bool> removeToken();

  /// Get stored refresh token
  Future<String?> getRefreshToken();

  /// Store refresh token
  Future<bool> setRefreshToken(String token);

  /// Remove refresh token
  Future<bool> removeRefreshToken();

  /// Get a string value by key
  Future<String?> getString(String key);

  /// Store a string value
  Future<bool> setString(String key, String value);

  /// Get a boolean value by key
  Future<bool?> getBool(String key);

  /// Store a boolean value
  Future<bool> setBool(String key, bool value);

  /// Get an integer value by key
  Future<int?> getInt(String key);

  /// Store an integer value
  Future<bool> setInt(String key, int value);

  /// Get a double value by key
  Future<double?> getDouble(String key);

  /// Store a double value
  Future<bool> setDouble(String key, double value);

  /// Get a list of strings by key
  Future<List<String>?> getStringList(String key);

  /// Store a list of strings
  Future<bool> setStringList(String key, List<String> value);

  /// Remove a value by key
  Future<bool> remove(String key);

  /// Clear all stored values
  Future<bool> clear();

  /// Check if a key exists
  Future<bool> containsKey(String key);
}

/// Implementation of StorageService using SharedPreferences
class StorageServiceImpl implements StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  final SharedPreferences _prefs;

  StorageServiceImpl(this._prefs);

  @override
  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  @override
  Future<bool> setToken(String token) async {
    return _prefs.setString(_tokenKey, token);
  }

  @override
  Future<bool> removeToken() async {
    return _prefs.remove(_tokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  @override
  Future<bool> setRefreshToken(String token) async {
    return _prefs.setString(_refreshTokenKey, token);
  }

  @override
  Future<bool> removeRefreshToken() async {
    return _prefs.remove(_refreshTokenKey);
  }

  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    return _prefs.setString(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    return _prefs.setBool(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    return _prefs.setInt(key, value);
  }

  @override
  Future<double?> getDouble(String key) async {
    return _prefs.getDouble(key);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    return _prefs.setDouble(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    return _prefs.getStringList(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return _prefs.setStringList(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    return _prefs.remove(key);
  }

  @override
  Future<bool> clear() async {
    return _prefs.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }
}
