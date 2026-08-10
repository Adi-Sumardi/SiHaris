import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/auth_datasource.dart';
import '../../../../data/datasources/auth_remote_datasource.dart';
import 'change_password_event.dart';
import 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final AuthDatasource _authDatasource;

  ChangePasswordBloc({
    AuthDatasource? authDatasource,
  })  : _authDatasource = authDatasource ?? AuthRemoteDatasource(),
        super(ChangePasswordInitial()) {
    on<ChangePasswordSubmitted>(_onChangePasswordSubmitted);
    on<ChangePasswordReset>(_onChangePasswordReset);
  }

  Future<void> _onChangePasswordSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(ChangePasswordLoading());

    final result = await _authDatasource.changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
      confirmPassword: event.confirmPassword,
    );

    result.fold(
      (error) => emit(ChangePasswordError(error)),
      (success) => emit(ChangePasswordSuccess()),
    );
  }

  void _onChangePasswordReset(
    ChangePasswordReset event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(ChangePasswordInitial());
  }
}
