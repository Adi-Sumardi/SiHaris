import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('should return null for valid email', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
        expect(Validators.validateEmail('user.name@domain.co.id'), isNull);
        expect(Validators.validateEmail('user+tag@example.org'), isNull);
      });

      test('should return error for empty email', () {
        expect(Validators.validateEmail(''), isNotNull);
        expect(Validators.validateEmail(null), isNotNull);
      });

      test('should return error for invalid email format', () {
        expect(Validators.validateEmail('invalid'), isNotNull);
        expect(Validators.validateEmail('invalid@'), isNotNull);
        expect(Validators.validateEmail('@example.com'), isNotNull);
        expect(Validators.validateEmail('invalid@.com'), isNotNull);
      });
    });

    group('validatePassword', () {
      test('should return null for valid password', () {
        expect(Validators.validatePassword('password123'), isNull);
        expect(Validators.validatePassword('MyPass123'), isNull);
      });

      test('should return error for empty password', () {
        expect(Validators.validatePassword(''), isNotNull);
        expect(Validators.validatePassword(null), isNotNull);
      });

      test('should return error for short password', () {
        expect(Validators.validatePassword('123'), isNotNull);
        expect(Validators.validatePassword('short'), isNotNull);
      });

      test('should allow custom min length', () {
        expect(Validators.validatePassword('12345678', minLength: 8), isNull);
        expect(Validators.validatePassword('1234567', minLength: 8), isNotNull);
      });
    });

    group('validateRequired', () {
      test('should return null for non-empty value', () {
        expect(Validators.validateRequired('some value'), isNull);
        expect(Validators.validateRequired('  text  '), isNull);
      });

      test('should return error for empty or null value', () {
        expect(Validators.validateRequired(''), isNotNull);
        expect(Validators.validateRequired(null), isNotNull);
        expect(Validators.validateRequired('   '), isNotNull);
      });

      test('should use custom field name in error message', () {
        final error = Validators.validateRequired('', fieldName: 'Nama');
        expect(error, contains('Nama'));
      });
    });

    group('validatePhone', () {
      test('should return null for valid phone number', () {
        expect(Validators.validatePhone('08123456789'), isNull);
        expect(Validators.validatePhone('+6281234567890'), isNull);
        expect(Validators.validatePhone('081234567890'), isNull);
      });

      test('should return error for empty phone', () {
        expect(Validators.validatePhone(''), isNotNull);
        expect(Validators.validatePhone(null), isNotNull);
      });

      test('should return error for invalid phone format', () {
        expect(Validators.validatePhone('123'), isNotNull);
        expect(Validators.validatePhone('abcdefghijk'), isNotNull);
        expect(Validators.validatePhone('12345'), isNotNull);
      });
    });

    group('validateConfirmPassword', () {
      test('should return null when passwords match', () {
        expect(Validators.validateConfirmPassword('password123', 'password123'), isNull);
      });

      test('should return error when passwords do not match', () {
        expect(Validators.validateConfirmPassword('password123', 'different'), isNotNull);
      });

      test('should return error for empty confirm password', () {
        expect(Validators.validateConfirmPassword('', 'password123'), isNotNull);
        expect(Validators.validateConfirmPassword(null, 'password123'), isNotNull);
      });
    });

    group('validateMinLength', () {
      test('should return null when value meets min length', () {
        expect(Validators.validateMinLength('hello', 5), isNull);
        expect(Validators.validateMinLength('hello world', 5), isNull);
      });

      test('should return error when value is too short', () {
        expect(Validators.validateMinLength('hi', 5), isNotNull);
      });

      test('should return error for empty value', () {
        expect(Validators.validateMinLength('', 5), isNotNull);
        expect(Validators.validateMinLength(null, 5), isNotNull);
      });
    });

    group('validateMaxLength', () {
      test('should return null when value is within max length', () {
        expect(Validators.validateMaxLength('hello', 10), isNull);
        expect(Validators.validateMaxLength('hi', 10), isNull);
      });

      test('should return error when value exceeds max length', () {
        expect(Validators.validateMaxLength('hello world', 5), isNotNull);
      });

      test('should return null for empty value', () {
        expect(Validators.validateMaxLength('', 10), isNull);
        expect(Validators.validateMaxLength(null, 10), isNull);
      });
    });

    group('validateNumeric', () {
      test('should return null for valid numeric string', () {
        expect(Validators.validateNumeric('12345'), isNull);
        expect(Validators.validateNumeric('0'), isNull);
      });

      test('should return error for non-numeric string', () {
        expect(Validators.validateNumeric('abc'), isNotNull);
        expect(Validators.validateNumeric('12.34'), isNotNull);
        expect(Validators.validateNumeric('12a34'), isNotNull);
      });

      test('should return error for empty value', () {
        expect(Validators.validateNumeric(''), isNotNull);
        expect(Validators.validateNumeric(null), isNotNull);
      });
    });

    group('validateEmployeeId', () {
      test('should return null for valid employee ID', () {
        expect(Validators.validateEmployeeId('EMP001'), isNull);
        expect(Validators.validateEmployeeId('12345'), isNull);
        expect(Validators.validateEmployeeId('ABC-123'), isNull);
      });

      test('should return error for empty employee ID', () {
        expect(Validators.validateEmployeeId(''), isNotNull);
        expect(Validators.validateEmployeeId(null), isNotNull);
      });

      test('should return error for too short employee ID', () {
        expect(Validators.validateEmployeeId('AB'), isNotNull);
      });
    });

    group('validateAmount', () {
      test('should return null for valid amount', () {
        expect(Validators.validateAmount('5000000'), isNull);
        expect(Validators.validateAmount('1000'), isNull);
      });

      test('should return error for zero or negative', () {
        expect(Validators.validateAmount('0'), isNotNull);
        expect(Validators.validateAmount('-1000'), isNotNull);
      });

      test('should return error for empty value', () {
        expect(Validators.validateAmount(''), isNotNull);
        expect(Validators.validateAmount(null), isNotNull);
      });

      test('should validate with minimum amount', () {
        expect(Validators.validateAmount('50000', minAmount: 100000), isNotNull);
        expect(Validators.validateAmount('100000', minAmount: 100000), isNull);
      });
    });
  });
}
