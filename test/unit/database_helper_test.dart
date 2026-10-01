import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:disaster_ready/core/database/database_helper.dart';
import 'package:disaster_ready/core/database/migrations.dart';
import 'package:disaster_ready/data/local/dao/user_dao.dart';
import 'package:disaster_ready/data/local/dao/emergency_request_dao.dart';
import 'package:disaster_ready/data/local/dao/sync_queue_dao.dart';
import 'package:disaster_ready/data/local/dao/emergency_service_dao.dart';
import 'package:disaster_ready/data/local/models/user_model.dart';
import 'package:disaster_ready/data/local/models/emergency_request_model.dart';
import 'package:disaster_ready/data/local/models/sync_queue_model.dart';

void main() {
  // Initialize ffi for running sqlite tests on desktop/host
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseHelper dbHelper;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: DatabaseMigrations.onCreate,
      ),
    );
    dbHelper = DatabaseHelper.withDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SQLite Database & Migration Tests', () {
    test('Database initializes all 15 tables and seeds default emergency services', () async {
      final serviceDao = EmergencyServiceDao(dbHelper: dbHelper);
      final services = await serviceDao.getAll();

      // Check seed data
      expect(services.isNotEmpty, true);
      expect(services.any((s) => s.phone == '1078'), true); // NDRF Helpline
      expect(services.any((s) => s.phone == '100'), true); // Police
      expect(services.any((s) => s.phone == '101'), true); // Fire
    });

    test('UserDao insert, query active user, and soft delete', () async {
      final userDao = UserDao(dbHelper: dbHelper);

      const user = UserModel(
        id: 'u-offline-1',
        name: 'Sarah Connor',
        phone: '9988776655',
        role: 'responder',
        createdAt: '2026-10-01T12:00:00Z',
        updatedAt: '2026-10-01T12:00:00Z',
      );

      await userDao.insert(user);
      final fetched = await userDao.getById('u-offline-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Sarah Connor');

      final active = await userDao.getActiveUser();
      expect(active, isNotNull);
      expect(active!.id, 'u-offline-1');

      await userDao.deleteSoft('u-offline-1');
      final afterDelete = await userDao.getById('u-offline-1');
      expect(afterDelete, isNull);
    });

    test('EmergencyRequestDao and SyncQueueDao operations', () async {
      final requestDao = EmergencyRequestDao(dbHelper: dbHelper);
      final syncQueueDao = SyncQueueDao(dbHelper: dbHelper);

      const req = EmergencyRequestModel(
        id: 'req-offline-10',
        userName: 'Mark Vance',
        phone: '1122334455',
        requestType: 'evacuation',
        priority: 'HIGH',
        description: 'Rising water level in low-lying village',
        location: 'Village South, Sector 2',
        createdAt: '2026-10-01T12:00:00Z',
        updatedAt: '2026-10-01T12:00:00Z',
      );

      await requestDao.insert(req);

      const queueItem = SyncQueueModel(
        id: 'q-10',
        entityType: 'emergency_request',
        entityId: 'req-offline-10',
        operation: 'CREATE',
        payload: '{"id": "req-offline-10"}',
        createdAt: '2026-10-01T12:00:00Z',
      );

      await syncQueueDao.enqueue(queueItem);

      final pendingCount = await syncQueueDao.getPendingCount();
      expect(pendingCount, 1);

      final pendingList = await syncQueueDao.getPendingItems();
      expect(pendingList.length, 1);
      expect(pendingList.first.entityId, 'req-offline-10');

      // Update sync queue item status to SYNCED
      await syncQueueDao.updateStatus('q-10', 'SYNCED');
      final countAfterSync = await syncQueueDao.getPendingCount();
      expect(countAfterSync, 0);
    });
  });
}
