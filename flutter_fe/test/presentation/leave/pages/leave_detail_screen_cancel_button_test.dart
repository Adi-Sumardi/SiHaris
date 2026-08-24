// Regression test: the "Batalkan Pengajuan" button must mirror the
// backend's LeaveRequest::canBeCancelled() — visible not just while
// 'pending', but also while 'approved' as long as the leave hasn't started
// yet. Previously it only checked `status == 'pending'`, so an employee
// could not cancel an already-approved leave from the app even though the
// API allowed it.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gaji_pro/data/models/responses/leave_model.dart';
import 'package:gaji_pro/data/models/responses/leave_type_model.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_crud/leave_crud_bloc.dart';
import 'package:gaji_pro/presentation/leave/pages/leave_detail_screen.dart';

class MockLeaveCrudBloc extends MockBloc<LeaveCrudEvent, LeaveCrudState>
    implements LeaveCrudBloc {}

LeaveModel _leave({required String status, required String startDate}) {
  return LeaveModel(
    id: 1,
    requestNumber: 'CUTI-001',
    leaveType: const LeaveTypeModel(
      id: 1,
      name: 'Cuti Tahunan',
      quota: 12,
      isPaid: true,
      requiresAttachment: false,
    ),
    startDate: startDate,
    endDate: startDate,
    totalDays: 1,
    isHalfDay: false,
    status: status,
    statusLabel: status,
    createdAt: DateTime.now().toIso8601String(),
  );
}

Widget _wrap(LeaveModel leave, LeaveCrudBloc bloc) {
  return MaterialApp(
    home: BlocProvider<LeaveCrudBloc>.value(
      value: bloc,
      child: LeaveDetailScreen(leave: leave),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  late MockLeaveCrudBloc bloc;

  setUp(() {
    bloc = MockLeaveCrudBloc();
    when(() => bloc.state).thenReturn(LeaveCrudInitial());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  });

  final future = DateTime.now().add(const Duration(days: 7));
  final past = DateTime.now().subtract(const Duration(days: 7));

  testWidgets('tampil saat status pending', (tester) async {
    await tester.pumpWidget(_wrap(
      _leave(status: 'pending', startDate: future.toIso8601String()),
      bloc,
    ));
    expect(find.text('Batalkan Pengajuan'), findsOneWidget);
  });

  testWidgets(
    'tampil saat status approved dan cuti belum dimulai',
    (tester) async {
      await tester.pumpWidget(_wrap(
        _leave(status: 'approved', startDate: future.toIso8601String()),
        bloc,
      ));
      expect(find.text('Batalkan Pengajuan'), findsOneWidget);
    },
  );

  testWidgets(
    'tidak tampil saat status approved tapi cuti sudah lewat/sedang berjalan',
    (tester) async {
      await tester.pumpWidget(_wrap(
        _leave(status: 'approved', startDate: past.toIso8601String()),
        bloc,
      ));
      expect(find.text('Batalkan Pengajuan'), findsNothing);
    },
  );

  testWidgets('tidak tampil saat status rejected', (tester) async {
    await tester.pumpWidget(_wrap(
      _leave(status: 'rejected', startDate: future.toIso8601String()),
      bloc,
    ));
    expect(find.text('Batalkan Pengajuan'), findsNothing);
  });
}
