import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/auth_datasource.dart';
import '../../../../data/datasources/auth_remote_datasource.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthDatasource _authDatasource;

  RegisterBloc({
    AuthDatasource? authDatasource,
  })  : _authDatasource = authDatasource ?? AuthRemoteDatasource(),
        super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<RegisterReset>(_onRegisterReset);
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    // Validate request
    final validationError = event.request.validate();
    if (validationError != null) {
      emit(RegisterError(validationError));
      return;
    }

    emit(RegisterLoading());

    final result = await _authDatasource.demoRegister(event.request);

    result.fold(
      (error) => emit(RegisterError(error)),
      (response) {
        if (response.success) {
          emit(RegisterSuccess(
            email: response.email ?? event.request.email,
            name: response.name,
            message: response.message ?? 'Registrasi berhasil!',
          ));
        } else {
          emit(RegisterError(response.message ?? 'Registrasi gagal'));
        }
      },
    );
  }

  void _onRegisterReset(
    RegisterReset event,
    Emitter<RegisterState> emit,
  ) {
    emit(RegisterInitial());
  }
}
