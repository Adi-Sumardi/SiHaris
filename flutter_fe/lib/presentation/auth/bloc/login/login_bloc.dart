import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/auth_datasource.dart';
import '../../../../data/datasources/auth_remote_datasource.dart';
import '../../../../data/datasources/auth_local_datasource.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthDatasource _authDatasource;
  final AuthLocalDatasourceBase _localDatasource;

  LoginBloc({
    AuthDatasource? authDatasource,
    AuthLocalDatasourceBase? localDatasource,
  })  : _authDatasource = authDatasource ?? AuthRemoteDatasource(),
        _localDatasource = localDatasource ?? AuthLocalDatasource(),
        super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginReset>(_onLoginReset);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    final result = await _authDatasource.login(
      event.identifier,
      event.password,
    );

    await result.fold(
      (error) async => emit(LoginError(error)),
      (authResponse) async {
        if (authResponse.success && authResponse.token != null) {
          await _localDatasource.saveAuthData(authResponse);
          emit(LoginSuccess());
        } else {
          emit(LoginError(authResponse.message ?? 'Login gagal'));
        }
      },
    );
  }

  void _onLoginReset(
    LoginReset event,
    Emitter<LoginState> emit,
  ) {
    emit(LoginInitial());
  }
}
