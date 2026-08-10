import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/data/datasources/tax_form_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/tax_form_model.dart';

part 'tax_form_list_event.dart';
part 'tax_form_list_state.dart';

class TaxFormListBloc extends Bloc<TaxFormListEvent, TaxFormListState> {
  final TaxFormRemoteDatasource datasource;

  static const _tag = 'TaxFormListBloc';

  TaxFormListBloc({required this.datasource}) : super(TaxFormListInitial()) {
    on<GetTaxForms>(_onGetTaxForms);
    on<GetTaxFormYears>(_onGetTaxFormYears);
    on<RefreshTaxForms>(_onRefreshTaxForms);
  }

  void _log(String message) {
    developer.log(message, name: _tag);
  }

  Future<void> _onGetTaxForms(
    GetTaxForms event,
    Emitter<TaxFormListState> emit,
  ) async {
    _log('GetTaxForms event: year=${event.year}');
    emit(TaxFormListLoading());
    try {
      final taxForms = await datasource.getTaxForms(year: event.year);
      _log('Loaded ${taxForms.length} tax forms');
      emit(TaxFormListLoaded(taxForms, year: event.year));
    } catch (e, stackTrace) {
      _log('Error: $e');
      _log('StackTrace: $stackTrace');
      emit(TaxFormListError(e.toString()));
    }
  }

  Future<void> _onGetTaxFormYears(
    GetTaxFormYears event,
    Emitter<TaxFormListState> emit,
  ) async {
    _log('GetTaxFormYears event');
    try {
      final years = await datasource.getTaxFormYears();
      _log('Loaded ${years.length} tax years');
      emit(TaxFormYearsLoaded(years));
    } catch (e, stackTrace) {
      _log('Error: $e');
      _log('StackTrace: $stackTrace');
      emit(TaxFormListError(e.toString()));
    }
  }

  Future<void> _onRefreshTaxForms(
    RefreshTaxForms event,
    Emitter<TaxFormListState> emit,
  ) async {
    _log('RefreshTaxForms event: year=${event.year}');
    emit(TaxFormListLoading());
    try {
      final taxForms = await datasource.getTaxForms(year: event.year);
      _log('Refreshed ${taxForms.length} tax forms');
      emit(TaxFormListLoaded(taxForms, year: event.year));
    } catch (e, stackTrace) {
      _log('Error: $e');
      _log('StackTrace: $stackTrace');
      emit(TaxFormListError(e.toString()));
    }
  }
}
