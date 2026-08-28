class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final String priority;
  final String priorityLabel;
  final bool isPinned;
  final bool isRead;
  final bool hasAttachment;
  final String? attachmentName;
  final int? attachmentSize;
  final String? humanAttachmentSize;
  final String? attachmentMimeType;
  final bool isAttachmentImage;
  final bool isAttachmentPdf;
  final String? attachmentPreviewUrl;
  final String? attachmentDownloadUrl;
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
    this.hasAttachment = false,
    this.attachmentName,
    this.attachmentSize,
    this.humanAttachmentSize,
    this.attachmentMimeType,
    this.isAttachmentImage = false,
    this.isAttachmentPdf = false,
    this.attachmentPreviewUrl,
    this.attachmentDownloadUrl,
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
      hasAttachment: json['has_attachment'] as bool? ?? false,
      attachmentName: json['attachment_name'] as String?,
      attachmentSize: json['attachment_size'] as int?,
      humanAttachmentSize: json['human_attachment_size'] as String?,
      attachmentMimeType: json['attachment_mime_type'] as String?,
      isAttachmentImage: json['is_attachment_image'] as bool? ?? false,
      isAttachmentPdf: json['is_attachment_pdf'] as bool? ?? false,
      attachmentPreviewUrl: json['attachment_preview_url'] as String?,
      attachmentDownloadUrl: json['attachment_download_url'] as String?,
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
      'has_attachment': hasAttachment,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'human_attachment_size': humanAttachmentSize,
      'attachment_mime_type': attachmentMimeType,
      'is_attachment_image': isAttachmentImage,
      'is_attachment_pdf': isAttachmentPdf,
      'attachment_preview_url': attachmentPreviewUrl,
      'attachment_download_url': attachmentDownloadUrl,
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
        other.hasAttachment == hasAttachment &&
        other.attachmentName == attachmentName &&
        other.attachmentSize == attachmentSize &&
        other.humanAttachmentSize == humanAttachmentSize &&
        other.attachmentMimeType == attachmentMimeType &&
        other.isAttachmentImage == isAttachmentImage &&
        other.isAttachmentPdf == isAttachmentPdf &&
        other.attachmentPreviewUrl == attachmentPreviewUrl &&
        other.attachmentDownloadUrl == attachmentDownloadUrl &&
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
        hasAttachment.hashCode ^
        attachmentName.hashCode ^
        attachmentSize.hashCode ^
        humanAttachmentSize.hashCode ^
        attachmentMimeType.hashCode ^
        isAttachmentImage.hashCode ^
        isAttachmentPdf.hashCode ^
        attachmentPreviewUrl.hashCode ^
        attachmentDownloadUrl.hashCode ^
        publishedAt.hashCode ^
        createdAt.hashCode ^
        creatorName.hashCode;
  }
}
