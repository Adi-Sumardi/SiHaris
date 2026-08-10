import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/payslip_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_detail_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_download_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_summary_model.dart';

void main() {
  group('PayslipModel', () {
    const tPayslipModel = PayslipModel(
      id: 1,
      payrollId: 101,
      period: 'Februari 2026',
      periodMonth: 2,
      periodYear: 2026,
      netSalary: 10325000,
      formattedNetSalary: 'Rp 10.325.000',
      paymentDate: '2026-02-28',
      status: 'paid',
    );

    test('should be a subclass of PayslipModel', () {
      expect(tPayslipModel, isA<PayslipModel>());
    });

    test('should return a valid model when the JSON is valid', () {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'payroll_id': 101,
        'period': 'Februari 2026',
        'period_month': 2,
        'period_year': 2026,
        'net_salary': 10325000,
        'formatted_net_salary': 'Rp 10.325.000',
        'payment_date': '2026-02-28',
        'status': 'paid',
      };

      // act
      final result = PayslipModel.fromJson(jsonMap);

      // assert
      expect(result, tPayslipModel);
    });

    test('should return a JSON map containing the proper data', () {
      // act
      final result = tPayslipModel.toJson();

      // assert
      final expectedMap = {
        'id': 1,
        'payroll_id': 101,
        'period': 'Februari 2026',
        'period_month': 2,
        'period_year': 2026,
        'net_salary': 10325000,
        'formatted_net_salary': 'Rp 10.325.000',
        'payment_date': '2026-02-28',
        'status': 'paid',
      };
      expect(result, expectedMap);
    });
  });

  group('PayslipDetailModel', () {
    const tPayslipDetailModel = PayslipDetailModel(
      id: 1,
      payrollId: 101,
      period: 'Februari 2026',
      periodMonth: 2,
      periodYear: 2026,
      employee: EmployeeInfo(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'Ahmad Bahri',
        department: 'Engineering',
        position: 'Senior Developer',
      ),
      baseSalary: 8000000,
      formattedBaseSalary: 'Rp 8.000.000',
      earnings: [
        EarningItem(
          name: 'Gaji Pokok',
          amount: 8000000,
          formattedAmount: 'Rp 8.000.000',
        ),
        EarningItem(
          name: 'Tunjangan Transport',
          amount: 500000,
          formattedAmount: 'Rp 500.000',
        ),
      ],
      deductions: [
        DeductionItem(
          name: 'PPh21',
          amount: 800000,
          formattedAmount: 'Rp 800.000',
        ),
        DeductionItem(
          name: 'BPJS',
          amount: 200000,
          formattedAmount: 'Rp 200.000',
        ),
      ],
      totalEarnings: 8500000,
      totalDeductions: 1000000,
      netSalary: 7500000,
      formattedTotalEarnings: 'Rp 8.500.000',
      formattedTotalDeductions: 'Rp 1.000.000',
      formattedNetSalary: 'Rp 7.500.000',
      paymentDate: '2026-02-28',
      paymentMethod: 'Bank Transfer',
      status: 'paid',
    );

    test('should be a subclass of PayslipDetailModel', () {
      expect(tPayslipDetailModel, isA<PayslipDetailModel>());
    });

    test('should return a valid model when the JSON is valid', () {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'payroll_id': 101,
        'period': 'Februari 2026',
        'period_month': 2,
        'period_year': 2026,
        'employee': {
          'id': 1,
          'employee_id': 'EMP001',
          'full_name': 'Ahmad Bahri',
          'department': 'Engineering',
          'position': 'Senior Developer',
        },
        'base_salary': 8000000,
        'formatted_base_salary': 'Rp 8.000.000',
        'earnings': [
          {
            'name': 'Gaji Pokok',
            'amount': 8000000,
            'formatted_amount': 'Rp 8.000.000',
          },
          {
            'name': 'Tunjangan Transport',
            'amount': 500000,
            'formatted_amount': 'Rp 500.000',
          },
        ],
        'deductions': [
          {'name': 'PPh21', 'amount': 800000, 'formatted_amount': 'Rp 800.000'},
          {'name': 'BPJS', 'amount': 200000, 'formatted_amount': 'Rp 200.000'},
        ],
        'total_earnings': 8500000,
        'total_deductions': 1000000,
        'net_salary': 7500000,
        'formatted_total_earnings': 'Rp 8.500.000',
        'formatted_total_deductions': 'Rp 1.000.000',
        'formatted_net_salary': 'Rp 7.500.000',
        'payment_date': '2026-02-28',
        'payment_method': 'Bank Transfer',
        'status': 'paid',
      };

      // act
      final result = PayslipDetailModel.fromJson(jsonMap);

      // assert
      expect(result, tPayslipDetailModel);
    });

    test('should return a JSON map containing the proper data', () {
      // act
      final result = tPayslipDetailModel.toJson();

      // assert
      expect(result['id'], 1);
      expect(result['payroll_id'], 101);
      expect(result['employee']['full_name'], 'Ahmad Bahri');
      expect(result['earnings'].length, 2);
      expect(result['deductions'].length, 2);
      expect(result['net_salary'], 7500000);
    });
  });

  group('PayslipDownloadModel', () {
    const tPayslipDownloadModel = PayslipDownloadModel(
      downloadUrl: 'https://example.com/payslips/1/download',
      filename: 'payslip_feb_2026.pdf',
    );

    test('should be a subclass of PayslipDownloadModel', () {
      expect(tPayslipDownloadModel, isA<PayslipDownloadModel>());
    });

    test('should return a valid model when the JSON is valid', () {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'download_url': 'https://example.com/payslips/1/download',
        'filename': 'payslip_feb_2026.pdf',
      };

      // act
      final result = PayslipDownloadModel.fromJson(jsonMap);

      // assert
      expect(result, tPayslipDownloadModel);
    });

    test('should return a JSON map containing the proper data', () {
      // act
      final result = tPayslipDownloadModel.toJson();

      // assert
      final expectedMap = {
        'download_url': 'https://example.com/payslips/1/download',
        'filename': 'payslip_feb_2026.pdf',
      };
      expect(result, expectedMap);
    });
  });

  group('PayslipSummaryModel', () {
    const tPayslipSummaryModel = PayslipSummaryModel(
      totalMonths: 12,
      totalEarnings: 102000000,
      totalDeductions: 12000000,
      totalNetSalary: 90000000,
      averageNetSalary: 7500000,
      monthlyBreakdown: [
        MonthlyBreakdown(month: 1, monthName: 'Januari', netSalary: 7500000),
        MonthlyBreakdown(month: 2, monthName: 'Februari', netSalary: 7500000),
      ],
    );

    test('should be a subclass of PayslipSummaryModel', () {
      expect(tPayslipSummaryModel, isA<PayslipSummaryModel>());
    });

    test('should return a valid model when the JSON is valid', () {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'total_months': 12,
        'total_earnings': 102000000,
        'total_deductions': 12000000,
        'total_net_salary': 90000000,
        'average_net_salary': 7500000,
        'monthly_breakdown': [
          {'month': 1, 'month_name': 'Januari', 'net_salary': 7500000},
          {'month': 2, 'month_name': 'Februari', 'net_salary': 7500000},
        ],
      };

      // act
      final result = PayslipSummaryModel.fromJson(jsonMap);

      // assert
      expect(result, tPayslipSummaryModel);
    });

    test('should return a JSON map containing the proper data', () {
      // act
      final result = tPayslipSummaryModel.toJson();

      // assert
      expect(result['total_months'], 12);
      expect(result['total_net_salary'], 90000000);
      expect(result['monthly_breakdown'].length, 2);
    });
  });
}
