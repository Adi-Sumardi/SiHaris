class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final String priority;
  final String priorityLabel;
  final bool isPinned;
  final bool isRead;
  final String publishedAt;
  final String createdAt;
  final String? creatorName;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.priorityLabel,
    required this.isPinned,
    required this.isRead,
    required this.publishedAt,
    required this.createdAt,
    this.creatorName,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      priority: json['priority'] as String,
      priorityLabel: json['priority_label'] as String,
      isPinned: json['is_pinned'] as bool,
      isRead: json['is_read'] as bool,
      publishedAt: json['published_at'] as String,
      createdAt: json['created_at'] as String,
      creatorName: json['creator'] != null
          ? (json['creator'] as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'title': title,
      'content': content,
      'priority': priority,
      'priority_label': priorityLabel,
      'is_pinned': isPinned,
      'is_read': isRead,
      'published_at': publishedAt,
      'created_at': createdAt,
    };

    if (creatorName != null) {
      map['creator'] = {'name': creatorName};
    }

    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnnouncementModel &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.priority == priority &&
        other.priorityLabel == priorityLabel &&
        other.isPinned == isPinned &&
        other.isRead == isRead &&
        other.publishedAt == publishedAt &&
        other.createdAt == createdAt &&
        other.creatorName == creatorName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        priority.hashCode ^
        priorityLabel.hashCode ^
        isPinned.hashCode ^
        isRead.hashCode ^
        publishedAt.hashCode ^
        createdAt.hashCode ^
        creatorName.hashCode;
  }
}
