import 'package:flutter/foundation.dart';

class EmployeeInfo {
  final int id;
  final String employeeId;
  final String fullName;
  final String department;
  final String position;

  const EmployeeInfo({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.department,
    required this.position,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? '',
      fullName: json['full_name'] ?? '',
      department: json['department'] ?? '',
      position: json['position'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'full_name': fullName,
      'department': department,
      'position': position,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EmployeeInfo &&
        other.id == id &&
        other.employeeId == employeeId &&
        other.fullName == fullName &&
        other.department == department &&
        other.position == position;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        employeeId.hashCode ^
        fullName.hashCode ^
        department.hashCode ^
        position.hashCode;
  }
}

class EarningItem {
  final String name;
  final int amount;
  final String formattedAmount;

  const EarningItem({
    required this.name,
    required this.amount,
    required this.formattedAmount,
  });

  factory EarningItem.fromJson(Map<String, dynamic> json) {
    return EarningItem(
      name: json['name'] ?? '',
      amount: json['amount'] ?? 0,
      formattedAmount: json['formatted_amount'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'formatted_amount': formattedAmount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EarningItem &&
        other.name == name &&
        other.amount == amount &&
        other.formattedAmount == formattedAmount;
  }

  @override
  int get hashCode {
    return name.hashCode ^ amount.hashCode ^ formattedAmount.hashCode;
  }
}

class DeductionItem {
  final String name;
  final int amount;
  final String formattedAmount;

  const DeductionItem({
    required this.name,
    required this.amount,
    required this.formattedAmount,
  });

  factory DeductionItem.fromJson(Map<String, dynamic> json) {
    return DeductionItem(
      name: json['name'] ?? '',
      amount: json['amount'] ?? 0,
      formattedAmount: json['formatted_amount'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'formatted_amount': formattedAmount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeductionItem &&
        other.name == name &&
        other.amount == amount &&
        other.formattedAmount == formattedAmount;
  }

  @override
  int get hashCode {
    return name.hashCode ^ amount.hashCode ^ formattedAmount.hashCode;
  }
}

class PayslipDetailModel {
  final int id;
  final int payrollId;
  final String period;
  final int periodMonth;
  final int periodYear;
  final EmployeeInfo employee;
  final int baseSalary;
  final String formattedBaseSalary;
  final List<EarningItem> earnings;
  final List<DeductionItem> deductions;
  final int totalEarnings;
  final int totalDeductions;
  final int netSalary;
  final String formattedTotalEarnings;
  final String formattedTotalDeductions;
  final String formattedNetSalary;
  final String paymentDate;
  final String paymentMethod;
  final String status;

  const PayslipDetailModel({
    required this.id,
    required this.payrollId,
    required this.period,
    required this.periodMonth,
    required this.periodYear,
    required this.employee,
    required this.baseSalary,
    required this.formattedBaseSalary,
    required this.earnings,
    required this.deductions,
    required this.totalEarnings,
    required this.totalDeductions,
    required this.netSalary,
    required this.formattedTotalEarnings,
    required this.formattedTotalDeductions,
    required this.formattedNetSalary,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
  });

  factory PayslipDetailModel.fromJson(Map<String, dynamic> json) {
    return PayslipDetailModel(
      id: json['id'] ?? 0,
      payrollId: json['payroll_id'] ?? 0,
      period: json['period'] ?? '',
      periodMonth: json['period_month'] ?? 0,
      periodYear: json['period_year'] ?? 0,
      employee: EmployeeInfo.fromJson(json['employee'] ?? {}),
      baseSalary: json['base_salary'] ?? 0,
      formattedBaseSalary: json['formatted_base_salary'] ?? '',
      earnings: (json['earnings'] as List?)
              ?.map((e) => EarningItem.fromJson(e))
              .toList() ??
          [],
      deductions: (json['deductions'] as List?)
              ?.map((e) => DeductionItem.fromJson(e))
              .toList() ??
          [],
      totalEarnings: json['total_earnings'] ?? 0,
      totalDeductions: json['total_deductions'] ?? 0,
      netSalary: json['net_salary'] ?? 0,
      formattedTotalEarnings: json['formatted_total_earnings'] ?? '',
      formattedTotalDeductions: json['formatted_total_deductions'] ?? '',
      formattedNetSalary: json['formatted_net_salary'] ?? '',
      paymentDate: json['payment_date'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
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
      'employee': employee.toJson(),
      'base_salary': baseSalary,
      'formatted_base_salary': formattedBaseSalary,
      'earnings': earnings.map((e) => e.toJson()).toList(),
      'deductions': deductions.map((e) => e.toJson()).toList(),
      'total_earnings': totalEarnings,
      'total_deductions': totalDeductions,
      'net_salary': netSalary,
      'formatted_total_earnings': formattedTotalEarnings,
      'formatted_total_deductions': formattedTotalDeductions,
      'formatted_net_salary': formattedNetSalary,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PayslipDetailModel &&
        other.id == id &&
        other.payrollId == payrollId &&
        other.period == period &&
        other.periodMonth == periodMonth &&
        other.periodYear == periodYear &&
        other.employee == employee &&
        other.baseSalary == baseSalary &&
        listEquals(other.earnings, earnings) &&
        listEquals(other.deductions, deductions) &&
        other.totalEarnings == totalEarnings &&
        other.totalDeductions == totalDeductions &&
        other.netSalary == netSalary &&
        other.paymentDate == paymentDate &&
        other.paymentMethod == paymentMethod &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        payrollId.hashCode ^
        period.hashCode ^
        periodMonth.hashCode ^
        periodYear.hashCode ^
        employee.hashCode ^
        baseSalary.hashCode ^
        earnings.hashCode ^
        deductions.hashCode ^
        totalEarnings.hashCode ^
        totalDeductions.hashCode ^
        netSalary.hashCode ^
        paymentDate.hashCode ^
        paymentMethod.hashCode ^
        status.hashCode;
  }
}
