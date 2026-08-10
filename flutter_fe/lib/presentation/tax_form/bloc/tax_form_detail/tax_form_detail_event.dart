part of 'tax_form_detail_bloc.dart';

abstract class TaxFormDetailEvent {}

class GetTaxFormDetail extends TaxFormDetailEvent {
  final int id;

  GetTaxFormDetail(this.id);
}

class DownloadTaxForm extends TaxFormDetailEvent {
  final int id;

  DownloadTaxForm(this.id);
}
