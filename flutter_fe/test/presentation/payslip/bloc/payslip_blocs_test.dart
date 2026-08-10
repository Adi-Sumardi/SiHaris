import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/payslip_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/payslip_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_detail_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_download_model.dart';
import 'package:gaji_pro/data/models/responses/payslip_summary_model.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_list/payslip_list_bloc.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_detail/payslip_detail_bloc.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_download/payslip_download_bloc.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_summary/payslip_summary_bloc.dart';

class MockPayslipRemoteDatasource extends Mock
    implements PayslipRemoteDatasource {}

void main() {
  late MockPayslipRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockPayslipRemoteDatasource();
  });

  group('PayslipListBloc', () {
    late PayslipListBloc bloc;

    setUp(() {
      bloc = PayslipListBloc(datasource: mockDatasource);
    });

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

    test('initial state should be PayslipListInitial', () {
      expect(bloc.state, PayslipListInitial());
    });

    blocTest<PayslipListBloc, PayslipListState>(
      'emits [PayslipListLoading, PayslipListLoaded] when GetPayslips is added and fetch is successful',
      build: () {
        when(
          () => mockDatasource.getPayslips(year: 2026, page: 1),
        ).thenAnswer((_) async => [tPayslipModel]);
        return bloc;
      },
      act: (bloc) => bloc.add(GetPayslips(year: 2026)),
      expect: () => [
        PayslipListLoading(),
        const PayslipListLoaded([tPayslipModel], year: 2026),
      ],
    );

    blocTest<PayslipListBloc, PayslipListState>(
      'emits [PayslipListLoading, PayslipListError] when GetPayslips is added and fetch fails',
      build: () {
        when(
          () => mockDatasource.getPayslips(year: 2026, page: 1),
        ).thenThrow(Exception('Failed to fetch'));
        return bloc;
      },
      act: (bloc) => bloc.add(GetPayslips(year: 2026)),
      expect: () => [
        PayslipListLoading(),
        const PayslipListError('Exception: Failed to fetch'),
      ],
    );

    blocTest<PayslipListBloc, PayslipListState>(
      'emits [PayslipListLoading, PayslipListLoaded] when RefreshPayslips is added',
      build: () {
        when(
          () => mockDatasource.getPayslips(year: 2026, page: 1),
        ).thenAnswer((_) async => [tPayslipModel]);
        return bloc;
      },
      act: (bloc) => bloc.add(RefreshPayslips(year: 2026)),
      expect: () => [
        PayslipListLoading(),
        const PayslipListLoaded([tPayslipModel], year: 2026),
      ],
    );
  });

  group('PayslipDetailBloc', () {
    late PayslipDetailBloc bloc;

    setUp(() {
      bloc = PayslipDetailBloc(datasource: mockDatasource);
    });

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

    test('initial state should be PayslipDetailInitial', () {
      expect(bloc.state, PayslipDetailInitial());
    });

    blocTest<PayslipDetailBloc, PayslipDetailState>(
      'emits [PayslipDetailLoading, PayslipDetailLoaded] when GetPayslipDetail is added and fetch is successful',
      build: () {
        when(
          () => mockDatasource.getPayslipDetail(1),
        ).thenAnswer((_) async => tPayslipDetailModel);
        return bloc;
      },
      act: (bloc) => bloc.add(GetPayslipDetail(1)),
      expect: () => [
        PayslipDetailLoading(),
        const PayslipDetailLoaded(tPayslipDetailModel),
      ],
    );

    blocTest<PayslipDetailBloc, PayslipDetailState>(
      'emits [PayslipDetailLoading, PayslipDetailError] when GetPayslipDetail is added and fetch fails',
      build: () {
        when(
          () => mockDatasource.getPayslipDetail(1),
        ).thenThrow(Exception('Failed to fetch'));
        return bloc;
      },
      act: (bloc) => bloc.add(GetPayslipDetail(1)),
      expect: () => [
        PayslipDetailLoading(),
        const PayslipDetailError('Exception: Failed to fetch'),
      ],
    );
  });

  group('PayslipDownloadBloc', () {
    late PayslipDownloadBloc bloc;

    setUp(() {
      bloc = PayslipDownloadBloc(datasource: mockDatasource);
    });

    const tPayslipDownloadModel = PayslipDownloadModel(
      downloadUrl: 'https://example.com/payslips/1/download',
      filename: 'payslip_feb_2026.pdf',
    );

    test('initial state should be PayslipDownloadInitial', () {
      expect(bloc.state, PayslipDownloadInitial());
    });

    blocTest<PayslipDownloadBloc, PayslipDownloadState>(
      'emits [PayslipDownloadLoading, PayslipDownloadSuccess] when DownloadPayslip is added and download is successful',
      build: () {
        when(
          () => mockDatasource.downloadPayslip(1),
        ).thenAnswer((_) async => tPayslipDownloadModel);
        return bloc;
      },
      act: (bloc) => bloc.add(DownloadPayslip(1)),
      expect: () => [
        PayslipDownloadLoading(),
        const PayslipDownloadSuccess(tPayslipDownloadModel),
      ],
    );

    blocTest<PayslipDownloadBloc, PayslipDownloadState>(
      'emits [PayslipDownloadLoading, PayslipDownloadError] when DownloadPayslip is added and download fails',
      build: () {
        when(
          () => mockDatasource.downloadPayslip(1),
        ).thenThrow(Exception('Failed to download'));
        return bloc;
      },
      act: (bloc) => bloc.add(DownloadPayslip(1)),
      expect: () => [
        PayslipDownloadLoading(),
        const PayslipDownloadError('Exception: Failed to download'),
      ],
    );
  });

  group('PayslipSummaryBloc', () {
    late PayslipSummaryBloc bloc;

    setUp(() {
      bloc = PayslipSummaryBloc(datasource: mockDatasource);
    });

    const tPayslipSummaryModel = PayslipSummaryModel(
      totalMonths: 12,
      totalEarnings: 102000000,
      totalDeductions: 12000000,
      totalNetSalary: 90000000,
      averageNetSalary: 7500000,
      monthlyBreakdown: [],
    );

    test('initial state should be PayslipSummaryInitial', () {
      expect(bloc.state, PayslipSummaryInitial());
    });

    blocTest<PayslipSummaryBloc, PayslipSummaryState>(
      'emits [PayslipSummaryLoading, PayslipSummaryLoaded] when GetPayslipSummary is added and fetch is successful',
      build: () {
        when(
          () => mockDatasource.getPayslipSummary(year: 2026),
        ).thenAnswer((_) async => tPayslipSummaryModel);
        return bloc;
      },
      act: (bloc) => bloc.add(GetPayslipSummary(year: 2026)),
      expect: () => [
        PayslipSummaryLoading(),
        const PayslipSummaryLoaded(tPayslipSummaryModel),
      ],
    );

    blocTest<PayslipSummaryBloc, PayslipSummaryState>(
      'emits [PayslipSummaryLoading, PayslipSummaryError] when GetPayslipSummary is added and fetch fails',
      build: () {
        when(
          () => mockDatasource.getPayslipSummary(year: 2026),
        ).thenThrow(Exception('Failed to fetch'));
        return bloc;
      },
      act: (bloc) => bloc.add(GetPayslipSummary(year: 2026)),
      expect: () => [
        PayslipSummaryLoading(),
        const PayslipSummaryError('Exception: Failed to fetch'),
      ],
    );
  });
}
