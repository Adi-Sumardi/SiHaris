import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    group('formatRupiah', () {
      test('should format number to Rupiah with Rp prefix', () {
        expect(CurrencyFormatter.formatRupiah(5000000), 'Rp 5.000.000');
        expect(CurrencyFormatter.formatRupiah(1000), 'Rp 1.000');
        expect(CurrencyFormatter.formatRupiah(500), 'Rp 500');
      });

      test('should handle zero', () {
        expect(CurrencyFormatter.formatRupiah(0), 'Rp 0');
      });

      test('should handle decimal values', () {
        expect(CurrencyFormatter.formatRupiah(5000000.50), 'Rp 5.000.001');
        expect(CurrencyFormatter.formatRupiah(1234.99), 'Rp 1.235');
      });

      test('should handle negative values', () {
        expect(CurrencyFormatter.formatRupiah(-5000000), '-Rp 5.000.000');
      });

      test('should format without symbol when specified', () {
        expect(CurrencyFormatter.formatRupiah(5000000, withSymbol: false), '5.000.000');
      });

      test('should format with custom symbol', () {
        expect(CurrencyFormatter.formatRupiah(5000000, symbol: 'IDR '), 'IDR 5.000.000');
      });
    });

    group('formatCompact', () {
      test('should format millions as "jt"', () {
        expect(CurrencyFormatter.formatCompact(5000000), 'Rp 5 jt');
        expect(CurrencyFormatter.formatCompact(10500000), 'Rp 10,5 jt');
        expect(CurrencyFormatter.formatCompact(1000000), 'Rp 1 jt');
      });

      test('should format thousands as "rb"', () {
        expect(CurrencyFormatter.formatCompact(500000), 'Rp 500 rb');
        expect(CurrencyFormatter.formatCompact(150000), 'Rp 150 rb');
        expect(CurrencyFormatter.formatCompact(1000), 'Rp 1 rb');
      });

      test('should format hundreds normally', () {
        expect(CurrencyFormatter.formatCompact(500), 'Rp 500');
        expect(CurrencyFormatter.formatCompact(999), 'Rp 999');
      });

      test('should handle zero', () {
        expect(CurrencyFormatter.formatCompact(0), 'Rp 0');
      });
    });

    group('parseRupiah', () {
      test('should parse Rupiah string to number', () {
        expect(CurrencyFormatter.parseRupiah('Rp 5.000.000'), 5000000);
        expect(CurrencyFormatter.parseRupiah('Rp 1.000'), 1000);
        expect(CurrencyFormatter.parseRupiah('500'), 500);
      });

      test('should handle string without Rp prefix', () {
        expect(CurrencyFormatter.parseRupiah('5.000.000'), 5000000);
        expect(CurrencyFormatter.parseRupiah('1.000'), 1000);
      });

      test('should return 0 for empty or invalid string', () {
        expect(CurrencyFormatter.parseRupiah(''), 0);
        expect(CurrencyFormatter.parseRupiah('invalid'), 0);
      });

      test('should handle negative values', () {
        expect(CurrencyFormatter.parseRupiah('-Rp 5.000.000'), -5000000);
        expect(CurrencyFormatter.parseRupiah('-5.000.000'), -5000000);
      });
    });

    group('formatWithSeparator', () {
      test('should format with custom thousand separator', () {
        expect(CurrencyFormatter.formatWithSeparator(5000000), '5.000.000');
        expect(CurrencyFormatter.formatWithSeparator(1000), '1.000');
        expect(CurrencyFormatter.formatWithSeparator(500), '500');
      });

      test('should use comma as separator when specified', () {
        expect(CurrencyFormatter.formatWithSeparator(5000000, separator: ','), '5,000,000');
      });
    });

    group('formatPercentage', () {
      test('should format decimal to percentage', () {
        expect(CurrencyFormatter.formatPercentage(0.5), '50%');
        expect(CurrencyFormatter.formatPercentage(0.75), '75%');
        expect(CurrencyFormatter.formatPercentage(1.0), '100%');
      });

      test('should handle decimal percentages', () {
        expect(CurrencyFormatter.formatPercentage(0.555, decimalPlaces: 1), '55,5%');
        expect(CurrencyFormatter.formatPercentage(0.3333, decimalPlaces: 2), '33,33%');
      });

      test('should handle zero', () {
        expect(CurrencyFormatter.formatPercentage(0), '0%');
      });

      test('should handle values over 100%', () {
        expect(CurrencyFormatter.formatPercentage(1.5), '150%');
      });
    });

    group('formatSalaryRange', () {
      test('should format salary range', () {
        expect(CurrencyFormatter.formatSalaryRange(5000000, 8000000), 'Rp 5 jt - Rp 8 jt');
        expect(CurrencyFormatter.formatSalaryRange(3000000, 5000000), 'Rp 3 jt - Rp 5 jt');
      });

      test('should handle same min and max', () {
        expect(CurrencyFormatter.formatSalaryRange(5000000, 5000000), 'Rp 5 jt');
      });
    });

    group('formatCurrencyInput', () {
      test('should format while typing', () {
        expect(CurrencyFormatter.formatCurrencyInput('5000000'), '5.000.000');
        expect(CurrencyFormatter.formatCurrencyInput('1000'), '1.000');
        expect(CurrencyFormatter.formatCurrencyInput('500'), '500');
      });

      test('should remove non-numeric characters', () {
        expect(CurrencyFormatter.formatCurrencyInput('Rp 5.000'), '5.000');
        expect(CurrencyFormatter.formatCurrencyInput('abc123'), '123');
      });

      test('should handle empty input', () {
        expect(CurrencyFormatter.formatCurrencyInput(''), '');
      });
    });
  });
}
