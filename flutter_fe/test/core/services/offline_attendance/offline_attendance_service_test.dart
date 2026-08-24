// Regression test: a single "poisoned" queue entry (e.g. corrupt photo,
// unexpected server response — any non-network error) must not block every
// attendance record queued after it forever. After a bounded number of
// retries, the poisoned entry is dropped and the rest of the queue proceeds.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gaji_pro/core/services/offline_attendance/attendance_queue_db.dart';
import 'package:gaji_pro/core/services/offline_attendance/offline_attendance_service.dart';
import 'package:gaji_pro/core/services/offline_attendance/pending_attendance.dart';
import 'package:gaji_pro/data/models/requests/clock_in_request_model.dart';
import 'package:gaji_pro/data/models/requests/clock_out_request_model.dart';

/// Fake uploader: always throws a non-network error for the item whose
/// `notes` is 'poison', and succeeds for everything else.
class _PoisonedUploader implements AttendanceUploader {
  int poisonAttempts = 0;

  @override
  Future<bool> uploadClockIn(ClockInRequestModel request) async {
    if (request.notes == 'poison') {
      poisonAttempts++;
      throw const FormatException('corrupt payload');
    }
    return true;
  }

  @override
  Future<bool> uploadClockOut(ClockOutRequestModel request) async {
    if (request.notes == 'poison') {
      poisonAttempts++;
      throw const FormatException('corrupt payload');
    }
    return true;
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final db = AttendanceQueueDb.instance;
  final service = OfflineAttendanceService.instance;

  Future<void> clearQueue() async {
    for (final item in await db.getAll()) {
      if (item.id != null) await db.delete(item.id!);
    }
  }

  setUp(() async {
    await clearQueue();
  });

  tearDown(() async {
    await clearQueue();
  });

  test(
    'sync() drops a poisoned item after the retry cap instead of blocking the queue forever',
    () async {
      await db.insert(PendingAttendance(
        type: PendingAttendanceType.clockIn,
        latitude: -6.2,
        longitude: 106.8,
        officeLocationId: 1,
        gpsVerified: true,
        faceVerified: true,
        notes: 'poison',
        createdAt: DateTime.now(),
      ));
      await db.insert(PendingAttendance(
        type: PendingAttendanceType.clockIn,
        latitude: -6.2,
        longitude: 106.8,
        officeLocationId: 1,
        gpsVerified: true,
        faceVerified: true,
        notes: 'good',
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
      ));

      final uploader = _PoisonedUploader();

      // While under the retry cap, the poisoned item keeps blocking the
      // queue (sync stops as soon as it fails) — the good item behind it
      // never gets a chance to run.
      await service.sync(uploader);
      expect(await db.count(), 2);

      await service.sync(uploader);
      expect(await db.count(), 2);

      // This sync exceeds the retry cap: the poisoned item is dropped and
      // the sync loop continues on to the good item, which succeeds.
      final successCount = await service.sync(uploader);

      expect(await db.count(), 0);
      expect(successCount, 1);
      expect(uploader.poisonAttempts, 3);
    },
  );

  test(
    'sync() still stops (does not drop anything) on a plain network failure',
    () async {
      await db.insert(PendingAttendance(
        type: PendingAttendanceType.clockOut,
        latitude: -6.2,
        longitude: 106.8,
        officeLocationId: 1,
        gpsVerified: true,
        faceVerified: true,
        notes: 'good',
        createdAt: DateTime.now(),
      ));

      final uploader = _AlwaysOfflineUploader();

      final successCount = await service.sync(uploader);

      expect(successCount, 0);
      expect(await db.count(), 1, reason: 'offline retries must not be dropped');
    },
  );
}

class _AlwaysOfflineUploader implements AttendanceUploader {
  @override
  Future<bool> uploadClockIn(ClockInRequestModel request) {
    throw const SocketException('offline');
  }

  @override
  Future<bool> uploadClockOut(ClockOutRequestModel request) {
    throw const SocketException('offline');
  }
}
