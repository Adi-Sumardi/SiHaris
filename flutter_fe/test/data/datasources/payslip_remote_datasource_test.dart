import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/data/datasources/auth_datasource.dart';
import 'package:gaji_pro/data/datasources/payslip_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/payslip_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_detail_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_download_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_summary_model.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockAuthLocalDatasource extends Mock implements AuthLocalDatasourceBase {}

class FakeUri extends Fake implements Uri {}

void main() {
  late PayslipRemoteDatasource datasource;
  late MockHttpClient mockHttpClient;
  late MockAuthLocalDatasource mockAuthLocalDatasource;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuthLocalDatasource = MockAuthLocalDatasource();
    datasource = PayslipRemoteDatasource(
      client: mockHttpClient,
      authLocalDatasource: mockAuthLocalDatasource,
    );
    registerFallbackValue(FakeUri());
  });

  const tAuthToken = 'test_token';
  const tHeaders = {
    'Accept': 'application/json',
    'Authorization': 'Bearer $tAuthToken',
  };

  void setUpMockToken() {
    when(
      () => mockAuthLocalDatasource.getToken(),
    ).thenAnswer((_) async => tAuthToken);
  }

  group('getPayslips', () {
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

    test('should return List<PayslipModel> when response code is 200', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips?year=2026&page=1'),
          headers: tHeaders,
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"status": "success", "data": {"data": [{"id": 1, "payroll_id": 101, "period": "Februari 2026", "period_month": 2, "period_year": 2026, "net_salary": 10325000, "formatted_net_salary": "Rp 10.325.000", "payment_date": "2026-02-28", "status": "paid"}]}}',
          200,
        ),
      );

      // act
      final result = await datasource.getPayslips(year: 2026, page: 1);

      // assert
      expect(result, equals([tPayslipModel]));
    });

    test('should use default page 1 when page is not provided', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips?year=2026&page=1'),
          headers: tHeaders,
        ),
      ).thenAnswer(
        (_) async =>
            http.Response('{"status": "success", "data": {"data": []}}', 200),
      );

      // act
      await datasource.getPayslips(year: 2026);

      // assert
      verify(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips?year=2026&page=1'),
          headers: tHeaders,
        ),
      ).called(1);
    });

    test('should throw exception when response code is not 200', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips?year=2026&page=1'),
          headers: tHeaders,
        ),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      // act
      final call = datasource.getPayslips(year: 2026);

      // assert
      expect(call, throwsException);
    });
  });

  group('getPayslipDetail', () {
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
      earnings: [],
      deductions: [],
      totalEarnings: 8000000,
      totalDeductions: 500000,
      netSalary: 7500000,
      formattedTotalEarnings: 'Rp 8.000.000',
      formattedTotalDeductions: 'Rp 500.000',
      formattedNetSalary: 'Rp 7.500.000',
      paymentDate: '2026-02-28',
      paymentMethod: 'Bank Transfer',
      status: 'paid',
    );

    test('should return PayslipDetailModel when response code is 200', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips/1'),
          headers: tHeaders,
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"status": "success", "data": {"id": 1, "payroll_id": 101, "period": "Februari 2026", "period_month": 2, "period_year": 2026, "employee": {"id": 1, "employee_id": "EMP001", "full_name": "Ahmad Bahri", "department": "Engineering", "position": "Senior Developer"}, "base_salary": 8000000, "formatted_base_salary": "Rp 8.000.000", "earnings": [], "deductions": [], "total_earnings": 8000000, "total_deductions": 500000, "net_salary": 7500000, "formatted_total_earnings": "Rp 8.000.000", "formatted_total_deductions": "Rp 500.000", "formatted_net_salary": "Rp 7.500.000", "payment_date": "2026-02-28", "payment_method": "Bank Transfer", "status": "paid"}}',
          200,
        ),
      );

      // act
      final result = await datasource.getPayslipDetail(1);

      // assert
      expect(result, equals(tPayslipDetailModel));
    });

    test('should throw exception when response code is 404', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips/999'),
          headers: tHeaders,
        ),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      // act
      final call = datasource.getPayslipDetail(999);

      // assert
      expect(call, throwsException);
    });
  });

  group('downloadPayslip', () {
    const tPayslipDownloadModel = PayslipDownloadModel(
      downloadUrl: 'https://example.com/payslips/1/download',
      filename: 'payslip_feb_2026.pdf',
    );

    test(
      'should return PayslipDownloadModel when response code is 200',
      () async {
        // arrange
        setUpMockToken();
        when(
          () => mockHttpClient.get(
            Uri.parse('${Variables.baseUrl}/payslips/1/download'),
            headers: tHeaders,
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"status": "success", "data": {"download_url": "https://example.com/payslips/1/download", "filename": "payslip_feb_2026.pdf"}}',
            200,
          ),
        );

        // act
        final result = await datasource.downloadPayslip(1);

        // assert
        expect(result, equals(tPayslipDownloadModel));
      },
    );

    test('should throw exception when response code is not 200', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips/1/download'),
          headers: tHeaders,
        ),
      ).thenAnswer((_) async => http.Response('Unauthorized', 401));

      // act
      final call = datasource.downloadPayslip(1);

      // assert
      expect(call, throwsException);
    });
  });

  group('getPayslipSummary', () {
    const tPayslipSummaryModel = PayslipSummaryModel(
      totalMonths: 12,
      totalEarnings: 102000000,
      totalDeductions: 12000000,
      totalNetSalary: 90000000,
      averageNetSalary: 7500000,
      monthlyBreakdown: [],
    );

    test('should return PayslipSummaryModel when response code is 200', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips/summary?year=2026'),
          headers: tHeaders,
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"status": "success", "data": {"total_months": 12, "total_earnings": 102000000, "total_deductions": 12000000, "total_net_salary": 90000000, "average_net_salary": 7500000, "monthly_breakdown": []}}',
          200,
        ),
      );

      // act
      final result = await datasource.getPayslipSummary(year: 2026);

      // assert
      expect(result, equals(tPayslipSummaryModel));
    });

    test('should include year parameter in request', () async {
      // arrange
      setUpMockToken();
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips/summary?year=2025'),
          headers: tHeaders,
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"status": "success", "data": {"total_months": 12, "total_earnings": 102000000, "total_deductions": 12000000, "total_net_salary": 90000000, "average_net_salary": 7500000, "monthly_breakdown": []}}',
          200,
        ),
      );

      // act
      await datasource.getPayslipSummary(year: 2025);

      // assert
      verify(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/payslips/summary?year=2025'),
          headers: tHeaders,
        ),
      ).called(1);
    });
  });
}
