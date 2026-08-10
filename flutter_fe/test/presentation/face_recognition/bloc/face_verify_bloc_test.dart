import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_verify_request_model.dart';
import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_state.dart';
import '../../../mocks/mock_face_recognition_datasource.dart';

void main() {
  late FaceVerifyBloc bloc;
  late MockFaceRecognitionDatasource mockDatasource;

  final testDescriptors = List.generate(192, (i) => i * 0.01);
  final testRequest = FaceVerifyRequestModel(
    descriptors: testDescriptors,
    verificationType: VerificationType.clockIn,
  );

  setUpAll(() {
    registerFallbackValue(FaceVerifyRequestModel(descriptors: []));
  });

  setUp(() {
    mockDatasource = MockFaceRecognitionDatasource();
    bloc = FaceVerifyBloc(datasource: mockDatasource);
  });

  tearDown(() => bloc.close());

  test('initial state should be FaceVerifyInitial', () {
    expect(bloc.state, isA<FaceVerifyInitial>());
  });

  group('VerifyFace', () {
    blocTest<FaceVerifyBloc, FaceVerifyState>(
      'emits [Loading, Matched] when face matches',
      build: () {
        when(() => mockDatasource.verify(any())).thenAnswer(
          (_) async => Right(FaceVerifyResponseModel(matched: true, confidence: 0.87)),
        );
        return bloc;
      },
      act: (b) => b.add(VerifyFace(request: testRequest)),
      expect: () => [
        isA<FaceVerifyLoading>(),
        isA<FaceVerifyMatched>().having(
          (s) => s.response.confidence,
          'confidence',
          0.87,
        ),
      ],
      verify: (_) => verify(() => mockDatasource.verify(any())).called(1),
    );

    blocTest<FaceVerifyBloc, FaceVerifyState>(
      'emits [Loading, NotMatched] when face does not match',
      build: () {
        when(() => mockDatasource.verify(any())).thenAnswer(
          (_) async => Right(FaceVerifyResponseModel(matched: false, confidence: 0.23)),
        );
        return bloc;
      },
      act: (b) => b.add(VerifyFace(request: testRequest)),
      expect: () => [
        isA<FaceVerifyLoading>(),
        isA<FaceVerifyNotMatched>().having(
          (s) => s.response.confidence,
          'confidence',
          0.23,
        ),
      ],
    );

    blocTest<FaceVerifyBloc, FaceVerifyState>(
      'emits [Loading, Error] on network error',
      build: () {
        when(() => mockDatasource.verify(any()))
            .thenAnswer((_) async => const Left('Terjadi kesalahan: No internet'));
        return bloc;
      },
      act: (b) => b.add(VerifyFace(request: testRequest)),
      expect: () => [
        isA<FaceVerifyLoading>(),
        isA<FaceVerifyError>().having(
          (s) => s.message,
          'message',
          contains('Terjadi kesalahan'),
        ),
      ],
    );

    blocTest<FaceVerifyBloc, FaceVerifyState>(
      'emits [Loading, Error] when Unauthenticated',
      build: () {
        when(() => mockDatasource.verify(any()))
            .thenAnswer((_) async => const Left('Unauthenticated'));
        return bloc;
      },
      act: (b) => b.add(VerifyFace(request: testRequest)),
      expect: () => [
        isA<FaceVerifyLoading>(),
        isA<FaceVerifyError>().having(
          (s) => s.message,
          'message',
          'Unauthenticated',
        ),
      ],
    );
  });

  group('ResetFaceVerify', () {
    blocTest<FaceVerifyBloc, FaceVerifyState>(
      'emits [Initial] when reset',
      build: () => bloc,
      seed: () => FaceVerifyMatched(
        response: FaceVerifyResponseModel(matched: true, confidence: 0.87),
      ),
      act: (b) => b.add(ResetFaceVerify()),
      expect: () => [isA<FaceVerifyInitial>()],
    );
  });
}
