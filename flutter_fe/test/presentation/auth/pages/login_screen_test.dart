import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/presentation/auth/pages/login_screen.dart';
import 'package:gaji_pro/presentation/auth/bloc/login/login_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/login/login_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/login/login_state.dart';
import 'package:gaji_pro/core/components/widgets.dart';

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class FakeLoginEvent extends Fake implements LoginEvent {}

class FakeLoginState extends Fake implements LoginState {}

void main() {
  late MockLoginBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FakeLoginEvent());
    registerFallbackValue(FakeLoginState());
  });

  setUp(() {
    mockBloc = MockLoginBloc();
    when(() => mockBloc.state).thenReturn(LoginInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<LoginBloc>.value(
        value: mockBloc,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('should render correctly with all elements', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Check header elements
      expect(find.text('Selamat Datang!'), findsOneWidget);
      expect(find.text('Masuk ke akun SiHaris Anda'), findsOneWidget);

      // Check form fields & OTP action button
      expect(find.text('Nomor HP / Email / ID Karyawan'), findsOneWidget);
      expect(find.text('Kirim Kode OTP (WA / Email)'), findsOneWidget);
      expect(find.text('Atau Masuk dengan Password'), findsOneWidget);
    });

    testWidgets('should show validation error for empty input', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap OTP send button without filling input
      await tester.tap(find.text('Kirim Kode OTP (WA / Email)'));
      await tester.pumpAndSettle();

      expect(find.text('Nomor HP atau Email tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('should toggle password login mode', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap password login toggle
      await tester.tap(find.text('Atau Masuk dengan Password'));
      await tester.pumpAndSettle();

      // Check password field appears
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Masuk dengan Password'), findsOneWidget);
    });
  });
}
