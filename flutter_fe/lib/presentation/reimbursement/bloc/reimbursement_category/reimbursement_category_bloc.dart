import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_category_model.dart';

part 'reimbursement_category_event.dart';
part 'reimbursement_category_state.dart';

class ReimbursementCategoryBloc
    extends Bloc<ReimbursementCategoryEvent, ReimbursementCategoryState> {
  final ReimbursementRemoteDatasource datasource;

  ReimbursementCategoryBloc(this.datasource)
    : super(ReimbursementCategoryInitial()) {
    on<LoadReimbursementCategories>(_onLoadReimbursementCategories);
  }

  Future<void> _onLoadReimbursementCategories(
    LoadReimbursementCategories event,
    Emitter<ReimbursementCategoryState> emit,
  ) async {
    try {
      emit(ReimbursementCategoryLoading());
      final categories = await datasource.getCategories();
      emit(ReimbursementCategoryLoaded(categories));
    } catch (e) {
      emit(ReimbursementCategoryError(e.toString()));
    }
  }
}
