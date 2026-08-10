import 'package:equatable/equatable.dart';
import '../../../../data/models/requests/overtime_request_model.dart';
import '../../../../data/datasources/overtime_remote_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class OvertimeActionEvent extends Equatable {
  const OvertimeActionEvent();

  @override
  List<Object?> get props => [];
}

class CreateOvertime extends OvertimeActionEvent {
  final OvertimeRequestModel request;

  const CreateOvertime(this.request);

  @override
  List<Object?> get props => [request];
}

class CancelOvertime extends OvertimeActionEvent {
  final int id;

  const CancelOvertime(this.id);

  @override
  List<Object?> get props => [id];
}

// States
abstract class OvertimeActionState extends Equatable {
  const OvertimeActionState();

  @override
  List<Object?> get props => [];
}

class OvertimeActionInitial extends OvertimeActionState {}

class OvertimeActionLoading extends OvertimeActionState {}

class OvertimeActionSuccess extends OvertimeActionState {
  final String message;

  const OvertimeActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class OvertimeActionFailure extends OvertimeActionState {
  final String message;

  const OvertimeActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class OvertimeActionBloc
    extends Bloc<OvertimeActionEvent, OvertimeActionState> {
  final OvertimeRemoteDatasource datasource;

  OvertimeActionBloc(this.datasource) : super(OvertimeActionInitial()) {
    on<CreateOvertime>(_onCreateOvertime);
    on<CancelOvertime>(_onCancelOvertime);
  }

  Future<void> _onCreateOvertime(
    CreateOvertime event,
    Emitter<OvertimeActionState> emit,
  ) async {
    emit(OvertimeActionLoading());
    try {
      await datasource.createOvertime(event.request);
      emit(const OvertimeActionSuccess('Permintaan lembur berhasil dibuat'));
    } catch (e) {
      emit(OvertimeActionFailure(e.toString()));
    }
  }

  Future<void> _onCancelOvertime(
    CancelOvertime event,
    Emitter<OvertimeActionState> emit,
  ) async {
    emit(OvertimeActionLoading());
    try {
      await datasource.cancelOvertime(event.id);
      emit(
        const OvertimeActionSuccess('Permintaan lembur berhasil dibatalkan'),
      );
    } catch (e) {
      emit(OvertimeActionFailure(e.toString()));
    }
  }
}
