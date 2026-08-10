part of 'reimbursement_category_bloc.dart';

abstract class ReimbursementCategoryState extends Equatable {
  const ReimbursementCategoryState();

  @override
  List<Object?> get props => [];
}

class ReimbursementCategoryInitial extends ReimbursementCategoryState {}

class ReimbursementCategoryLoading extends ReimbursementCategoryState {}

class ReimbursementCategoryLoaded extends ReimbursementCategoryState {
  final List<ReimbursementCategoryModel> categories;

  const ReimbursementCategoryLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class ReimbursementCategoryError extends ReimbursementCategoryState {
  final String message;

  const ReimbursementCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
