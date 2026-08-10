import 'package:equatable/equatable.dart';

abstract class DeleteAccountEvent extends Equatable {
  const DeleteAccountEvent();

  @override
  List<Object?> get props => [];
}

class DeleteAccountSubmit extends DeleteAccountEvent {
  final String password;
  final String? reason;

  const DeleteAccountSubmit({
    required this.password,
    this.reason,
  });

  @override
  List<Object?> get props => [password, reason];
}

class DeleteAccountReset extends DeleteAccountEvent {
  const DeleteAccountReset();
}
