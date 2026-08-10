import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/face_recognition_datasource.dart';
import 'face_enroll_event.dart';
import 'face_enroll_state.dart';

class FaceEnrollBloc extends Bloc<FaceEnrollEvent, FaceEnrollState> {
  final FaceRecognitionDatasource datasource;

  FaceEnrollBloc({required this.datasource}) : super(FaceEnrollInitial()) {
    on<SubmitFaceEnroll>(_onSubmit);
    on<ResetFaceEnroll>(_onReset);
  }

  Future<void> _onSubmit(
    SubmitFaceEnroll event,
    Emitter<FaceEnrollState> emit,
  ) async {
    emit(FaceEnrollLoading());
    final result = await datasource.enroll(event.request);
    result.fold(
      (error) => emit(FaceEnrollError(error)),
      (response) => emit(FaceEnrollSuccess(response: response)),
    );
  }

  void _onReset(ResetFaceEnroll event, Emitter<FaceEnrollState> emit) {
    emit(FaceEnrollInitial());
  }
}
