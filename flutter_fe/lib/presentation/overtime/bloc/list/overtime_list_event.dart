import 'package:equatable/equatable.dart';

abstract class OvertimeListEvent extends Equatable {
  const OvertimeListEvent();

  @override
  List<Object?> get props => [];
}

class GetOvertimeList extends OvertimeListEvent {
  final String? status;
  final String? startDate;
  final String? endDate;

  const GetOvertimeList({this.status, this.startDate, this.endDate});

  @override
  List<Object?> get props => [status, startDate, endDate];
}

class LoadMoreOvertimeList extends OvertimeListEvent {
  final String? status;
  final String? startDate;
  final String? endDate;

  const LoadMoreOvertimeList({this.status, this.startDate, this.endDate});

  @override
  List<Object?> get props => [status, startDate, endDate];
}

class RefreshOvertimeList extends OvertimeListEvent {
  final String? status;
  final String? startDate;
  final String? endDate;

  const RefreshOvertimeList({this.status, this.startDate, this.endDate});

  @override
  List<Object?> get props => [status, startDate, endDate];
}
