class UnreadCountModel {
  final int count;

  const UnreadCountModel({required this.count});

  factory UnreadCountModel.fromJson(Map<String, dynamic> json) {
    return UnreadCountModel(count: json['count'] as int);
  }

  Map<String, dynamic> toJson() {
    return {'count': count};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UnreadCountModel && other.count == count;
  }

  @override
  int get hashCode => count.hashCode;
}
