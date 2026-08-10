import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/face_recognition_datasource.dart';
import 'face_recognition_status_event.dart';
import 'face_recognition_status_state.dart';

class FaceRecognitionStatusBloc
    extends Bloc<FaceRecognitionStatusEvent, FaceRecognitionStatusState> {
  final FaceRecognitionDatasource datasource;

  FaceRecognitionStatusBloc({required this.datasource})
      : super(FaceRecognitionStatusInitial()) {
    on<LoadFaceRecognitionStatus>(_onLoadStatus);
  }

  Future<void> _onLoadStatus(
    LoadFaceRecognitionStatus event,
    Emitter<FaceRecognitionStatusState> emit,
  ) async {
    emit(FaceRecognitionStatusLoading());
    final result = await datasource.getStatus();
    result.fold(
      (error) => emit(FaceRecognitionStatusError(error)),
      (status) => emit(FaceRecognitionStatusLoaded(status)),
    );
  }
}
