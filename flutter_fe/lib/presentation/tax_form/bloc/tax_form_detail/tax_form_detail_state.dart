part of 'tax_form_detail_bloc.dart';

abstract class TaxFormDetailState {}

class TaxFormDetailInitial extends TaxFormDetailState {}

class TaxFormDetailLoading extends TaxFormDetailState {}

class TaxFormDetailLoaded extends TaxFormDetailState {
  final TaxFormDetailModel taxForm;

  TaxFormDetailLoaded(this.taxForm);
}

class TaxFormDetailError extends TaxFormDetailState {
  final String message;

  TaxFormDetailError(this.message);
}

class TaxFormDownloading extends TaxFormDetailState {}

class TaxFormDownloadReady extends TaxFormDetailState {
  final TaxFormDownloadModel download;

  TaxFormDownloadReady(this.download);
}

class TaxFormDownloadError extends TaxFormDetailState {
  final String message;

  TaxFormDownloadError(this.message);
}
