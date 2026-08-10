import 'package:equatable/equatable.dart';

class ApprovalHistoryModel extends Equatable {
  final String type; // leave, overtime, reimbursement
  final int id;
  final String employeeName;
  final String status; // approved, rejected
  final String approvedAt;
  final String? notes;

  const ApprovalHistoryModel({
    required this.type,
    required this.id,
    required this.employeeName,
    required this.status,
    required this.approvedAt,
    this.notes,
  });

  factory ApprovalHistoryModel.fromJson(Map<String, dynamic> json) {
    return ApprovalHistoryModel(
      type: json['type'] as String,
      id: json['id'] as int,
      employeeName: json['employee_name'] as String,
      status: json['status'] as String,
      approvedAt: json['approved_at'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'employee_name': employeeName,
      'status': status,
      'approved_at': approvedAt,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
    type,
    id,
    employeeName,
    status,
    approvedAt,
    notes,
  ];
}
