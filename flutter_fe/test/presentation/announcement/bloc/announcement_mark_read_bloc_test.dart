import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/announcement_remote_datasource.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_mark_read/announcement_mark_read_bloc.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_mark_read/announcement_mark_read_event.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_mark_read/announcement_mark_read_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAnnouncementRemoteDatasource extends Mock
    implements AnnouncementRemoteDatasource {}

void main() {
  late AnnouncementMarkReadBloc bloc;
  late MockAnnouncementRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockAnnouncementRemoteDatasource();
    bloc = AnnouncementMarkReadBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be AnnouncementMarkReadInitial', () {
    expect(bloc.state, equals(AnnouncementMarkReadInitial()));
  });

  group('MarkAnnouncementAsRead', () {
    blocTest<AnnouncementMarkReadBloc, AnnouncementMarkReadState>(
      'emits [Loading, Success] when mark as read is successful',
      build: () {
        when(
          () => mockDatasource.markAsRead(1),
        ).thenAnswer((_) async => Future.value());
        return bloc;
      },
      act: (bloc) => bloc.add(const MarkAnnouncementAsRead(1)),
      expect: () => [
        AnnouncementMarkReadLoading(),
        AnnouncementMarkReadSuccess(),
      ],
    );

    blocTest<AnnouncementMarkReadBloc, AnnouncementMarkReadState>(
      'emits [Loading, Error] when mark as read fails',
      build: () {
        when(
          () => mockDatasource.markAsRead(1),
        ).thenThrow(Exception('Failed to mark as read'));
        return bloc;
      },
      act: (bloc) => bloc.add(const MarkAnnouncementAsRead(1)),
      expect: () => [
        AnnouncementMarkReadLoading(),
        const AnnouncementMarkReadError('Exception: Failed to mark as read'),
      ],
    );
  });
}
