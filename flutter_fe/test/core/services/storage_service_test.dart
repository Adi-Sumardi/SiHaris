import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaji_pro/core/services/storage_service.dart';

void main() {
  late StorageServiceImpl storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageServiceImpl(prefs);
  });

  group('StorageService', () {
    group('Token operations', () {
      test('getToken should return null when no token stored', () async {
        final token = await storageService.getToken();
        expect(token, isNull);
      });

      test('setToken should store token', () async {
        await storageService.setToken('test_token');
        final token = await storageService.getToken();
        expect(token, 'test_token');
      });

      test('removeToken should remove token', () async {
        await storageService.setToken('test_token');
        await storageService.removeToken();
        final token = await storageService.getToken();
        expect(token, isNull);
      });
    });

    group('Refresh token operations', () {
      test('getRefreshToken should return null when no refresh token stored',
          () async {
        final token = await storageService.getRefreshToken();
        expect(token, isNull);
      });

      test('setRefreshToken should store refresh token', () async {
        await storageService.setRefreshToken('refresh_token');
        final token = await storageService.getRefreshToken();
        expect(token, 'refresh_token');
      });

      test('removeRefreshToken should remove refresh token', () async {
        await storageService.setRefreshToken('refresh_token');
        await storageService.removeRefreshToken();
        final token = await storageService.getRefreshToken();
        expect(token, isNull);
      });
    });

    group('String operations', () {
      test('getString should return null when key not found', () async {
        final value = await storageService.getString('unknown_key');
        expect(value, isNull);
      });

      test('setString should store string value', () async {
        await storageService.setString('name', 'John Doe');
        final value = await storageService.getString('name');
        expect(value, 'John Doe');
      });

      test('setString should overwrite existing value', () async {
        await storageService.setString('name', 'John');
        await storageService.setString('name', 'Jane');
        final value = await storageService.getString('name');
        expect(value, 'Jane');
      });
    });

    group('Bool operations', () {
      test('getBool should return null when key not found', () async {
        final value = await storageService.getBool('unknown_key');
        expect(value, isNull);
      });

      test('setBool should store boolean value', () async {
        await storageService.setBool('is_logged_in', true);
        final value = await storageService.getBool('is_logged_in');
        expect(value, true);
      });

      test('setBool should store false value', () async {
        await storageService.setBool('is_logged_in', false);
        final value = await storageService.getBool('is_logged_in');
        expect(value, false);
      });
    });

    group('Int operations', () {
      test('getInt should return null when key not found', () async {
        final value = await storageService.getInt('unknown_key');
        expect(value, isNull);
      });

      test('setInt should store integer value', () async {
        await storageService.setInt('count', 42);
        final value = await storageService.getInt('count');
        expect(value, 42);
      });

      test('setInt should store negative value', () async {
        await storageService.setInt('temperature', -10);
        final value = await storageService.getInt('temperature');
        expect(value, -10);
      });
    });

    group('Double operations', () {
      test('getDouble should return null when key not found', () async {
        final value = await storageService.getDouble('unknown_key');
        expect(value, isNull);
      });

      test('setDouble should store double value', () async {
        await storageService.setDouble('price', 99.99);
        final value = await storageService.getDouble('price');
        expect(value, 99.99);
      });
    });

    group('StringList operations', () {
      test('getStringList should return null when key not found', () async {
        final value = await storageService.getStringList('unknown_key');
        expect(value, isNull);
      });

      test('setStringList should store list of strings', () async {
        await storageService.setStringList('tags', ['flutter', 'dart', 'mobile']);
        final value = await storageService.getStringList('tags');
        expect(value, ['flutter', 'dart', 'mobile']);
      });

      test('setStringList should store empty list', () async {
        await storageService.setStringList('empty', []);
        final value = await storageService.getStringList('empty');
        expect(value, []);
      });
    });

    group('Remove operation', () {
      test('remove should remove value by key', () async {
        await storageService.setString('temp', 'value');
        await storageService.remove('temp');
        final value = await storageService.getString('temp');
        expect(value, isNull);
      });

      test('remove should return true for existing key', () async {
        await storageService.setString('key', 'value');
        final result = await storageService.remove('key');
        expect(result, true);
      });
    });

    group('Clear operation', () {
      test('clear should remove all stored values', () async {
        await storageService.setString('key1', 'value1');
        await storageService.setInt('key2', 42);
        await storageService.setBool('key3', true);

        await storageService.clear();

        expect(await storageService.getString('key1'), isNull);
        expect(await storageService.getInt('key2'), isNull);
        expect(await storageService.getBool('key3'), isNull);
      });
    });

    group('ContainsKey operation', () {
      test('containsKey should return false for non-existent key', () async {
        final result = await storageService.containsKey('unknown');
        expect(result, false);
      });

      test('containsKey should return true for existing key', () async {
        await storageService.setString('key', 'value');
        final result = await storageService.containsKey('key');
        expect(result, true);
      });

      test('containsKey should return false after key is removed', () async {
        await storageService.setString('key', 'value');
        await storageService.remove('key');
        final result = await storageService.containsKey('key');
        expect(result, false);
      });
    });
  });
}
