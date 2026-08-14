import 'package:dartz/dartz.dart';
import '../models/requests/register_request_model.dart';
import '../models/requests/update_profile_request_model.dart';
import '../models/responses/auth_response_model.dart';
import '../models/responses/office_location_model.dart';
import '../models/responses/register_response_model.dart';

/// Abstract class untuk Auth Datasource
/// Memudahkan testing dengan dependency injection
abstract class AuthDatasource {
  Future<Either<String, AuthResponseModel>> login(String identifier, String password);
  Future<Either<String, Map<String, dynamic>>> requestOtp(String login);
  Future<Either<String, AuthResponseModel>> verifyOtp(String login, String otp);
  Future<Either<String, RegisterResponseModel>> demoRegister(RegisterRequestModel request);
  Future<Either<String, bool>> logout();
  Future<Either<String, (UserModel, CompanyModel?)>> getProfile();
  Future<Either<String, UserModel>> updateProfile(UpdateProfileRequestModel request);
  Future<Either<String, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<Either<String, bool>> deleteAccount({
    required String password,
    required String confirmation,
    String? reason,
  });
}

/// Abstract class untuk Auth Local Datasource
abstract class AuthLocalDatasourceBase {
  Future<void> saveAuthData(AuthResponseModel response);
  Future<String?> getToken();
  Future<bool> isLoggedIn();
  Future<void> removeAuthData();
  Future<Map<String, dynamic>?> getUserData();
  Future<List<OfficeLocationModel>> getAssignedOffices();
}
