import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/utils/snackbar_utils.dart';
import 'package:gaji_pro/core/constants/colors.dart';

void main() {
  group('SnackbarUtils', () {
    testWidgets('showSuccess should display green snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showSuccess(context, 'Success message');
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Success message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.success);
    });

    testWidgets('showError should display red snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showError(context, 'Error message');
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Error message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.danger);
    });

    testWidgets('showWarning should display orange snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showWarning(context, 'Warning message');
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Warning message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.warning);
    });

    testWidgets('showInfo should display blue snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showInfo(context, 'Info message');
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Info message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.info);
    });

    testWidgets('showCustom should display snackbar with custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showCustom(
                      context,
                      message: 'Custom message',
                      backgroundColor: Colors.purple,
                      icon: Icons.star,
                    );
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Custom message'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.purple);
    });

    testWidgets('showSuccess should have check icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showSuccess(context, 'Success');
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('showError should have error icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showError(context, 'Error');
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('showWarning should have warning icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showWarning(context, 'Warning');
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('showInfo should have info icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showInfo(context, 'Info');
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.byIcon(Icons.info_rounded), findsOneWidget);
    });

    testWidgets('snackbar should have custom duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showSuccess(
                      context,
                      'Success',
                      duration: const Duration(seconds: 5),
                    );
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, const Duration(seconds: 5));
    });

    testWidgets('snackbar should have action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showSuccess(
                      context,
                      'Success',
                      actionLabel: 'UNDO',
                      onAction: () {},
                    );
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('UNDO'), findsOneWidget);
    });

    testWidgets('hide should dismiss current snackbar', (tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              savedContext = context;
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showSuccess(context, 'Success');
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);

      SnackbarUtils.hide(savedContext);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
