import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/announcement_model.dart';

void main() {
  group('AnnouncementModel', () {
    const tAnnouncementJson = {
      'id': 1,
      'title': 'Company Holiday Announcement',
      'content': 'The office will be closed on February 20, 2026.',
      'priority': 'high',
      'priority_label': 'Tinggi',
      'is_pinned': true,
      'is_read': false,
      'published_at': '2026-02-15T10:00:00Z',
      'created_at': '2026-02-15T09:30:00Z',
    };

    const tAnnouncementDetailJson = {
      'id': 1,
      'title': 'Company Holiday Announcement',
      'content': 'The office will be closed on February 20, 2026.',
      'priority': 'high',
      'priority_label': 'Tinggi',
      'is_pinned': true,
      'is_read': false,
      'published_at': '2026-02-15T10:00:00Z',
      'created_at': '2026-02-15T09:30:00Z',
      'creator': {'name': 'HR Department'},
    };

    const tAnnouncementWithAttachmentJson = {
      'id': 2,
      'title': 'Surat Edaran',
      'content': 'Lihat lampiran.',
      'priority': 'normal',
      'priority_label': 'Normal',
      'is_pinned': false,
      'is_read': false,
      'has_attachment': true,
      'attachment_name': 'edaran.pdf',
      'attachment_size': 307200,
      'human_attachment_size': '300.0 KB',
      'attachment_mime_type': 'application/pdf',
      'is_attachment_image': false,
      'is_attachment_pdf': true,
      'attachment_preview_url':
          'https://siharis.yapinet.id/api/v1/announcements/2/preview?token=abc&expires=123',
      'attachment_download_url':
          'https://siharis.yapinet.id/api/v1/announcements/2/download?token=abc&expires=123',
      'published_at': '2026-02-15T10:00:00Z',
      'created_at': '2026-02-15T09:30:00Z',
    };

    const tAnnouncement = AnnouncementModel(
      id: 1,
      title: 'Company Holiday Announcement',
      content: 'The office will be closed on February 20, 2026.',
      priority: 'high',
      priorityLabel: 'Tinggi',
      isPinned: true,
      isRead: false,
      publishedAt: '2026-02-15T10:00:00Z',
      createdAt: '2026-02-15T09:30:00Z',
      creatorName: null,
    );

    const tAnnouncementDetail = AnnouncementModel(
      id: 1,
      title: 'Company Holiday Announcement',
      content: 'The office will be closed on February 20, 2026.',
      priority: 'high',
      priorityLabel: 'Tinggi',
      isPinned: true,
      isRead: false,
      publishedAt: '2026-02-15T10:00:00Z',
      createdAt: '2026-02-15T09:30:00Z',
      creatorName: 'HR Department',
    );

    test('should create AnnouncementModel from JSON (list)', () {
      final result = AnnouncementModel.fromJson(tAnnouncementJson);
      expect(result, equals(tAnnouncement));
    });

    test('should create AnnouncementModel from JSON (detail with creator)', () {
      final result = AnnouncementModel.fromJson(tAnnouncementDetailJson);
      expect(result, equals(tAnnouncementDetail));
    });

    test('should convert AnnouncementModel to JSON', () {
      final result = tAnnouncement.toJson();
      expect(result['id'], equals(1));
      expect(result['title'], equals('Company Holiday Announcement'));
      expect(result['priority'], equals('high'));
      expect(result['is_pinned'], equals(true));
      expect(result['is_read'], equals(false));
    });

    test('should default hasAttachment to false when not present in JSON', () {
      final result = AnnouncementModel.fromJson(tAnnouncementJson);
      expect(result.hasAttachment, isFalse);
      expect(result.attachmentPreviewUrl, isNull);
      expect(result.attachmentDownloadUrl, isNull);
    });

    test('should parse attachment fields from JSON', () {
      final result = AnnouncementModel.fromJson(
        tAnnouncementWithAttachmentJson,
      );

      expect(result.hasAttachment, isTrue);
      expect(result.attachmentName, equals('edaran.pdf'));
      expect(result.attachmentSize, equals(307200));
      expect(result.humanAttachmentSize, equals('300.0 KB'));
      expect(result.attachmentMimeType, equals('application/pdf'));
      expect(result.isAttachmentImage, isFalse);
      expect(result.isAttachmentPdf, isTrue);
      expect(
        result.attachmentPreviewUrl,
        equals(
          'https://siharis.yapinet.id/api/v1/announcements/2/preview?token=abc&expires=123',
        ),
      );
      expect(
        result.attachmentDownloadUrl,
        equals(
          'https://siharis.yapinet.id/api/v1/announcements/2/download?token=abc&expires=123',
        ),
      );
    });
  });
}
