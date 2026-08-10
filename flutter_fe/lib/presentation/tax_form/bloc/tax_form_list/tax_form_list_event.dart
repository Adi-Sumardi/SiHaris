part of 'tax_form_list_bloc.dart';

abstract class TaxFormListEvent {}

class GetTaxForms extends TaxFormListEvent {
  final int? year;

  GetTaxForms({this.year});
}

class GetTaxFormYears extends TaxFormListEvent {}

class RefreshTaxForms extends TaxFormListEvent {
  final int? year;

  RefreshTaxForms({this.year});
}
