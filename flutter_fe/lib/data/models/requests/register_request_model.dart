/// Request model for demo register API
class RegisterRequestModel {
  final String name;
  final String email;
  final String? phone;
  final String password;
  final String passwordConfirmation;

  const RegisterRequestModel({
    required this.name,
    required this.email,
    this.phone,
    required this.password,
    required this.passwordConfirmation,
  });

  /// Convert to JSON map for API request
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }

  /// Validate if the request data is valid
  String? validate() {
    if (name.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (name.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    if (email.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Format email tidak valid';
    }
    if (password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (password.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (password != passwordConfirmation) {
      return 'Konfirmasi password tidak cocok';
    }
    return null;
  }

  bool get isValid => validate() == null;

  @override
  String toString() => 'RegisterRequestModel(name: $name, email: $email)';
}
