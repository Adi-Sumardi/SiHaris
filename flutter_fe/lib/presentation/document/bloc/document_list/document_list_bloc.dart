import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/core/utils/error_parser.dart';
import 'package:gaji_pro/data/datasources/employee_document_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/employee_document_model.dart';

part 'document_list_event.dart';
part 'document_list_state.dart';

class DocumentListBloc extends Bloc<DocumentListEvent, DocumentListState> {
  final EmployeeDocumentRemoteDatasource datasource;

  static const _tag = 'DocumentListBloc';

  List<DocumentTypeModel> _cachedTypes = [];

  DocumentListBloc({required this.datasource}) : super(DocumentListInitial()) {
    on<GetDocuments>(_onGetDocuments);
    on<RefreshDocuments>(_onRefreshDocuments);
    on<FilterDocumentsByType>(_onFilterDocumentsByType);
    on<SearchDocuments>(_onSearchDocuments);
  }

  void _log(String message) {
    developer.log(message, name: _tag);
  }

  Future<void> _ensureTypesLoaded() async {
    if (_cachedTypes.isEmpty) {
      try {
        _cachedTypes = await datasource.getDocumentTypes();
      } catch (e) {
        _log('Error loading document types: $e');
      }
    }
  }

  Future<void> _onGetDocuments(
    GetDocuments event,
    Emitter<DocumentListState> emit,
  ) async {
    _log('GetDocuments event: type=${event.type}, search=${event.search}');
    emit(DocumentListLoading());
    try {
      await _ensureTypesLoaded();
      final docs = await datasource.getDocuments(
        type: event.type,
        search: event.search,
      );
      _log('Loaded ${docs.length} documents');
      emit(DocumentListLoaded(
        documents: docs,
        types: _cachedTypes,
        selectedType: event.type ?? 'all',
        searchQuery: event.search ?? '',
      ));
    } catch (e, stackTrace) {
      _log('Error: $e');
      _log('StackTrace: $stackTrace');
      emit(DocumentListError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshDocuments(
    RefreshDocuments event,
    Emitter<DocumentListState> emit,
  ) async {
    final currentType = state is DocumentListLoaded
        ? (state as DocumentListLoaded).selectedType
        : event.type ?? 'all';
    final currentSearch = state is DocumentListLoaded
        ? (state as DocumentListLoaded).searchQuery
        : event.search ?? '';

    try {
      await _ensureTypesLoaded();
      final docs = await datasource.getDocuments(
        type: currentType,
        search: currentSearch,
      );
      emit(DocumentListLoaded(
        documents: docs,
        types: _cachedTypes,
        selectedType: currentType,
        searchQuery: currentSearch,
      ));
    } catch (e) {
      emit(DocumentListError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFilterDocumentsByType(
    FilterDocumentsByType event,
    Emitter<DocumentListState> emit,
  ) async {
    final currentSearch = state is DocumentListLoaded
        ? (state as DocumentListLoaded).searchQuery
        : '';
    emit(DocumentListLoading());
    try {
      await _ensureTypesLoaded();
      final docs = await datasource.getDocuments(
        type: event.type,
        search: currentSearch,
      );
      emit(DocumentListLoaded(
        documents: docs,
        types: _cachedTypes,
        selectedType: event.type,
        searchQuery: currentSearch,
      ));
    } catch (e) {
      emit(DocumentListError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchDocuments(
    SearchDocuments event,
    Emitter<DocumentListState> emit,
  ) async {
    final currentType = state is DocumentListLoaded
        ? (state as DocumentListLoaded).selectedType
        : 'all';
    emit(DocumentListLoading());
    try {
      await _ensureTypesLoaded();
      final docs = await datasource.getDocuments(
        type: currentType,
        search: event.query,
      );
      emit(DocumentListLoaded(
        documents: docs,
        types: _cachedTypes,
        selectedType: currentType,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(DocumentListError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
