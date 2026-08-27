part of 'document_action_bloc.dart';

abstract class DocumentActionState extends Equatable {
  const DocumentActionState();

  @override
  List<Object?> get props => [];
}

class DocumentActionInitial extends DocumentActionState {}

class DocumentActionLoading extends DocumentActionState {}

class DocumentActionDeleteSuccess extends DocumentActionState {
  final int id;

  const DocumentActionDeleteSuccess(this.id);

  @override
  List<Object?> get props => [id];
}

class DocumentActionError extends DocumentActionState {
  final String message;

  const DocumentActionError(this.message);

  @override
  List<Object?> get props => [message];
}
