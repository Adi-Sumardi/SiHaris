import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/announcement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/unread_count_model.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_unread_count/announcement_unread_count_bloc.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_unread_count/announcement_unread_count_event.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_unread_count/announcement_unread_count_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAnnouncementRemoteDatasource extends Mock
    implements AnnouncementRemoteDatasource {}

void main() {
  late AnnouncementUnreadCountBloc bloc;
  late MockAnnouncementRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockAnnouncementRemoteDatasource();
    bloc = AnnouncementUnreadCountBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  const tUnreadCount = UnreadCountModel(count: 5);

  test('initial state should be AnnouncementUnreadCountInitial', () {
    expect(bloc.state, equals(AnnouncementUnreadCountInitial()));
  });

  group('LoadUnreadCount', () {
    blocTest<AnnouncementUnreadCountBloc, AnnouncementUnreadCountState>(
      'emits [Loading, Loaded] when count is fetched successfully',
      build: () {
        when(
          () => mockDatasource.getUnreadCount(),
        ).thenAnswer((_) async => tUnreadCount);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadUnreadCount()),
      expect: () => [
        AnnouncementUnreadCountLoading(),
        const AnnouncementUnreadCountLoaded(5),
      ],
    );

    blocTest<AnnouncementUnreadCountBloc, AnnouncementUnreadCountState>(
      'emits [Loading, Error] when fetching count fails',
      build: () {
        when(
          () => mockDatasource.getUnreadCount(),
        ).thenThrow(Exception('Failed to load count'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadUnreadCount()),
      expect: () => [
        AnnouncementUnreadCountLoading(),
        const AnnouncementUnreadCountError('Exception: Failed to load count'),
      ],
    );
  });

  group('RefreshUnreadCount', () {
    blocTest<AnnouncementUnreadCountBloc, AnnouncementUnreadCountState>(
      'emits [Loading, Loaded] when refresh is successful',
      build: () {
        when(
          () => mockDatasource.getUnreadCount(),
        ).thenAnswer((_) async => tUnreadCount);
        return bloc;
      },
      act: (bloc) => bloc.add(const RefreshUnreadCount()),
      expect: () => [
        AnnouncementUnreadCountLoading(),
        const AnnouncementUnreadCountLoaded(5),
      ],
    );
  });
}
