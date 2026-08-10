class ReimbursementCategoryModel {
  final int id;
  final String name;
  final String description;
  final int maxAmount;
  final bool requiresReceipt;

  const ReimbursementCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.maxAmount,
    required this.requiresReceipt,
  });

  factory ReimbursementCategoryModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      maxAmount: json['max_amount'] as int,
      requiresReceipt: json['requires_receipt'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'max_amount': maxAmount,
      'requires_receipt': requiresReceipt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReimbursementCategoryModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.maxAmount == maxAmount &&
        other.requiresReceipt == requiresReceipt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, description, maxAmount, requiresReceipt);
  }
}
