import 'package:flutter/foundation.dart';

class MonthlyBreakdown {
  final int month;
  final String monthName;
  final int netSalary;

  const MonthlyBreakdown({
    required this.month,
    required this.monthName,
    required this.netSalary,
  });

  factory MonthlyBreakdown.fromJson(Map<String, dynamic> json) {
    return MonthlyBreakdown(
      month: json['month'] ?? 0,
      monthName: json['month_name'] ?? '',
      netSalary: json['net_salary'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'month': month, 'month_name': monthName, 'net_salary': netSalary};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MonthlyBreakdown &&
        other.month == month &&
        other.monthName == monthName &&
        other.netSalary == netSalary;
  }

  @override
  int get hashCode {
    return month.hashCode ^ monthName.hashCode ^ netSalary.hashCode;
  }
}

class PayslipSummaryModel {
  final int totalMonths;
  final int totalEarnings;
  final int totalDeductions;
  final int totalNetSalary;
  final int averageNetSalary;
  final List<MonthlyBreakdown> monthlyBreakdown;

  const PayslipSummaryModel({
    required this.totalMonths,
    required this.totalEarnings,
    required this.totalDeductions,
    required this.totalNetSalary,
    required this.averageNetSalary,
    required this.monthlyBreakdown,
  });

  factory PayslipSummaryModel.fromJson(Map<String, dynamic> json) {
    return PayslipSummaryModel(
      totalMonths: json['total_months'] ?? 0,
      totalEarnings: json['total_earnings'] ?? 0,
      totalDeductions: json['total_deductions'] ?? 0,
      totalNetSalary: json['total_net_salary'] ?? 0,
      averageNetSalary: json['average_net_salary'] ?? 0,
      monthlyBreakdown: (json['monthly_breakdown'] as List?)
              ?.map((e) => MonthlyBreakdown.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_months': totalMonths,
      'total_earnings': totalEarnings,
      'total_deductions': totalDeductions,
      'total_net_salary': totalNetSalary,
      'average_net_salary': averageNetSalary,
      'monthly_breakdown': monthlyBreakdown.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PayslipSummaryModel &&
        other.totalMonths == totalMonths &&
        other.totalEarnings == totalEarnings &&
        other.totalDeductions == totalDeductions &&
        other.totalNetSalary == totalNetSalary &&
        other.averageNetSalary == averageNetSalary &&
        listEquals(other.monthlyBreakdown, monthlyBreakdown);
  }

  @override
  int get hashCode {
    return totalMonths.hashCode ^
        totalEarnings.hashCode ^
        totalDeductions.hashCode ^
        totalNetSalary.hashCode ^
        averageNetSalary.hashCode ^
        monthlyBreakdown.hashCode;
  }
}
