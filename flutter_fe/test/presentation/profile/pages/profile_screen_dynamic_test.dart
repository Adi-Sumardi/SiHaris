// RED test: ProfileScreen dinamis dari ProfileBloc
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/auth_response_model.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_state.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_state.dart';
import 'package:gaji_pro/presentation/profile/pages/profile_screen.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockLogoutBloc extends MockBloc<LogoutEvent, LogoutState>
    implements LogoutBloc {}

class FakeProfileEvent extends Fake implements ProfileEvent {}

final tUser = UserModel(
  id: 1,
  name: 'Ahmad Bahri',
  email: 'ahmad@example.com',
  employee: EmployeeModel(
    id: 1,
    employeeId: 'EMP001',
    fullName: 'Ahmad Bahri',
    department: 'Engineering',
    position: 'Senior Developer',
    phone: '08123456789',
    faceEnrolled: true,
  ),
);

Widget buildTestWidget(ProfileBloc bloc) {
  final logoutBloc = MockLogoutBloc();
  when(() => logoutBloc.state).thenReturn(LogoutInitial());
  when(() => logoutBloc.stream).thenAnswer((_) => const Stream.empty());

  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<ProfileBloc>.value(value: bloc),
        BlocProvider<LogoutBloc>.value(value: logoutBloc),
      ],
      child: const ProfileScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProfileEvent());
  });

  group('ProfileScreen dinamis', () {
    late MockProfileBloc mockBloc;

    setUp(() {
      mockBloc = MockProfileBloc();
    });

    testWidgets('dispatch GetProfile saat init', (tester) async {
      when(() => mockBloc.state).thenReturn(ProfileInitial());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      verify(() => mockBloc.add(any<ProfileEvent>())).called(1);
    });

    testWidgets('saat ProfileLoading, tampilkan CircularProgressIndicator',
        (tester) async {
      when(() => mockBloc.state).thenReturn(ProfileLoading());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('saat ProfileLoaded, tampilkan nama user', (tester) async {
      when(() => mockBloc.state).thenReturn(ProfileLoaded(tUser));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      expect(find.text('Ahmad Bahri'), findsAtLeastNWidgets(1));
    });

    testWidgets('saat ProfileLoaded, tampilkan email user', (tester) async {
      when(() => mockBloc.state).thenReturn(ProfileLoaded(tUser));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      expect(find.text('ahmad@example.com'), findsOneWidget);
    });

    testWidgets('saat ProfileLoaded, tampilkan posisi dari employee',
        (tester) async {
      when(() => mockBloc.state).thenReturn(ProfileLoaded(tUser));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      expect(find.text('Senior Developer'), findsAtLeastNWidgets(1));
    });

    testWidgets('saat ProfileError, tampilkan pesan error dan tombol retry',
        (tester) async {
      when(() => mockBloc.state)
          .thenReturn(ProfileError('Gagal memuat profil'));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      expect(find.text('Gagal memuat profil'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });
}
