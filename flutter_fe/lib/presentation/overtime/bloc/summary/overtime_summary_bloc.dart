import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/responses/overtime_summary_model.dart';
import '../../../../data/datasources/overtime_remote_datasource.dart';

// Events
abstract class OvertimeSummaryEvent extends Equatable {
  const OvertimeSummaryEvent();

  @override
  List<Object?> get props => [];
}

class GetOvertimeSummary extends OvertimeSummaryEvent {
  final int month;
  final int year;

  const GetOvertimeSummary({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

// States
abstract class OvertimeSummaryState extends Equatable {
  const OvertimeSummaryState();

  @override
  List<Object?> get props => [];
}

class OvertimeSummaryInitial extends OvertimeSummaryState {}

class OvertimeSummaryLoading extends OvertimeSummaryState {}

class OvertimeSummaryLoaded extends OvertimeSummaryState {
  final OvertimeSummaryModel summary;

  const OvertimeSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class OvertimeSummaryError extends OvertimeSummaryState {
  final String message;

  const OvertimeSummaryError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class OvertimeSummaryBloc
    extends Bloc<OvertimeSummaryEvent, OvertimeSummaryState> {
  final OvertimeRemoteDatasource datasource;

  OvertimeSummaryBloc(this.datasource) : super(OvertimeSummaryInitial()) {
    on<GetOvertimeSummary>(_onGetOvertimeSummary);
  }

  Future<void> _onGetOvertimeSummary(
    GetOvertimeSummary event,
    Emitter<OvertimeSummaryState> emit,
  ) async {
    emit(OvertimeSummaryLoading());
    try {
      final result = await datasource.getOvertimeSummary(
        month: event.month,
        year: event.year,
      );
      emit(OvertimeSummaryLoaded(result));
    } catch (e) {
      emit(OvertimeSummaryError(e.toString()));
    }
  }
}
