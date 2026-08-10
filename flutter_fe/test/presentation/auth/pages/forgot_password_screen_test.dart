import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/presentation/auth/pages/forgot_password_screen.dart';
import 'package:gaji_pro/core/components/widgets.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: ForgotPasswordScreen(),
    );
  }

  group('ForgotPasswordScreen', () {
    testWidgets('should render title and form elements', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Lupa Password'), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Kirim Link Reset'), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Kirim Link Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(JagoTextField), 'invalidemail');
      await tester.tap(find.text('Kirim Link Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Email tidak valid'), findsOneWidget);
    });

    testWidgets('should show loading state when submitting', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(JagoTextField), 'test@example.com');
      await tester.tap(find.text('Kirim Link Reset'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for timer to complete to avoid pending timer error
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('should show success content after submit', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(JagoTextField), 'test@example.com');
      await tester.tap(find.text('Kirim Link Reset'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Email Terkirim!'), findsOneWidget);
      expect(find.text('Kirim ulang'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('should go back to form when resend is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(JagoTextField), 'test@example.com');
      await tester.tap(find.text('Kirim Link Reset'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Email Terkirim!'), findsOneWidget);

      await tester.tap(find.text('Kirim ulang'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byType(JagoTextField), findsOneWidget);
    });

    testWidgets('should have email text field', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(JagoTextField), findsOneWidget);
    });

    testWidgets('should have JagoAppBar', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(JagoAppBar), findsOneWidget);
    });
  });
}
