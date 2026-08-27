part of 'document_action_bloc.dart';

abstract class DocumentActionEvent extends Equatable {
  const DocumentActionEvent();

  @override
  List<Object?> get props => [];
}

class DeleteDocumentEvent extends DocumentActionEvent {
  final int id;

  const DeleteDocumentEvent(this.id);

  @override
  List<Object?> get props => [id];
}
