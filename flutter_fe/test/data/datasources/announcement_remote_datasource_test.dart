import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/announcement_remote_datasource.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/models/responses/announcement_model.dart';
import 'package:gaji_pro/data/models/responses/unread_count_model.dart';
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockAuthLocalDatasource extends Mock implements AuthLocalDatasource {}

class FakeUri extends Fake implements Uri {}

void main() {
  late AnnouncementRemoteDatasource datasource;
  late MockHttpClient mockHttpClient;
  late MockAuthLocalDatasource mockAuthLocalDatasource;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuthLocalDatasource = MockAuthLocalDatasource();
    datasource = AnnouncementRemoteDatasource(
      mockHttpClient,
      mockAuthLocalDatasource,
    );
    registerFallbackValue(FakeUri());
  });

  const tToken = 'test_token';

  group('getAnnouncements', () {
    final tAnnouncementsList = [
      const AnnouncementModel(
        id: 1,
        title: 'Test Announcement',
        content: 'Test content',
        priority: 'high',
        priorityLabel: 'Tinggi',
        isPinned: true,
        isRead: false,
        publishedAt: '2026-02-15T10:00:00Z',
        createdAt: '2026-02-15T09:30:00Z',
      ),
    ];

    test('should return list of announcements when successful', () async {
      // arrange
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 1,
                'title': 'Test Announcement',
                'content': 'Test content',
                'priority': 'high',
                'priority_label': 'Tinggi',
                'is_pinned': true,
                'is_read': false,
                'published_at': '2026-02-15T10:00:00Z',
                'created_at': '2026-02-15T09:30:00Z',
              },
            ],
          }),
          200,
        ),
      );

      // act
      final result = await datasource.getAnnouncements();

      // assert
      expect(result, equals(tAnnouncementsList));
      verify(
        () => mockHttpClient.get(
          Uri.parse('${Variables.baseUrl}/announcements?page=1'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $tToken',
          },
        ),
      ).called(1);
    });

    test('should throw exception when request fails', () async {
      // arrange
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      // act & assert
      expect(() => datasource.getAnnouncements(), throwsException);
    });
  });

  group('getAnnouncementDetail', () {
    const tAnnouncement = AnnouncementModel(
      id: 1,
      title: 'Test Announcement',
      content: 'Test content',
      priority: 'high',
      priorityLabel: 'Tinggi',
      isPinned: true,
      isRead: false,
      publishedAt: '2026-02-15T10:00:00Z',
      createdAt: '2026-02-15T09:30:00Z',
      creatorName: 'HR Department',
    );

    test('should return announcement detail when successful', () async {
      // arrange
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 1,
              'title': 'Test Announcement',
              'content': 'Test content',
              'priority': 'high',
              'priority_label': 'Tinggi',
              'is_pinned': true,
              'is_read': false,
              'published_at': '2026-02-15T10:00:00Z',
              'created_at': '2026-02-15T09:30:00Z',
              'creator': {'name': 'HR Department'},
            },
          }),
          200,
        ),
      );

      // act
      final result = await datasource.getAnnouncementDetail(1);

      // assert
      expect(result, equals(tAnnouncement));
    });

    test('should throw exception when request fails', () async {
      // arrange
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Not found', 404));

      // act & assert
      expect(() => datasource.getAnnouncementDetail(1), throwsException);
    });
  });

  group('markAsRead', () {
    test('should mark announcement as read when successful', () async {
      // arrange
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': true, 'message': 'Marked as read'}),
          200,
        ),
      );

      // act
      await datasource.markAsRead(1);

      // assert
      verify(
        () => mockHttpClient.post(
          Uri.parse('${Variables.baseUrl}/announcements/1/read'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $tToken',
          },
        ),
      ).called(1);
    });

    test('should throw exception when request fails', () async {
      // arrange
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      // act & assert
      expect(() => datasource.markAsRead(1), throwsException);
    });
  });

  group('getUnreadCount', () {
    const tUnreadCount = UnreadCountModel(count: 5);

    test('should return unread count when successful', () async {
      // arrange
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {'count': 5},
          }),
          200,
        ),
      );

      // act
      final result = await datasource.getUnreadCount();

      // assert
      expect(result, equals(tUnreadCount));
    });

    test('should throw exception when request fails', () async {
      // arrange
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      // act & assert
      expect(() => datasource.getUnreadCount(), throwsException);
    });
  });
}
