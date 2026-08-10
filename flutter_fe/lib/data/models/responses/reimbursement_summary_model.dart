class ReimbursementSummaryModel {
  final int totalRequests;
  final int pendingRequests;
  final int approvedRequests;
  final int paidRequests;
  final int totalAmount;
  final int approvedAmount;
  final int paidAmount;
  final int pendingAmount;

  const ReimbursementSummaryModel({
    required this.totalRequests,
    required this.pendingRequests,
    required this.approvedRequests,
    required this.paidRequests,
    required this.totalAmount,
    required this.approvedAmount,
    required this.paidAmount,
    required this.pendingAmount,
  });

  factory ReimbursementSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementSummaryModel(
      totalRequests: json['total_requests'] as int,
      pendingRequests: json['pending_requests'] as int,
      approvedRequests: json['approved_requests'] as int,
      paidRequests: json['paid_requests'] as int,
      totalAmount: json['total_amount'] as int,
      approvedAmount: json['approved_amount'] as int,
      paidAmount: json['paid_amount'] as int,
      pendingAmount: json['pending_amount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_requests': totalRequests,
      'pending_requests': pendingRequests,
      'approved_requests': approvedRequests,
      'paid_requests': paidRequests,
      'total_amount': totalAmount,
      'approved_amount': approvedAmount,
      'paid_amount': paidAmount,
      'pending_amount': pendingAmount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReimbursementSummaryModel &&
        other.totalRequests == totalRequests &&
        other.pendingRequests == pendingRequests &&
        other.approvedRequests == approvedRequests &&
        other.paidRequests == paidRequests &&
        other.totalAmount == totalAmount &&
        other.approvedAmount == approvedAmount &&
        other.paidAmount == paidAmount &&
        other.pendingAmount == pendingAmount;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalRequests,
      pendingRequests,
      approvedRequests,
      paidRequests,
      totalAmount,
      approvedAmount,
      paidAmount,
      pendingAmount,
    );
  }
}
