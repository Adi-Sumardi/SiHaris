import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/face_recognition_datasource.dart';
import 'face_verify_event.dart';
import 'face_verify_state.dart';

class FaceVerifyBloc extends Bloc<FaceVerifyEvent, FaceVerifyState> {
  final FaceRecognitionDatasource datasource;

  FaceVerifyBloc({required this.datasource}) : super(FaceVerifyInitial()) {
    on<VerifyFace>(_onVerify);
    on<ResetFaceVerify>(_onReset);
  }

  Future<void> _onVerify(
    VerifyFace event,
    Emitter<FaceVerifyState> emit,
  ) async {
    emit(FaceVerifyLoading());
    final result = await datasource.verify(event.request);
    result.fold(
      (error) => emit(FaceVerifyError(error)),
      (response) {
        if (response.matched) {
          emit(FaceVerifyMatched(response: response));
        } else {
          emit(FaceVerifyNotMatched(response: response));
        }
      },
    );
  }

  void _onReset(ResetFaceVerify event, Emitter<FaceVerifyState> emit) {
    emit(FaceVerifyInitial());
  }
}
