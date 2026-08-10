import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_state.dart';
import '../../../mocks/mock_face_recognition_datasource.dart';

void main() {
  late FaceRecognitionStatusBloc bloc;
  late MockFaceRecognitionDatasource mockDatasource;

  final testStatus = FaceRecognitionStatusModel(
    enrolled: true,
    enrolledAt: '2026-02-17T10:00:00.000000Z',
    qualityScore: 0.85,
    companySettings: FaceRecognitionCompanySettings(
      faceRecognitionEnabled: true,
      livenessRequired: false,
      matchThreshold: 0.6,
    ),
  );

  setUp(() {
    mockDatasource = MockFaceRecognitionDatasource();
    bloc = FaceRecognitionStatusBloc(datasource: mockDatasource);
  });

  tearDown(() => bloc.close());

  test('initial state should be FaceRecognitionStatusInitial', () {
    expect(bloc.state, isA<FaceRecognitionStatusInitial>());
  });

  group('LoadFaceRecognitionStatus', () {
    blocTest<FaceRecognitionStatusBloc, FaceRecognitionStatusState>(
      'emits [Loading, Loaded] when successful',
      build: () {
        when(() => mockDatasource.getStatus())
            .thenAnswer((_) async => Right(testStatus));
        return bloc;
      },
      act: (b) => b.add(LoadFaceRecognitionStatus()),
      expect: () => [
        isA<FaceRecognitionStatusLoading>(),
        isA<FaceRecognitionStatusLoaded>().having(
          (s) => s.status.enrolled,
          'enrolled',
          true,
        ),
      ],
      verify: (_) => verify(() => mockDatasource.getStatus()).called(1),
    );

    blocTest<FaceRecognitionStatusBloc, FaceRecognitionStatusState>(
      'emits [Loading, Error] on network error',
      build: () {
        when(() => mockDatasource.getStatus())
            .thenAnswer((_) async => const Left('Terjadi kesalahan: No internet'));
        return bloc;
      },
      act: (b) => b.add(LoadFaceRecognitionStatus()),
      expect: () => [
        isA<FaceRecognitionStatusLoading>(),
        isA<FaceRecognitionStatusError>().having(
          (s) => s.message,
          'message',
          contains('Terjadi kesalahan'),
        ),
      ],
    );

    blocTest<FaceRecognitionStatusBloc, FaceRecognitionStatusState>(
      'emits [Loading, Error] on Unauthenticated',
      build: () {
        when(() => mockDatasource.getStatus())
            .thenAnswer((_) async => const Left('Unauthenticated'));
        return bloc;
      },
      act: (b) => b.add(LoadFaceRecognitionStatus()),
      expect: () => [
        isA<FaceRecognitionStatusLoading>(),
        isA<FaceRecognitionStatusError>().having(
          (s) => s.message,
          'message',
          'Unauthenticated',
        ),
      ],
    );
  });
}
