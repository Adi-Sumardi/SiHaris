import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/auth_datasource.dart';
import 'update_profile_event.dart';
import 'update_profile_state.dart';

class UpdateProfileBloc extends Bloc<UpdateProfileEvent, UpdateProfileState> {
  final AuthDatasource _datasource;

  UpdateProfileBloc({required AuthDatasource datasource})
      : _datasource = datasource,
        super(UpdateProfileInitial()) {
    on<SubmitUpdateProfile>(_onSubmit);
  }

  Future<void> _onSubmit(
    SubmitUpdateProfile event,
    Emitter<UpdateProfileState> emit,
  ) async {
    emit(UpdateProfileLoading());
    final result = await _datasource.updateProfile(event.request);
    result.fold(
      (error) => emit(UpdateProfileFailure(error)),
      (user) => emit(UpdateProfileSuccess(user)),
    );
  }
}
