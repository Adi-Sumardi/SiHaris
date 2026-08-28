import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gaji_pro/core/config/feature_config.dart';
import 'package:gaji_pro/core/services/notification_service.dart';
import 'package:gaji_pro/data/datasources/device_token_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/register_token_request_model.dart';
import 'package:gaji_pro/presentation/auth/bloc/login/login_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/logout/logout_bloc.dart';
import 'package:gaji_pro/presentation/notification/bloc/device_token/device_token_bloc.dart';
import 'package:gaji_pro/presentation/notification/widgets/notification_wrapper.dart';

import '../../../mocks/mock_auth_local_datasource.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockDeviceTokenRemoteDatasource extends Mock
    implements DeviceTokenRemoteDatasource {}

void main() {
  late MockNotificationService mockNotificationService;
  late MockAuthLocalDatasource mockAuthLocalDatasource;
  late MockDeviceTokenRemoteDatasource mockDeviceTokenDatasource;
  late DeviceTokenBloc deviceTokenBloc;

  setUpAll(() {
    registerFallbackValue(
      const RegisterTokenRequestModel(
        token: 'fallback_token',
        platform: 'fallback',
      ),
    );
    PackageInfo.setMockInitialValues(
      appName: 'SiHaris',
      packageName: 'id.yapinet.siharis',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    FeatureConfig.pushNotificationOverride = true;
    mockNotificationService = MockNotificationService();
    mockAuthLocalDatasource = MockAuthLocalDatasource();
    mockDeviceTokenDatasource = MockDeviceTokenRemoteDatasource();
    deviceTokenBloc = DeviceTokenBloc(mockDeviceTokenDatasource);

    when(() => mockNotificationService.initialize()).thenAnswer((_) async {});
    when(
      () => mockNotificationService.getToken(),
    ).thenAnswer((_) async => 'fcm-token-123');
    when(
      () => mockDeviceTokenDatasource.registerToken(any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    deviceTokenBloc.close();
    FeatureConfig.resetOverrides();
  });

  Future<void> pumpWrapper(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<LoginBloc>(create: (_) => LoginBloc()),
          BlocProvider<LogoutBloc>(create: (_) => LogoutBloc()),
          BlocProvider<DeviceTokenBloc>.value(value: deviceTokenBloc),
        ],
        child: MaterialApp(
          home: NotificationWrapper(
            notificationService: mockNotificationService,
            authLocalDatasource: mockAuthLocalDatasource,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('NotificationWrapper', () {
    testWidgets(
      'registers the device token on startup when already logged in',
      (tester) async {
        when(
          () => mockAuthLocalDatasource.isLoggedIn(),
        ).thenAnswer((_) async => true);

        await pumpWrapper(tester);

        verify(() => mockNotificationService.getToken()).called(1);
        verify(() => mockDeviceTokenDatasource.registerToken(any())).called(1);
      },
    );

    testWidgets(
      'does not register the device token on startup when not logged in',
      (tester) async {
        when(
          () => mockAuthLocalDatasource.isLoggedIn(),
        ).thenAnswer((_) async => false);

        await pumpWrapper(tester);

        verifyNever(() => mockNotificationService.getToken());
        verifyNever(() => mockDeviceTokenDatasource.registerToken(any()));
      },
    );
  });
}
