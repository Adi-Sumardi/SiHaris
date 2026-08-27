part of 'document_upload_bloc.dart';

abstract class DocumentUploadEvent extends Equatable {
  const DocumentUploadEvent();

  @override
  List<Object?> get props => [];
}

class UploadDocument extends DocumentUploadEvent {
  final UploadDocumentRequestModel request;
  final File file;

  const UploadDocument({
    required this.request,
    required this.file,
  });

  @override
  List<Object?> get props => [request, file];
}

class ResetUploadDocument extends DocumentUploadEvent {}
