import 'package:equatable/equatable.dart';
import '../../../../data/models/responses/overtime_model.dart';

abstract class OvertimeListState extends Equatable {
  const OvertimeListState();

  @override
  List<Object?> get props => [];
}

class OvertimeListInitial extends OvertimeListState {}

class OvertimeListLoading extends OvertimeListState {}

class OvertimeListLoaded extends OvertimeListState {
  final List<OvertimeModel> overtimes;
  final bool hasReachedMax;
  final int page;

  const OvertimeListLoaded({
    required this.overtimes,
    this.hasReachedMax = false,
    this.page = 1,
  });

  OvertimeListLoaded copyWith({
    List<OvertimeModel>? overtimes,
    bool? hasReachedMax,
    int? page,
  }) {
    return OvertimeListLoaded(
      overtimes: overtimes ?? this.overtimes,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [overtimes, hasReachedMax, page];
}

class OvertimeListError extends OvertimeListState {
  final String message;

  const OvertimeListError(this.message);

  @override
  List<Object?> get props => [message];
}
