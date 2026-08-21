class AttendanceHistoryModel {
  final int id;
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String status;
  final String statusLabel;
  final String? officeLocationName;
  final String? workingFormatted;
  final AttendanceLocationModel? clockInLocation;
  final AttendanceLocationModel? clockOutLocation;

  const AttendanceHistoryModel({
    required this.id,
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.status,
    required this.statusLabel,
    this.officeLocationName,
    this.workingFormatted,
    this.clockInLocation,
    this.clockOutLocation,
  });

  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryModel(
      id: _parseInt(json['id']),
      date: json['date']?.toString() ?? '',
      clockIn: json['clock_in']?.toString(),
      clockOut: json['clock_out']?.toString(),
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      officeLocationName: json['office_location_name']?.toString(),
      workingFormatted: json['working_formatted']?.toString(),
      clockInLocation: json['clock_in_location'] != null
          ? AttendanceLocationModel.fromJson(json['clock_in_location'])
          : null,
      clockOutLocation: json['clock_out_location'] != null
          ? AttendanceLocationModel.fromJson(json['clock_out_location'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'clock_in': clockIn,
      'clock_out': clockOut,
      'status': status,
      'status_label': statusLabel,
      'office_location_name': officeLocationName,
      'working_formatted': workingFormatted,
      'clock_in_location': clockInLocation?.toJson(),
      'clock_out_location': clockOutLocation?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceHistoryModel &&
        other.id == id &&
        other.date == date &&
        other.clockIn == clockIn &&
        other.clockOut == clockOut &&
        other.status == status &&
        other.statusLabel == statusLabel &&
        other.officeLocationName == officeLocationName &&
        other.workingFormatted == workingFormatted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        clockIn.hashCode ^
        clockOut.hashCode ^
        status.hashCode ^
        statusLabel.hashCode ^
        officeLocationName.hashCode ^
        workingFormatted.hashCode;
  }
}

class AttendanceLocationModel {
  final double latitude;
  final double longitude;
  final OfficeLocationModel? office;

  const AttendanceLocationModel({
    required this.latitude,
    required this.longitude,
    this.office,
  });

  factory AttendanceLocationModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      office: json['office'] != null
          ? OfficeLocationModel.fromJson(json['office'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'office': office?.toJson(),
    };
  }
}

class OfficeLocationModel {
  final int id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int radius;

  const OfficeLocationModel({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory OfficeLocationModel.fromJson(Map<String, dynamic> json) {
    return OfficeLocationModel(
      id: AttendanceHistoryModel._parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radius: AttendanceHistoryModel._parseInt(json['radius'], 100),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }
}
