import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/datasources/device_token_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/register_token_request_model.dart';
import 'package:gaji_pro/data/models/responses/device_token_model.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockAuthLocalDatasource extends Mock implements AuthLocalDatasource {}

void main() {
  late DeviceTokenRemoteDatasource datasource;
  late MockHttpClient mockHttpClient;
  late MockAuthLocalDatasource mockAuthLocalDatasource;

  setUp(() {
    registerFallbackValue(Uri());
    mockHttpClient = MockHttpClient();
    mockAuthLocalDatasource = MockAuthLocalDatasource();
    datasource = DeviceTokenRemoteDatasource(
      mockHttpClient,
      mockAuthLocalDatasource,
    );
    when(
      () => mockAuthLocalDatasource.getToken(),
    ).thenAnswer((_) async => 'auth_token');
  });

  const tRegisterRequest = RegisterTokenRequestModel(
    token: 'test_token',
    platform: 'android',
  );

  final tDeviceTokenModel = DeviceTokenModel(
    id: 1,
    platform: 'android',
    deviceName: 'Test Device',
    isActive: true,
  );

  group('registerToken', () {
    test('should perform a POST request to register token', () async {
      // Arrange
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"message": "Success"}', 200));

      // Act
      await datasource.registerToken(tRegisterRequest);

      // Assert
      verify(
        () => mockHttpClient.post(
          any(
            that: predicate<Uri>((uri) => uri.path.contains('/device-tokens')),
          ),
          headers: any(named: 'headers'),
          body: jsonEncode(tRegisterRequest.toJson()),
        ),
      ).called(1);
    });

    test(
      'should throw an exception when response code is not 200/201',
      () async {
        // Arrange
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Error', 400));

        // Act
        final call = datasource.registerToken(tRegisterRequest);

        // Assert
        expect(() => call, throwsException);
      },
    );
  });

  group('unregisterToken', () {
    test('should perform a DELETE request to unregister token', () async {
      // Arrange
      when(
        () => mockHttpClient.delete(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"message": "Success"}', 200));

      // Act
      await datasource.unregisterToken('test_token');

      // Assert
      verify(
        () => mockHttpClient.delete(
          any(
            that: predicate<Uri>((uri) => uri.path.contains('/device-tokens')),
          ),
          headers: any(named: 'headers'),
          body: jsonEncode({'token': 'test_token'}),
        ),
      ).called(1);
    });

    test('should throw an exception when response code is not 200', () async {
      // Arrange
      when(
        () => mockHttpClient.delete(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 400));

      // Act
      final call = datasource.unregisterToken('test_token');

      // Assert
      expect(() => call, throwsException);
    });
  });

  group('getDeviceTokens', () {
    test(
      'should return list of DeviceTokenModel when response is 200',
      () async {
        // Arrange
        final tResponse = jsonEncode({
          'data': [
            {
              'id': 1,
              'platform': 'android',
              'device_name': 'Test Device',
              'is_active': true,
            },
          ],
        });

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response(tResponse, 200));

        // Act
        final result = await datasource.getDeviceTokens();

        // Assert
        expect(result, [tDeviceTokenModel]);
      },
    );

    test('should throw an exception when response is not 200', () async {
      // Arrange
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      // Act
      final call = datasource.getDeviceTokens();

      // Assert
      expect(() => call, throwsException);
    });
  });

  group('refreshToken', () {
    test('should perform a POST request to refresh token', () async {
      // Arrange
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"message": "Success"}', 200));

      // Act
      await datasource.refreshToken('old_token', 'new_token');

      // Assert
      verify(
        () => mockHttpClient.post(
          any(
            that: predicate<Uri>(
                (uri) => uri.path.contains('/device-tokens/refresh')),
          ),
          headers: any(named: 'headers'),
          body: jsonEncode({'old_token': 'old_token', 'new_token': 'new_token'}),
        ),
      ).called(1);
    });

    test('should throw an exception when response code is not 200', () async {
      // Arrange
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 400));

      // Act
      final call = datasource.refreshToken('old_token', 'new_token');

      // Assert
      expect(() => call, throwsException);
    });
  });
}
