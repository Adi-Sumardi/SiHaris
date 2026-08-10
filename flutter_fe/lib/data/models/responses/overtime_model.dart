import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class OvertimeModel extends Equatable {
  final int id;
  final String date;
  final String startTime;
  final String endTime;
  final String overtimeHours;
  final String overtimeType;
  final String overtimeTypeLabel;
  final int overtimeAmount;
  final String formattedAmount;
  final String? reason;
  final String status;
  final String statusLabel;
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final String createdAt;

  const OvertimeModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.overtimeHours,
    required this.overtimeType,
    required this.overtimeTypeLabel,
    required this.overtimeAmount,
    required this.formattedAmount,
    this.reason,
    required this.status,
    required this.statusLabel,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  factory OvertimeModel.fromJson(Map<String, dynamic> json) {
    final amount = (json['overtime_amount'] as num?)?.toInt() ?? 0;
    return OvertimeModel(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      overtimeHours: json['overtime_hours']?.toString() ?? '0',
      overtimeType: json['overtime_type'] ?? '',
      overtimeTypeLabel: json['overtime_type_label'] ?? '',
      overtimeAmount: amount,
      formattedAmount: json['formatted_amount'] ??
          'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount).trim()}',
      reason: json['reason'],
      status: json['status'] ?? '',
      statusLabel: json['status_label'] ?? '',
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'],
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'overtime_hours': overtimeHours,
      'overtime_type': overtimeType,
      'overtime_type_label': overtimeTypeLabel,
      'overtime_amount': overtimeAmount,
      'formatted_amount': formattedAmount,
      'reason': reason,
      'status': status,
      'status_label': statusLabel,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'rejection_reason': rejectionReason,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    date,
    startTime,
    endTime,
    overtimeHours,
    overtimeType,
    overtimeTypeLabel,
    overtimeAmount,
    formattedAmount,
    reason,
    status,
    statusLabel,
    approvedBy,
    approvedAt,
    rejectionReason,
    createdAt,
  ];
}
