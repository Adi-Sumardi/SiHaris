import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_category_model.dart';
import 'package:gaji_pro/presentation/reimbursement/bloc/reimbursement_category/reimbursement_category_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockReimbursementRemoteDatasource extends Mock
    implements ReimbursementRemoteDatasource {}

void main() {
  late ReimbursementCategoryBloc bloc;
  late MockReimbursementRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockReimbursementRemoteDatasource();
    bloc = ReimbursementCategoryBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  const tCategories = [
    ReimbursementCategoryModel(
      id: 1,
      name: 'Transport',
      description: 'Transportation expenses',
      maxAmount: 500000,
      requiresReceipt: true,
    ),
    ReimbursementCategoryModel(
      id: 2,
      name: 'Meal',
      description: 'Meal expenses',
      maxAmount: 200000,
      requiresReceipt: false,
    ),
  ];

  test('initial state should be ReimbursementCategoryInitial', () {
    expect(bloc.state, equals(ReimbursementCategoryInitial()));
  });

  group('LoadReimbursementCategories', () {
    blocTest<ReimbursementCategoryBloc, ReimbursementCategoryState>(
      'emits [Loading, Loaded] when categories are fetched successfully',
      build: () {
        when(
          () => mockDatasource.getCategories(),
        ).thenAnswer((_) async => tCategories);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReimbursementCategories()),
      expect: () => [
        ReimbursementCategoryLoading(),
        const ReimbursementCategoryLoaded(tCategories),
      ],
    );

    blocTest<ReimbursementCategoryBloc, ReimbursementCategoryState>(
      'emits [Loading, Error] when fetching categories fails',
      build: () {
        when(
          () => mockDatasource.getCategories(),
        ).thenThrow(Exception('Failed to load categories'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReimbursementCategories()),
      expect: () => [
        ReimbursementCategoryLoading(),
        const ReimbursementCategoryError(
          'Exception: Failed to load categories',
        ),
      ],
    );
  });
}
