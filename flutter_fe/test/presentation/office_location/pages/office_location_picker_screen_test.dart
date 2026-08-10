// RED tests: OfficeLocationPickerScreen
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_bloc.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_event.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_state.dart';
import 'package:gaji_pro/presentation/office_location/pages/office_location_picker_screen.dart';

class MockOfficeLocationBloc
    extends MockBloc<OfficeLocationEvent, OfficeLocationState>
    implements OfficeLocationBloc {}

class FakeOfficeLocationEvent extends Fake implements OfficeLocationEvent {}

const tOffice1 = OfficeLocationModel(
  id: 1,
  name: 'Kantor Pusat',
  address: 'Jl. Sudirman No.1',
  city: 'Jakarta',
  latitude: -6.2,
  longitude: 106.8,
  radius: 100,
  isPrimary: true,
);

const tOffice2 = OfficeLocationModel(
  id: 2,
  name: 'Kantor Cabang Bandung',
  address: 'Jl. Asia Afrika No.5',
  city: 'Bandung',
  latitude: -6.9,
  longitude: 107.6,
  radius: 150,
  isPrimary: false,
);

Widget buildTestWidget(OfficeLocationBloc bloc) {
  return MaterialApp(
    home: BlocProvider<OfficeLocationBloc>.value(
      value: bloc,
      child: const OfficeLocationPickerScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOfficeLocationEvent());
  });

  group('OfficeLocationPickerScreen', () {
    late MockOfficeLocationBloc mockBloc;

    setUp(() {
      mockBloc = MockOfficeLocationBloc();
    });

    testWidgets('saat Loading, tampilkan CircularProgressIndicator',
        (tester) async {
      when(() => mockBloc.state).thenReturn(OfficeLocationLoading());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('saat Loaded, tampilkan daftar offices', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(OfficeLocationLoaded(const [tOffice1, tOffice2]));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      expect(find.text('Kantor Pusat'), findsOneWidget);
      expect(find.text('Kantor Cabang Bandung'), findsOneWidget);
    });

    testWidgets('office utama tampilkan badge "Utama"', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(OfficeLocationLoaded(const [tOffice1, tOffice2]));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      expect(find.text('Utama'), findsOneWidget);
    });

    testWidgets('saat Error, tampilkan pesan error', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(OfficeLocationError('Gagal memuat data'));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      expect(find.text('Gagal memuat data'), findsOneWidget);
    });

    testWidgets('dispatch GetAssignedOffices saat init', (tester) async {
      when(() => mockBloc.state).thenReturn(OfficeLocationInitial());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestWidget(mockBloc));
      await tester.pump();

      verify(() => mockBloc.add(any<OfficeLocationEvent>())).called(1);
    });
  });
}
