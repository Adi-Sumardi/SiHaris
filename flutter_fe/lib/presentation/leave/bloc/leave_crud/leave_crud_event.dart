part of 'leave_crud_bloc.dart';

abstract class LeaveCrudEvent {}

class CreateLeave extends LeaveCrudEvent {
  final LeaveRequestModel request;

  CreateLeave(this.request);
}

class CancelLeave extends LeaveCrudEvent {
  final int id;
  final String? reason;

  CancelLeave(this.id, this.reason);
}
