class LeaveTypeModel {
  final int id;
  final String name;
  final int quota;
  final bool isPaid;
  final bool requiresAttachment;

  const LeaveTypeModel({
    required this.id,
    required this.name,
    required this.quota,
    required this.isPaid,
    required this.requiresAttachment,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: json['id'],
      name: json['name'],
      quota: json['quota'],
      isPaid: json['is_paid'] ?? true, // Default to true if null
      requiresAttachment: json['requires_attachment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quota': quota,
      'is_paid': isPaid,
      'requires_attachment': requiresAttachment,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaveTypeModel &&
        other.id == id &&
        other.name == name &&
        other.quota == quota &&
        other.isPaid == isPaid &&
        other.requiresAttachment == requiresAttachment;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        quota.hashCode ^
        isPaid.hashCode ^
        requiresAttachment.hashCode;
  }
}
