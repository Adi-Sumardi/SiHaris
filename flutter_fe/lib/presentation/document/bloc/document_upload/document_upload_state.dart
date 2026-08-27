part of 'document_upload_bloc.dart';

abstract class DocumentUploadState extends Equatable {
  const DocumentUploadState();

  @override
  List<Object?> get props => [];
}

class DocumentUploadInitial extends DocumentUploadState {}

class DocumentUploadLoading extends DocumentUploadState {}

class DocumentUploadSuccess extends DocumentUploadState {
  final EmployeeDocumentModel document;

  const DocumentUploadSuccess(this.document);

  @override
  List<Object?> get props => [document];
}

class DocumentUploadError extends DocumentUploadState {
  final String message;

  const DocumentUploadError(this.message);

  @override
  List<Object?> get props => [message];
}
