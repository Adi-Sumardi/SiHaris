import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/leave_type_model.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_types/leave_types_bloc.dart';

class MockLeaveRemoteDatasource extends Mock implements LeaveRemoteDatasource {}

void main() {
  late LeaveTypesBloc bloc;
  late MockLeaveRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockLeaveRemoteDatasource();
    bloc = LeaveTypesBloc(mockDatasource);
  });

  const tLeaveTypeModel = LeaveTypeModel(
    id: 1,
    name: 'Cuti Tahunan',
    quota: 12,
    isPaid: true,
    requiresAttachment: false,
  );

  test('initial state should be LeaveTypesInitial', () {
    expect(bloc.state, LeaveTypesInitial());
  });

  blocTest<LeaveTypesBloc, LeaveTypesState>(
    'emits [LeaveTypesLoading, LeaveTypesLoaded] when GetLeaveTypes is added and fetch is successful',
    build: () {
      when(
        () => mockDatasource.getLeaveTypes(),
      ).thenAnswer((_) async => [tLeaveTypeModel]);
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveTypes()),
    expect: () => [
      LeaveTypesLoading(),
      const LeaveTypesLoaded([tLeaveTypeModel]),
    ],
  );

  blocTest<LeaveTypesBloc, LeaveTypesState>(
    'emits [LeaveTypesLoading, LeaveTypesError] when GetLeaveTypes is added and fetch fails',
    build: () {
      when(
        () => mockDatasource.getLeaveTypes(),
      ).thenThrow(Exception('Failed to fetch'));
      return bloc;
    },
    act: (bloc) => bloc.add(GetLeaveTypes()),
    expect: () => [
      LeaveTypesLoading(),
      const LeaveTypesError('Failed to fetch'),
    ],
  );
}
