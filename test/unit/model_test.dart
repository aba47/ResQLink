import 'package:flutter_test/flutter_test.dart';
import 'package:disaster_ready/data/local/models/user_model.dart';
import 'package:disaster_ready/data/local/models/disaster_model.dart';
import 'package:disaster_ready/data/local/models/emergency_request_model.dart';
import 'package:disaster_ready/data/local/models/disaster_report_model.dart';
import 'package:disaster_ready/data/local/models/shelter_model.dart';
import 'package:disaster_ready/data/local/models/sync_queue_model.dart';

void main() {
  group('Model Serialization Tests', () {
    test('UserModel toMap and fromMap', () {
      const user = UserModel(
        id: 'u-1',
        name: 'John Doe',
        phone: '9876543210',
        role: 'responder',
        createdAt: '2026-10-01T10:00:00Z',
        updatedAt: '2026-10-01T10:00:00Z',
      );
      final map = user.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.id, 'u-1');
      expect(restored.name, 'John Doe');
      expect(restored.role, 'responder');
      expect(restored.isDeleted, false);
    });

    test('DisasterModel toMap and fromMap', () {
      const disaster = DisasterModel(
        id: 'd-1',
        title: 'Coastal Cyclone Alert',
        type: 'cyclone',
        severity: 'critical',
        status: 'active',
        location: 'Bay Coast Area',
        reportedAt: '2026-10-01T10:00:00Z',
        updatedAt: '2026-10-01T10:00:00Z',
      );
      final map = disaster.toMap();
      final restored = DisasterModel.fromMap(map);

      expect(restored.title, 'Coastal Cyclone Alert');
      expect(restored.severity, 'critical');
      expect(restored.status, 'active');
    });

    test('EmergencyRequestModel toMap and fromMap', () {
      const req = EmergencyRequestModel(
        id: 'req-1',
        userName: 'Alice Smith',
        phone: '1234567890',
        requestType: 'rescue',
        priority: 'CRITICAL',
        status: 'Requested',
        description: 'Trapped on 2nd floor roof due to flash flooding',
        peopleCount: 4,
        location: 'Sector 5, Bridge Road',
        createdAt: '2026-10-01T10:00:00Z',
        updatedAt: '2026-10-01T10:00:00Z',
      );
      final map = req.toMap();
      final restored = EmergencyRequestModel.fromMap(map);

      expect(restored.id, 'req-1');
      expect(restored.peopleCount, 4);
      expect(restored.priority, 'CRITICAL');
      expect(restored.syncStatus, 'PENDING');
    });

    test('DisasterReportModel toMap and fromMap', () {
      const report = DisasterReportModel(
        id: 'rep-1',
        title: 'Bridge wash away',
        disasterType: 'flood',
        description: 'Main canal bridge has collapsed',
        severity: 'high',
        location: 'North Canal',
        casualtiesCount: 0,
        injuredCount: 2,
        createdAt: '2026-10-01T10:00:00Z',
        updatedAt: '2026-10-01T10:00:00Z',
      );
      final map = report.toMap();
      final restored = DisasterReportModel.fromMap(map);

      expect(restored.id, 'rep-1');
      expect(restored.injuredCount, 2);
      expect(restored.syncStatus, 'PENDING');
    });

    test('ShelterModel occupancy calculation', () {
      const shelter = ShelterModel(
        id: 'sh-1',
        name: 'Central High School Camp',
        address: '100 School Lane',
        capacity: 500,
        currentOccupancy: 350,
        createdAt: '2026-10-01T10:00:00Z',
        updatedAt: '2026-10-01T10:00:00Z',
      );

      expect(shelter.availableCapacity, 150);
    });

    test('SyncQueueModel toMap and fromMap', () {
      const item = SyncQueueModel(
        id: 'q-1',
        entityType: 'emergency_request',
        entityId: 'req-1',
        operation: 'CREATE',
        payload: '{"test": 1}',
        createdAt: '2026-10-01T10:00:00Z',
      );
      final map = item.toMap();
      final restored = SyncQueueModel.fromMap(map);

      expect(restored.id, 'q-1');
      expect(restored.operation, 'CREATE');
      expect(restored.status, 'PENDING');
      expect(restored.retryCount, 0);
    });
  });
}
