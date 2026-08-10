import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/presentation/auth/bloc/change_password/change_password_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/change_password/change_password_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/change_password/change_password_state.dart';
import '../../../mocks/mock_auth_datasource.dart';

void main() {
  late ChangePasswordBloc changePasswordBloc;
  late MockAuthDatasource mockAuthDatasource;

  setUp(() {
    mockAuthDatasource = MockAuthDatasource();
    changePasswordBloc = ChangePasswordBloc(authDatasource: mockAuthDatasource);
  });

  tearDown(() {
    changePasswordBloc.close();
  });

  test('initial state should be ChangePasswordInitial', () {
    expect(changePasswordBloc.state, isA<ChangePasswordInitial>());
  });

  group('ChangePasswordSubmitted', () {
    const currentPassword = 'oldPassword123';
    const newPassword = 'newPassword123';
    const confirmPassword = 'newPassword123';

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'emits [ChangePasswordLoading, ChangePasswordSuccess] when change password is successful',
      build: () {
        when(() => mockAuthDatasource.changePassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
              confirmPassword: confirmPassword,
            )).thenAnswer((_) async => const Right(true));
        return changePasswordBloc;
      },
      act: (bloc) => bloc.add(ChangePasswordSubmitted(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      )),
      expect: () => [
        isA<ChangePasswordLoading>(),
        isA<ChangePasswordSuccess>(),
      ],
      verify: (_) {
        verify(() => mockAuthDatasource.changePassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
              confirmPassword: confirmPassword,
            )).called(1);
      },
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'emits [ChangePasswordLoading, ChangePasswordError] when current password is wrong',
      build: () {
        when(() => mockAuthDatasource.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
              confirmPassword: any(named: 'confirmPassword'),
            )).thenAnswer((_) async => const Left('Password lama tidak sesuai'));
        return changePasswordBloc;
      },
      act: (bloc) => bloc.add(ChangePasswordSubmitted(
        currentPassword: 'wrongPassword',
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      )),
      expect: () => [
        isA<ChangePasswordLoading>(),
        isA<ChangePasswordError>().having(
          (e) => e.message,
          'message',
          'Password lama tidak sesuai',
        ),
      ],
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'emits [ChangePasswordLoading, ChangePasswordError] when password confirmation does not match',
      build: () {
        when(() => mockAuthDatasource.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
              confirmPassword: any(named: 'confirmPassword'),
            )).thenAnswer((_) async => const Left('Konfirmasi password tidak sesuai'));
        return changePasswordBloc;
      },
      act: (bloc) => bloc.add(ChangePasswordSubmitted(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: 'differentPassword',
      )),
      expect: () => [
        isA<ChangePasswordLoading>(),
        isA<ChangePasswordError>().having(
          (e) => e.message,
          'message',
          'Konfirmasi password tidak sesuai',
        ),
      ],
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'emits [ChangePasswordLoading, ChangePasswordError] when network error occurs',
      build: () {
        when(() => mockAuthDatasource.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
              confirmPassword: any(named: 'confirmPassword'),
            )).thenAnswer((_) async => const Left('Terjadi kesalahan: No internet'));
        return changePasswordBloc;
      },
      act: (bloc) => bloc.add(ChangePasswordSubmitted(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      )),
      expect: () => [
        isA<ChangePasswordLoading>(),
        isA<ChangePasswordError>().having(
          (e) => e.message,
          'message',
          contains('Terjadi kesalahan'),
        ),
      ],
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'emits [ChangePasswordLoading, ChangePasswordError] when session expired',
      build: () {
        when(() => mockAuthDatasource.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
              confirmPassword: any(named: 'confirmPassword'),
            )).thenAnswer((_) async => const Left('Unauthenticated'));
        return changePasswordBloc;
      },
      act: (bloc) => bloc.add(ChangePasswordSubmitted(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      )),
      expect: () => [
        isA<ChangePasswordLoading>(),
        isA<ChangePasswordError>().having(
          (e) => e.message,
          'message',
          'Unauthenticated',
        ),
      ],
    );
  });

  group('ChangePasswordReset', () {
    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'emits [ChangePasswordInitial] when reset is called',
      build: () => changePasswordBloc,
      seed: () => ChangePasswordError('Some error'),
      act: (bloc) => bloc.add(ChangePasswordReset()),
      expect: () => [isA<ChangePasswordInitial>()],
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'emits [ChangePasswordInitial] after success and reset',
      build: () => changePasswordBloc,
      seed: () => ChangePasswordSuccess(),
      act: (bloc) => bloc.add(ChangePasswordReset()),
      expect: () => [isA<ChangePasswordInitial>()],
    );
  });
}
