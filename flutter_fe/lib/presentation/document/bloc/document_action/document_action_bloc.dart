import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/employee_document_remote_datasource.dart';

part 'document_action_event.dart';
part 'document_action_state.dart';

class DocumentActionBloc extends Bloc<DocumentActionEvent, DocumentActionState> {
  final EmployeeDocumentRemoteDatasource datasource;

  static const _tag = 'DocumentActionBloc';

  DocumentActionBloc({required this.datasource}) : super(DocumentActionInitial()) {
    on<DeleteDocumentEvent>(_onDeleteDocument);
  }

  void _log(String message) {
    developer.log(message, name: _tag);
  }

  Future<void> _onDeleteDocument(
    DeleteDocumentEvent event,
    Emitter<DocumentActionState> emit,
  ) async {
    _log('DeleteDocument event: ID=${event.id}');
    emit(DocumentActionLoading());
    try {
      await datasource.deleteDocument(event.id);
      _log('Document deleted successfully: ID=${event.id}');
      emit(DocumentActionDeleteSuccess(event.id));
    } catch (e, stackTrace) {
      _log('Error: $e');
      _log('StackTrace: $stackTrace');
      emit(DocumentActionError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
