import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_enroll_request_model.dart';
import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_enroll/face_enroll_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_enroll/face_enroll_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_enroll/face_enroll_state.dart';
import '../../../mocks/mock_face_recognition_datasource.dart';

void main() {
  late FaceEnrollBloc bloc;
  late MockFaceRecognitionDatasource mockDatasource;

  final testDescriptors = List.generate(192, (i) => i * 0.01);
  final testRequest = FaceEnrollRequestModel(
    descriptors: testDescriptors,
    qualityScore: 0.9,
  );
  final testResponse = FaceEnrollResponseModel(
    enrolled: true,
    qualityScore: 0.9,
  );

  setUpAll(() {
    registerFallbackValue(FaceEnrollRequestModel(descriptors: []));
  });

  setUp(() {
    mockDatasource = MockFaceRecognitionDatasource();
    bloc = FaceEnrollBloc(datasource: mockDatasource);
  });

  tearDown(() => bloc.close());

  test('initial state should be FaceEnrollInitial', () {
    expect(bloc.state, isA<FaceEnrollInitial>());
  });

  group('SubmitFaceEnroll', () {
    blocTest<FaceEnrollBloc, FaceEnrollState>(
      'emits [Loading, Success] when enroll successful',
      build: () {
        when(() => mockDatasource.enroll(any()))
            .thenAnswer((_) async => Right(testResponse));
        return bloc;
      },
      act: (b) => b.add(SubmitFaceEnroll(request: testRequest)),
      expect: () => [
        isA<FaceEnrollLoading>(),
        isA<FaceEnrollSuccess>().having(
          (s) => s.response.enrolled,
          'enrolled',
          true,
        ),
      ],
      verify: (_) => verify(() => mockDatasource.enroll(any())).called(1),
    );

    blocTest<FaceEnrollBloc, FaceEnrollState>(
      'emits [Loading, Error] when enroll fails with server error',
      build: () {
        when(() => mockDatasource.enroll(any()))
            .thenAnswer((_) async => const Left('Server error'));
        return bloc;
      },
      act: (b) => b.add(SubmitFaceEnroll(request: testRequest)),
      expect: () => [
        isA<FaceEnrollLoading>(),
        isA<FaceEnrollError>().having(
          (s) => s.message,
          'message',
          'Server error',
        ),
      ],
    );

    blocTest<FaceEnrollBloc, FaceEnrollState>(
      'emits [Loading, Error] when Unauthenticated',
      build: () {
        when(() => mockDatasource.enroll(any()))
            .thenAnswer((_) async => const Left('Unauthenticated'));
        return bloc;
      },
      act: (b) => b.add(SubmitFaceEnroll(request: testRequest)),
      expect: () => [
        isA<FaceEnrollLoading>(),
        isA<FaceEnrollError>().having(
          (s) => s.message,
          'message',
          'Unauthenticated',
        ),
      ],
    );
  });

  group('ResetFaceEnroll', () {
    blocTest<FaceEnrollBloc, FaceEnrollState>(
      'emits [Initial] when reset dari Success state',
      build: () => bloc,
      seed: () => FaceEnrollSuccess(response: testResponse),
      act: (b) => b.add(ResetFaceEnroll()),
      expect: () => [isA<FaceEnrollInitial>()],
    );
  });
}
