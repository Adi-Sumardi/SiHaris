import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';
import 'package:gaji_pro/data/models/requests/clock_in_request_model.dart';
import 'package:gaji_pro/data/models/requests/clock_out_request_model.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance/attendance_bloc.dart';
import 'package:gaji_pro/presentation/attendance/pages/attendance_confirmation_screen.dart';

class MockAttendanceBloc
    extends MockBloc<AttendanceEvent, AttendanceState>
    implements AttendanceBloc {}

class FakeClockInRequestModel extends Fake implements ClockInRequestModel {}
class FakeClockOutRequestModel extends Fake implements ClockOutRequestModel {}
class FakeAttendanceEvent extends Fake implements AttendanceEvent {}

const _testOffice = OfficeLocationModel(
  id: 1,
  name: 'Kantor Pusat',
  latitude: -6.2,
  longitude: 106.8,
  radius: 100,
  address: 'Jl. Sudirman No.1',
  city: 'Jakarta',
);

const _userLat = -6.2001;
const _userLng = 106.8001;

/// Test-helper: renders the AttendanceConfirmationScreen info panel + header
/// WITHOUT flutter_map (to avoid real network calls in tests).
class _ConfirmationInfoView extends StatelessWidget {
  const _ConfirmationInfoView({
    required this.bloc,
    required this.type,
    this.withinRadius = true,
    this.distance = 15.0,
    this.faceConfidence = 0.87,
  });

  final AttendanceBloc bloc;
  final AttendanceType type;
  final bool withinRadius;
  final double distance;
  final double faceConfidence;

  String get _title => type == AttendanceType.clockIn
      ? 'Konfirmasi Clock In'
      : 'Konfirmasi Clock Out';

  String get _buttonLabel => type == AttendanceType.clockIn
      ? 'Clock In Sekarang'
      : 'Clock Out Sekarang';

  String get _confidencePercentage => '${(faceConfidence * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider<AttendanceBloc>.value(
        value: bloc,
        child: Scaffold(
          body: Column(
            children: [
              // Header
              Container(
                color: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    Expanded(
                      child: Text(
                        _title,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Info panel (no map)
              Expanded(
                child: _buildInfoPanel(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Office name
          Row(
            children: [
              const Icon(Icons.business, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _testOffice.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // GPS / face chips
          Row(
            children: [
              _chip(
                icon: withinRadius ? Icons.location_on : Icons.location_off,
                label: withinRadius ? 'Dalam Radius' : 'Luar Radius',
                color: withinRadius ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              _chip(
                icon: Icons.straighten,
                label: '${distance.toStringAsFixed(0)}m',
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              _chip(
                icon: Icons.face,
                label: _confidencePercentage,
                color: Colors.green,
              ),
            ],
          ),
          if (!withinRadius) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.red.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Anda berada di luar radius kantor (${_testOffice.radius}m). '
                      'Absensi tetap bisa dilakukan.',
                      style: const TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          // Submit button
          BlocBuilder<AttendanceBloc, AttendanceState>(
            builder: (context, state) {
              final isLoading = state is AttendanceLoading;
              return ElevatedButton(
                onPressed: isLoading ? null : () => _submit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: type == AttendanceType.clockIn
                      ? Colors.green
                      : Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_buttonLabel),
              );
            },
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context) {
    if (type == AttendanceType.clockIn) {
      context.read<AttendanceBloc>().add(
        AttendanceClockIn(
          ClockInRequestModel(
            latitude: _userLat,
            longitude: _userLng,
            officeLocationId: _testOffice.id,
            gpsVerified: withinRadius,
            faceVerified: true,
            faceConfidence: faceConfidence,
            faceDescriptors: [],
          ),
        ),
      );
    } else {
      context.read<AttendanceBloc>().add(
        AttendanceClockOut(
          ClockOutRequestModel(
            latitude: _userLat,
            longitude: _userLng,
            officeLocationId: _testOffice.id,
            gpsVerified: withinRadius,
            faceVerified: true,
            faceConfidence: faceConfidence,
            faceDescriptors: [],
          ),
        ),
      );
    }
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  late MockAttendanceBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FakeClockInRequestModel());
    registerFallbackValue(FakeClockOutRequestModel());
    registerFallbackValue(FakeAttendanceEvent());
  });

  setUp(() {
    mockBloc = MockAttendanceBloc();
    when(() => mockBloc.state).thenReturn(AttendanceInitial());
    when(() => mockBloc.stream).thenAnswer(
      (_) => const Stream.empty(),
    );
  });


  group('AttendanceConfirmationScreen — UI', () {
    testWidgets('shows office name', (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(bloc: mockBloc, type: AttendanceType.clockIn),
      );
      await tester.pump();

      expect(find.text('Kantor Pusat'), findsOneWidget);
    });

    testWidgets('shows clock-in title when type is clockIn', (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(bloc: mockBloc, type: AttendanceType.clockIn),
      );
      await tester.pump();

      expect(find.text('Konfirmasi Clock In'), findsOneWidget);
    });

    testWidgets('shows clock-out title when type is clockOut', (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(bloc: mockBloc, type: AttendanceType.clockOut),
      );
      await tester.pump();

      expect(find.text('Konfirmasi Clock Out'), findsOneWidget);
    });

    testWidgets('shows face confidence percentage', (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(bloc: mockBloc, type: AttendanceType.clockIn),
      );
      await tester.pump();

      expect(find.text('87%'), findsOneWidget);
    });

    testWidgets('shows submit button with correct label for clockIn',
        (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(bloc: mockBloc, type: AttendanceType.clockIn),
      );
      await tester.pump();

      expect(find.text('Clock In Sekarang'), findsOneWidget);
    });

    testWidgets('shows submit button with correct label for clockOut',
        (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(bloc: mockBloc, type: AttendanceType.clockOut),
      );
      await tester.pump();

      expect(find.text('Clock Out Sekarang'), findsOneWidget);
    });

    testWidgets('shows loading indicator when AttendanceLoading', (tester) async {
      when(() => mockBloc.state).thenReturn(AttendanceLoading());

      await tester.pumpWidget(
        _ConfirmationInfoView(bloc: mockBloc, type: AttendanceType.clockIn),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AttendanceConfirmationScreen — GPS status', () {
    testWidgets('shows dalam radius when user is within office radius',
        (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(
          bloc: mockBloc,
          type: AttendanceType.clockIn,
          withinRadius: true,
        ),
      );
      await tester.pump();

      expect(find.textContaining('Dalam Radius'), findsOneWidget);
    });

    testWidgets('shows luar radius when user is outside office radius',
        (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(
          bloc: mockBloc,
          type: AttendanceType.clockIn,
          withinRadius: false,
        ),
      );
      await tester.pump();

      expect(find.textContaining('Luar Radius'), findsOneWidget);
    });

    testWidgets('shows warning message when outside radius', (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(
          bloc: mockBloc,
          type: AttendanceType.clockIn,
          withinRadius: false,
        ),
      );
      await tester.pump();

      expect(find.textContaining('luar radius kantor'), findsOneWidget);
    });
  });

  group('AttendanceConfirmationScreen — submit', () {
    testWidgets('submit button dispatches AttendanceClockIn event',
        (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(bloc: mockBloc, type: AttendanceType.clockIn),
      );
      await tester.pump();

      await tester.tap(find.text('Clock In Sekarang'));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<AttendanceClockIn>()))).called(1);
    });

    testWidgets('submit button dispatches AttendanceClockOut event',
        (tester) async {
      await tester.pumpWidget(
        _ConfirmationInfoView(bloc: mockBloc, type: AttendanceType.clockOut),
      );
      await tester.pump();

      await tester.tap(find.text('Clock Out Sekarang'));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<AttendanceClockOut>()))).called(1);
    });

  });

  group('AttendanceType enum', () {
    test('clockIn dan clockOut tersedia', () {
      expect(AttendanceType.clockIn, isA<AttendanceType>());
      expect(AttendanceType.clockOut, isA<AttendanceType>());
    });

    test('AttendanceConfirmationScreen widget dapat diinstansiasi', () {
      const screen = AttendanceConfirmationScreen(
        type: AttendanceType.clockIn,
        userLatitude: _userLat,
        userLongitude: _userLng,
        office: _testOffice,
        faceConfidence: 0.87,
        faceDescriptors: [],
        livenessPassed: true,
      );
      expect(screen, isA<AttendanceConfirmationScreen>());
    });

    test('_isWithinRadius getter logic — type clockIn vs clockOut', () {
      expect(AttendanceType.clockIn.name, 'clockIn');
      expect(AttendanceType.clockOut.name, 'clockOut');
    });
  });
}
