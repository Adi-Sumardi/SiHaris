import '../../../../data/models/requests/register_request_model.dart';

abstract class RegisterEvent {}

class RegisterSubmitted extends RegisterEvent {
  final RegisterRequestModel request;

  RegisterSubmitted({required this.request});
}

class RegisterReset extends RegisterEvent {}
