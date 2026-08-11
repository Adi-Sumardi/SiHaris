import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaji_pro/core/services/api_service.dart';
import 'package:gaji_pro/core/services/storage_service.dart';
import 'package:gaji_pro/core/errors/exceptions.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockStorageService extends Mock implements StorageService {}

class FakeUri extends Fake implements Uri {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  late ApiService apiService;
  late MockHttpClient mockHttpClient;
  late MockStorageService mockStorageService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeBaseRequest());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    mockHttpClient = MockHttpClient();
    mockStorageService = MockStorageService();
    apiService = ApiService(
      client: mockHttpClient,
      storageService: mockStorageService,
      baseUrl: 'https://api.example.com',
    );
  });

  tearDown(() {
    reset(mockHttpClient);
    reset(mockStorageService);
  });

  group('ApiService', () {
    group('GET requests', () {
      test('should make GET request with correct URL', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('{"data": "test"}', 200));

        // Act
        await apiService.get('/users');

        // Assert
        verify(() => mockHttpClient.get(
              Uri.parse('https://api.example.com/users'),
              headers: any(named: 'headers'),
            )).called(1);
      });

      test('should include authorization header when token exists', () async {
        // Arrange
        when(() => mockStorageService.getToken())
            .thenAnswer((_) async => 'test_token');
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('{"data": "test"}', 200));

        // Act
        await apiService.get('/users');

        // Assert
        verify(() => mockHttpClient.get(
              any(),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer test_token',
              },
            )).called(1);
      });

      test('should return decoded JSON on success', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response('{"name": "John", "age": 30}', 200));

        // Act
        final result = await apiService.get('/users/1');

        // Assert
        expect(result, {'name': 'John', 'age': 30});
      });

      test('should throw ServerException on 500 error', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response('{"message": "Server error"}', 500));

        // Act & Assert
        expect(
          () => apiService.get('/users'),
          throwsA(isA<ServerException>()),
        );
      });

      test('should throw UnauthorizedException on 401 error', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response('{"message": "Unauthorized"}', 401));

        // Act & Assert
        expect(
          () => apiService.get('/users'),
          throwsA(isA<UnauthorizedException>()),
        );
      });

      test('should throw NotFoundException on 404 error', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response('{"message": "Not found"}', 404));

        // Act & Assert
        expect(
          () => apiService.get('/users/999'),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('should throw NetworkException on connection error', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenThrow(Exception('Connection failed'));

        // Act & Assert
        expect(
          () => apiService.get('/users'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('POST requests', () {
      test('should make POST request with body', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer(
            (_) async => http.Response('{"id": 1, "name": "John"}', 201));

        // Act
        final result = await apiService.post('/users', body: {'name': 'John'});

        // Assert
        expect(result, {'id': 1, 'name': 'John'});
        verify(() => mockHttpClient.post(
              Uri.parse('https://api.example.com/users'),
              headers: any(named: 'headers'),
              body: jsonEncode({'name': 'John'}),
            )).called(1);
      });

      test('should handle POST without body', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act
        final result = await apiService.post('/action');

        // Assert
        expect(result, {'success': true});
      });

      test('should throw ValidationException on 422 error', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(
            '{"message": "Validation failed", "errors": {"email": ["required"]}}',
            422));

        // Act & Assert
        expect(
          () => apiService.post('/users', body: {}),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('PUT requests', () {
      test('should make PUT request with body', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.put(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer(
            (_) async => http.Response('{"id": 1, "name": "Jane"}', 200));

        // Act
        final result =
            await apiService.put('/users/1', body: {'name': 'Jane'});

        // Assert
        expect(result, {'id': 1, 'name': 'Jane'});
      });
    });

    group('DELETE requests', () {
      test('should make DELETE request', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response('{"message": "Deleted"}', 200));

        // Act
        final result = await apiService.delete('/users/1');

        // Assert
        expect(result, {'message': 'Deleted'});
        verify(() => mockHttpClient.delete(
              Uri.parse('https://api.example.com/users/1'),
              headers: any(named: 'headers'),
            )).called(1);
      });

      test('should handle 204 No Content response', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('', 204));

        // Act
        final result = await apiService.delete('/users/1');

        // Assert
        expect(result, isNull);
      });
    });

    group('PATCH requests', () {
      test('should make PATCH request with body', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.patch(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer(
            (_) async => http.Response('{"id": 1, "status": "active"}', 200));

        // Act
        final result =
            await apiService.patch('/users/1', body: {'status': 'active'});

        // Assert
        expect(result, {'id': 1, 'status': 'active'});
      });
    });

    group('Query parameters', () {
      test('should append query parameters to URL', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response('{"users": []}', 200));

        // Act
        await apiService.get('/users', queryParams: {'page': '1', 'limit': '10'});

        // Assert
        verify(() => mockHttpClient.get(
              Uri.parse('https://api.example.com/users?page=1&limit=10'),
              headers: any(named: 'headers'),
            )).called(1);
      });
    });

    group('Custom headers', () {
      test('should merge custom headers with default headers', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('{}', 200));

        // Act
        await apiService.get('/users', headers: {'X-Custom-Header': 'value'});

        // Assert
        verify(() => mockHttpClient.get(
              any(),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-Custom-Header': 'value',
              },
            )).called(1);
      });
    });

    group('Error response parsing', () {
      test('should include error message in exception', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async =>
                http.Response('{"message": "User not found"}', 404));

        // Act & Assert
        try {
          await apiService.get('/users/999');
          fail('Should throw NotFoundException');
        } on NotFoundException catch (e) {
          expect(e.message, 'User not found');
        }
      });

      test('should handle non-JSON error response', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response('Internal Server Error', 500));

        // Act & Assert
        expect(
          () => apiService.get('/users'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('Multipart requests', () {
      test('should make multipart POST request', () async {
        // Arrange
        when(() => mockStorageService.getToken()).thenAnswer((_) async => 'token');
        when(() => mockHttpClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(
                  Stream.value(utf8.encode('{"success": true}')),
                  200,
                ));

        // Act
        final result = await apiService.postMultipart(
          '/upload',
          fields: {'name': 'test'},
          files: [],
        );

        // Assert
        expect(result, {'success': true});
      });
    });
  });
}
