import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:disaster_ready/core/connectivity/connectivity_service.dart';
import 'package:disaster_ready/core/database/database_helper.dart';
import 'package:disaster_ready/core/database/migrations.dart';
import 'package:disaster_ready/data/local/dao/emergency_request_dao.dart';
import 'package:disaster_ready/data/local/dao/sync_queue_dao.dart';
import 'package:disaster_ready/data/repositories/emergency_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String tempDbPath;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('disaster_offline_test');
    tempDbPath = '${tempDir.path}${Platform.pathSeparator}test_offline.db';
  });

  tearDown(() async {
    final file = File(tempDbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  group('Phase 1 Requirement: Offline Core Lifecycle & Persistence across Restarts', () {
    test('Simulate complete offline creation, restart, and data availability', () async {
      // Step 1: Simulate Internet Disabled (Offline)
      final connectivity = ConnectivityService.forTesting(initialStatus: NetworkStatus.offline);
      expect(connectivity.isOffline, isTrue);
      expect(connectivity.isOnline, isFalse);

      // Step 2 & 3 & 4: Start app & initialize local database on disk
      var db = await databaseFactory.openDatabase(
        tempDbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: DatabaseMigrations.onCreate,
        ),
      );
      var dbHelper = DatabaseHelper.withDatabase(db);
      var reqDao = EmergencyRequestDao(dbHelper: dbHelper);
      var syncDao = SyncQueueDao(dbHelper: dbHelper);
      var emergencyRepo = EmergencyRepository(requestDao: reqDao, syncQueueDao: syncDao);

      // Step 5: Create local emergency test data in offline mode
      final createdRequest = await emergencyRepo.createEmergencyRequest(
        userName: 'Offline Citizen',
        phone: '9112233445',
        requestType: 'rescue',
        priority: 'CRITICAL',
        description: 'Flooded house, family on second floor',
        location: 'Zone 4, Riverside Road',
        peopleCount: 5,
      );

      expect(createdRequest.id, isNotEmpty);
      expect(createdRequest.syncStatus, 'PENDING');

      // Verify immediate local presence in SQLite
      final allBeforeRestart = await emergencyRepo.getAllRequests();
      expect(allBeforeRestart.length, 1);
      expect(allBeforeRestart.first.userName, 'Offline Citizen');
      expect(allBeforeRestart.first.peopleCount, 5);

      // Verify sync queue enqueued the action
      final pendingCountBeforeRestart = await syncDao.getPendingCount();
      expect(pendingCountBeforeRestart, 1);

      // Step 6: Simulate App Process Kill & Restart (Close DB connection)
      await db.close();

      // Step 7: Restart App (Re-open database file without internet)
      expect(connectivity.isOffline, isTrue); // still offline!
      var restartedDb = await databaseFactory.openDatabase(tempDbPath);
      var restartedDbHelper = DatabaseHelper.withDatabase(restartedDb);
      var restartedReqDao = EmergencyRequestDao(dbHelper: restartedDbHelper);
      var restartedSyncDao = SyncQueueDao(dbHelper: restartedDbHelper);
      var restartedRepo = EmergencyRepository(requestDao: restartedReqDao, syncQueueDao: restartedSyncDao);

      // Verify data remains fully available across app restart!
      final allAfterRestart = await restartedRepo.getAllRequests();
      expect(allAfterRestart.length, 1);
      expect(allAfterRestart.first.id, createdRequest.id);
      expect(allAfterRestart.first.userName, 'Offline Citizen');
      expect(allAfterRestart.first.location, 'Zone 4, Riverside Road');
      expect(allAfterRestart.first.priority, 'CRITICAL');

      final pendingCountAfterRestart = await restartedSyncDao.getPendingCount();
      expect(pendingCountAfterRestart, 1);

      await restartedDb.close();
    });
  });
}
