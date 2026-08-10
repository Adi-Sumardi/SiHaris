import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_state.dart';
import '../../../mocks/mock_auth_datasource.dart';

void main() {
  late LogoutBloc logoutBloc;
  late MockAuthDatasource mockAuthDatasource;

  setUp(() {
    mockAuthDatasource = MockAuthDatasource();
    logoutBloc = LogoutBloc(authDatasource: mockAuthDatasource);
  });

  tearDown(() {
    logoutBloc.close();
  });

  test('initial state should be LogoutInitial', () {
    expect(logoutBloc.state, isA<LogoutInitial>());
  });

  group('LogoutSubmitted', () {
    blocTest<LogoutBloc, LogoutState>(
      'emits [LogoutLoading, LogoutSuccess] when logout is successful',
      build: () {
        when(() => mockAuthDatasource.logout())
            .thenAnswer((_) async => const Right(true));
        return logoutBloc;
      },
      act: (bloc) => bloc.add(LogoutSubmitted()),
      expect: () => [
        isA<LogoutLoading>(),
        isA<LogoutSuccess>(),
      ],
      verify: (_) {
        verify(() => mockAuthDatasource.logout()).called(1);
      },
    );

    blocTest<LogoutBloc, LogoutState>(
      'emits [LogoutLoading, LogoutError] when logout fails with API error',
      build: () {
        when(() => mockAuthDatasource.logout())
            .thenAnswer((_) async => const Left('Token tidak valid'));
        return logoutBloc;
      },
      act: (bloc) => bloc.add(LogoutSubmitted()),
      expect: () => [
        isA<LogoutLoading>(),
        isA<LogoutError>().having(
          (e) => e.message,
          'message',
          'Token tidak valid',
        ),
      ],
      verify: (_) {
        verify(() => mockAuthDatasource.logout()).called(1);
      },
    );

    blocTest<LogoutBloc, LogoutState>(
      'emits [LogoutLoading, LogoutError] when logout fails with network error',
      build: () {
        when(() => mockAuthDatasource.logout())
            .thenAnswer((_) async => const Left('Terjadi kesalahan: No internet'));
        return logoutBloc;
      },
      act: (bloc) => bloc.add(LogoutSubmitted()),
      expect: () => [
        isA<LogoutLoading>(),
        isA<LogoutError>().having(
          (e) => e.message,
          'message',
          contains('Terjadi kesalahan'),
        ),
      ],
    );

    blocTest<LogoutBloc, LogoutState>(
      'emits [LogoutLoading, LogoutError] when session expired',
      build: () {
        when(() => mockAuthDatasource.logout())
            .thenAnswer((_) async => const Left('Sesi telah berakhir'));
        return logoutBloc;
      },
      act: (bloc) => bloc.add(LogoutSubmitted()),
      expect: () => [
        isA<LogoutLoading>(),
        isA<LogoutError>().having(
          (e) => e.message,
          'message',
          'Sesi telah berakhir',
        ),
      ],
    );
  });
}
