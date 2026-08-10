import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'pending_attendance.dart';

/// Penyimpanan lokal (SQLite) untuk antrean absensi offline.
class AttendanceQueueDb {
  AttendanceQueueDb._();
  static final AttendanceQueueDb instance = AttendanceQueueDb._();

  static const _dbName = 'attendance_queue.db';
  static const _table = 'pending_attendance';
  Database? _db;

  Future<Database> get _database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _dbName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            office_location_id INTEGER NOT NULL,
            gps_verified INTEGER NOT NULL DEFAULT 0,
            face_verified INTEGER NOT NULL DEFAULT 0,
            face_confidence REAL,
            notes TEXT,
            photo_path TEXT,
            created_at TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
      },
    );
  }

  Future<int> insert(PendingAttendance item) async {
    final db = await _database;
    final map = item.toMap()..remove('id');
    return db.insert(_table, map);
  }

  /// Ambil semua entri tertunda, diurutkan dari yang paling lama (FIFO).
  Future<List<PendingAttendance>> getAll() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'created_at ASC');
    return rows.map(PendingAttendance.fromMap).toList();
  }

  Future<int> count() async {
    final db = await _database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Tandai sebuah entri gagal disinkronkan (naikkan retry & simpan error).
  Future<void> markFailed(int id, String error) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE $_table SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }
}
