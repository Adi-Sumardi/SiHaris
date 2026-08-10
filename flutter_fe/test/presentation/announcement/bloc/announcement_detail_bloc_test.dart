import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/announcement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/announcement_model.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_detail/announcement_detail_bloc.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_detail/announcement_detail_event.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_detail/announcement_detail_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAnnouncementRemoteDatasource extends Mock
    implements AnnouncementRemoteDatasource {}

void main() {
  late AnnouncementDetailBloc bloc;
  late MockAnnouncementRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockAnnouncementRemoteDatasource();
    bloc = AnnouncementDetailBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

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

  test('initial state should be AnnouncementDetailInitial', () {
    expect(bloc.state, equals(AnnouncementDetailInitial()));
  });

  group('LoadAnnouncementDetail', () {
    blocTest<AnnouncementDetailBloc, AnnouncementDetailState>(
      'emits [Loading, Loaded] when detail is fetched successfully',
      build: () {
        when(
          () => mockDatasource.getAnnouncementDetail(1),
        ).thenAnswer((_) async => tAnnouncement);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAnnouncementDetail(1)),
      expect: () => [
        AnnouncementDetailLoading(),
        const AnnouncementDetailLoaded(tAnnouncement),
      ],
    );

    blocTest<AnnouncementDetailBloc, AnnouncementDetailState>(
      'emits [Loading, Error] when fetching detail fails',
      build: () {
        when(
          () => mockDatasource.getAnnouncementDetail(1),
        ).thenThrow(Exception('Not found'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAnnouncementDetail(1)),
      expect: () => [
        AnnouncementDetailLoading(),
        const AnnouncementDetailError('Exception: Not found'),
      ],
    );
  });
}
