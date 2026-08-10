// RED test: EditProfileScreen
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/requests/update_profile_request_model.dart';
import 'package:gaji_pro/data/models/responses/auth_response_model.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_state.dart';
import 'package:gaji_pro/presentation/profile/bloc/update_profile/update_profile_bloc.dart';
import 'package:gaji_pro/presentation/profile/bloc/update_profile/update_profile_event.dart';
import 'package:gaji_pro/presentation/profile/bloc/update_profile/update_profile_state.dart';
import 'package:gaji_pro/presentation/profile/pages/edit_profile_screen.dart';

class MockUpdateProfileBloc
    extends MockBloc<UpdateProfileEvent, UpdateProfileState>
    implements UpdateProfileBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class FakeUpdateProfileEvent extends Fake implements UpdateProfileEvent {}

class FakeProfileEvent extends Fake implements ProfileEvent {}

final tUser = UserModel(
  id: 1,
  name: 'Ahmad Bahri',
  email: 'ahmad@example.com',
  employee: EmployeeModel(
    id: 1,
    employeeId: 'EMP001',
    fullName: 'Ahmad Bahri',
    firstName: 'Ahmad',
    lastName: 'Bahri',
    phone: '08123456789',
  ),
);

Widget buildTestWidget({
  required UpdateProfileBloc updateBloc,
  required ProfileBloc profileBloc,
  required UserModel user,
}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<UpdateProfileBloc>.value(value: updateBloc),
        BlocProvider<ProfileBloc>.value(value: profileBloc),
      ],
      child: EditProfileScreen(user: user),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUpdateProfileEvent());
    registerFallbackValue(FakeProfileEvent());
    registerFallbackValue(UpdateProfileRequestModel());
  });

  group('EditProfileScreen', () {
    late MockUpdateProfileBloc mockUpdateBloc;
    late MockProfileBloc mockProfileBloc;

    setUp(() {
      mockUpdateBloc = MockUpdateProfileBloc();
      mockProfileBloc = MockProfileBloc();
      when(() => mockUpdateBloc.state).thenReturn(UpdateProfileInitial());
      when(() => mockUpdateBloc.stream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockProfileBloc.state).thenReturn(ProfileInitial());
      when(() => mockProfileBloc.stream)
          .thenAnswer((_) => const Stream.empty());
    });

    testWidgets('EditProfileScreen dapat dirender', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        updateBloc: mockUpdateBloc,
        profileBloc: mockProfileBloc,
        user: tUser,
      ));
      await tester.pump();

      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('menampilkan field Nama Depan dengan nilai awal',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        updateBloc: mockUpdateBloc,
        profileBloc: mockProfileBloc,
        user: tUser,
      ));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Ahmad'), findsOneWidget);
    });

    testWidgets('menampilkan field Nama Belakang dengan nilai awal',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        updateBloc: mockUpdateBloc,
        profileBloc: mockProfileBloc,
        user: tUser,
      ));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Bahri'), findsOneWidget);
    });

    testWidgets('menampilkan field Telepon dengan nilai awal', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        updateBloc: mockUpdateBloc,
        profileBloc: mockProfileBloc,
        user: tUser,
      ));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, '08123456789'), findsOneWidget);
    });

    testWidgets('tombol Simpan ada di screen', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        updateBloc: mockUpdateBloc,
        profileBloc: mockProfileBloc,
        user: tUser,
      ));
      await tester.pump();

      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('tap Simpan dispatch SubmitUpdateProfile ke bloc',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        updateBloc: mockUpdateBloc,
        profileBloc: mockProfileBloc,
        user: tUser,
      ));
      await tester.pumpAndSettle();

      // Scroll to ensure Simpan button is visible
      await tester.ensureVisible(find.text('Simpan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));
      await tester.pump();

      verify(() => mockUpdateBloc.add(any<UpdateProfileEvent>())).called(1);
    });

    testWidgets(
        'saat UpdateProfileLoading, tombol Simpan menampilkan loading indicator',
        (tester) async {
      when(() => mockUpdateBloc.state).thenReturn(UpdateProfileLoading());

      await tester.pumpWidget(buildTestWidget(
        updateBloc: mockUpdateBloc,
        profileBloc: mockProfileBloc,
        user: tUser,
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
