import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/auth_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/update_profile_request_model.dart';
import 'package:gaji_pro/core/constants/variables.dart';
import '../../mocks/mock_http_client.dart';
import '../../mocks/mock_auth_local_datasource.dart';

class FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  late AuthRemoteDatasource datasource;
  late MockHttpClient mockHttpClient;
  late MockAuthLocalDatasource mockLocalDatasource;

  setUpAll(() {
    // Initialize binding for SessionService
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock shared preferences for SessionService
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, Object>{};
        }
        if (methodCall.method == 'remove') {
          return true;
        }
        if (methodCall.method == 'clear') {
          return true;
        }
        return null;
      },
    );

    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeBaseRequest());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockLocalDatasource = MockAuthLocalDatasource();
    datasource = AuthRemoteDatasource(
      client: mockHttpClient,
      localDatasource: mockLocalDatasource,
    );
  });

  group('login', () {
    const email = 'test@example.com';
    const password = 'password123';

    final successResponse = {
      'success': true,
      'message': 'Login berhasil',
      'token': 'test_token_123',
      'user': {
        'id': 1,
        'name': 'Test User',
        'email': email,
        'employee_id': 'EMP001',
        'department': 'IT',
        'position': 'Developer',
      },
    };

    test('should return AuthResponseModel when login is successful', () async {
      // Arrange
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode(successResponse), 200),
      );

      // Act
      final result = await datasource.login(email, password);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) {
          expect(r.success, true);
          expect(r.token, 'test_token_123');
          expect(r.user?.name, 'Test User');
          expect(r.user?.email, email);
        },
      );

      verify(() => mockHttpClient.post(
            Uri.parse(Variables.login),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )).called(1);
    });

    test('should return error message when login fails with 401', () async {
      // Arrange
      final errorResponse = {
        'success': false,
        'message': 'Email atau password salah',
      };

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode(errorResponse), 401),
      );

      // Act
      final result = await datasource.login(email, password);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Email atau password salah'),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error message when login fails with 422 validation error', () async {
      // Arrange
      final errorResponse = {
        'success': false,
        'message': 'Email tidak valid',
        'errors': {
          'email': ['Format email tidak valid'],
        },
      };

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode(errorResponse), 422),
      );

      // Act
      final result = await datasource.login('invalid-email', password);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Email tidak valid'),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error when network exception occurs', () async {
      // Arrange
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(Exception('No internet connection'));

      // Act
      final result = await datasource.login(email, password);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l.contains('Terjadi kesalahan'), true),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('logout', () {
    const testToken = 'test_token_123';

    test('should return true when logout is successful', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockLocalDatasource.removeAuthData())
          .thenAnswer((_) async {});
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': true, 'message': 'Logout berhasil'}),
          200,
        ),
      );

      // Act
      final result = await datasource.logout();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r, true),
      );

      verify(() => mockLocalDatasource.removeAuthData()).called(1);
    });

    test('should still return success when API fails (force logout)', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockLocalDatasource.removeAuthData())
          .thenAnswer((_) async {});
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Token tidak valid'}),
          401,
        ),
      );

      // Act
      final result = await datasource.logout();

      // Assert - Force logout always succeeds and clears local data
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r, true),
      );
      verify(() => mockLocalDatasource.removeAuthData()).called(1);
    });
  });

  group('getProfile', () {
    const testToken = 'test_token_123';

    final profileResponse = {
      'success': true,
      'data': {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'employee_id': 'EMP001',
        'department': 'Engineering',
        'position': 'Senior Developer',
        'phone': '08123456789',
        'avatar': 'https://example.com/avatar.jpg',
      },
    };

    test('should return UserModel when getProfile is successful', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode(profileResponse), 200),
      );

      // Act
      final result = await datasource.getProfile();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (data) {
          final (user, company) = data;
          expect(user.id, 1);
          expect(user.name, 'John Doe');
          expect(user.email, 'john@example.com');
        },
      );
    });

    test('should return error when getProfile fails with 401', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Unauthenticated'}),
          401,
        ),
      );

      // Act
      final result = await datasource.getProfile();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Sesi Anda telah berakhir'),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('updateProfile', () {
    const testToken = 'test_token_123';

    final successResponse = {
      'success': true,
      'message': 'Profil berhasil diperbarui',
      'data': {
        'id': 1,
        'name': 'Ahmad Bahri',
        'email': 'ahmad@example.com',
        'employee_id': 'EMP001',
        'department': 'Engineering',
        'position': 'Developer',
        'phone': '08123456789',
        'avatar': 'https://example.com/avatar.jpg',
      },
    };

    http.StreamedResponse fakeStreamedResponse(String body, int statusCode) {
      return http.StreamedResponse(
        Stream.fromIterable([body.codeUnits.map((c) => c & 0xFF).toList()]),
        statusCode,
      );
    }

    test('should return UserModel when updateProfile text-only succeeds', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.send(any()))
          .thenAnswer((_) async => fakeStreamedResponse(jsonEncode(successResponse), 200));

      final request = UpdateProfileRequestModel(
        firstName: 'Ahmad',
        lastName: 'Bahri',
        phone: '08123456789',
        address: 'Jl. Sudirman No.1',
      );

      final result = await datasource.updateProfile(request);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left: $l'),
        (r) => expect(r.name, 'Ahmad Bahri'),
      );
    });

    test('should return error when updateProfile fails with 422', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.send(any())).thenAnswer((_) async =>
          fakeStreamedResponse(
              jsonEncode({'success': false, 'message': 'Validasi gagal'}), 422));

      final request = UpdateProfileRequestModel(firstName: 'Ahmad');
      final result = await datasource.updateProfile(request);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Validasi gagal'),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error when network exception occurs', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.send(any())).thenThrow(Exception('No internet'));

      final request = UpdateProfileRequestModel(firstName: 'Ahmad');
      final result = await datasource.updateProfile(request);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l.contains('Terjadi kesalahan'), true),
        (r) => fail('Should not return Right'),
      );
    });

    test('should include photo in request when hasPhoto is true', () async {
      final tmpFile = File('/tmp/test_avatar.jpg');
      await tmpFile.writeAsBytes([0xFF, 0xD8, 0xFF]); // minimal JPEG bytes

      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.send(any()))
          .thenAnswer((_) async => fakeStreamedResponse(jsonEncode(successResponse), 200));

      final request = UpdateProfileRequestModel(
        firstName: 'Ahmad',
        photo: tmpFile,
      );

      final result = await datasource.updateProfile(request);

      expect(result.isRight(), true);
      final captured = verify(() => mockHttpClient.send(captureAny())).captured;
      final multipartRequest = captured.first as http.MultipartRequest;
      expect(multipartRequest.method, 'PATCH');
      expect(multipartRequest.url.toString(), Variables.profile);
      expect(multipartRequest.files.isNotEmpty, true);

      await tmpFile.delete();
    });
  });

  group('changePassword', () {
    const testToken = 'test_token_123';
    const currentPassword = 'oldPassword123';
    const newPassword = 'newPassword123';
    const confirmPassword = 'newPassword123';

    test('should return true when changePassword is successful', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': true, 'message': 'Password berhasil diubah'}),
          200,
        ),
      );

      // Act
      final result = await datasource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r, true),
      );

      verify(() => mockHttpClient.post(
            Uri.parse(Variables.changePassword),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $testToken',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'password': newPassword,
              'password_confirmation': confirmPassword,
            }),
          )).called(1);
    });

    test('should return error when current password is wrong', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Password lama tidak sesuai'}),
          422,
        ),
      );

      // Act
      final result = await datasource.changePassword(
        currentPassword: 'wrongPassword',
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Password lama tidak sesuai'),
        (r) => fail('Should not return Right'),
      );
    });

    test('should return error when password confirmation does not match', () async {
      // Arrange
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Konfirmasi password tidak sesuai'}),
          422,
        ),
      );

      // Act
      final result = await datasource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: 'differentPassword',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Konfirmasi password tidak sesuai'),
        (r) => fail('Should not return Right'),
      );
    });
  });
}
