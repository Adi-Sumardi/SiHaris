import 'package:equatable/equatable.dart';
import 'leave_model.dart';
import 'reimbursement_model.dart';

class PendingApprovalsModel extends Equatable {
  final List<LeaveModel> leaveRequests;
  final List<dynamic>
  overtimeRequests; // Will use dynamic for now until OvertimeModel exists
  final List<ReimbursementModel> reimbursements;
  final int totalPending;

  const PendingApprovalsModel({
    required this.leaveRequests,
    required this.overtimeRequests,
    required this.reimbursements,
    required this.totalPending,
  });

  factory PendingApprovalsModel.fromJson(Map<String, dynamic> json) {
    return PendingApprovalsModel(
      leaveRequests:
          (json['leave_requests'] as List<dynamic>?)
              ?.map((e) => LeaveModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overtimeRequests: (json['overtime_requests'] as List<dynamic>?) ?? [],
      reimbursements:
          (json['reimbursements'] as List<dynamic>?)
              ?.map(
                (e) => ReimbursementModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      totalPending: json['total_pending'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leave_requests': leaveRequests.map((e) => e.toJson()).toList(),
      'overtime_requests': overtimeRequests,
      'reimbursements': reimbursements.map((e) => e.toJson()).toList(),
      'total_pending': totalPending,
    };
  }

  @override
  List<Object?> get props => [
    leaveRequests,
    overtimeRequests,
    reimbursements,
    totalPending,
  ];
}
