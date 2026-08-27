import 'dart:developer' as developer;
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/employee_document_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/upload_document_request_model.dart';
import 'package:gaji_pro/data/models/responses/employee_document_model.dart';

part 'document_upload_event.dart';
part 'document_upload_state.dart';

class DocumentUploadBloc extends Bloc<DocumentUploadEvent, DocumentUploadState> {
  final EmployeeDocumentRemoteDatasource datasource;

  static const _tag = 'DocumentUploadBloc';

  DocumentUploadBloc({required this.datasource}) : super(DocumentUploadInitial()) {
    on<UploadDocument>(_onUploadDocument);
    on<ResetUploadDocument>(_onResetUploadDocument);
  }

  void _log(String message) {
    developer.log(message, name: _tag);
  }

  Future<void> _onUploadDocument(
    UploadDocument event,
    Emitter<DocumentUploadState> emit,
  ) async {
    _log('UploadDocument event: type=${event.request.documentType}, name=${event.request.documentName}');
    emit(DocumentUploadLoading());
    try {
      final document = await datasource.uploadDocument(
        event.request,
        event.file,
      );
      _log('Document uploaded successfully: ID=${document.id}');
      emit(DocumentUploadSuccess(document));
    } catch (e, stackTrace) {
      _log('Error: $e');
      _log('StackTrace: $stackTrace');
      emit(DocumentUploadError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onResetUploadDocument(
    ResetUploadDocument event,
    Emitter<DocumentUploadState> emit,
  ) {
    emit(DocumentUploadInitial());
  }
}
