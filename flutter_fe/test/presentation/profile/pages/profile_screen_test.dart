// Fix 8 (updated): Profile screen settings icon — hubungkan ke SettingsScreen
// Profile screen now uses ProfileBloc, so tests need to provide it.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/auth_response_model.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_state.dart';
import 'package:gaji_pro/presentation/profile/pages/profile_screen.dart';
import 'package:gaji_pro/presentation/settings/pages/settings_screen.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_state.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_enroll/face_enroll_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_enroll/face_enroll_event.dart';
import 'package:gaji_pro/presentation/face_enrollment/pages/face_enrollment_screen.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_enroll/face_enroll_state.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockLogoutBloc extends MockBloc<LogoutEvent, LogoutState>
    implements LogoutBloc {}

class MockFaceEnrollBloc extends MockBloc<FaceEnrollEvent, FaceEnrollState>
    implements FaceEnrollBloc {}

class FakeProfileEvent extends Fake implements ProfileEvent {}

Widget buildWithBloc(
  ProfileBloc profileBloc, {
  LogoutBloc? logoutBloc,
  FaceEnrollBloc? faceEnrollBloc,
}) {
  final mockLogout = logoutBloc ?? MockLogoutBloc();
  final mockFaceEnroll = faceEnrollBloc ?? MockFaceEnrollBloc();

  // Setup defaults for mocks if not provided
  if (logoutBloc == null) {
    when(() => mockLogout.state).thenReturn(LogoutInitial());
    when(() => mockLogout.stream).thenAnswer((_) => const Stream.empty());
  }
  if (faceEnrollBloc == null) {
    when(() => mockFaceEnroll.state).thenReturn(FaceEnrollInitial());
    when(() => mockFaceEnroll.stream).thenAnswer((_) => const Stream.empty());
  }

  return MultiBlocProvider(
    providers: [
      BlocProvider<ProfileBloc>.value(value: profileBloc),
      BlocProvider<LogoutBloc>.value(value: mockLogout),
      BlocProvider<FaceEnrollBloc>.value(value: mockFaceEnroll),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProfileEvent());
  });

  group('Fix 8: ProfileScreen — settings icon navigasi ke SettingsScreen', () {
    late MockProfileBloc mockBloc;

    final loadedUser = UserModel(
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
    );

    setUp(() {
      mockBloc = MockProfileBloc();
    });

    testWidgets('ProfileScreen dapat dirender', (tester) async {
      when(() => mockBloc.state).thenReturn(ProfileInitial());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(buildWithBloc(mockBloc));
      await tester.pump();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('settings icon ada di ProfileScreen header', (tester) async {
      when(() => mockBloc.state).thenReturn(ProfileLoaded(loadedUser));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(buildWithBloc(mockBloc));
      await tester.pump();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('tap settings icon membuka SettingsScreen', (tester) async {
      when(() => mockBloc.state).thenReturn(ProfileLoaded(loadedUser));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(buildWithBloc(mockBloc));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('menampilkan PIN mesin fingerprint dan ID karyawan pada profile', (tester) async {
      final userWithPin = UserModel(
        id: 1,
        name: 'Adi Sumardi',
        email: 'adi@example.com',
        employee: EmployeeModel(
          id: 10,
          employeeId: 'EMP001',
          pin: '1032',
          nik: '3175012345670001',
          fullName: 'Adi Sumardi',
          department: 'Engineering',
          position: 'Software Engineer',
          faceEnrolled: false,
        ),
      );

      when(() => mockBloc.state).thenReturn(ProfileLoaded(userWithPin));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(buildWithBloc(mockBloc));
      await tester.pump();

      expect(find.text('PIN Mesin'), findsOneWidget);
      expect(find.text('PIN Mesin Fingerprint'), findsOneWidget);
      expect(find.text('1032'), findsNWidgets(2));
      expect(find.text('Pendaftaran Wajah'), findsOneWidget);
      expect(find.text('Daftarkan Wajah Sekarang'), findsOneWidget);
    });

    testWidgets('tap daftarkan wajah membuka FaceEnrollmentScreen', (tester) async {
      final userWithPin = UserModel(
        id: 1,
        name: 'Adi Sumardi',
        email: 'adi@example.com',
        employee: EmployeeModel(
          id: 10,
          employeeId: 'EMP001',
          pin: '1032',
          fullName: 'Adi Sumardi',
          faceEnrolled: false,
        ),
      );

      when(() => mockBloc.state).thenReturn(ProfileLoaded(userWithPin));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(buildWithBloc(mockBloc));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Daftarkan Wajah Sekarang'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      await tester.tap(find.text('Daftarkan Wajah Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FaceEnrollmentScreen), findsOneWidget);
    });

    testWidgets('jika wajah sudah terdaftar, tombol daftar ulang tidak muncul dan ada info hubungi admin', (tester) async {
      final userEnrolled = UserModel(
        id: 1,
        name: 'Adi Sumardi',
        email: 'adi@example.com',
        employee: EmployeeModel(
          id: 10,
          employeeId: 'EMP001',
          pin: '1032',
          fullName: 'Adi Sumardi',
          faceEnrolled: true,
        ),
      );

      when(() => mockBloc.state).thenReturn(ProfileLoaded(userEnrolled));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(buildWithBloc(mockBloc));
      await tester.pump();

      expect(find.text('Daftarkan Wajah Sekarang'), findsNothing);
      expect(find.text('Daftarkan Ulang Wajah'), findsNothing);
      expect(find.text('Perlu daftar ulang wajah? Hubungi Admin'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Perlu daftar ulang wajah? Hubungi Admin'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      await tester.tap(find.text('Perlu daftar ulang wajah? Hubungi Admin'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ajukan Reset Wajah'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);
    });
  });
}
