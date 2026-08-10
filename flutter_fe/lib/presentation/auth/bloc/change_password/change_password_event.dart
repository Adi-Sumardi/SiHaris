abstract class ChangePasswordEvent {}

class ChangePasswordSubmitted extends ChangePasswordEvent {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordSubmitted({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}

class ChangePasswordReset extends ChangePasswordEvent {}
