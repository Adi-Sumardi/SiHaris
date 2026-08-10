/// Office Location Model
/// Sesuai dengan API docs untuk assigned_offices dan /office-locations endpoints
class OfficeLocationModel {
  final int id;
  final String name;
  final String? code;
  final String? address;
  final String? city;
  final String? province;
  final double latitude;
  final double longitude;
  final int radius; // in meters
  final bool isActive;
  final bool isHeadquarters;
  final bool isPrimary;

  const OfficeLocationModel({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.city,
    this.province,
    required this.latitude,
    required this.longitude,
    this.radius = 100,
    this.isActive = true,
    this.isHeadquarters = false,
    this.isPrimary = false,
  });

  factory OfficeLocationModel.fromJson(Map<String, dynamic> json) {
    return OfficeLocationModel(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'],
      address: json['address'],
      city: json['city'],
      province: json['province'],
      latitude: _parseDouble(json['latitude']) ?? 0,
      longitude: _parseDouble(json['longitude']) ?? 0,
      radius: _parseInt(json['radius']) ?? 100,
      isActive: json['is_active'] ?? true,
      isHeadquarters: json['is_headquarters'] ?? false,
      isPrimary: json['is_primary'] ?? false,
    );
  }

  /// Parse value to double, handling both num and String types
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse value to int, handling both num and String types
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'is_active': isActive,
      'is_headquarters': isHeadquarters,
      'is_primary': isPrimary,
    };
  }

  /// Get full address string
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (province != null && province!.isNotEmpty) parts.add(province!);
    return parts.join(', ');
  }
}

/// GPS Validation Response Model
/// Sesuai dengan API docs: POST /office-locations/validate-gps
class GpsValidationResponse {
  final bool valid;
  final int? officeLocationId;
  final double? distance; // in meters
  final String?
  reason; // 'no_assigned_offices', 'no_active_offices', 'outside_radius'
  final OfficeLocationModel? office;

  const GpsValidationResponse({
    required this.valid,
    this.officeLocationId,
    this.distance,
    this.reason,
    this.office,
  });

  factory GpsValidationResponse.fromJson(Map<String, dynamic> json) {
    return GpsValidationResponse(
      valid: json['valid'] ?? false,
      officeLocationId: json['office_location_id'],
      distance: (json['distance'] as num?)?.toDouble(),
      reason: json['reason'],
      office: json['office'] != null
          ? OfficeLocationModel.fromJson(json['office'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valid': valid,
      'office_location_id': officeLocationId,
      'distance': distance,
      'reason': reason,
      'office': office?.toJson(),
    };
  }

  /// Get user-friendly error message
  String? get errorMessage {
    if (valid) return null;
    switch (reason) {
      case 'no_assigned_offices':
        return 'Anda belum ditugaskan ke lokasi kantor manapun';
      case 'no_active_offices':
        return 'Tidak ada lokasi kantor aktif yang ditugaskan';
      case 'outside_radius':
        return 'Anda berada di luar radius lokasi kantor';
      default:
        return 'Validasi GPS gagal';
    }
  }
}
