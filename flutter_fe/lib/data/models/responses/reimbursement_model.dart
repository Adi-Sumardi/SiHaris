class ReimbursementModel {
  final int id;
  final String category;
  final int amount;
  final String formattedAmount;
  final String description;
  final String expenseDate;
  final String? receiptUrl;
  final String status;
  final String statusLabel;
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final String? paidAt;
  final String? paymentMethod;
  final String createdAt;

  const ReimbursementModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.formattedAmount,
    required this.description,
    required this.expenseDate,
    this.receiptUrl,
    required this.status,
    required this.statusLabel,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.paidAt,
    this.paymentMethod,
    required this.createdAt,
  });

  factory ReimbursementModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementModel(
      id: json['id'] as int,
      category: json['category'] as String,
      amount: (json['amount'] as num).toInt(),
      formattedAmount: json['formatted_amount'] as String,
      description: json['description'] as String,
      expenseDate: json['expense_date'] as String,
      receiptUrl: json['receipt_url'] as String?,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      paidAt: json['paid_at'] as String?,
      paymentMethod: json['payment_method'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'formatted_amount': formattedAmount,
      'description': description,
      'expense_date': expenseDate,
      'receipt_url': receiptUrl,
      'status': status,
      'status_label': statusLabel,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'rejection_reason': rejectionReason,
      'paid_at': paidAt,
      'payment_method': paymentMethod,
      'created_at': createdAt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReimbursementModel &&
        other.id == id &&
        other.category == category &&
        other.amount == amount &&
        other.formattedAmount == formattedAmount &&
        other.description == description &&
        other.expenseDate == expenseDate &&
        other.receiptUrl == receiptUrl &&
        other.status == status &&
        other.statusLabel == statusLabel &&
        other.approvedBy == approvedBy &&
        other.approvedAt == approvedAt &&
        other.rejectionReason == rejectionReason &&
        other.paidAt == paidAt &&
        other.paymentMethod == paymentMethod &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      category,
      amount,
      formattedAmount,
      description,
      expenseDate,
      receiptUrl,
      status,
      statusLabel,
      approvedBy,
      approvedAt,
      rejectionReason,
      paidAt,
      paymentMethod,
      createdAt,
    );
  }
}
