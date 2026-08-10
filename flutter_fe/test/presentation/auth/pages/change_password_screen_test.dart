import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/presentation/auth/pages/change_password_screen.dart';
import 'package:gaji_pro/presentation/auth/bloc/change_password/change_password_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/change_password/change_password_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/change_password/change_password_state.dart';

class MockChangePasswordBloc
    extends MockBloc<ChangePasswordEvent, ChangePasswordState>
    implements ChangePasswordBloc {}

class FakeChangePasswordEvent extends Fake implements ChangePasswordEvent {}

class FakeChangePasswordState extends Fake implements ChangePasswordState {}

void main() {
  late MockChangePasswordBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FakeChangePasswordEvent());
    registerFallbackValue(FakeChangePasswordState());
  });

  setUp(() {
    mockBloc = MockChangePasswordBloc();
    when(() => mockBloc.state).thenReturn(ChangePasswordInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<ChangePasswordBloc>.value(
        value: mockBloc,
        child: const ChangePasswordScreen(),
      ),
    );
  }

  group('ChangePasswordScreen', () {
    testWidgets('should render correctly with all fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Check title - appears in header and button
      expect(find.text('Ubah Password'), findsWidgets);

      // Check input fields
      expect(find.text('Password Saat Ini'), findsOneWidget);
      expect(find.text('Password Baru'), findsOneWidget);
      expect(find.text('Konfirmasi Password'), findsOneWidget);

      // Check we have 3 text form fields
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('should show validation error for empty fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap submit button without filling fields
      await tester.tap(find.widgetWithText(GestureDetector, 'Ubah Password').last);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Password saat ini harus diisi'), findsOneWidget);
    });

    testWidgets('should show validation error for short password', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill current password
      await tester.enterText(
        find.byType(TextFormField).first,
        'oldpassword',
      );

      // Fill short new password
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '12345',
      );

      // Fill confirm password
      await tester.enterText(
        find.byType(TextFormField).at(2),
        '12345',
      );

      // Tap submit
      await tester.tap(find.widgetWithText(GestureDetector, 'Ubah Password').last);
      await tester.pumpAndSettle();

      expect(find.text('Password minimal 6 karakter'), findsOneWidget);
    });

    testWidgets('should show validation error for mismatched passwords', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill current password
      await tester.enterText(
        find.byType(TextFormField).first,
        'oldpassword',
      );

      // Fill new password
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'newpassword123',
      );

      // Fill different confirm password
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'differentpassword',
      );

      // Tap submit
      await tester.tap(find.widgetWithText(GestureDetector, 'Ubah Password').last);
      await tester.pumpAndSettle();

      expect(find.text('Password tidak cocok'), findsOneWidget);
    });

    testWidgets('should dispatch event when form is valid', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill all fields correctly
      await tester.enterText(
        find.byType(TextFormField).first,
        'oldpassword123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'newpassword123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'newpassword123',
      );

      // Tap submit
      await tester.tap(find.widgetWithText(GestureDetector, 'Ubah Password').last);
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<ChangePasswordSubmitted>()))).called(1);
    });

    testWidgets('should show loading indicator when state is loading', (tester) async {
      when(() => mockBloc.state).thenReturn(ChangePasswordLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error snackbar on error state', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([
          ChangePasswordInitial(),
          ChangePasswordError('Gagal mengubah password'),
        ]),
        initialState: ChangePasswordInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Gagal mengubah password'), findsOneWidget);
    });

    testWidgets('should show success message on success state', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([
          ChangePasswordInitial(),
          ChangePasswordSuccess(),
        ]),
        initialState: ChangePasswordInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Process state change

      // SnackBar might not be visible immediately, just verify no error
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should have visibility toggle icons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Should have visibility off icons (passwords are hidden by default)
      expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);

      // Tap visibility icon to show password
      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pump();

      // Should show visibility icon (password now visible)
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should have back button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });
  });
}
