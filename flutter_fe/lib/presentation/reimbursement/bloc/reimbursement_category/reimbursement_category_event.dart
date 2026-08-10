part of 'reimbursement_category_bloc.dart';

abstract class ReimbursementCategoryEvent extends Equatable {
  const ReimbursementCategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadReimbursementCategories extends ReimbursementCategoryEvent {
  const LoadReimbursementCategories();
}
