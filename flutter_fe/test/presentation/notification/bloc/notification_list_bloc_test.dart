import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/notification_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/notification_model.dart';
import 'package:gaji_pro/presentation/notification/bloc/notification_list/notification_list_bloc.dart';
import 'package:gaji_pro/presentation/notification/bloc/notification_list/notification_list_event.dart';
import 'package:gaji_pro/presentation/notification/bloc/notification_list/notification_list_state.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRemoteDatasource extends Mock
    implements NotificationRemoteDatasource {}

void main() {
  late NotificationListBloc bloc;
  late MockNotificationRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockNotificationRemoteDatasource();
    bloc = NotificationListBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  const tNotifications = [
    NotificationModel(
      id: 1,
      title: 'Pengajuan Cuti Disetujui',
      message: 'Cuti Anda telah disetujui.',
      type: 'approval',
      isRead: false,
      createdAt: '2026-02-15T09:30:00Z',
    ),
  ];

  final tFullPageNotifications = List.generate(
    20,
    (i) => NotificationModel(
      id: i + 1,
      title: 'Notifikasi $i',
      message: 'Pesan $i',
      type: 'approval',
      isRead: false,
      createdAt: '2026-02-15T09:30:00Z',
    ),
  );

  test('initial state should be NotificationListInitial', () {
    expect(bloc.state, equals(NotificationListInitial()));
  });

  group('LoadNotifications', () {
    blocTest<NotificationListBloc, NotificationListState>(
      'emits [Loading, Loaded] with hasReachedMax true when fewer than 20 items are fetched',
      build: () {
        when(
          () => mockDatasource.getNotifications(page: any(named: 'page')),
        ).thenAnswer((_) async => tNotifications);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications()),
      expect: () => [
        NotificationListLoading(),
        const NotificationListLoaded(tNotifications, hasReachedMax: true),
      ],
    );

    blocTest<NotificationListBloc, NotificationListState>(
      'emits [Loading, Loaded] with hasReachedMax false when a full page of 20 items is fetched',
      build: () {
        when(
          () => mockDatasource.getNotifications(page: any(named: 'page')),
        ).thenAnswer((_) async => tFullPageNotifications);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications()),
      expect: () => [
        NotificationListLoading(),
        NotificationListLoaded(tFullPageNotifications, hasReachedMax: false),
      ],
    );

    blocTest<NotificationListBloc, NotificationListState>(
      'emits [Loading, Error] when fetching data fails',
      build: () {
        when(
          () => mockDatasource.getNotifications(page: any(named: 'page')),
        ).thenThrow(Exception('Failed to load'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications()),
      expect: () => [
        NotificationListLoading(),
        const NotificationListError('Exception: Failed to load'),
      ],
    );
  });

  group('LoadMoreNotifications', () {
    blocTest<NotificationListBloc, NotificationListState>(
      'emits [Loaded] with more notifications when load more is successful',
      build: () {
        when(
          () => mockDatasource.getNotifications(page: any(named: 'page')),
        ).thenAnswer((_) async => tNotifications);
        return bloc;
      },
      seed: () =>
          NotificationListLoaded(tFullPageNotifications, hasReachedMax: false),
      act: (bloc) => bloc.add(const LoadMoreNotifications()),
      expect: () => [
        NotificationListLoaded([
          ...tFullPageNotifications,
          ...tNotifications,
        ], hasReachedMax: true),
      ],
    );
  });

  group('MarkNotificationAsRead', () {
    blocTest<NotificationListBloc, NotificationListState>(
      'marks only the matching notification as read in the current list',
      build: () {
        when(() => mockDatasource.markAsRead(1)).thenAnswer((_) async {});
        return bloc;
      },
      seed: () =>
          const NotificationListLoaded(tNotifications, hasReachedMax: false),
      act: (bloc) => bloc.add(const MarkNotificationAsRead(1)),
      expect: () => [
        NotificationListLoaded(
          [tNotifications.first.copyWith(isRead: true)],
          hasReachedMax: false,
        ),
      ],
      verify: (_) {
        verify(() => mockDatasource.markAsRead(1)).called(1);
      },
    );
  });

  group('MarkAllNotificationsAsRead', () {
    blocTest<NotificationListBloc, NotificationListState>(
      'marks every notification in the current list as read',
      build: () {
        when(() => mockDatasource.markAllAsRead()).thenAnswer((_) async {});
        return bloc;
      },
      seed: () =>
          const NotificationListLoaded(tNotifications, hasReachedMax: false),
      act: (bloc) => bloc.add(const MarkAllNotificationsAsRead()),
      expect: () => [
        NotificationListLoaded(
          [tNotifications.first.copyWith(isRead: true)],
          hasReachedMax: false,
        ),
      ],
    );
  });
}
