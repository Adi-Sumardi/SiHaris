part of 'leave_list_bloc.dart';

abstract class LeaveListEvent {}

class GetLeaveList extends LeaveListEvent {
  final int page;
  final String? status;
  final int? year;

  GetLeaveList({this.page = 1, this.status, this.year});
}
