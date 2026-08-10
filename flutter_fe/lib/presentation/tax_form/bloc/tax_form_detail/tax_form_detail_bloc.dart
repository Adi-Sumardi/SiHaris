import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/tax_form_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/tax_form_detail_model.dart';

part 'tax_form_detail_event.dart';
part 'tax_form_detail_state.dart';

class TaxFormDetailBloc extends Bloc<TaxFormDetailEvent, TaxFormDetailState> {
  final TaxFormRemoteDatasource datasource;

  static const _tag = 'TaxFormDetailBloc';

  TaxFormDetailBloc({required this.datasource}) : super(TaxFormDetailInitial()) {
    on<GetTaxFormDetail>(_onGetTaxFormDetail);
    on<DownloadTaxForm>(_onDownloadTaxForm);
  }

  void _log(String message) {
    developer.log(message, name: _tag);
  }

  Future<void> _onGetTaxFormDetail(
    GetTaxFormDetail event,
    Emitter<TaxFormDetailState> emit,
  ) async {
    _log('GetTaxFormDetail event: id=${event.id}');
    emit(TaxFormDetailLoading());
    try {
      final taxForm = await datasource.getTaxFormDetail(event.id);
      _log('Loaded tax form detail: ${taxForm.formNumber}');
      emit(TaxFormDetailLoaded(taxForm));
    } catch (e, stackTrace) {
      _log('Error: $e');
      _log('StackTrace: $stackTrace');
      emit(TaxFormDetailError(e.toString()));
    }
  }

  Future<void> _onDownloadTaxForm(
    DownloadTaxForm event,
    Emitter<TaxFormDetailState> emit,
  ) async {
    _log('DownloadTaxForm event: id=${event.id}');
    emit(TaxFormDownloading());
    try {
      final download = await datasource.downloadTaxForm(event.id);
      _log('Download URL: ${download.downloadUrl}');
      emit(TaxFormDownloadReady(download));
    } catch (e, stackTrace) {
      _log('Error: $e');
      _log('StackTrace: $stackTrace');
      emit(TaxFormDownloadError(e.toString()));
    }
  }
}
