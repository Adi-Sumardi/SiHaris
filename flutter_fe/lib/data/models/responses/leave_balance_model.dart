class LeaveBalanceModel {
  final int leaveTypeId;
  final String leaveTypeName;
  final int year;
  final double entitledDays;
  final double usedDays;
  final double pendingDays;
  final double remainingDays;

  const LeaveBalanceModel({
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.year,
    required this.entitledDays,
    required this.usedDays,
    required this.pendingDays,
    required this.remainingDays,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      leaveTypeId: json['leave_type_id'] ?? 0,
      leaveTypeName: json['leave_type_name'] ?? '',
      year: json['year'] ?? DateTime.now().year,
      entitledDays: (json['entitled_days'] as num?)?.toDouble() ?? 0,
      usedDays: (json['used_days'] as num?)?.toDouble() ?? 0,
      pendingDays: (json['pending_days'] as num?)?.toDouble() ?? 0,
      remainingDays: (json['remaining_days'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leave_type_id': leaveTypeId,
      'leave_type_name': leaveTypeName,
      'year': year,
      'entitled_days': entitledDays,
      'used_days': usedDays,
      'pending_days': pendingDays,
      'remaining_days': remainingDays,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaveBalanceModel &&
        other.leaveTypeId == leaveTypeId &&
        other.leaveTypeName == leaveTypeName &&
        other.year == year &&
        other.entitledDays == entitledDays &&
        other.usedDays == usedDays &&
        other.pendingDays == pendingDays &&
        other.remainingDays == remainingDays;
  }

  @override
  int get hashCode {
    return leaveTypeId.hashCode ^
        leaveTypeName.hashCode ^
        year.hashCode ^
        entitledDays.hashCode ^
        usedDays.hashCode ^
        pendingDays.hashCode ^
        remainingDays.hashCode;
  }
}
