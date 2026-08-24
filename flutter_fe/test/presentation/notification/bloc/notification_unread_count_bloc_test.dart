import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/notification_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/unread_count_model.dart';
import 'package:gaji_pro/presentation/notification/bloc/notification_unread_count/notification_unread_count_bloc.dart';
import 'package:gaji_pro/presentation/notification/bloc/notification_unread_count/notification_unread_count_event.dart';
import 'package:gaji_pro/presentation/notification/bloc/notification_unread_count/notification_unread_count_state.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRemoteDatasource extends Mock
    implements NotificationRemoteDatasource {}

void main() {
  late NotificationUnreadCountBloc bloc;
  late MockNotificationRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockNotificationRemoteDatasource();
    bloc = NotificationUnreadCountBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  const tUnreadCount = UnreadCountModel(count: 4);

  test('initial state should be NotificationUnreadCountInitial', () {
    expect(bloc.state, equals(NotificationUnreadCountInitial()));
  });

  group('LoadNotificationUnreadCount', () {
    blocTest<NotificationUnreadCountBloc, NotificationUnreadCountState>(
      'emits [Loading, Loaded] when count is fetched successfully',
      build: () {
        when(
          () => mockDatasource.getUnreadCount(),
        ).thenAnswer((_) async => tUnreadCount);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadNotificationUnreadCount()),
      expect: () => [
        NotificationUnreadCountLoading(),
        const NotificationUnreadCountLoaded(4),
      ],
    );

    blocTest<NotificationUnreadCountBloc, NotificationUnreadCountState>(
      'emits [Loading, Error] when fetching count fails',
      build: () {
        when(
          () => mockDatasource.getUnreadCount(),
        ).thenThrow(Exception('Failed to load count'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadNotificationUnreadCount()),
      expect: () => [
        NotificationUnreadCountLoading(),
        const NotificationUnreadCountError('Exception: Failed to load count'),
      ],
    );
  });

  group('RefreshNotificationUnreadCount', () {
    blocTest<NotificationUnreadCountBloc, NotificationUnreadCountState>(
      'emits [Loading, Loaded] when refresh is successful',
      build: () {
        when(
          () => mockDatasource.getUnreadCount(),
        ).thenAnswer((_) async => tUnreadCount);
        return bloc;
      },
      act: (bloc) => bloc.add(const RefreshNotificationUnreadCount()),
      expect: () => [
        NotificationUnreadCountLoading(),
        const NotificationUnreadCountLoaded(4),
      ],
    );
  });
}
