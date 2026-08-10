class ApprovalActionRequest {
  final String? notes;

  const ApprovalActionRequest({this.notes});

  Map<String, dynamic> toJson() {
    return {if (notes != null) 'notes': notes};
  }
}
