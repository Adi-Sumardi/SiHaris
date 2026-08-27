part of 'document_list_bloc.dart';

abstract class DocumentListState extends Equatable {
  const DocumentListState();

  @override
  List<Object?> get props => [];
}

class DocumentListInitial extends DocumentListState {}

class DocumentListLoading extends DocumentListState {}

class DocumentListLoaded extends DocumentListState {
  final List<EmployeeDocumentModel> documents;
  final List<DocumentTypeModel> types;
  final String selectedType;
  final String searchQuery;

  const DocumentListLoaded({
    required this.documents,
    required this.types,
    this.selectedType = 'all',
    this.searchQuery = '',
  });

  DocumentListLoaded copyWith({
    List<EmployeeDocumentModel>? documents,
    List<DocumentTypeModel>? types,
    String? selectedType,
    String? searchQuery,
  }) {
    return DocumentListLoaded(
      documents: documents ?? this.documents,
      types: types ?? this.types,
      selectedType: selectedType ?? this.selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [documents, types, selectedType, searchQuery];
}

class DocumentListError extends DocumentListState {
  final String message;

  const DocumentListError(this.message);

  @override
  List<Object?> get props => [message];
}
