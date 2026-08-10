class PayslipModel {
  final int id;
  final int payrollId;
  final String period;
  final int periodMonth;
  final int periodYear;
  final int netSalary;
  final String formattedNetSalary;
  final String paymentDate;
  final String status;

  const PayslipModel({
    required this.id,
    required this.payrollId,
    required this.period,
    required this.periodMonth,
    required this.periodYear,
    required this.netSalary,
    required this.formattedNetSalary,
    required this.paymentDate,
    required this.status,
  });

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    return PayslipModel(
      id: json['id'] ?? 0,
      payrollId: json['payroll_id'] ?? 0,
      period: json['period'] ?? '',
      periodMonth: json['period_month'] ?? 0,
      periodYear: json['period_year'] ?? 0,
      netSalary: json['net_salary'] ?? 0,
      formattedNetSalary: json['formatted_net_salary'] ?? '',
      paymentDate: json['payment_date'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payroll_id': payrollId,
      'period': period,
      'period_month': periodMonth,
      'period_year': periodYear,
      'net_salary': netSalary,
      'formatted_net_salary': formattedNetSalary,
      'payment_date': paymentDate,
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PayslipModel &&
        other.id == id &&
        other.payrollId == payrollId &&
        other.period == period &&
        other.periodMonth == periodMonth &&
        other.periodYear == periodYear &&
        other.netSalary == netSalary &&
        other.formattedNetSalary == formattedNetSalary &&
        other.paymentDate == paymentDate &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        payrollId.hashCode ^
        period.hashCode ^
        periodMonth.hashCode ^
        periodYear.hashCode ^
        netSalary.hashCode ^
        formattedNetSalary.hashCode ^
        paymentDate.hashCode ^
        status.hashCode;
  }
}
