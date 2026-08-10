/// Request model for change password API
class ChangePasswordRequestModel {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequestModel({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  /// Create instance from JSON map
  factory ChangePasswordRequestModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordRequestModel(
      currentPassword: json['current_password'] ?? '',
      newPassword: json['password'] ?? '',
      confirmPassword: json['password_confirmation'] ?? '',
    );
  }

  /// Convert to JSON map for API request
  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmPassword,
    };
  }

  /// Create a copy with updated values
  ChangePasswordRequestModel copyWith({
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
  }) {
    return ChangePasswordRequestModel(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }

  /// Check if new password matches confirmation
  bool get passwordsMatch => newPassword == confirmPassword;

  /// Validate if the request data is valid
  bool get isValid {
    // Current password must not be empty
    if (currentPassword.isEmpty) return false;
    // New password must be at least 6 characters
    if (newPassword.length < 6) return false;
    // Passwords must match
    if (!passwordsMatch) return false;
    // New password must be different from current
    if (newPassword == currentPassword) return false;
    return true;
  }

  /// Validate and return error message if invalid
  String? validate() {
    if (currentPassword.isEmpty) {
      return 'Password saat ini harus diisi';
    }
    if (newPassword.length < 6) {
      return 'Password baru minimal 6 karakter';
    }
    if (!passwordsMatch) {
      return 'Konfirmasi password tidak cocok';
    }
    if (newPassword == currentPassword) {
      return 'Password baru harus berbeda dari password saat ini';
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangePasswordRequestModel &&
          runtimeType == other.runtimeType &&
          currentPassword == other.currentPassword &&
          newPassword == other.newPassword &&
          confirmPassword == other.confirmPassword;

  @override
  int get hashCode =>
      currentPassword.hashCode ^ newPassword.hashCode ^ confirmPassword.hashCode;

  @override
  String toString() => 'ChangePasswordRequestModel(currentPassword: ***, newPassword: ***)';
}
