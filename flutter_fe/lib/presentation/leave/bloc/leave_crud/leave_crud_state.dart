part of 'leave_crud_bloc.dart';

abstract class LeaveCrudState {
  const LeaveCrudState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveCrudState && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class LeaveCrudInitial extends LeaveCrudState {}

class LeaveCrudLoading extends LeaveCrudState {}

class LeaveCrudSuccess extends LeaveCrudState {
  final String message;

  const LeaveCrudSuccess(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveCrudSuccess && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class LeaveCrudFailure extends LeaveCrudState {
  final String message;

  const LeaveCrudFailure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveCrudFailure && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
