import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/secure_storage_service.dart';
import '../models/responses/auth_response_model.dart';
import '../models/responses/office_location_model.dart';
import 'auth_datasource.dart';

class AuthLocalDatasource implements AuthLocalDatasourceBase {
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPositionKey = 'user_position';
  static const String _userDepartmentKey = 'user_department';
  static const String _assignedOfficesKey = 'assigned_offices';

  // Data sensitif (token & face embedding) disimpan terenkripsi.
  final SecureStorageService _secure = SecureStorageService.instance;

  @override
  Future<void> saveAuthData(AuthResponseModel response) async {
    final prefs = await SharedPreferences.getInstance();
    if (response.token != null) {
      await _secure.setToken(response.token!);
    }
    if (response.user != null) {
      await prefs.setInt(_userIdKey, response.user!.id);
      await prefs.setString(_userNameKey, response.user!.name);
      await prefs.setString(_userEmailKey, response.user!.email);
    }
    if (response.employee?.position != null) {
      await prefs.setString(_userPositionKey, response.employee!.position!);
    }
    if (response.employee?.department != null) {
      await prefs.setString(_userDepartmentKey, response.employee!.department!);
    }
    // Save assigned offices
    if (response.employee?.assignedOffices != null) {
      final officesJson = response.employee!.assignedOffices
          .map((o) => o.toJson())
          .toList();
      await prefs.setString(_assignedOfficesKey, jsonEncode(officesJson));
    }
    // Save face embedding from server (for device switching)
    if (response.employee?.faceEmbedding != null &&
        response.employee!.faceEmbedding!.embedding.isNotEmpty) {
      final embeddingString = response.employee!.faceEmbedding!.embedding.join(',');
      await _secure.setFaceEmbedding(embeddingString);
    }
  }

  @override
  Future<String?> getToken() async {
    return _secure.getToken();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> removeAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await _secure.removeToken();
    await _secure.removeFaceEmbedding();
    await prefs.remove('auth_token');
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPositionKey);
    await prefs.remove(_userDepartmentKey);
    await prefs.remove(_assignedOfficesKey);
  }

  /// Save face embedding to local storage (encrypted, comma-separated string)
  Future<void> saveFaceEmbedding(List<double> embedding) async {
    final embeddingString = embedding.join(',');
    await _secure.setFaceEmbedding(embeddingString);
  }

  /// Get face embedding from local storage
  Future<List<double>?> getFaceEmbedding() async {
    final embeddingString = await _secure.getFaceEmbedding();
    if (embeddingString == null || embeddingString.isEmpty) return null;

    try {
      return embeddingString.split(',').map((e) => double.parse(e)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Check if face is enrolled locally
  Future<bool> isFaceEnrolled() async {
    final embedding = await getFaceEmbedding();
    return embedding != null && embedding.isNotEmpty;
  }

  /// Remove face embedding from local storage
  Future<void> removeFaceEmbedding() async {
    await _secure.removeFaceEmbedding();
  }

  /// Save assigned offices to local storage
  @override
  Future<void> saveAssignedOffices(List<OfficeLocationModel> offices) async {
    final prefs = await SharedPreferences.getInstance();
    final officesJson = offices.map((o) => o.toJson()).toList();
    await prefs.setString(_assignedOfficesKey, jsonEncode(officesJson));
  }

  /// Get assigned offices from local storage
  @override
  Future<List<OfficeLocationModel>> getAssignedOffices() async {
    final prefs = await SharedPreferences.getInstance();
    final officesJson = prefs.getString(_assignedOfficesKey);
    if (officesJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(officesJson);
      return decoded
          .map((json) => OfficeLocationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get primary office from local storage
  Future<OfficeLocationModel?> getPrimaryOffice() async {
    final offices = await getAssignedOffices();
    if (offices.isEmpty) return null;

    // Find primary, or return first
    return offices.firstWhere(
      (o) => o.isPrimary,
      orElse: () => offices.first,
    );
  }

  /// Get the employee's position and department, as saved from the last
  /// login/profile response (used by the home screen greeting card).
  Future<({String? position, String? department})> getEmployeeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      position: prefs.getString(_userPositionKey),
      department: prefs.getString(_userDepartmentKey),
    );
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    final userName = prefs.getString(_userNameKey);
    final userEmail = prefs.getString(_userEmailKey);

    if (userId != null && userName != null && userEmail != null) {
      return {
        'id': userId,
        'name': userName,
        'email': userEmail,
      };
    }
    return null;
  }
}
