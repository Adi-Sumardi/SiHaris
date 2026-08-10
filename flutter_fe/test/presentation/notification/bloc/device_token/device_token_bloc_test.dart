import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/core/config/feature_config.dart';
import 'package:gaji_pro/data/datasources/device_token_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/register_token_request_model.dart';
import 'package:gaji_pro/data/models/responses/device_token_model.dart';
import 'package:gaji_pro/presentation/notification/bloc/device_token/device_token_bloc.dart';
import 'package:gaji_pro/presentation/notification/bloc/device_token/device_token_event.dart';
import 'package:gaji_pro/presentation/notification/bloc/device_token/device_token_state.dart';

class MockDeviceTokenRemoteDatasource extends Mock
    implements DeviceTokenRemoteDatasource {}

void main() {
  late DeviceTokenBloc bloc;
  late MockDeviceTokenRemoteDatasource mockDatasource;

  setUpAll(() {
    registerFallbackValue(const RegisterTokenRequestModel(
      token: 'fallback_token',
      platform: 'fallback',
    ));
  });

  setUp(() {
    // Enable push notifications for testing
    FeatureConfig.pushNotificationOverride = true;
    mockDatasource = MockDeviceTokenRemoteDatasource();
    bloc = DeviceTokenBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
    FeatureConfig.resetOverrides();
  });

  const tRegisterRequest = RegisterTokenRequestModel(
    token: 'test_token',
    platform: 'android',
  );

  final tDeviceTokenModel = DeviceTokenModel(
    id: 1,
    platform: 'android',
    deviceName: 'Test Device',
    isActive: true,
  );

  group('DeviceTokenBloc', () {
    test('initial state is DeviceTokenInitial', () {
      expect(bloc.state, DeviceTokenInitial());
    });

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Loading, Success] when RegisterDeviceToken is successful',
      build: () {
        when(
          () => mockDatasource.registerToken(tRegisterRequest),
        ).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const RegisterDeviceToken(tRegisterRequest)),
      expect: () => [
        DeviceTokenLoading(),
        const DeviceTokenSuccess('Device token registered successfully'),
      ],
    );

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Loading, Failure] when RegisterDeviceToken fails',
      build: () {
        when(
          () => mockDatasource.registerToken(tRegisterRequest),
        ).thenThrow(Exception('Failed to register'));
        return bloc;
      },
      act: (bloc) => bloc.add(const RegisterDeviceToken(tRegisterRequest)),
      expect: () => [
        DeviceTokenLoading(),
        const DeviceTokenFailure('Exception: Failed to register'),
      ],
    );

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Loading, Success] when UnregisterDeviceToken is successful',
      build: () {
        when(
          () => mockDatasource.unregisterToken('test_token'),
        ).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const UnregisterDeviceToken('test_token')),
      expect: () => [
        DeviceTokenLoading(),
        const DeviceTokenSuccess('Device token unregistered successfully'),
      ],
    );

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Loading, Failure] when UnregisterDeviceToken fails',
      build: () {
        when(
          () => mockDatasource.unregisterToken('test_token'),
        ).thenThrow(Exception('Failed to unregister'));
        return bloc;
      },
      act: (bloc) => bloc.add(const UnregisterDeviceToken('test_token')),
      expect: () => [
        DeviceTokenLoading(),
        const DeviceTokenFailure('Exception: Failed to unregister'),
      ],
    );

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Loading, Success] when RefreshDeviceToken is successful',
      build: () {
        when(
          () => mockDatasource.refreshToken('old_token', 'new_token'),
        ).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(
        const RefreshDeviceToken(oldToken: 'old_token', newToken: 'new_token'),
      ),
      expect: () => [
        DeviceTokenLoading(),
        const DeviceTokenSuccess('Device token refreshed successfully'),
      ],
    );

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Loading, Failure] when RefreshDeviceToken fails',
      build: () {
        when(
          () => mockDatasource.refreshToken('old_token', 'new_token'),
        ).thenThrow(Exception('Failed to refresh'));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const RefreshDeviceToken(oldToken: 'old_token', newToken: 'new_token'),
      ),
      expect: () => [
        DeviceTokenLoading(),
        const DeviceTokenFailure('Exception: Failed to refresh'),
      ],
    );

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Loading, ListLoaded] when LoadDeviceTokens is successful',
      build: () {
        when(
          () => mockDatasource.getDeviceTokens(),
        ).thenAnswer((_) async => [tDeviceTokenModel]);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadDeviceTokens()),
      expect: () => [
        DeviceTokenLoading(),
        DeviceTokenListLoaded([tDeviceTokenModel]),
      ],
    );

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Loading, Failure] when LoadDeviceTokens fails',
      build: () {
        when(
          () => mockDatasource.getDeviceTokens(),
        ).thenThrow(Exception('Failed to load'));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadDeviceTokens()),
      expect: () => [
        DeviceTokenLoading(),
        const DeviceTokenFailure('Exception: Failed to load'),
      ],
    );
  });

  group('DeviceTokenBloc with push notifications disabled', () {
    setUp(() {
      FeatureConfig.pushNotificationOverride = false;
      mockDatasource = MockDeviceTokenRemoteDatasource();
      bloc = DeviceTokenBloc(mockDatasource);
    });

    tearDown(() {
      bloc.close();
      FeatureConfig.resetOverrides();
    });

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Success] immediately when RegisterDeviceToken called with disabled config',
      build: () => bloc,
      act: (bloc) => bloc.add(const RegisterDeviceToken(tRegisterRequest)),
      expect: () => [
        const DeviceTokenSuccess('Push notifications disabled'),
      ],
      verify: (_) {
        verifyNever(() => mockDatasource.registerToken(any()));
      },
    );

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [Success] immediately when UnregisterDeviceToken called with disabled config',
      build: () => bloc,
      act: (bloc) => bloc.add(const UnregisterDeviceToken('test_token')),
      expect: () => [
        const DeviceTokenSuccess('Push notifications disabled'),
      ],
      verify: (_) {
        verifyNever(() => mockDatasource.unregisterToken(any()));
      },
    );

    blocTest<DeviceTokenBloc, DeviceTokenState>(
      'emit [ListLoaded(empty)] immediately when LoadDeviceTokens called with disabled config',
      build: () => bloc,
      act: (bloc) => bloc.add(LoadDeviceTokens()),
      expect: () => [
        const DeviceTokenListLoaded([]),
      ],
      verify: (_) {
        verifyNever(() => mockDatasource.getDeviceTokens());
      },
    );
  });
}
