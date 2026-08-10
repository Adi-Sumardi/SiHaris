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
  });
}
