abstract class LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String identifier;
  final String password;

  LoginSubmitted({
    required this.identifier,
    required this.password,
  });
}

class LoginReset extends LoginEvent {}
