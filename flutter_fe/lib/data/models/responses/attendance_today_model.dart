import 'package:gaji_pro/data/models/responses/office_location_model.dart';
import 'package:flutter/foundation.dart';

class AttendanceTodayModel {
  final int id;
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String? targetClockOut;
  final int flexiMinutes;
  final bool isFlexible;
  final String? clockInSource;
  final String? clockOutSource;
  final String status;
  final String statusLabel;
  final int lateMinutes;
  final int workingMinutes;
  final bool faceVerified;
  final OfficeLocationModel? officeLocation;
  final Schedule? schedule;

  const AttendanceTodayModel({
    required this.id,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.targetClockOut,
    this.flexiMinutes = 0,
    this.isFlexible = false,
    this.clockInSource,
    this.clockOutSource,
    required this.status,
    required this.statusLabel,
    this.lateMinutes = 0,
    this.workingMinutes = 0,
    this.faceVerified = false,
    this.officeLocation,
    this.schedule,
  });

  factory AttendanceTodayModel.empty({Schedule? schedule}) {
    return AttendanceTodayModel(
      id: 0,
      date: DateTime.now().toIso8601String().split('T')[0],
      status: 'not_clocked_in',
      statusLabel: 'Belum Absen',
      schedule: schedule,
    );
  }

  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory AttendanceTodayModel.fromJson(Map<String, dynamic> json) {
    return AttendanceTodayModel(
      id: _parseInt(json['id']),
      date: json['date']?.toString() ?? '',
      clockIn: json['clock_in']?.toString(),
      clockOut: json['clock_out']?.toString(),
      targetClockOut: json['target_clock_out']?.toString(),
      flexiMinutes: _parseInt(json['flexi_minutes']),
      isFlexible: json['is_flexible'] == true,
      clockInSource: json['clock_in_source']?.toString(),
      clockOutSource: json['clock_out_source']?.toString(),
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      lateMinutes: _parseInt(json['late_minutes']),
      workingMinutes: _parseInt(json['working_minutes']),
      faceVerified: json['face_verified'] == true,
      officeLocation: json['office_location'] != null
          ? OfficeLocationModel.fromJson(json['office_location'])
          : null,
      schedule: json['schedule'] != null
          ? Schedule.fromJson(json['schedule'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'clock_in': clockIn,
      'clock_out': clockOut,
      'clock_in_source': clockInSource,
      'clock_out_source': clockOutSource,
      'status': status,
      'status_label': statusLabel,
      'late_minutes': lateMinutes,
      'working_minutes': workingMinutes,
      'face_verified': faceVerified,
      'office_location': officeLocation?.toJson(),
      'schedule': schedule?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceTodayModel &&
        other.id == id &&
        other.date == date &&
        other.clockIn == clockIn &&
        other.clockOut == clockOut &&
        other.targetClockOut == targetClockOut &&
        other.flexiMinutes == flexiMinutes &&
        other.isFlexible == isFlexible &&
        other.status == status &&
        other.statusLabel == statusLabel &&
        other.lateMinutes == lateMinutes &&
        other.workingMinutes == workingMinutes &&
        other.faceVerified == faceVerified &&
        mapEquals(other.officeLocation?.toJson(), officeLocation?.toJson()) &&
        other.schedule == schedule;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        clockIn.hashCode ^
        clockOut.hashCode ^
        targetClockOut.hashCode ^
        flexiMinutes.hashCode ^
        isFlexible.hashCode ^
        status.hashCode ^
        statusLabel.hashCode ^
        lateMinutes.hashCode ^
        workingMinutes.hashCode ^
        faceVerified.hashCode ^
        officeLocation.hashCode ^
        schedule.hashCode;
  }
}

class Schedule {
  final String? name;
  final String startTime;
  final String endTime;
  final bool isFlexible;
  final int lateTolerance;
  final int earlyLeaveTolerance;

  const Schedule({
    this.name,
    required this.startTime,
    required this.endTime,
    this.isFlexible = false,
    this.lateTolerance = 15,
    this.earlyLeaveTolerance = 15,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      name: json['name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      isFlexible: json['is_flexible'] == true,
      lateTolerance: json['late_tolerance'] is int ? json['late_tolerance'] : 15,
      earlyLeaveTolerance: json['early_leave_tolerance'] is int ? json['early_leave_tolerance'] : 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'start_time': startTime, 'end_time': endTime};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Schedule &&
        other.name == name &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => name.hashCode ^ startTime.hashCode ^ endTime.hashCode;
}
