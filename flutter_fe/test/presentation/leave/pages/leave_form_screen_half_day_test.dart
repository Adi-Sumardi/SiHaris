// Regression test: LeaveFormScreen previously had no half-day option at
// all (isHalfDay was always sent as false), even though the backend and
// LeaveRequestModel both fully support it. This covers the "Setengah Hari"
// checkbox toggling the half-day-type picker on/off.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gaji_pro/data/models/responses/leave_type_model.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_crud/leave_crud_bloc.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_types/leave_types_bloc.dart';
import 'package:gaji_pro/presentation/leave/pages/leave_form_screen.dart';

class MockLeaveCrudBloc extends MockBloc<LeaveCrudEvent, LeaveCrudState>
    implements LeaveCrudBloc {}

class MockLeaveTypesBloc extends MockBloc<LeaveTypesEvent, LeaveTypesState>
    implements LeaveTypesBloc {}

Widget _wrap(LeaveCrudBloc crudBloc, LeaveTypesBloc typesBloc) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<LeaveCrudBloc>.value(value: crudBloc),
        BlocProvider<LeaveTypesBloc>.value(value: typesBloc),
      ],
      child: const LeaveFormScreen(),
    ),
  );
}

void main() {
  late MockLeaveCrudBloc crudBloc;
  late MockLeaveTypesBloc typesBloc;

  setUp(() {
    crudBloc = MockLeaveCrudBloc();
    typesBloc = MockLeaveTypesBloc();

    when(() => crudBloc.state).thenReturn(LeaveCrudInitial());
    when(() => crudBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => typesBloc.state).thenReturn(
      const LeaveTypesLoaded([
        LeaveTypeModel(
          id: 1,
          name: 'Cuti Tahunan',
          quota: 12,
          isPaid: true,
          requiresAttachment: false,
        ),
      ]),
    );
    when(() => typesBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('half-day type picker is hidden until Setengah Hari is checked', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(crudBloc, typesBloc));
    await tester.pumpAndSettle();

    expect(find.text('Setengah Hari'), findsOneWidget);
    expect(find.text('Tipe Setengah Hari'), findsNothing);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    expect(find.text('Tipe Setengah Hari'), findsOneWidget);
    expect(find.text('Pilih Waktu'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('unchecking Setengah Hari hides the half-day type picker again', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(crudBloc, typesBloc));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(find.text('Tipe Setengah Hari'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(find.text('Tipe Setengah Hari'), findsNothing);
  });

  testWidgets('Kontak Darurat is not marked as required', (tester) async {
    await tester.pumpWidget(_wrap(crudBloc, typesBloc));
    await tester.pumpAndSettle();

    expect(find.text('Kontak Darurat (Opsional)'), findsOneWidget);
  });
}
