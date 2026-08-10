import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/auth_remote_datasource.dart';
import 'delete_account_event.dart';
import 'delete_account_state.dart';

class DeleteAccountBloc extends Bloc<DeleteAccountEvent, DeleteAccountState> {
  final AuthRemoteDatasource _datasource;

  DeleteAccountBloc({AuthRemoteDatasource? datasource})
      : _datasource = datasource ?? AuthRemoteDatasource(),
        super(const DeleteAccountInitial()) {
    on<DeleteAccountSubmit>(_onDeleteAccount);
    on<DeleteAccountReset>(_onReset);
  }

  Future<void> _onDeleteAccount(
    DeleteAccountSubmit event,
    Emitter<DeleteAccountState> emit,
  ) async {
    emit(const DeleteAccountLoading());

    final result = await _datasource.deleteAccount(
      password: event.password,
      confirmation: 'HAPUS AKUN',
      reason: event.reason,
    );

    result.fold(
      (error) => emit(DeleteAccountError(error)),
      (_) => emit(const DeleteAccountSuccess(
        'Akun Anda berhasil dihapus. Anda dapat mengaktifkan kembali akun dalam 30 hari dengan menghubungi admin.',
      )),
    );
  }

  void _onReset(
    DeleteAccountReset event,
    Emitter<DeleteAccountState> emit,
  ) {
    emit(const DeleteAccountInitial());
  }
}
