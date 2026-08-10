import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/auth_response_model.dart';
import 'package:gaji_pro/presentation/auth/bloc/login/login_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/login/login_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/login/login_state.dart';
import '../../../mocks/mock_auth_datasource.dart';
import '../../../mocks/mock_auth_local_datasource.dart';

void main() {
  late LoginBloc loginBloc;
  late MockAuthDatasource mockAuthDatasource;
  late MockAuthLocalDatasource mockLocalDatasource;

  setUpAll(() {
    registerFallbackValue(AuthResponseModel(success: false));
  });

  setUp(() {
    mockAuthDatasource = MockAuthDatasource();
    mockLocalDatasource = MockAuthLocalDatasource();
    loginBloc = LoginBloc(
      authDatasource: mockAuthDatasource,
      localDatasource: mockLocalDatasource,
    );
  });

  tearDown(() {
    loginBloc.close();
  });

  test('initial state should be LoginInitial', () {
    expect(loginBloc.state, isA<LoginInitial>());
  });

  group('LoginSubmitted', () {
    const email = 'test@example.com';
    const password = 'password123';

    final successResponse = AuthResponseModel(
      success: true,
      message: 'Login berhasil',
      token: 'test_token_123',
      user: UserModel(
        id: 1,
        name: 'Test User',
        email: email,
      ),
    );

    final failedResponse = AuthResponseModel(
      success: false,
      message: 'Email atau password salah',
      token: null,
      user: null,
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginSuccess] when login is successful',
      build: () {
        when(() => mockAuthDatasource.login(email, password))
            .thenAnswer((_) async => Right(successResponse));
        when(() => mockLocalDatasource.saveAuthData(successResponse))
            .thenAnswer((_) async {});
        return loginBloc;
      },
      act: (bloc) => bloc.add(LoginSubmitted(identifier: email, password: password)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>(),
      ],
      verify: (_) {
        verify(() => mockAuthDatasource.login(email, password)).called(1);
        verify(() => mockLocalDatasource.saveAuthData(successResponse)).called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginError] when login returns error from API',
      build: () {
        when(() => mockAuthDatasource.login(email, password))
            .thenAnswer((_) async => const Left('Email atau password salah'));
        return loginBloc;
      },
      act: (bloc) => bloc.add(LoginSubmitted(identifier: email, password: password)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginError>().having(
          (e) => e.message,
          'message',
          'Email atau password salah',
        ),
      ],
      verify: (_) {
        verify(() => mockAuthDatasource.login(email, password)).called(1);
        verifyNever(() => mockLocalDatasource.saveAuthData(any()));
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginError] when login response success is false',
      build: () {
        when(() => mockAuthDatasource.login(email, password))
            .thenAnswer((_) async => Right(failedResponse));
        return loginBloc;
      },
      act: (bloc) => bloc.add(LoginSubmitted(identifier: email, password: password)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginError>().having(
          (e) => e.message,
          'message',
          'Email atau password salah',
        ),
      ],
      verify: (_) {
        verify(() => mockAuthDatasource.login(email, password)).called(1);
        verifyNever(() => mockLocalDatasource.saveAuthData(any()));
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginError] when login response has no token',
      build: () {
        final noTokenResponse = AuthResponseModel(
          success: true,
          message: 'Login berhasil',
          token: null,
          user: UserModel(id: 1, name: 'Test', email: email),
        );
        when(() => mockAuthDatasource.login(email, password))
            .thenAnswer((_) async => Right(noTokenResponse));
        return loginBloc;
      },
      act: (bloc) => bloc.add(LoginSubmitted(identifier: email, password: password)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginError>().having(
          (e) => e.message,
          'message',
          'Login berhasil',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginError] when network error occurs',
      build: () {
        when(() => mockAuthDatasource.login(email, password))
            .thenAnswer((_) async => const Left('Terjadi kesalahan: No internet'));
        return loginBloc;
      },
      act: (bloc) => bloc.add(LoginSubmitted(identifier: email, password: password)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginError>().having(
          (e) => e.message,
          'message',
          contains('Terjadi kesalahan'),
        ),
      ],
    );
  });

  group('LoginReset', () {
    blocTest<LoginBloc, LoginState>(
      'emits [LoginInitial] when LoginReset is added',
      build: () => loginBloc,
      seed: () => LoginError('Some error'),
      act: (bloc) => bloc.add(LoginReset()),
      expect: () => [isA<LoginInitial>()],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginInitial] after successful login and reset',
      build: () {
        final successResponse = AuthResponseModel(
          success: true,
          token: 'token',
          user: UserModel(id: 1, name: 'Test', email: 'test@test.com'),
        );
        when(() => mockAuthDatasource.login(any(), any()))
            .thenAnswer((_) async => Right(successResponse));
        when(() => mockLocalDatasource.saveAuthData(any()))
            .thenAnswer((_) async {});
        return loginBloc;
      },
      act: (bloc) async {
        bloc.add(LoginSubmitted(identifier: 'test@test.com', password: 'pass'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(LoginReset());
      },
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>(),
        isA<LoginInitial>(),
      ],
    );
  });
}
