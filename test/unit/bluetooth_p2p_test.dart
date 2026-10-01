import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:disaster_ready/core/bluetooth/bluetooth_envelope.dart';
import 'package:disaster_ready/core/bluetooth/bluetooth_p2p_service.dart';
import 'package:disaster_ready/core/bluetooth/bluetooth_staging.dart';
import 'package:disaster_ready/core/bluetooth/bluetooth_transport.dart';
import 'package:disaster_ready/core/bluetooth/bluetooth_validator.dart';
import 'package:disaster_ready/core/database/database_helper.dart';
import 'package:disaster_ready/core/database/migrations.dart';
import 'package:disaster_ready/data/local/dao/bluetooth_peer_dao.dart';
import 'package:disaster_ready/data/local/dao/disaster_report_dao.dart';
import 'package:disaster_ready/data/local/dao/emergency_contact_dao.dart';
import 'package:disaster_ready/data/local/dao/emergency_request_dao.dart';
import 'package:disaster_ready/data/local/dao/hospital_dao.dart';
import 'package:disaster_ready/data/local/dao/resource_dao.dart';
import 'package:disaster_ready/data/local/dao/safe_zone_dao.dart';
import 'package:disaster_ready/data/local/dao/shelter_dao.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Phase 4 Requirements: Bluetooth P2P Protocol & Envelope', () {
    test('1. Envelope serialization, deserialization, and round-trip fidelity', () {
      const envelope = BluetoothEnvelope(
        messageId: 'msg-001',
        deviceId: 'device-alpha',
        timestamp: '2026-10-01T12:00:00Z',
        entityType: 'emergency_request',
        operation: 'INSERT',
        version: 1,
        payload: {
          'id': 'req-bt-1',
          'user_name': 'John Doe',
          'phone': '9112233445',
          'request_type': 'rescue',
          'priority': 'HIGH',
          'status': 'Requested',
          'description': 'Water rising',
          'people_count': 3,
          'location': 'Zone B',
          'created_at': '2026-10-01T12:00:00Z',
          'updated_at': '2026-10-01T12:00:00Z',
        },
      );

      final jsonStr = envelope.toJson();
      final decoded = BluetoothEnvelope.fromJson(jsonStr);

      expect(decoded.protocolVersion, '1.0');
      expect(decoded.messageId, 'msg-001');
      expect(decoded.deviceId, 'device-alpha');
      expect(decoded.entityType, 'emergency_request');
      expect(decoded.operation, 'INSERT');
      expect(decoded.payload['user_name'], 'John Doe');
      expect(decoded.payload['people_count'], 3);
    });

    test('2. Envelope rejects unsupported protocol versions', () {
      const invalidEnvelope = BluetoothEnvelope(
        protocolVersion: '2.5', // Unsupported
        messageId: 'msg-002',
        deviceId: 'device-beta',
        timestamp: '2026-10-01T12:00:00Z',
        entityType: 'emergency_request',
        operation: 'INSERT',
        version: 1,
        payload: {'id': 'req-1', 'user_name': 'Test', 'phone': '123'},
      );

      final result = BluetoothValidator.validateEnvelope(invalidEnvelope);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Unsupported protocol version'));
    });

    test('3. Security rules: Never trust remote admin / role escalation claims', () {
      const maliciousEnvelope = BluetoothEnvelope(
        messageId: 'msg-hacker-1',
        deviceId: 'untrusted-peer',
        timestamp: '2026-10-01T12:00:00Z',
        entityType: 'emergency_request',
        operation: 'INSERT',
        version: 1,
        payload: {
          'id': 'req-exploit-1',
          'user_name': 'Attacker',
          'phone': '9999999999',
          'request_type': 'medical',
          'priority': 'SUPER_URGENT_ADMIN', // Invalid priority
          'status': 'Completed', // Remote untrusted claim to close ticket
          'is_admin': true, // Malicious admin claim
          'role': 'SUPER_ADMIN', // Malicious role escalation
          'description': 'Fake alert',
          'location': 'Base',
          'created_at': '2026-10-01T12:00:00Z',
          'updated_at': '2026-10-01T12:00:00Z',
        },
      );

      final result = BluetoothValidator.validateEnvelope(maliciousEnvelope);
      expect(result.isValid, isTrue);

      final sanitized = result.sanitizedPayload!;
      // is_admin must be completely stripped
      expect(sanitized.containsKey('is_admin'), isFalse);
      // role must be demoted to CITIZEN
      expect(sanitized['role'], 'CITIZEN');
      // invalid priority clamped to MEDIUM
      expect(sanitized['priority'], 'MEDIUM');
      // status Completed overridden to Requested
      expect(sanitized['status'], 'Requested');
    });

    test('4. Security rules: Resource quantity validation bounds', () {
      const invalidResourceEnvelope = BluetoothEnvelope(
        messageId: 'msg-res-1',
        deviceId: 'peer-res',
        timestamp: '2026-10-01T12:00:00Z',
        entityType: 'resource',
        operation: 'UPDATE',
        version: 1,
        payload: {
          'id': 'res-1',
          'name': 'Blankets',
          'quantity': -500, // Negative quantity
        },
      );

      final result = BluetoothValidator.validateEnvelope(invalidResourceEnvelope);
      expect(result.isValid, isFalse);
      expect(result.error, contains('out of bounds'));
    });
  });

  group('Phase 4 Requirements: Staging Queue, Validation & Deduplication', () {
    late Database db;
    late DatabaseHelper dbHelper;
    late EmergencyRequestDao requestDao;

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
    });

    tearDown(() async {
      await db.close();
    });

    test('5. Staging queue prevents direct primary table inserts prior to validation', () async {
      final stagingQueue = BluetoothStagingQueue();
      const envelope = BluetoothEnvelope(
        messageId: 'msg-stage-1',
        deviceId: 'dev-1',
        timestamp: '2026-10-01T12:00:00Z',
        entityType: 'emergency_request',
        operation: 'INSERT',
        version: 1,
        payload: {
          'id': 'req-unvalidated',
          'user_name': 'Alice',
          'phone': '9111222333',
        },
      );

      // Stage the envelope
      final staged = stagingQueue.stage(envelope);
      expect(staged.status, StagingStatus.staged);

      // Verify PRIMARY database table has NOT been touched yet
      final inPrimaryDb = await requestDao.getById('req-unvalidated');
      expect(inPrimaryDb, isNull);
    });

    test('6. Duplicate detection rejects duplicate message ID with DUPLICATE status', () {
      final stagingQueue = BluetoothStagingQueue();
      const envelope = BluetoothEnvelope(
        messageId: 'duplicate-msg-id',
        deviceId: 'dev-1',
        timestamp: '2026-10-01T12:00:00Z',
        entityType: 'emergency_request',
        operation: 'INSERT',
        version: 1,
        payload: {'id': 'req-dup', 'user_name': 'Bob', 'phone': '123'},
      );

      final item = stagingQueue.stage(envelope);
      stagingQueue.validateItem(item);
      stagingQueue.markCommitted(item);

      expect(stagingQueue.isDuplicate('duplicate-msg-id'), isTrue);
    });
  });

  group('Phase 4 Requirements: End-to-End P2P Device A <-> Device B Sync', () {
    late Database dbA;
    late Database dbB;
    late DatabaseHelper helperA;
    late DatabaseHelper helperB;

    late InMemoryBluetoothTransport transportA;
    late InMemoryBluetoothTransport transportB;

    late BluetoothP2pService serviceA;
    late BluetoothP2pService serviceB;

    setUp(() async {
      // Initialize Device A Database
      dbA = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: DatabaseMigrations.onCreate,
        ),
      );
      helperA = DatabaseHelper.withDatabase(dbA);

      // Initialize Device B Database
      dbB = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: DatabaseMigrations.onCreate,
        ),
      );
      helperB = DatabaseHelper.withDatabase(dbB);

      // Setup simulated Bluetooth transports and pair them
      transportA = InMemoryBluetoothTransport();
      transportB = InMemoryBluetoothTransport();
      InMemoryBluetoothTransport.pair(transportA, transportB);

      // Initialize Device A P2P Service
      serviceA = BluetoothP2pService(
        transport: transportA,
        peerDao: BluetoothPeerDao(dbHelper: helperA),
        requestDao: EmergencyRequestDao(dbHelper: helperA),
        reportDao: DisasterReportDao(dbHelper: helperA),
        shelterDao: ShelterDao(dbHelper: helperA),
        hospitalDao: HospitalDao(dbHelper: helperA),
        contactDao: EmergencyContactDao(dbHelper: helperA),
        safeZoneDao: SafeZoneDao(dbHelper: helperA),
        resourceDao: ResourceDao(dbHelper: helperA),
        localDeviceId: 'DEVICE-A-ID',
      );

      // Initialize Device B P2P Service
      serviceB = BluetoothP2pService(
        transport: transportB,
        peerDao: BluetoothPeerDao(dbHelper: helperB),
        requestDao: EmergencyRequestDao(dbHelper: helperB),
        reportDao: DisasterReportDao(dbHelper: helperB),
        shelterDao: ShelterDao(dbHelper: helperB),
        hospitalDao: HospitalDao(dbHelper: helperB),
        contactDao: EmergencyContactDao(dbHelper: helperB),
        safeZoneDao: SafeZoneDao(dbHelper: helperB),
        resourceDao: ResourceDao(dbHelper: helperB),
        localDeviceId: 'DEVICE-B-ID',
      );
    });

    tearDown(() async {
      serviceA.dispose();
      serviceB.dispose();
      await dbA.close();
      await dbB.close();
    });

    test('7. Device A transfers Emergency Request to Device B without Internet -> Verified in Device B SQLite', () async {
      const emergencyReqId = 'p2p-emer-req-101';
      final emergencyPayload = {
        'id': emergencyReqId,
        'user_name': 'Device A Citizen',
        'phone': '9876543210',
        'request_type': 'evacuation',
        'priority': 'CRITICAL',
        'status': 'Requested',
        'description': 'Trapped by landslide on Ridge Road',
        'people_count': 4,
        'location': 'Ridge Road Sector 4',
        'created_at': '2026-10-01T12:00:00Z',
        'updated_at': '2026-10-01T12:00:00Z',
        'sync_status': 'SYNCED',
        'is_deleted': 0,
      };

      // Device A sends to Device B
      final sendSuccess = await serviceA.sendEntity(
        entityType: 'emergency_request',
        operation: 'INSERT',
        version: 1,
        payload: emergencyPayload,
      );
      expect(sendSuccess, isTrue);

      // Allow microtask queue to process stream transfer
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Device B must have received, validated, staged, and committed the request to its local SQLite database
      final bDao = EmergencyRequestDao(dbHelper: helperB);
      final receivedInB = await bDao.getById(emergencyReqId);

      expect(receivedInB, isNotNull);
      expect(receivedInB!.userName, 'Device A Citizen');
      expect(receivedInB.priority, 'CRITICAL');
      expect(receivedInB.peopleCount, 4);

      // Device A should have received the ACK back
      expect(serviceA.transferLogs.any((l) => l.entityType == 'ACK'), isTrue);
    });

    test('8. Reverse Transfer: Device B sends Disaster Report to Device A', () async {
      const reportId = 'p2p-rep-202';
      final reportPayload = {
        'id': reportId,
        'title': 'Submerged Underpass',
        'disaster_type': 'flood',
        'description': 'Underpass on Main Street flooded under 2m of water',
        'severity': 'HIGH',
        'location': 'Main Street Underpass',
        'status': 'submitted',
        'created_at': '2026-10-01T12:15:00Z',
        'updated_at': '2026-10-01T12:15:00Z',
      };

      // Device B sends to Device A
      final sendSuccess = await serviceB.sendEntity(
        entityType: 'disaster_report',
        operation: 'INSERT',
        version: 1,
        payload: reportPayload,
      );
      expect(sendSuccess, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify in Device A SQLite
      final aReportDao = DisasterReportDao(dbHelper: helperA);
      final reportInA = await aReportDao.getById(reportId);

      expect(reportInA, isNotNull);
      expect(reportInA!.title, 'Submerged Underpass');
      expect(reportInA.disasterType, 'flood');
      expect(reportInA.severity, 'HIGH');
    });

    test('9. Tampered payload is rejected during P2P transfer and NOT inserted into peer database', () async {
      const tamperedReqId = 'p2p-tampered-999';
      final tamperedPayload = {
        'id': tamperedReqId,
        'user_name': '', // Invalid empty user name
        'phone': '911',
      };

      await serviceA.sendEntity(
        entityType: 'emergency_request',
        operation: 'INSERT',
        version: 1,
        payload: tamperedPayload,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Device B must NOT have inserted this invalid record
      final bDao = EmergencyRequestDao(dbHelper: helperB);
      final item = await bDao.getById(tamperedReqId);
      expect(item, isNull);

      // Device B staging queue must mark it rejected
      expect(serviceB.stagingQueue.items.any((i) => i.isRejected), isTrue);
    });
  });
}
