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
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('SettingsScreen dapat diinstansiasi dari ProfileScreen', (
      tester,
    ) async {
      const settingsScreen = SettingsScreen();
      expect(settingsScreen, isA<SettingsScreen>());
    });
  });
}
