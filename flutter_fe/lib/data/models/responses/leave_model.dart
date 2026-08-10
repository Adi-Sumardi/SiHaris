import 'package:gaji_pro/data/models/responses/leave_type_model.dart';

class LeaveModel {
  final int id;
  final String requestNumber;
  final LeaveTypeModel leaveType;
  final String startDate;
  final String endDate;
  final double totalDays;
  final bool isHalfDay;
  final String? halfDayType;
  final String? reason;
  final String? attachment;
  final String status;
  final String statusLabel;
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final String createdAt;

  const LeaveModel({
    required this.id,
    required this.requestNumber,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.isHalfDay,
    this.halfDayType,
    this.reason,
    this.attachment,
    required this.status,
    required this.statusLabel,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'],
      requestNumber: json['request_number'],
      leaveType: LeaveTypeModel.fromJson(json['leave_type']),
      startDate: json['start_date'],
      endDate: json['end_date'],
      totalDays: (json['total_days'] as num).toDouble(),
      isHalfDay: json['is_half_day'] ?? false,
      halfDayType: json['half_day_type'],
      reason: json['reason'],
      attachment: json['attachment'],
      status: json['status'],
      statusLabel: json['status_label'] ?? _getStatusLabel(json['status']),
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'],
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] ?? '',
    );
  }

  static String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_number': requestNumber,
      'leave_type': leaveType.toJson(),
      'start_date': startDate,
      'end_date': endDate,
      'total_days': totalDays,
      'is_half_day': isHalfDay,
      'half_day_type': halfDayType,
      'reason': reason,
      'attachment': attachment,
      'status': status,
      'status_label': statusLabel,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'rejection_reason': rejectionReason,
      'created_at': createdAt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaveModel &&
        other.id == id &&
        other.requestNumber == requestNumber &&
        other.leaveType == leaveType &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.totalDays == totalDays &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        requestNumber.hashCode ^
        leaveType.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        totalDays.hashCode ^
        status.hashCode;
  }
}
