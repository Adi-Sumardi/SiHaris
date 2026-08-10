import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/services/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    group('ConnectivityStatus', () {
      test('should have online status', () {
        expect(ConnectivityStatus.online, isNotNull);
      });

      test('should have offline status', () {
        expect(ConnectivityStatus.offline, isNotNull);
      });
    });

    group('MockableConnectivityService', () {
      late MockableConnectivityService service;

      setUp(() {
        service = MockableConnectivityService();
      });

      tearDown(() {
        service.dispose();
      });

      test('initial status should be online', () async {
        expect(await service.checkConnectivity(), ConnectivityStatus.online);
      });

      test('isOnline should return true when online', () async {
        expect(await service.isOnline(), true);
      });

      test('setStatus should change connectivity status', () async {
        service.setStatus(ConnectivityStatus.offline);
        expect(await service.checkConnectivity(), ConnectivityStatus.offline);
      });

      test('isOnline should return false when offline', () async {
        service.setStatus(ConnectivityStatus.offline);
        expect(await service.isOnline(), false);
      });

      test('stream should emit status changes', () async {
        final statuses = <ConnectivityStatus>[];
        final subscription = service.onStatusChange.listen(statuses.add);

        service.setStatus(ConnectivityStatus.offline);
        service.setStatus(ConnectivityStatus.online);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(statuses, [
          ConnectivityStatus.offline,
          ConnectivityStatus.online,
        ]);

        await subscription.cancel();
      });

      test('status should persist across multiple checks', () async {
        expect(await service.isOnline(), true);

        service.setStatus(ConnectivityStatus.offline);
        expect(await service.isOnline(), false);
        expect(await service.isOnline(), false);

        service.setStatus(ConnectivityStatus.online);
        expect(await service.isOnline(), true);
      });
    });

    group('ConnectivityServiceImpl', () {
      test('should implement ConnectivityService interface', () {
        final service = ConnectivityServiceImpl();
        expect(service, isA<ConnectivityService>());
        service.dispose();
      });

      test('checkConnectivity should return a status', () async {
        final service = ConnectivityServiceImpl();
        final status = await service.checkConnectivity();
        expect(status, isA<ConnectivityStatus>());
        service.dispose();
      });

      test('isOnline should return a boolean', () async {
        final service = ConnectivityServiceImpl();
        final result = await service.isOnline();
        expect(result, isA<bool>());
        service.dispose();
      });

      test('onStatusChange should return a stream', () {
        final service = ConnectivityServiceImpl();
        expect(service.onStatusChange, isA<Stream<ConnectivityStatus>>());
        service.dispose();
      });
    });
  });
}
