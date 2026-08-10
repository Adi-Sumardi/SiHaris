part of 'tax_form_list_bloc.dart';

abstract class TaxFormListState {}

class TaxFormListInitial extends TaxFormListState {}

class TaxFormListLoading extends TaxFormListState {}

class TaxFormListLoaded extends TaxFormListState {
  final List<TaxFormModel> taxForms;
  final int? year;

  TaxFormListLoaded(this.taxForms, {this.year});
}

class TaxFormYearsLoaded extends TaxFormListState {
  final List<TaxFormYearModel> years;

  TaxFormYearsLoaded(this.years);
}

class TaxFormListError extends TaxFormListState {
  final String message;

  TaxFormListError(this.message);
}
