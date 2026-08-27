part of 'document_list_bloc.dart';

abstract class DocumentListEvent extends Equatable {
  const DocumentListEvent();

  @override
  List<Object?> get props => [];
}

class GetDocuments extends DocumentListEvent {
  final String? type;
  final String? search;

  const GetDocuments({this.type, this.search});

  @override
  List<Object?> get props => [type, search];
}

class RefreshDocuments extends DocumentListEvent {
  final String? type;
  final String? search;

  const RefreshDocuments({this.type, this.search});

  @override
  List<Object?> get props => [type, search];
}

class FilterDocumentsByType extends DocumentListEvent {
  final String type;

  const FilterDocumentsByType(this.type);

  @override
  List<Object?> get props => [type];
}

class SearchDocuments extends DocumentListEvent {
  final String query;

  const SearchDocuments(this.query);

  @override
  List<Object?> get props => [query];
}
