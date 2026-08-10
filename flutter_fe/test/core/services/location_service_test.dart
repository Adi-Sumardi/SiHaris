import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/core/services/location_service.dart';

// Mock classes
class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

void main() {
  late LocationService locationService;
  late MockGeolocatorPlatform mockGeolocator;

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    locationService = LocationService(geolocator: mockGeolocator);
  });

  group('LocationService', () {
    group('checkPermission', () {
      test('should return true when permission is granted', () async {
        when(() => mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.always);

        final result = await locationService.checkPermission();

        expect(result, true);
        verify(() => mockGeolocator.checkPermission()).called(1);
      });

      test('should return true when permission is whileInUse', () async {
        when(() => mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);

        final result = await locationService.checkPermission();

        expect(result, true);
      });

      test('should return false when permission is denied', () async {
        when(() => mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);

        final result = await locationService.checkPermission();

        expect(result, false);
      });

      test('should return false when permission is deniedForever', () async {
        when(() => mockGeolocator.checkPermission())
            .thenAnswer((_) async => LocationPermission.deniedForever);

        final result = await locationService.checkPermission();

        expect(result, false);
      });
    });

    group('requestPermission', () {
      test('should return true when permission request is granted', () async {
        when(() => mockGeolocator.requestPermission())
            .thenAnswer((_) async => LocationPermission.always);

        final result = await locationService.requestPermission();

        expect(result, true);
        verify(() => mockGeolocator.requestPermission()).called(1);
      });

      test('should return false when permission request is denied', () async {
        when(() => mockGeolocator.requestPermission())
            .thenAnswer((_) async => LocationPermission.denied);

        final result = await locationService.requestPermission();

        expect(result, false);
      });
    });

    group('isLocationServiceEnabled', () {
      test('should return true when location service is enabled', () async {
        when(() => mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => true);

        final result = await locationService.isLocationServiceEnabled();

        expect(result, true);
        verify(() => mockGeolocator.isLocationServiceEnabled()).called(1);
      });

      test('should return false when location service is disabled', () async {
        when(() => mockGeolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => false);

        final result = await locationService.isLocationServiceEnabled();

        expect(result, false);
      });
    });

    group('getCurrentPosition', () {
      test('should return position when successful', () async {
        final mockPosition = Position(
          latitude: -6.2088,
          longitude: 106.8456,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        when(() => mockGeolocator.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer((_) async => mockPosition);

        final result = await locationService.getCurrentPosition();

        expect(result, isNotNull);
        expect(result!.latitude, -6.2088);
        expect(result.longitude, 106.8456);
      });

      test('should return null when exception occurs', () async {
        when(() => mockGeolocator.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenThrow(Exception('Location error'));

        final result = await locationService.getCurrentPosition();

        expect(result, isNull);
      });
    });

    group('calculateDistance', () {
      test('should calculate distance between two points', () {
        // Jakarta to Bandung approximately 120-150 km
        final distance = locationService.calculateDistance(
          startLatitude: -6.2088,
          startLongitude: 106.8456,
          endLatitude: -6.9175,
          endLongitude: 107.6191,
        );

        // Distance should be approximately 120-150 km
        expect(distance, greaterThan(100000)); // > 100 km in meters
        expect(distance, lessThan(200000)); // < 200 km in meters
      });

      test('should return 0 for same location', () {
        final distance = locationService.calculateDistance(
          startLatitude: -6.2088,
          startLongitude: 106.8456,
          endLatitude: -6.2088,
          endLongitude: 106.8456,
        );

        expect(distance, 0.0);
      });
    });

    group('isWithinRadius', () {
      test('should return true when within radius', () {
        // Current location and target are same
        final result = locationService.isWithinRadius(
          currentLatitude: -6.2088,
          currentLongitude: 106.8456,
          targetLatitude: -6.2088,
          targetLongitude: 106.8456,
          radiusInMeters: 100,
        );

        expect(result, true);
      });

      test('should return false when outside radius', () {
        // Jakarta to Bandung - definitely outside 100m
        final result = locationService.isWithinRadius(
          currentLatitude: -6.2088,
          currentLongitude: 106.8456,
          targetLatitude: -6.9175,
          targetLongitude: 107.6191,
          radiusInMeters: 100,
        );

        expect(result, false);
      });

      test('should return true when exactly on radius boundary', () {
        // Test with calculated point at exactly 100m
        final result = locationService.isWithinRadius(
          currentLatitude: -6.2088,
          currentLongitude: 106.8456,
          targetLatitude: -6.2089, // Very close point
          targetLongitude: 106.8456,
          radiusInMeters: 100,
        );

        expect(result, true);
      });
    });

    group('LocationData', () {
      test('should create LocationData instance', () {
        final locationData = LocationData(
          latitude: -6.2088,
          longitude: 106.8456,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );

        expect(locationData.latitude, -6.2088);
        expect(locationData.longitude, 106.8456);
        expect(locationData.accuracy, 10.0);
      });

      test('should convert to map', () {
        final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
        final locationData = LocationData(
          latitude: -6.2088,
          longitude: 106.8456,
          accuracy: 10.0,
          timestamp: timestamp,
        );

        final map = locationData.toMap();

        expect(map['latitude'], -6.2088);
        expect(map['longitude'], 106.8456);
        expect(map['accuracy'], 10.0);
        expect(map['timestamp'], timestamp.toIso8601String());
      });

      test('should create from Position', () {
        final position = Position(
          latitude: -6.2088,
          longitude: 106.8456,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final locationData = LocationData.fromPosition(position);

        expect(locationData.latitude, position.latitude);
        expect(locationData.longitude, position.longitude);
        expect(locationData.accuracy, position.accuracy);
      });
    });
  });
}
