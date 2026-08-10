// RED test: UpdateProfileBloc
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/requests/update_profile_request_model.dart';
import 'package:gaji_pro/data/models/responses/auth_response_model.dart';
import 'package:gaji_pro/presentation/profile/bloc/update_profile/update_profile_bloc.dart';
import 'package:gaji_pro/presentation/profile/bloc/update_profile/update_profile_event.dart';
import 'package:gaji_pro/presentation/profile/bloc/update_profile/update_profile_state.dart';
import '../../../mocks/mock_auth_datasource.dart';

class FakeUpdateProfileRequestModel extends Fake
    implements UpdateProfileRequestModel {}

void main() {
  late MockAuthDatasource mockDatasource;

  setUpAll(() {
    registerFallbackValue(FakeUpdateProfileRequestModel());
  });

  setUp(() {
    mockDatasource = MockAuthDatasource();
  });

  final tUser = UserModel(
    id: 1,
    name: 'Ahmad Bahri',
    email: 'ahmad@example.com',
  );

  final tRequest = UpdateProfileRequestModel(
    firstName: 'Ahmad',
    lastName: 'Bahri',
    phone: '08123456789',
  );

  group('UpdateProfileBloc', () {
    blocTest<UpdateProfileBloc, UpdateProfileState>(
      'emits [Loading, Success] when updateProfile succeeds',
      build: () {
        when(() => mockDatasource.updateProfile(any()))
            .thenAnswer((_) async => Right(tUser));
        return UpdateProfileBloc(datasource: mockDatasource);
      },
      act: (bloc) => bloc.add(SubmitUpdateProfile(tRequest)),
      expect: () => [
        UpdateProfileLoading(),
        UpdateProfileSuccess(tUser),
      ],
    );

    blocTest<UpdateProfileBloc, UpdateProfileState>(
      'emits [Loading, Failure] when updateProfile fails',
      build: () {
        when(() => mockDatasource.updateProfile(any()))
            .thenAnswer((_) async => const Left('Gagal memperbarui profil'));
        return UpdateProfileBloc(datasource: mockDatasource);
      },
      act: (bloc) => bloc.add(SubmitUpdateProfile(tRequest)),
      expect: () => [
        UpdateProfileLoading(),
        const UpdateProfileFailure('Gagal memperbarui profil'),
      ],
    );

    blocTest<UpdateProfileBloc, UpdateProfileState>(
      'initial state is UpdateProfileInitial',
      build: () => UpdateProfileBloc(datasource: mockDatasource),
      verify: (bloc) => expect(bloc.state, UpdateProfileInitial()),
    );
  });
}
