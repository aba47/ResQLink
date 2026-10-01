import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:disaster_ready/core/constants/app_constants.dart';
import 'package:disaster_ready/core/database/database_helper.dart';
import 'package:disaster_ready/core/database/migrations.dart';
import 'package:disaster_ready/data/local/dao/disaster_dao.dart';
import 'package:disaster_ready/data/local/dao/emergency_request_dao.dart';
import 'package:disaster_ready/data/local/dao/disaster_report_dao.dart';
import 'package:disaster_ready/data/local/dao/shelter_dao.dart';
import 'package:disaster_ready/data/local/dao/hospital_dao.dart';
import 'package:disaster_ready/data/local/dao/emergency_contact_dao.dart';
import 'package:disaster_ready/data/local/dao/safe_zone_dao.dart';
import 'package:disaster_ready/data/local/dao/resource_dao.dart';
import 'package:disaster_ready/data/local/dao/sync_queue_dao.dart';
import 'package:disaster_ready/data/local/models/disaster_model.dart';
import 'package:disaster_ready/data/local/models/emergency_contact_model.dart';
import 'package:disaster_ready/data/local/models/hospital_model.dart';
import 'package:disaster_ready/data/local/models/resource_model.dart';
import 'package:disaster_ready/data/local/models/safe_zone_model.dart';
import 'package:disaster_ready/data/local/models/shelter_model.dart';
import 'package:disaster_ready/data/repositories/disaster_repository.dart';
import 'package:disaster_ready/data/repositories/emergency_repository.dart';
import 'package:disaster_ready/data/repositories/facilities_repository.dart';
import 'package:disaster_ready/data/repositories/sync_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseHelper dbHelper;
  late EmergencyRepository emergencyRepo;
  late DisasterRepository disasterRepo;
  late FacilitiesRepository facilitiesRepo;
  late SyncRepository syncRepo;
  late SyncQueueDao syncQueueDao;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: DatabaseMigrations.onCreate,
      ),
    );
    dbHelper = DatabaseHelper.withDatabase(db);
    syncQueueDao = SyncQueueDao(dbHelper: dbHelper);

    emergencyRepo = EmergencyRepository(
      requestDao: EmergencyRequestDao(dbHelper: dbHelper),
      syncQueueDao: syncQueueDao,
    );
    disasterRepo = DisasterRepository(
      disasterDao: DisasterDao(dbHelper: dbHelper),
      reportDao: DisasterReportDao(dbHelper: dbHelper),
      syncQueueDao: syncQueueDao,
    );
    facilitiesRepo = FacilitiesRepository(
      shelterDao: ShelterDao(dbHelper: dbHelper),
      hospitalDao: HospitalDao(dbHelper: dbHelper),
      contactDao: EmergencyContactDao(dbHelper: dbHelper),
      safeZoneDao: SafeZoneDao(dbHelper: dbHelper),
      resourceDao: ResourceDao(dbHelper: dbHelper),
    );
    syncRepo = SyncRepository(syncQueueDao: syncQueueDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 2 Requirements: Complete Disaster Features', () {
    test('1. Disaster Feed and Filtering', () async {
      const disaster = DisasterModel(
        id: 'dist-101',
        title: 'River Breach Flood Alert',
        type: 'flood',
        severity: 'critical',
        status: 'active',
        location: 'North District Zone 3',
        radiusKm: 15.0,
        affectedPopulation: 25000,
        reportedAt: '2026-10-01T08:00:00Z',
        updatedAt: '2026-10-01T08:00:00Z',
      );
      await DisasterDao(dbHelper: dbHelper).insert(disaster);

      final all = await disasterRepo.getAllDisasters();
      expect(all.any((d) => d.id == 'dist-101'), isTrue);

      final active = await disasterRepo.getActiveDisasters();
      expect(active.any((d) => d.id == 'dist-101'), isTrue);
    });

    test('2. Emergency Request creation with PRD required fields and Sync Queue validation', () async {
      final req = await emergencyRepo.createEmergencyRequest(
        userName: 'Priya Sharma',
        phone: '9820011223',
        requestType: 'evacuation',
        priority: AppConstants.priorityCritical,
        description: 'Water reached 1st floor balcony. Need boat evacuation.',
        location: 'Plot 12, Riverview Enclave',
        peopleCount: 4,
        latitude: 19.0800,
        longitude: 72.8800,
      );

      expect(req.id, isNotEmpty);
      expect(req.userName, 'Priya Sharma');
      expect(req.peopleCount, 4);
      expect(req.priority, 'CRITICAL');
      expect(req.status, AppConstants.statusRequested);

      // Verify sync queue received a CREATE entry
      final pendingCount = await syncRepo.getPendingCount();
      expect(pendingCount, 1);

      final items = await syncRepo.getPendingItems();
      expect(items.first.entityId, req.id);
      expect(items.first.operation, AppConstants.syncOpCreate);
    });

    test('3. Responder Request Workflow execution across all 5 states', () async {
      // Step A: Initial creation (Requested)
      final req = await emergencyRepo.createEmergencyRequest(
        userName: 'Ramesh Patel',
        phone: '9898989898',
        requestType: 'medical',
        priority: AppConstants.priorityHigh,
        description: 'Elderly diabetic patient needing insulin and evacuation',
        location: 'Camp Road, Sector 8',
      );
      expect(req.status, AppConstants.statusRequested);

      // Step B: Requested -> Accepted
      await emergencyRepo.updateRequestStatus(req.id, AppConstants.statusAccepted);
      var fetched = await emergencyRepo.getRequestById(req.id);
      expect(fetched!.status, AppConstants.statusAccepted);

      // Step C: Accepted -> Team Assigned
      await emergencyRepo.updateRequestStatus(
        req.id,
        AppConstants.statusTeamAssigned,
        assignedTeam: 'NDRF Quick Response Team 4',
      );
      fetched = await emergencyRepo.getRequestById(req.id);
      expect(fetched!.status, AppConstants.statusTeamAssigned);
      expect(fetched.assignedTeam, 'NDRF Quick Response Team 4');

      // Step D: Team Assigned -> In Progress
      await emergencyRepo.updateRequestStatus(req.id, AppConstants.statusInProgress);
      fetched = await emergencyRepo.getRequestById(req.id);
      expect(fetched!.status, AppConstants.statusInProgress);

      // Step E: In Progress -> Completed
      await emergencyRepo.updateRequestStatus(req.id, AppConstants.statusCompleted);
      fetched = await emergencyRepo.getRequestById(req.id);
      expect(fetched!.status, AppConstants.statusCompleted);

      // Check that sync queue records were created for the lifecycle
      final pending = await syncRepo.getPendingItems();
      expect(pending.length >= 4, isTrue);
    });

    test('4. Disaster Report creation with casualties and sync queue integration', () async {
      final report = await disasterRepo.submitReport(
        title: 'Main Expressway Bridge Partial Collapse',
        disasterType: 'earthquake',
        description: 'Flyover girder shifted, roadway blocked to all traffic.',
        severity: 'CRITICAL',
        location: 'Highway 48, KM 114',
        casualtiesCount: 1,
        injuredCount: 6,
      );

      expect(report.id, isNotEmpty);
      expect(report.casualtiesCount, 1);
      expect(report.injuredCount, 6);

      final reports = await disasterRepo.getAllReports();
      expect(reports.any((r) => r.id == report.id), isTrue);
    });

    test('5. Shelter Management and Occupancy tracking', () async {
      const shelter = ShelterModel(
        id: 'sh-test-1',
        name: 'Community Relief Center',
        address: 'Sector 10 Community Hall',
        capacity: 300,
        currentOccupancy: 210,
        status: 'open',
        facilities: 'Food, Water, Blankets, Solar Power',
        createdAt: '2026-10-01T09:00:00Z',
        updatedAt: '2026-10-01T09:00:00Z',
      );
      await facilitiesRepo.addShelter(shelter);

      final shelters = await facilitiesRepo.getShelters();
      expect(shelters.any((s) => s.id == 'sh-test-1'), isTrue);
      expect(shelter.availableCapacity, 90);
    });

    test('6. Hospital information and beds tracking', () async {
      const hospital = HospitalModel(
        id: 'hosp-test-1',
        name: 'Civil Emergency Trauma Center',
        address: 'Hospital Square, Sector 2',
        emergencyContact: '022-24101010',
        totalBeds: 250,
        availableBeds: 45,
        icuBedsAvailable: 8,
        bloodUnitsAvailable: 35,
        status: 'operational',
        createdAt: '2026-10-01T09:00:00Z',
        updatedAt: '2026-10-01T09:00:00Z',
      );
      await facilitiesRepo.addHospital(hospital);

      final hospitals = await facilitiesRepo.getHospitals();
      expect(hospitals.any((h) => h.id == 'hosp-test-1'), isTrue);
      expect(hospitals.firstWhere((h) => h.id == 'hosp-test-1').icuBedsAvailable, 8);
    });

    test('7. Emergency Contacts with Primary flag', () async {
      const contact = EmergencyContactModel(
        id: 'cnt-1',
        name: 'Dr. Anita Roy',
        relationship: 'District Medical Officer',
        phone: '9811223344',
        isPrimary: true,
        createdAt: '2026-10-01T09:00:00Z',
        updatedAt: '2026-10-01T09:00:00Z',
      );
      await facilitiesRepo.addContact(contact);

      final contacts = await facilitiesRepo.getEmergencyContacts();
      expect(contacts.any((c) => c.id == 'cnt-1'), isTrue);
      expect(contacts.firstWhere((c) => c.id == 'cnt-1').isPrimary, isTrue);
    });

    test('8. Safe Zones designation and Assembly guidelines', () async {
      const zone = SafeZoneModel(
        id: 'sz-1',
        name: 'University Sports Ground Safe Haven',
        latitude: 19.0700,
        longitude: 72.8700,
        radiusMeters: 250.0,
        safetyLevel: 'high',
        guidelines: 'Elevated open stadium. Helipad landing area at north corner.',
        createdAt: '2026-10-01T09:00:00Z',
        updatedAt: '2026-10-01T09:00:00Z',
      );
      await facilitiesRepo.addSafeZone(zone);

      final zones = await facilitiesRepo.getSafeZones();
      expect(zones.any((z) => z.id == 'sz-1'), isTrue);
      expect(zones.firstWhere((z) => z.id == 'sz-1').safetyLevel, 'high');
    });

    test('9. Resource inventory tracking by category', () async {
      const res = ResourceModel(
        id: 'res-1',
        name: 'Purified Water Cans (20L)',
        category: 'water',
        quantity: 120,
        unit: 'cans',
        location: 'Shelter 1 Storehouse',
        updatedAt: '2026-10-01T09:00:00Z',
      );
      await ResourceDao(dbHelper: dbHelper).insert(res);

      final resources = await facilitiesRepo.getResources();
      expect(resources.any((r) => r.id == 'res-1'), isTrue);
      expect(resources.firstWhere((r) => r.id == 'res-1').quantity, 120);
    });

    test('10. Sync Center queue lifecycle: Pending, Syncing, Synced, Retry Counter', () async {
      // Enqueue an action
      await emergencyRepo.createEmergencyRequest(
        userName: 'Test Citizen',
        phone: '1000000000',
        requestType: 'rescue',
        priority: 'LOW',
        description: 'Test queue',
        location: 'Test location',
      );

      final pending = await syncRepo.getPendingItems();
      expect(pending.isNotEmpty, isTrue);
      final itemId = pending.first.id;

      // Mark syncing
      await syncRepo.markSyncing(itemId);
      var queueDaoItems = await syncQueueDao.getPendingItems();
      // Since SYNCING is in progress, it's not pending
      expect(queueDaoItems.any((i) => i.id == itemId), isFalse);

      // Simulate failure -> updates retry count and error message
      await syncRepo.markFailed(itemId, 'Connection timeout to backend');
      queueDaoItems = await syncQueueDao.getPendingItems();
      final failedItem = queueDaoItems.firstWhere((i) => i.id == itemId);
      expect(failedItem.status, AppConstants.syncFailed);
      expect(failedItem.retryCount, 1);
      expect(failedItem.lastError, 'Connection timeout to backend');

      // Now mark synced
      await syncRepo.markSynced(itemId);

      // Clear synced
      await syncRepo.clearSynced();
      final remaining = await syncRepo.getPendingItems();
      expect(remaining.any((i) => i.id == itemId), isFalse);
    });
  });
}
