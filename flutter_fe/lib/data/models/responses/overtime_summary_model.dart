import 'package:equatable/equatable.dart';

class OvertimeSummaryModel extends Equatable {
  final int totalRequests;
  final int approvedRequests;
  final int pendingRequests;
  final String totalHours;
  final int totalAmount;

  const OvertimeSummaryModel({
    required this.totalRequests,
    required this.approvedRequests,
    required this.pendingRequests,
    required this.totalHours,
    required this.totalAmount,
  });

  factory OvertimeSummaryModel.fromJson(Map<String, dynamic> json) {
    return OvertimeSummaryModel(
      totalRequests: json['total_requests'] ?? 0,
      approvedRequests: json['approved_requests'] ?? 0,
      pendingRequests: json['pending_requests'] ?? 0,
      totalHours: json['total_hours']?.toString() ?? '0',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_requests': totalRequests,
      'approved_requests': approvedRequests,
      'pending_requests': pendingRequests,
      'total_hours': totalHours,
      'total_amount': totalAmount,
    };
  }

  @override
  List<Object?> get props => [
    totalRequests,
    approvedRequests,
    pendingRequests,
    totalHours,
    totalAmount,
  ];
}
