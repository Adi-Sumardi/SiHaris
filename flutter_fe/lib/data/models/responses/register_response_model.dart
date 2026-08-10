/// Response model for demo register API
class RegisterResponseModel {
  final bool success;
  final String? message;
  final String? email;
  final String? name;

  RegisterResponseModel({
    required this.success,
    this.message,
    this.email,
    this.name,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return RegisterResponseModel(
      success: json['success'] ?? false,
      message: json['message'],
      email: data?['email'],
      name: data?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'email': email,
        'name': name,
      },
    };
  }
}
