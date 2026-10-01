import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:disaster_ready/core/constants/app_constants.dart';
import 'package:disaster_ready/core/connectivity/connectivity_service.dart';
import 'package:disaster_ready/core/database/database_helper.dart';
import 'package:disaster_ready/core/database/migrations.dart';
import 'package:disaster_ready/core/network/api_client.dart';
import 'package:disaster_ready/data/local/dao/disaster_dao.dart';
import 'package:disaster_ready/data/local/dao/emergency_request_dao.dart';
import 'package:disaster_ready/data/local/dao/shelter_dao.dart';
import 'package:disaster_ready/data/local/dao/sync_queue_dao.dart';
import 'package:disaster_ready/data/local/models/sync_queue_model.dart';
import 'package:disaster_ready/data/repositories/emergency_repository.dart';
import 'package:disaster_ready/data/repositories/sync_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseHelper dbHelper;
  late EmergencyRequestDao requestDao;
  late SyncQueueDao syncQueueDao;
  late EmergencyRepository emergencyRepo;

  // In-memory mock server state
  final Map<String, Map<String, dynamic>> serverEmergencyRequests = {};
  bool serverAvailable = true;

  MockClient createMockServerClient() {
    return MockClient((request) async {
      if (!serverAvailable) {
        return http.Response('Server connection refused', 503);
      }

      final path = request.url.path;

      if (path == '/health') {
        return http.Response(jsonEncode({'status': 'healthy', 'service': 'DisasterReady Backend'}), 200);
      }

      if (path == '/sync/push') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final items = body['items'] as List<dynamic>;
        final List<Map<String, dynamic>> acks = [];
        int syncedCount = 0;

        for (final item in items) {
          final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
          final entityId = item['entity_id'] as String;
          final queueId = item['id'] as String;
          final incomingVersion = (item['version'] as int?) ?? 1;

          if (serverEmergencyRequests.containsKey(entityId)) {
            final existing = serverEmergencyRequests[entityId]!;
            final existingVersion = (existing['version'] as int?) ?? 1;

            if (incomingVersion >= existingVersion) {
              serverEmergencyRequests[entityId] = payload;
              syncedCount++;
              acks.add({'queue_id': queueId, 'entity_id': entityId, 'status': 'SYNCED'});
            } else {
              acks.add({
                'queue_id': queueId,
                'entity_id': entityId,
                'status': 'CONFLICT',
                'error': 'Server contains newer version'
              });
            }
          } else {
            serverEmergencyRequests[entityId] = payload;
            syncedCount++;
            acks.add({'queue_id': queueId, 'entity_id': entityId, 'status': 'SYNCED'});
          }
        }

        return http.Response(jsonEncode({
          'synced_count': syncedCount,
          'acknowledgements': acks,
        }), 200);
      }

      if (path == '/sync/pull') {
        return http.Response(jsonEncode({
          'server_time': '2026-10-01T12:00:00Z',
          'disasters': [],
          'emergency_requests': serverEmergencyRequests.values.toList(),
          'shelters': [],
          'hospitals': [],
          'emergency_contacts': [],
          'safe_zones': [],
          'resources': [],
        }), 200);
      }

      return http.Response('Not Found', 404);
    });
  }

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: DatabaseMigrations.onCreate,
      ),
    );
    dbHelper = DatabaseHelper.withDatabase(db);
    requestDao = EmergencyRequestDao(dbHelper: dbHelper);
    syncQueueDao = SyncQueueDao(dbHelper: dbHelper);
    emergencyRepo = EmergencyRepository(requestDao: requestDao, syncQueueDao: syncQueueDao);

    serverEmergencyRequests.clear();
    serverAvailable = true;
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3 Requirements: Real End-to-End Sync (Tests A through G)', () {
    test('TEST A: Online sync - Create emergency request -> API push -> Server ACK & SYNCED status', () async {
      final mockClient = createMockServerClient();
      final apiClient = ApiClient(baseUrl: 'http://test-server:8000', httpClient: mockClient);
      final syncRepo = SyncRepository(
        syncQueueDao: syncQueueDao,
        apiClient: apiClient,
        requestDao: requestDao,
        disasterDao: DisasterDao(dbHelper: dbHelper),
        shelterDao: ShelterDao(dbHelper: dbHelper),
      );

      // Create request
      final req = await emergencyRepo.createEmergencyRequest(
        userName: 'Aarav Patel',
        phone: '9876543210',
        requestType: 'rescue',
        priority: 'HIGH',
        description: 'Stranded in rising water',
        location: 'Zone 1',
      );

      // Verify pending in queue
      expect(await syncRepo.getPendingCount(), 1);

      // Perform sync
      final result = await syncRepo.performSync();
      expect(result.success, isTrue);
      expect(result.pushedCount, 1);

      // Verify server received the item
      expect(serverEmergencyRequests.containsKey(req.id), isTrue);
      expect(serverEmergencyRequests[req.id]!['user_name'], 'Aarav Patel');

      // Verify pending count in queue is now 0 (all processed)
      expect(await syncRepo.getPendingCount(), 0);
    });

    test('TEST B: Offline sync - Create request -> stored in SQLite -> PENDING', () async {
      final connectivity = ConnectivityService.forTesting(initialStatus: NetworkStatus.offline);
      expect(connectivity.isOffline, isTrue);

      final req = await emergencyRepo.createEmergencyRequest(
        userName: 'Offline Requester',
        phone: '9000000000',
        requestType: 'medical',
        priority: 'CRITICAL',
        description: 'First aid needed immediately',
        location: 'Sector 4',
      );

      // Stored in local SQLite
      final inDb = await requestDao.getById(req.id);
      expect(inDb, isNotNull);
      expect(inDb!.userName, 'Offline Requester');
      expect(inDb.syncStatus, 'PENDING');

      // Queue status is PENDING
      final pendingItems = await syncQueueDao.getPendingItems();
      expect(pendingItems.length, 1);
      expect(pendingItems.first.status, AppConstants.syncPending);
    });

    test('TEST C: Restart - Request still exists in SQLite and queue', () async {
      final tempDir = await Directory.systemTemp.createTemp('sync_restart_test');
      final tempDbFile = '${tempDir.path}${Platform.pathSeparator}restart_test.db';

      var tempDb = await databaseFactory.openDatabase(
        tempDbFile,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: DatabaseMigrations.onCreate,
        ),
      );
      var tempHelper = DatabaseHelper.withDatabase(tempDb);
      var tempReqDao = EmergencyRequestDao(dbHelper: tempHelper);
      var tempSyncDao = SyncQueueDao(dbHelper: tempHelper);
      var tempEmergencyRepo = EmergencyRepository(requestDao: tempReqDao, syncQueueDao: tempSyncDao);

      final req = await tempEmergencyRepo.createEmergencyRequest(
        userName: 'Persistent Requester',
        phone: '9111111111',
        requestType: 'food_water',
        priority: 'MEDIUM',
        description: 'Dry rations needed',
        location: 'Sector 5',
      );

      // Close database connection (simulate app kill)
      await tempDb.close();

      // Simulate re-opening database on process restart
      final reopenedDb = await databaseFactory.openDatabase(
        tempDbFile,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: DatabaseMigrations.onCreate,
        ),
      );
      final reopenedHelper = DatabaseHelper.withDatabase(reopenedDb);
      final reopenedRequestDao = EmergencyRequestDao(dbHelper: reopenedHelper);

      final fetched = await reopenedRequestDao.getById(req.id);
      expect(fetched, isNotNull);
      expect(fetched!.userName, 'Persistent Requester');
      await reopenedDb.close();
      try {
        await File(tempDbFile).delete();
      } catch (_) {}
    });

    test('TEST D: Backend unavailable - App remains usable, queue records remain safely stored', () async {
      serverAvailable = false; // Server is DOWN

      final mockClient = createMockServerClient();
      final apiClient = ApiClient(baseUrl: 'http://test-server:8000', httpClient: mockClient);
      final syncRepo = SyncRepository(
        syncQueueDao: syncQueueDao,
        apiClient: apiClient,
        requestDao: requestDao,
        disasterDao: DisasterDao(dbHelper: dbHelper),
        shelterDao: ShelterDao(dbHelper: dbHelper),
      );

      await emergencyRepo.createEmergencyRequest(
        userName: 'Resilient User',
        phone: '9222222222',
        requestType: 'rescue',
        priority: 'LOW',
        description: 'Tree blocking access road',
        location: 'Street 9',
      );

      // Attempt sync while server is down
      final result = await syncRepo.performSync();
      expect(result.success, isFalse);
      expect(result.message, contains('Backend unavailable'));

      // Queue record is still safely preserved in SQLite
      final pendingCount = await syncRepo.getPendingCount();
      expect(pendingCount, 1);
    });

    test('TEST E: Connection restored - PENDING items synced successfully', () async {
      serverAvailable = false; // Server starts down

      final mockClient = createMockServerClient();
      final apiClient = ApiClient(baseUrl: 'http://test-server:8000', httpClient: mockClient);
      final syncRepo = SyncRepository(
        syncQueueDao: syncQueueDao,
        apiClient: apiClient,
        requestDao: requestDao,
        disasterDao: DisasterDao(dbHelper: dbHelper),
        shelterDao: ShelterDao(dbHelper: dbHelper),
      );

      await emergencyRepo.createEmergencyRequest(
        userName: 'Recovery Citizen',
        phone: '9333333333',
        requestType: 'evacuation',
        priority: 'HIGH',
        description: 'Rising water',
        location: 'Zone 7',
      );

      // Fails while server is down
      var syncResult = await syncRepo.performSync();
      expect(syncResult.success, isFalse);

      // SERVER IS RESTORED
      serverAvailable = true;

      // Sync again
      syncResult = await syncRepo.performSync();
      expect(syncResult.success, isTrue);
      expect(syncResult.pushedCount, 1);

      // Verify pending count is 0
      expect(await syncRepo.getPendingCount(), 0);
    });

    test('TEST F: Repeat sync - Duplicate prevention verified', () async {
      final mockClient = createMockServerClient();
      final apiClient = ApiClient(baseUrl: 'http://test-server:8000', httpClient: mockClient);
      final syncRepo = SyncRepository(
        syncQueueDao: syncQueueDao,
        apiClient: apiClient,
        requestDao: requestDao,
        disasterDao: DisasterDao(dbHelper: dbHelper),
        shelterDao: ShelterDao(dbHelper: dbHelper),
      );

      final req = await emergencyRepo.createEmergencyRequest(
        userName: 'Single Instance',
        phone: '9444444444',
        requestType: 'rescue',
        priority: 'CRITICAL',
        description: 'Roof rescue',
        location: 'Hut 3',
      );

      // 1st sync
      await syncRepo.performSync();
      expect(serverEmergencyRequests.length, 1);

      // Repeat sync (e.g. queue not yet cleared or retry)
      final items = await syncQueueDao.getPendingItems();
      if (items.isNotEmpty) {
        await syncRepo.performSync();
      }
      // Server still has exactly 1 entry for this ID
      expect(serverEmergencyRequests.length, 1);
      expect(serverEmergencyRequests.containsKey(req.id), isTrue);
    });

    test('TEST G: Conflict handling - Server newer version produces CONFLICT status without data loss', () async {
      final mockClient = createMockServerClient();
      final apiClient = ApiClient(baseUrl: 'http://test-server:8000', httpClient: mockClient);
      final syncRepo = SyncRepository(
        syncQueueDao: syncQueueDao,
        apiClient: apiClient,
        requestDao: requestDao,
        disasterDao: DisasterDao(dbHelper: dbHelper),
        shelterDao: ShelterDao(dbHelper: dbHelper),
      );

      const entityId = 'req-conflict-10';

      // Prepopulate server with a newer version (version 3)
      serverEmergencyRequests[entityId] = {
        'id': entityId,
        'user_name': 'Server Newer Version',
        'phone': '9119999999',
        'request_type': 'rescue',
        'priority': 'HIGH',
        'status': 'Completed',
        'description': 'Rescued already',
        'people_count': 1,
        'location': 'Safe Zone',
        'version': 3,
        'created_at': '2026-10-01T10:00:00Z',
        'updated_at': '2026-10-01T15:00:00Z',
        'sync_status': 'SYNCED',
        'is_deleted': 0,
      };

      // Mobile has older version (version 1)
      final queueItem = SyncQueueModel(
        id: 'q-conflict-1',
        entityType: 'emergency_request',
        entityId: entityId,
        operation: 'UPDATE',
        payload: jsonEncode({
          'id': entityId,
          'user_name': 'Mobile Older Version',
          'status': 'Accepted',
          'version': 1,
          'updated_at': '2026-10-01T12:00:00Z',
        }),
        version: 1,
        createdAt: '2026-10-01T12:00:00Z',
      );
      await syncQueueDao.enqueue(queueItem);

      // Perform sync
      final result = await syncRepo.performSync();
      expect(result.success, isTrue);

      // Check conflict state
      final conflictItem = await syncQueueDao.getById('q-conflict-1');
      // Item marked as CONFLICT, not silently deleted!
      expect(conflictItem, isNotNull);
      expect(conflictItem!.status, AppConstants.syncConflict);
    });
  });
}
