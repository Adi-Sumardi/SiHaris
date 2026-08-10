import 'package:intl/intl.dart';

class DateFormatter {
  static const List<String> _monthNames = [
    '', // index 0 unused
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _dayNames = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  /// Format date to "dd MMMM yyyy" (e.g., "16 Februari 2026")
  static String formatDate(DateTime date, {String? pattern}) {
    if (pattern != null) {
      return DateFormat(pattern, 'id_ID').format(date);
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthNames[date.month];
    final year = date.year;
    return '$day $month $year';
  }

  /// Format time to "HH:mm" or "HH:mm:ss"
  static String formatTime(DateTime date, {bool withSeconds = false}) {
    if (withSeconds) {
      return DateFormat('HH:mm:ss').format(date);
    }
    return DateFormat('HH:mm').format(date);
  }

  /// Format date and time together
  static String formatDateTime(DateTime date, {String separator = ', '}) {
    return '${formatDate(date)}$separator${formatTime(date)}';
  }

  /// Format to short date "dd MMM yyyy" (e.g., "16 Feb 2026")
  static String formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthNames[date.month].substring(0, 3);
    final year = date.year;
    return '$day $month $year';
  }

  /// Format with day name "Senin, 16 Feb 2026"
  static String formatDayDate(DateTime date) {
    final dayName = _dayNames[date.weekday % 7];
    final shortDate = formatShortDate(date);
    return '$dayName, $shortDate';
  }

  /// Format relative date (Hari ini, Kemarin, Besok, or formatted date)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(date.year, date.month, date.day);
    final difference = inputDate.difference(today).inDays;

    if (difference == 0) {
      return 'Hari ini';
    } else if (difference == -1) {
      return 'Kemarin';
    } else if (difference == 1) {
      return 'Besok';
    } else {
      return formatDayDate(date);
    }
  }

  /// Format to "MMMM yyyy" (e.g., "Februari 2026")
  static String formatMonthYear(DateTime date) {
    return '${_monthNames[date.month]} ${date.year}';
  }

  /// Get greeting based on hour
  static String getGreeting({int? hour}) {
    final h = hour ?? DateTime.now().hour;
    if (h >= 5 && h < 12) {
      return 'Selamat Pagi';
    } else if (h >= 12 && h < 15) {
      return 'Selamat Siang';
    } else if (h >= 15 && h < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  /// Parse date string to DateTime
  static DateTime? parseDate(String dateString, {String format = 'yyyy-MM-dd'}) {
    if (dateString.isEmpty) return null;
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get Indonesian day name
  static String getDayName(DateTime date) {
    return _dayNames[date.weekday % 7];
  }

  /// Get Indonesian month name
  static String getMonthName(int month) {
    if (month < 1 || month > 12) return '';
    return _monthNames[month];
  }

  /// Format minutes to "Xj Ym" format
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}j ${mins}m';
  }

  /// Format work hours with total "4j 30m / 8j"
  static String formatWorkHours(int workedMinutes, int requiredMinutes) {
    final worked = formatDuration(workedMinutes);
    final requiredHours = requiredMinutes ~/ 60;
    return '$worked / ${requiredHours}j';
  }
}
