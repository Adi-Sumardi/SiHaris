class CurrencyFormatter {
  /// Format number to Rupiah (e.g., "Rp 5.000.000")
  static String formatRupiah(
    num amount, {
    bool withSymbol = true,
    String symbol = 'Rp ',
  }) {
    final isNegative = amount < 0;
    final absAmount = amount.abs().round();
    final formatted = _formatNumber(absAmount);

    if (withSymbol) {
      return isNegative ? '-$symbol$formatted' : '$symbol$formatted';
    }
    return isNegative ? '-$formatted' : formatted;
  }

  /// Format to compact (e.g., "Rp 5 jt", "Rp 500 rb")
  static String formatCompact(num amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      if (millions == millions.roundToDouble()) {
        return 'Rp ${millions.round()} jt';
      }
      return 'Rp ${millions.toStringAsFixed(1).replaceAll('.', ',')} jt';
    } else if (amount >= 1000) {
      final thousands = (amount / 1000).round();
      return 'Rp $thousands rb';
    }
    return 'Rp ${amount.round()}';
  }

  /// Parse Rupiah string to number
  static num parseRupiah(String value) {
    if (value.isEmpty) return 0;

    // Remove Rp, spaces, and dots
    String cleaned = value
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .trim();

    // Handle negative
    final isNegative = cleaned.startsWith('-');
    if (isNegative) {
      cleaned = cleaned.substring(1);
    }

    final parsed = int.tryParse(cleaned) ?? 0;
    return isNegative ? -parsed : parsed;
  }

  /// Format with custom separator
  static String formatWithSeparator(num amount, {String separator = '.'}) {
    final formatted = _formatNumber(amount.round());
    if (separator != '.') {
      return formatted.replaceAll('.', separator);
    }
    return formatted;
  }

  /// Format decimal to percentage
  static String formatPercentage(double value, {int decimalPlaces = 0}) {
    final percentage = value * 100;
    if (decimalPlaces == 0) {
      return '${percentage.round()}%';
    }
    return '${percentage.toStringAsFixed(decimalPlaces).replaceAll('.', ',')}%';
  }

  /// Format salary range
  static String formatSalaryRange(num min, num max) {
    final minFormatted = formatCompact(min);
    final maxFormatted = formatCompact(max);

    if (min == max) {
      return minFormatted;
    }
    return '$minFormatted - $maxFormatted';
  }

  /// Format currency input while typing
  static String formatCurrencyInput(String value) {
    if (value.isEmpty) return '';

    // Remove all non-numeric characters
    final numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isEmpty) return '';

    final number = int.tryParse(numericOnly) ?? 0;
    return _formatNumber(number);
  }

  /// Helper to format number with thousand separators
  static String _formatNumber(int number) {
    if (number == 0) return '0';

    final result = StringBuffer();
    final str = number.toString();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(str[i]);
    }

    return result.toString();
  }
}
