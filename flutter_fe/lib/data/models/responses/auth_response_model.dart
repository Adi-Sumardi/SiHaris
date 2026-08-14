class AuthResponseModel {
  final bool success;
  final String? message;
  final String? token;
  final UserModel? user;
  final EmployeeModel? employee;
  final CompanyModel? company;

  AuthResponseModel({
    required this.success,
    this.message,
    this.token,
    this.user,
    this.employee,
    this.company,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'],
      token: data?['token'] ?? json['token'],
      user: data?['user'] != null
          ? UserModel.fromJson(data!['user'])
          : (json['user'] != null ? UserModel.fromJson(json['user']) : null),
      employee: data?['employee'] != null
          ? EmployeeModel.fromJson(data!['employee'])
          : null,
      company: data?['company'] != null
          ? CompanyModel.fromJson(data!['company'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'token': token,
        'user': user?.toJson(),
        'employee': employee?.toJson(),
        'company': company?.toJson(),
      },
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthResponseModel &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          message == other.message &&
          token == other.token &&
          user == other.user;

  @override
  int get hashCode =>
      success.hashCode ^ message.hashCode ^ token.hashCode ^ user.hashCode;
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final EmployeeModel? employee;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.employee,
  });

  /// Parses the full GET /auth/profile response data object.
  /// data['data'] = {user: {...}, employee: {...}, company: {...}}
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both flat response (legacy) and nested {user, employee} response
    if (json.containsKey('user')) {
      final userJson = json['user'] as Map<String, dynamic>;
      final employeeJson = json['employee'] as Map<String, dynamic>?;
      return UserModel(
        id: userJson['id'],
        name: userJson['name'] ?? '',
        email: userJson['email'] ?? '',
        employee: employeeJson != null
            ? EmployeeModel.fromJson(employeeJson)
            : null,
      );
    }
    // Flat response fallback (e.g., updateProfile returns user directly)
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (employee != null) 'employee': employee!.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode;
}

class EmployeeModel {
  final int id;
  final String employeeId;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? photo;
  final String? department;
  final String? position;
  final String? hireDate;
  final String? employmentStatus;
  final bool faceEnrolled;
  final FaceEmbeddingModel? faceEmbedding;
  final List<AssignedOfficeModel> assignedOffices;

  EmployeeModel({
    required this.id,
    required this.employeeId,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.phone,
    this.photo,
    this.department,
    this.position,
    this.hireDate,
    this.employmentStatus,
    this.faceEnrolled = false,
    this.faceEmbedding,
    this.assignedOffices = const [],
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      employeeId: json['employee_id'] ?? '',
      fullName: json['full_name'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      photo: json['photo'],
      department: json['department'],
      position: json['position'],
      hireDate: json['hire_date'],
      employmentStatus: json['employment_status'],
      faceEnrolled: json['face_enrolled'] ?? false,
      faceEmbedding: json['face_embedding'] != null
          ? FaceEmbeddingModel.fromJson(json['face_embedding'])
          : null,
      assignedOffices: (json['assigned_offices'] as List<dynamic>?)
              ?.map((e) => AssignedOfficeModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'photo': photo,
      'department': department,
      'position': position,
      'hire_date': hireDate,
      'employment_status': employmentStatus,
      'face_enrolled': faceEnrolled,
      'face_embedding': faceEmbedding?.toJson(),
      'assigned_offices': assignedOffices.map((e) => e.toJson()).toList(),
    };
  }

  /// Get primary office if exists
  AssignedOfficeModel? get primaryOffice {
    try {
      return assignedOffices.firstWhere((o) => o.isPrimary);
    } catch (_) {
      return assignedOffices.isNotEmpty ? assignedOffices.first : null;
    }
  }
}

/// Assigned Office Model - untuk employee.assigned_offices
class AssignedOfficeModel {
  final int id;
  final String name;
  final String? code;
  final double latitude;
  final double longitude;
  final int radius; // in meters
  final bool isPrimary;

  AssignedOfficeModel({
    required this.id,
    required this.name,
    this.code,
    required this.latitude,
    required this.longitude,
    this.radius = 100,
    this.isPrimary = false,
  });

  factory AssignedOfficeModel.fromJson(Map<String, dynamic> json) {
    return AssignedOfficeModel(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'],
      latitude: _parseDouble(json['latitude']) ?? 0,
      longitude: _parseDouble(json['longitude']) ?? 0,
      radius: _parseInt(json['radius']) ?? 100,
      isPrimary: json['is_primary'] ?? false,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'is_primary': isPrimary,
    };
  }
}

/// Face embedding data model for face recognition
class FaceEmbeddingModel {
  final String model;
  final String version;
  final List<double> embedding;

  FaceEmbeddingModel({
    required this.model,
    required this.version,
    required this.embedding,
  });

  factory FaceEmbeddingModel.fromJson(Map<String, dynamic> json) {
    // Support both 'embedding' and 'descriptors' field names
    final embeddingList = json['embedding'] ?? json['descriptors'];
    return FaceEmbeddingModel(
      model: json['model'] ?? '',
      version: json['version'] ?? '',
      embedding: (embeddingList as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'version': version,
      'embedding': embedding,
    };
  }
}

class CompanyModel {
  final int id;
  final String name;
  final String? logo;
  final bool enableFaceRecognition;
  final double faceMatchThreshold;
  final bool enableGpsValidation;

  CompanyModel({
    required this.id,
    required this.name,
    this.logo,
    this.enableFaceRecognition = false,
    this.faceMatchThreshold = 0.48,
    this.enableGpsValidation = true,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'],
      name: json['name'] ?? '',
      logo: json['logo'],
      enableFaceRecognition: json['enable_face_recognition'] ?? false,
      faceMatchThreshold:
          (json['face_match_threshold'] as num?)?.toDouble() ?? 0.6,
      enableGpsValidation: json['enable_gps_validation'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'enable_face_recognition': enableFaceRecognition,
      'face_match_threshold': faceMatchThreshold,
      'enable_gps_validation': enableGpsValidation,
    };
  }
}
