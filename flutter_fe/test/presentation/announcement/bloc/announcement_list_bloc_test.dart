import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/announcement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/announcement_model.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_list/announcement_list_bloc.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_list/announcement_list_event.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_list/announcement_list_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAnnouncementRemoteDatasource extends Mock
    implements AnnouncementRemoteDatasource {}

void main() {
  late AnnouncementListBloc bloc;
  late MockAnnouncementRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockAnnouncementRemoteDatasource();
    bloc = AnnouncementListBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  const tAnnouncements = [
    AnnouncementModel(
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

  test('initial state should be AnnouncementListInitial', () {
    expect(bloc.state, equals(AnnouncementListInitial()));
  });

  group('LoadAnnouncements', () {
    blocTest<AnnouncementListBloc, AnnouncementListState>(
      'emits [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(
          () => mockDatasource.getAnnouncements(page: any(named: 'page')),
        ).thenAnswer((_) async => tAnnouncements);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAnnouncements()),
      expect: () => [
        AnnouncementListLoading(),
        const AnnouncementListLoaded(tAnnouncements, hasReachedMax: false),
      ],
    );

    blocTest<AnnouncementListBloc, AnnouncementListState>(
      'emits [Loading, Error] when fetching data fails',
      build: () {
        when(
          () => mockDatasource.getAnnouncements(page: any(named: 'page')),
        ).thenThrow(Exception('Failed to load'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAnnouncements()),
      expect: () => [
        AnnouncementListLoading(),
        const AnnouncementListError('Exception: Failed to load'),
      ],
    );
  });

  group('RefreshAnnouncements', () {
    blocTest<AnnouncementListBloc, AnnouncementListState>(
      'emits [Loading, Loaded] when refresh is successful',
      build: () {
        when(
          () => mockDatasource.getAnnouncements(page: any(named: 'page')),
        ).thenAnswer((_) async => tAnnouncements);
        return bloc;
      },
      act: (bloc) => bloc.add(const RefreshAnnouncements()),
      expect: () => [
        AnnouncementListLoading(),
        const AnnouncementListLoaded(tAnnouncements, hasReachedMax: false),
      ],
    );
  });

  group('LoadMoreAnnouncements', () {
    blocTest<AnnouncementListBloc, AnnouncementListState>(
      'emits [Loaded] with more announcements when load more is successful',
      build: () {
        when(
          () => mockDatasource.getAnnouncements(page: any(named: 'page')),
        ).thenAnswer((_) async => tAnnouncements);
        return bloc;
      },
      seed: () =>
          const AnnouncementListLoaded(tAnnouncements, hasReachedMax: false),
      act: (bloc) => bloc.add(const LoadMoreAnnouncements()),
      expect: () => [
        const AnnouncementListLoaded([
          ...tAnnouncements,
          ...tAnnouncements,
        ], hasReachedMax: false),
      ],
    );
  });
}
