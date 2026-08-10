class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(
    r'^(\+62|62|0)[0-9]{9,12}$',
  );

  static final RegExp _numericRegex = RegExp(r'^[0-9]+$');

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < minLength) {
      return 'Password minimal $minLength karakter';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    if (!_phoneRegex.hasMatch(value)) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }

  /// Validate confirm password matches
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != password) {
      return 'Konfirmasi password tidak sesuai';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (value.length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return null; // Max length validation allows empty
    }
    if (value.length > maxLength) {
      return '$fieldName maksimal $maxLength karakter';
    }
    return null;
  }

  /// Validate numeric string
  static String? validateNumeric(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (!_numericRegex.hasMatch(value)) {
      return '$fieldName harus berupa angka';
    }
    return null;
  }

  /// Validate employee ID
  static String? validateEmployeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'ID Karyawan tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'ID Karyawan minimal 3 karakter';
    }
    return null;
  }

  /// Validate amount (currency)
  static String? validateAmount(String? value, {int minAmount = 1}) {
    if (value == null || value.isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }

    // Handle negative sign
    final isNegative = value.startsWith('-');
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    final amount = int.tryParse(cleanValue);
    if (amount == null) {
      return 'Jumlah harus berupa angka';
    }

    final actualAmount = isNegative ? -amount : amount;

    if (actualAmount < minAmount) {
      return 'Jumlah minimal Rp ${minAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    }
    return null;
  }
}
