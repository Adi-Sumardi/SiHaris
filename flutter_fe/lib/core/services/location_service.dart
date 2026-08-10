import 'package:geolocator/geolocator.dart';

/// Service for handling GPS location functionality
class LocationService {
  final GeolocatorPlatform _geolocator;

  LocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  /// Check if location permission is granted
  Future<bool> checkPermission() async {
    final permission = await _geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    final permission = await _geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _geolocator.isLocationServiceEnabled();
  }

  /// Get current position
  /// Returns null if failed to get position
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    try {
      final position = await _geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Get current position as LocationData
  Future<LocationData?> getCurrentLocationData({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    final position = await getCurrentPosition(
      accuracy: accuracy,
      timeLimit: timeLimit,
    );
    if (position == null) return null;
    return LocationData.fromPosition(position);
  }

  /// Apakah posisi berasal dari mock location (fake GPS).
  ///
  /// `Position.isMocked` diisi oleh OS Android (`isFromMockProvider`). Pada iOS
  /// fake GPS jauh lebih sulit tanpa jailbreak, sehingga umumnya selalu `false`.
  bool isMockLocation(Position position) => position.isMocked;

  /// Calculate distance between two points in meters
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if current location is within radius of target location
  bool isWithinRadius({
    required double currentLatitude,
    required double currentLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double radiusInMeters,
  }) {
    final distance = calculateDistance(
      startLatitude: currentLatitude,
      startLongitude: currentLongitude,
      endLatitude: targetLatitude,
      endLongitude: targetLongitude,
    );
    return distance <= radiusInMeters;
  }

  /// Open location settings (for when service is disabled)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for when permission is denied forever)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get last known position (faster but may be stale)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await _geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Stream position updates
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return _geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}

/// Simplified location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;
  final double? heading;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.altitude,
    this.speed,
    this.heading,
  });

  /// Create from Geolocator Position
  factory LocationData.fromPosition(Position position) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
    );
  }

  /// Convert to map for API submission
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    };
  }

  /// Create from map
  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] as String),
      altitude: (map['altitude'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, accuracy: ${accuracy}m)';
  }
}
