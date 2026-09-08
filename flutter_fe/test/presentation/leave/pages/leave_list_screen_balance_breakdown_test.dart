import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/leave_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/leave_balance_model.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_balance/leave_balance_bloc.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_list/leave_list_bloc.dart';
import 'package:gaji_pro/presentation/leave/pages/leave_list_screen.dart';

class MockLeaveRemoteDatasource extends Mock implements LeaveRemoteDatasource {}

void main() {
  late MockLeaveRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockLeaveRemoteDatasource();
    when(
      () => mockDatasource.getLeaves(
        page: any(named: 'page'),
        status: any(named: 'status'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) async => []);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<LeaveListBloc>(
              create: (_) => LeaveListBloc(mockDatasource),
            ),
            BlocProvider<LeaveBalanceBloc>(
              create: (_) => LeaveBalanceBloc(mockDatasource),
            ),
          ],
          child: const LeaveListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LeaveListScreen — per-leave-type balance breakdown', () {
    testWidgets(
      'shows a separate card per leave type with its own remaining/entitled days',
      (tester) async {
        when(() => mockDatasource.getLeaveBalances()).thenAnswer(
          (_) async => const [
            LeaveBalanceModel(
              leaveTypeId: 1,
              leaveTypeName: 'Cuti Tahunan',
              year: 2026,
              entitledDays: 12,
              usedDays: 4,
              pendingDays: 0,
              remainingDays: 8,
            ),
            LeaveBalanceModel(
              leaveTypeId: 2,
              leaveTypeName: 'Cuti Melahirkan',
              year: 2026,
              entitledDays: 90,
              usedDays: 0,
              pendingDays: 0,
              remainingDays: 90,
            ),
          ],
        );

        await pumpScreen(tester);

        // Regression: previously only a combined total was shown (e.g.
        // "102" total entitled across both types), leaving employees
        // unable to tell which specific leave type still has balance.
        expect(find.text('Cuti Tahunan'), findsOneWidget);
        expect(find.text('Cuti Melahirkan'), findsOneWidget);

        // The remaining/entitled figures are rendered as a single RichText
        // combining two TextSpans ("8" and " / 12 hari") — match on the
        // combined plain text via the RichText widget's data.
        final richTexts = tester
            .widgetList<RichText>(find.byType(RichText))
            .map((w) => w.text.toPlainText())
            .toList();

        expect(richTexts, contains('8 / 12 hari'));
        expect(richTexts, contains('90 / 90 hari'));
      },
    );

    testWidgets('shows nothing extra when there are no leave balances yet', (
      tester,
    ) async {
      when(
        () => mockDatasource.getLeaveBalances(),
      ).thenAnswer((_) async => const []);

      await pumpScreen(tester);

      expect(find.text('Cuti Tahunan'), findsNothing);
    });

    testWidgets(
      'no longer shows the old combined Jatah/Sisa/Terpakai summary cards',
      (tester) async {
        when(() => mockDatasource.getLeaveBalances()).thenAnswer(
          (_) async => const [
            LeaveBalanceModel(
              leaveTypeId: 1,
              leaveTypeName: 'Cuti Tahunan',
              year: 2026,
              entitledDays: 12,
              usedDays: 4,
              pendingDays: 0,
              remainingDays: 8,
            ),
          ],
        );

        await pumpScreen(tester);

        expect(find.text('Jatah Cuti'), findsNothing);
        expect(find.text('Sisa Cuti'), findsNothing);
        expect(find.text('Terpakai'), findsNothing);
      },
    );

    testWidgets(
      'scales to any number of leave types (e.g. a newly added "Cuti Haji") without code changes',
      (tester) async {
        when(() => mockDatasource.getLeaveBalances()).thenAnswer(
          (_) async => const [
            LeaveBalanceModel(
              leaveTypeId: 1,
              leaveTypeName: 'Cuti Tahunan',
              year: 2026,
              entitledDays: 12,
              usedDays: 4,
              pendingDays: 0,
              remainingDays: 8,
            ),
            LeaveBalanceModel(
              leaveTypeId: 2,
              leaveTypeName: 'Cuti Umroh',
              year: 2026,
              entitledDays: 9,
              usedDays: 0,
              pendingDays: 0,
              remainingDays: 9,
            ),
            LeaveBalanceModel(
              leaveTypeId: 3,
              leaveTypeName: 'Cuti Sakit',
              year: 2026,
              entitledDays: 14,
              usedDays: 3,
              pendingDays: 0,
              remainingDays: 11,
            ),
            LeaveBalanceModel(
              leaveTypeId: 5,
              leaveTypeName: 'Cuti Haji',
              year: 2026,
              entitledDays: 40,
              usedDays: 0,
              pendingDays: 0,
              remainingDays: 40,
            ),
          ],
        );

        await pumpScreen(tester);

        expect(find.text('Cuti Tahunan'), findsOneWidget);
        expect(find.text('Cuti Umroh'), findsOneWidget);
        expect(find.text('Cuti Sakit'), findsOneWidget);
        expect(find.text('Cuti Haji'), findsOneWidget);

        final richTexts = tester
            .widgetList<RichText>(find.byType(RichText))
            .map((w) => w.text.toPlainText())
            .toList();
        expect(richTexts, contains('40 / 40 hari'));
      },
    );
  });
}
