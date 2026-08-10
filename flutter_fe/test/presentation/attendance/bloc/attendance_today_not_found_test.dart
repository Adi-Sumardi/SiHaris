/// Fix 9: AttendanceTodayBloc — tambah state AttendanceTodayNotFound
/// saat backend return 200 tapi data null (belum ada absensi hari ini)
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_today/attendance_today_bloc.dart';

class MockAttendanceRemoteDatasource extends Mock
    implements AttendanceRemoteDatasource {}

void main() {
  late AttendanceTodayBloc bloc;
  late MockAttendanceRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockAttendanceRemoteDatasource();
    bloc = AttendanceTodayBloc(datasource: mockDatasource);
  });

  tearDown(() => bloc.close());

  group('Fix 9: AttendanceTodayBloc — AttendanceTodayNotFound state', () {
    test('RED: AttendanceTodayNotFound state tersedia', () {
      // Verify state class bisa diinstansiasi
      final state = AttendanceTodayNotFound();
      expect(state, isA<AttendanceTodayState>());
    });

    test('AttendanceTodayNotFound equality benar', () {
      expect(AttendanceTodayNotFound(), equals(AttendanceTodayNotFound()));
    });

    blocTest<AttendanceTodayBloc, AttendanceTodayState>(
      'RED: emits AttendanceTodayNotFound ketika backend return Left dengan kode 404/not found',
      build: () {
        when(() => mockDatasource.getTodayAttendance())
            .thenAnswer((_) async => const Left('Data tidak ditemukan'));
        return bloc;
      },
      act: (bloc) => bloc.add(GetTodayStatus()),
      expect: () => [
        AttendanceTodayLoading(),
        // Seharusnya emit NotFound (bukan Error) untuk "Data tidak ditemukan"
        AttendanceTodayNotFound(),
      ],
    );

    blocTest<AttendanceTodayBloc, AttendanceTodayState>(
      'tetap emit AttendanceTodayError untuk error selain not found',
      build: () {
        when(() => mockDatasource.getTodayAttendance())
            .thenAnswer((_) async => const Left('Server error'));
        return bloc;
      },
      act: (bloc) => bloc.add(GetTodayStatus()),
      expect: () => [
        AttendanceTodayLoading(),
        const AttendanceTodayError('Server error'),
      ],
    );
  });
}
