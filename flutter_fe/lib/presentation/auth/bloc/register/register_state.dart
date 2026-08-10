abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final String email;
  final String? name;
  final String message;

  RegisterSuccess({
    required this.email,
    this.name,
    required this.message,
  });
}

class RegisterError extends RegisterState {
  final String message;

  RegisterError(this.message);
}
