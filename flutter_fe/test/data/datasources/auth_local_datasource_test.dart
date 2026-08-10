import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/models/responses/auth_response_model.dart';

void main() {
  late AuthLocalDatasource datasource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    datasource = AuthLocalDatasource();
  });

  group('saveAuthData', () {
    test('should save token and user data to SharedPreferences', () async {
      // Arrange
      final authResponse = AuthResponseModel(
        success: true,
        message: 'Login berhasil',
        token: 'test_token_123',
        user: UserModel(
          id: 1,
          name: 'Test User',
          email: 'test@example.com',
        ),
      );

      // Act
      await datasource.saveAuthData(authResponse);

      // Assert
      final token = await datasource.getToken();
      expect(token, 'test_token_123');

      final userData = await datasource.getUserData();
      expect(userData, isNotNull);
      expect(userData!['id'], 1);
      expect(userData['name'], 'Test User');
      expect(userData['email'], 'test@example.com');
    });

    test('should not save token when token is null', () async {
      // Arrange
      final authResponse = AuthResponseModel(
        success: false,
        message: 'Login gagal',
        token: null,
        user: null,
      );

      // Act
      await datasource.saveAuthData(authResponse);

      // Assert
      final token = await datasource.getToken();
      expect(token, isNull);
    });
  });

  group('getToken', () {
    test('should return token when it exists', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'auth_token': 'existing_token',
      });
      datasource = AuthLocalDatasource();

      // Act
      final token = await datasource.getToken();

      // Assert
      expect(token, 'existing_token');
    });

    test('should return null when token does not exist', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      datasource = AuthLocalDatasource();

      // Act
      final token = await datasource.getToken();

      // Assert
      expect(token, isNull);
    });
  });

  group('isLoggedIn', () {
    test('should return true when token exists and is not empty', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'auth_token': 'valid_token',
      });
      datasource = AuthLocalDatasource();

      // Act
      final isLoggedIn = await datasource.isLoggedIn();

      // Assert
      expect(isLoggedIn, true);
    });

    test('should return false when token is null', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      datasource = AuthLocalDatasource();

      // Act
      final isLoggedIn = await datasource.isLoggedIn();

      // Assert
      expect(isLoggedIn, false);
    });

    test('should return false when token is empty string', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'auth_token': '',
      });
      datasource = AuthLocalDatasource();

      // Act
      final isLoggedIn = await datasource.isLoggedIn();

      // Assert
      expect(isLoggedIn, false);
    });
  });

  group('removeAuthData', () {
    test('should remove all auth data from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_token',
        'user_id': 1,
        'user_name': 'Test User',
        'user_email': 'test@example.com',
      });
      datasource = AuthLocalDatasource();

      // Act
      await datasource.removeAuthData();

      // Assert
      final token = await datasource.getToken();
      final userData = await datasource.getUserData();
      final isLoggedIn = await datasource.isLoggedIn();

      expect(token, isNull);
      expect(userData, isNull);
      expect(isLoggedIn, false);
    });
  });

  group('getUserData', () {
    test('should return user data when it exists', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'user_name': 'Test User',
        'user_email': 'test@example.com',
      });
      datasource = AuthLocalDatasource();

      // Act
      final userData = await datasource.getUserData();

      // Assert
      expect(userData, isNotNull);
      expect(userData!['id'], 1);
      expect(userData['name'], 'Test User');
      expect(userData['email'], 'test@example.com');
    });

    test('should return null when user data is incomplete', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'user_name': 'Test User',
        // missing user_email
      });
      datasource = AuthLocalDatasource();

      // Act
      final userData = await datasource.getUserData();

      // Assert
      expect(userData, isNull);
    });

    test('should return null when no user data exists', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      datasource = AuthLocalDatasource();

      // Act
      final userData = await datasource.getUserData();

      // Assert
      expect(userData, isNull);
    });
  });
}
