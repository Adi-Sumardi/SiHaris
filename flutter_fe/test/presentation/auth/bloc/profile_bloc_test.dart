import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/auth_response_model.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_state.dart';
import '../../../mocks/mock_auth_datasource.dart';

void main() {
  late ProfileBloc profileBloc;
  late MockAuthDatasource mockAuthDatasource;

  setUp(() {
    mockAuthDatasource = MockAuthDatasource();
    profileBloc = ProfileBloc(authDatasource: mockAuthDatasource);
  });

  tearDown(() {
    profileBloc.close();
  });

  test('initial state should be ProfileInitial', () {
    expect(profileBloc.state, isA<ProfileInitial>());
  });

  group('GetProfile', () {
    final testUser = UserModel(
      id: 1,
      name: 'John Doe',
      email: 'john@example.com',
    );
    final testCompany = CompanyModel(id: 1, name: 'PT Demo GajiPro');

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] when getProfile is successful',
      build: () {
        when(() => mockAuthDatasource.getProfile())
            .thenAnswer((_) async => Right((testUser, testCompany)));
        return profileBloc;
      },
      act: (bloc) => bloc.add(GetProfile()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having(
          (s) => s.user.name,
          'user name',
          'John Doe',
        ),
      ],
      verify: (_) {
        verify(() => mockAuthDatasource.getProfile()).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] when getProfile fails with unauthorized',
      build: () {
        when(() => mockAuthDatasource.getProfile())
            .thenAnswer((_) async => const Left('Unauthenticated'));
        return profileBloc;
      },
      act: (bloc) => bloc.add(GetProfile()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having(
          (e) => e.message,
          'message',
          'Unauthenticated',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] when network error occurs',
      build: () {
        when(() => mockAuthDatasource.getProfile())
            .thenAnswer((_) async => const Left('Terjadi kesalahan: No internet'));
        return profileBloc;
      },
      act: (bloc) => bloc.add(GetProfile()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having(
          (e) => e.message,
          'message',
          contains('Terjadi kesalahan'),
        ),
      ],
    );
  });

  group('RefreshProfile', () {
    final testUser = UserModel(
      id: 1,
      name: 'Jane Doe',
      email: 'jane@example.com',
    );
    final testCompany = CompanyModel(id: 1, name: 'PT Demo GajiPro');

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] when refresh is successful',
      build: () {
        when(() => mockAuthDatasource.getProfile())
            .thenAnswer((_) async => Right((testUser, testCompany)));
        return profileBloc;
      },
      seed: () => ProfileLoaded(testUser),
      act: (bloc) => bloc.add(RefreshProfile()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having(
          (s) => s.user.name,
          'user name',
          'Jane Doe',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] when refresh fails',
      build: () {
        when(() => mockAuthDatasource.getProfile())
            .thenAnswer((_) async => const Left('Session expired'));
        return profileBloc;
      },
      seed: () => ProfileLoaded(testUser),
      act: (bloc) => bloc.add(RefreshProfile()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having(
          (e) => e.message,
          'message',
          'Session expired',
        ),
      ],
    );
  });
}
