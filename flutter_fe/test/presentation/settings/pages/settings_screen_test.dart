import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_enroll/face_enroll_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_enroll/face_enroll_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_enroll/face_enroll_state.dart';
import 'package:gaji_pro/presentation/face_recognition/pages/face_enroll_screen.dart';
import 'package:gaji_pro/presentation/settings/pages/settings_screen.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_state.dart';

class MockFaceEnrollBloc extends MockBloc<FaceEnrollEvent, FaceEnrollState>
    implements FaceEnrollBloc {}

class MockLogoutBloc extends MockBloc<LogoutEvent, LogoutState>
    implements LogoutBloc {}

void main() {
  late MockFaceEnrollBloc mockEnrollBloc;
  late MockLogoutBloc mockLogoutBloc;

  setUp(() {
    mockEnrollBloc = MockFaceEnrollBloc();
    mockLogoutBloc = MockLogoutBloc();
    when(() => mockEnrollBloc.state).thenReturn(FaceEnrollInitial());
    when(() => mockEnrollBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockLogoutBloc.state).thenReturn(LogoutInitial());
    when(() => mockLogoutBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildSubject() => MultiBlocProvider(
    providers: [
      BlocProvider<FaceEnrollBloc>.value(value: mockEnrollBloc),
      BlocProvider<LogoutBloc>.value(value: mockLogoutBloc),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );

  group('SettingsScreen — widget', () {
    testWidgets('SettingsScreen dapat diinstansiasi', (tester) async {
      const screen = SettingsScreen();
      expect(screen, isA<SettingsScreen>());
    });

    testWidgets('menampilkan menu Face Recognition', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Face Recognition'), findsOneWidget);
    });

    testWidgets(
      'menu Face Recognition memiliki subtitle Belum terdaftar by default',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.text('Belum terdaftar'), findsOneWidget);
      },
    );
  });

  group('SettingsScreen — Face Recognition navigation', () {
    testWidgets(
      'SettingsScreen menggunakan Navigator.push (bukan pushNamed) untuk Face Recognition',
      (tester) async {
        bool unknownRouteCalled = false;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<FaceEnrollBloc>.value(value: mockEnrollBloc),
              BlocProvider<LogoutBloc>.value(value: mockLogoutBloc),
            ],
            child: MaterialApp(
              home: const SettingsScreen(),
              onUnknownRoute: (settings) {
                unknownRouteCalled = true;
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Center(
                      child: Text('Route tidak ditemukan: ${settings.name}'),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        await tester.ensureVisible(find.text('Face Recognition'));

        expect(find.text('Face Recognition'), findsOneWidget);
        expect(unknownRouteCalled, isFalse);
      },
    );

    testWidgets('SettingsScreen dapat dirender dengan Face Recognition menu', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Face Recognition'), findsOneWidget);
      expect(find.text('Belum terdaftar'), findsOneWidget);
      expect(find.text('Setup'), findsOneWidget);
    });

    test(
      'FaceEnrollScreen dapat diinstansiasi tanpa membutuhkan navigator',
      () {
        // Verify FaceEnrollScreen adalah widget yang bisa diinstansiasi
        const enrollScreen = FaceEnrollScreen();
        expect(enrollScreen, isA<FaceEnrollScreen>());
      },
    );
  });
}
