/// Model untuk daftar bukti potong 1721-A1
class TaxFormModel {
  final int id;
  final String formNumber;
  final int taxYear;
  final String employeeName;
  final double grossSalary;
  final String formattedGrossSalary;
  final double totalPph21Withheld;
  final String formattedPph21;
  final String? generatedAt;

  const TaxFormModel({
    required this.id,
    required this.formNumber,
    required this.taxYear,
    required this.employeeName,
    required this.grossSalary,
    required this.formattedGrossSalary,
    required this.totalPph21Withheld,
    required this.formattedPph21,
    this.generatedAt,
  });

  factory TaxFormModel.fromJson(Map<String, dynamic> json) {
    return TaxFormModel(
      id: json['id'],
      formNumber: json['form_number'],
      taxYear: json['tax_year'],
      employeeName: json['employee_name'],
      grossSalary: (json['gross_salary'] as num).toDouble(),
      formattedGrossSalary: json['formatted_gross_salary'],
      totalPph21Withheld: (json['total_pph21_withheld'] as num).toDouble(),
      formattedPph21: json['formatted_pph21'],
      generatedAt: json['generated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form_number': formNumber,
      'tax_year': taxYear,
      'employee_name': employeeName,
      'gross_salary': grossSalary,
      'formatted_gross_salary': formattedGrossSalary,
      'total_pph21_withheld': totalPph21Withheld,
      'formatted_pph21': formattedPph21,
      'generated_at': generatedAt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaxFormModel &&
        other.id == id &&
        other.formNumber == formNumber &&
        other.taxYear == taxYear &&
        other.employeeName == employeeName &&
        other.grossSalary == grossSalary &&
        other.totalPph21Withheld == totalPph21Withheld &&
        other.generatedAt == generatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        formNumber.hashCode ^
        taxYear.hashCode ^
        employeeName.hashCode ^
        grossSalary.hashCode ^
        totalPph21Withheld.hashCode ^
        generatedAt.hashCode;
  }
}

/// Model untuk tahun pajak yang tersedia
class TaxFormYearModel {
  final int year;
  final int count;

  const TaxFormYearModel({
    required this.year,
    required this.count,
  });

  factory TaxFormYearModel.fromJson(Map<String, dynamic> json) {
    return TaxFormYearModel(
      year: json['year'],
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'count': count,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaxFormYearModel && other.year == year && other.count == count;
  }

  @override
  int get hashCode => year.hashCode ^ count.hashCode;
}
