import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gaji_pro/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('DateFormatter', () {
    group('formatDate', () {
      test('should format date to "dd MMMM yyyy" in Indonesian', () {
        final date = DateTime(2026, 2, 16);
        expect(DateFormatter.formatDate(date), '16 Februari 2026');
      });

      test('should format date with custom pattern', () {
        final date = DateTime(2026, 2, 16);
        expect(DateFormatter.formatDate(date, pattern: 'dd/MM/yyyy'), '16/02/2026');
      });

      test('should handle different months correctly', () {
        expect(DateFormatter.formatDate(DateTime(2026, 1, 1)), '01 Januari 2026');
        expect(DateFormatter.formatDate(DateTime(2026, 12, 31)), '31 Desember 2026');
      });
    });

    group('formatTime', () {
      test('should format time to "HH:mm"', () {
        final date = DateTime(2026, 2, 16, 8, 5);
        expect(DateFormatter.formatTime(date), '08:05');
      });

      test('should format time with seconds', () {
        final date = DateTime(2026, 2, 16, 14, 30, 45);
        expect(DateFormatter.formatTime(date, withSeconds: true), '14:30:45');
      });

      test('should handle midnight correctly', () {
        final date = DateTime(2026, 2, 16, 0, 0);
        expect(DateFormatter.formatTime(date), '00:00');
      });
    });

    group('formatDateTime', () {
      test('should format date and time together', () {
        final date = DateTime(2026, 2, 16, 14, 30);
        expect(DateFormatter.formatDateTime(date), '16 Februari 2026, 14:30');
      });

      test('should format with custom separator', () {
        final date = DateTime(2026, 2, 16, 14, 30);
        expect(DateFormatter.formatDateTime(date, separator: ' pukul '), '16 Februari 2026 pukul 14:30');
      });
    });

    group('formatShortDate', () {
      test('should format date to short format "dd MMM yyyy"', () {
        final date = DateTime(2026, 2, 16);
        expect(DateFormatter.formatShortDate(date), '16 Feb 2026');
      });
    });

    group('formatDayDate', () {
      test('should format with day name', () {
        final date = DateTime(2026, 2, 16); // Monday
        expect(DateFormatter.formatDayDate(date), 'Senin, 16 Feb 2026');
      });

      test('should handle different days', () {
        expect(DateFormatter.formatDayDate(DateTime(2026, 2, 15)), 'Minggu, 15 Feb 2026');
        expect(DateFormatter.formatDayDate(DateTime(2026, 2, 17)), 'Selasa, 17 Feb 2026');
      });
    });

    group('formatRelativeDate', () {
      test('should return "Hari ini" for today', () {
        final today = DateTime.now();
        expect(DateFormatter.formatRelativeDate(today), 'Hari ini');
      });

      test('should return "Kemarin" for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateFormatter.formatRelativeDate(yesterday), 'Kemarin');
      });

      test('should return "Besok" for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(DateFormatter.formatRelativeDate(tomorrow), 'Besok');
      });

      test('should return formatted date for other dates', () {
        final otherDate = DateTime.now().subtract(const Duration(days: 5));
        expect(DateFormatter.formatRelativeDate(otherDate), isNot('Hari ini'));
        expect(DateFormatter.formatRelativeDate(otherDate), isNot('Kemarin'));
      });
    });

    group('formatMonthYear', () {
      test('should format to "MMMM yyyy"', () {
        final date = DateTime(2026, 2, 16);
        expect(DateFormatter.formatMonthYear(date), 'Februari 2026');
      });
    });

    group('getGreeting', () {
      test('should return "Selamat Pagi" for morning (5-11)', () {
        expect(DateFormatter.getGreeting(hour: 5), 'Selamat Pagi');
        expect(DateFormatter.getGreeting(hour: 8), 'Selamat Pagi');
        expect(DateFormatter.getGreeting(hour: 11), 'Selamat Pagi');
      });

      test('should return "Selamat Siang" for noon (12-14)', () {
        expect(DateFormatter.getGreeting(hour: 12), 'Selamat Siang');
        expect(DateFormatter.getGreeting(hour: 14), 'Selamat Siang');
      });

      test('should return "Selamat Sore" for afternoon (15-17)', () {
        expect(DateFormatter.getGreeting(hour: 15), 'Selamat Sore');
        expect(DateFormatter.getGreeting(hour: 17), 'Selamat Sore');
      });

      test('should return "Selamat Malam" for evening/night (18-4)', () {
        expect(DateFormatter.getGreeting(hour: 18), 'Selamat Malam');
        expect(DateFormatter.getGreeting(hour: 23), 'Selamat Malam');
        expect(DateFormatter.getGreeting(hour: 0), 'Selamat Malam');
        expect(DateFormatter.getGreeting(hour: 4), 'Selamat Malam');
      });
    });

    group('parseDate', () {
      test('should parse date string to DateTime', () {
        final result = DateFormatter.parseDate('2026-02-16');
        expect(result, isNotNull);
        expect(result!.year, 2026);
        expect(result.month, 2);
        expect(result.day, 16);
      });

      test('should return null for invalid date string', () {
        expect(DateFormatter.parseDate('invalid'), isNull);
        expect(DateFormatter.parseDate(''), isNull);
      });

      test('should parse with custom format', () {
        final result = DateFormatter.parseDate('16/02/2026', format: 'dd/MM/yyyy');
        expect(result, isNotNull);
        expect(result!.day, 16);
        expect(result.month, 2);
        expect(result.year, 2026);
      });
    });

    group('getDayName', () {
      test('should return Indonesian day name', () {
        expect(DateFormatter.getDayName(DateTime(2026, 2, 16)), 'Senin');
        expect(DateFormatter.getDayName(DateTime(2026, 2, 15)), 'Minggu');
      });
    });

    group('getMonthName', () {
      test('should return Indonesian month name', () {
        expect(DateFormatter.getMonthName(1), 'Januari');
        expect(DateFormatter.getMonthName(2), 'Februari');
        expect(DateFormatter.getMonthName(12), 'Desember');
      });

      test('should return empty for invalid month', () {
        expect(DateFormatter.getMonthName(0), '');
        expect(DateFormatter.getMonthName(13), '');
      });
    });

    group('formatDuration', () {
      test('should format minutes to hours and minutes', () {
        expect(DateFormatter.formatDuration(90), '1j 30m');
        expect(DateFormatter.formatDuration(60), '1j 0m');
        expect(DateFormatter.formatDuration(30), '0j 30m');
      });

      test('should handle zero minutes', () {
        expect(DateFormatter.formatDuration(0), '0j 0m');
      });
    });

    group('formatWorkHours', () {
      test('should format work hours with total', () {
        expect(DateFormatter.formatWorkHours(270, 480), '4j 30m / 8j');
        expect(DateFormatter.formatWorkHours(480, 480), '8j 0m / 8j');
      });

      test('should handle zero values', () {
        expect(DateFormatter.formatWorkHours(0, 480), '0j 0m / 8j');
        expect(DateFormatter.formatWorkHours(0, 0), '0j 0m / 0j');
      });
    });
  });
}
