import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatter.dart';
import '../local/dao/disaster_dao.dart';
import '../local/dao/disaster_report_dao.dart';
import '../local/dao/emergency_contact_dao.dart';
import '../local/dao/emergency_request_dao.dart';
import '../local/dao/hospital_dao.dart';
import '../local/dao/resource_dao.dart';
import '../local/dao/safe_zone_dao.dart';
import '../local/dao/shelter_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../local/models/disaster_model.dart';
import '../local/models/disaster_report_model.dart';
import '../local/models/emergency_contact_model.dart';
import '../local/models/emergency_request_model.dart';
import '../local/models/hospital_model.dart';
import '../local/models/resource_model.dart';
import '../local/models/safe_zone_model.dart';
import '../local/models/shelter_model.dart';
import '../local/models/sync_queue_model.dart';

class SyncResult {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final String message;

  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    required this.message,
  });
}

class SyncRepository extends ChangeNotifier {
  static const String _keyDeviceId = 'sync_device_id';
  static const String _keyLastSync = 'sync_last_timestamp';
  static const String _keyBaseUrl = 'sync_base_url';

  final SyncQueueDao _syncQueueDao;
  final ApiClient _apiClient;
  final EmergencyRequestDao _requestDao;
  final DisasterDao _disasterDao;
  final ShelterDao _shelterDao;
  final HospitalDao _hospitalDao;
  final SafeZoneDao _safeZoneDao;
  final ResourceDao _resourceDao;
  final DisasterReportDao _reportDao;
  final EmergencyContactDao _contactDao;

  String? _lastSyncTimestamp;
  String _deviceId = 'device-default';
  bool _isInitialized = false;

  SyncRepository({
    SyncQueueDao? syncQueueDao,
    ApiClient? apiClient,
    EmergencyRequestDao? requestDao,
    DisasterDao? disasterDao,
    ShelterDao? shelterDao,
    HospitalDao? hospitalDao,
    SafeZoneDao? safeZoneDao,
    ResourceDao? resourceDao,
    DisasterReportDao? reportDao,
    EmergencyContactDao? contactDao,
  })  : _syncQueueDao = syncQueueDao ?? SyncQueueDao(),
        _apiClient = apiClient ?? ApiClient(),
        _requestDao = requestDao ?? EmergencyRequestDao(),
        _disasterDao = disasterDao ?? DisasterDao(),
        _shelterDao = shelterDao ?? ShelterDao(),
        _hospitalDao = hospitalDao ?? HospitalDao(),
        _safeZoneDao = safeZoneDao ?? SafeZoneDao(),
        _resourceDao = resourceDao ?? ResourceDao(),
        _reportDao = reportDao ?? DisasterReportDao(),
        _contactDao = contactDao ?? EmergencyContactDao() {
    _initDevice();
  }

  ApiClient get apiClient => _apiClient;
  String get deviceId => _deviceId;
  String? get lastSyncTimestamp => _lastSyncTimestamp;
  bool get isInitialized => _isInitialized;

  Future<void> _initDevice() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      var savedId = prefs.getString(_keyDeviceId);
      if (savedId == null || savedId.isEmpty) {
        savedId = 'device-${const Uuid().v4()}';
        await prefs.setString(_keyDeviceId, savedId);
      }
      _deviceId = savedId;
      _lastSyncTimestamp = prefs.getString(_keyLastSync);

      final savedUrl = prefs.getString(_keyBaseUrl);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _apiClient.baseUrl = savedUrl;
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('SyncRepository init error: $e');
      _deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> updateBaseUrl(String url) async {
    final cleanUrl = url.trim();
    _apiClient.baseUrl = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBaseUrl, cleanUrl);
    } catch (_) {}
    notifyListeners();
  }

  Future<List<SyncQueueModel>> getPendingItems() async {
    return await _syncQueueDao.getPendingItems();
  }

  Future<int> getPendingCount() async {
    return await _syncQueueDao.getPendingCount();
  }

  Future<void> markSyncing(String id) async {
    await _syncQueueDao.updateStatus(id, AppConstants.syncInProgress);
  }

  Future<void> markSynced(String id) async {
    await _syncQueueDao.updateStatus(id, AppConstants.syncCompleted);
  }

  Future<void> markFailed(String id, String error) async {
    await _syncQueueDao.updateStatus(id, AppConstants.syncFailed, error: error);
  }

  Future<void> clearSynced() async {
    await _syncQueueDao.clearSynced();
  }

  /// Full 2-Way Push + Pull Sync Engine with complete 8-Collection Reconciliation
  Future<SyncResult> performSync() async {
    int totalPushed = 0;
    int totalPulled = 0;

    // Check backend health first
    final isHealthy = await _apiClient.checkHealth();
    if (!isHealthy) {
      return const SyncResult(
        success: false,
        message: 'Backend unavailable. Local records safely remain queued in SQLite.',
      );
    }

    // 1. PUSH STEP
    final pendingItems = await _syncQueueDao.getPendingItems(limit: 50);
    if (pendingItems.isNotEmpty) {
      for (final item in pendingItems) {
        await markSyncing(item.id);
      }

      try {
        final pushResponse = await _apiClient.pushSync(_deviceId, pendingItems);
        final acks = pushResponse['acknowledgements'] as List<dynamic>? ?? [];

        for (final ack in acks) {
          final queueId = ack['queue_id'] as String;
          final status = ack['status'] as String;
          final error = ack['error'] as String?;

          if (status == 'SYNCED') {
            await markSynced(queueId);
            totalPushed++;
          } else if (status == 'CONFLICT') {
            await _syncQueueDao.updateStatus(queueId, AppConstants.syncConflict, error: error);
          } else {
            await markFailed(queueId, error ?? 'Sync error');
          }
        }
      } catch (e) {
        for (final item in pendingItems) {
          await markFailed(item.id, e.toString());
        }
        return SyncResult(
          success: false,
          pushedCount: totalPushed,
          message: 'Push sync failed: $e',
        );
      }
    }

    // 2. PULL STEP (Reconcile all 8 collections)
    try {
      final pullResponse = await _apiClient.pullSync(_deviceId, sinceTimestamp: _lastSyncTimestamp);
      final serverTime = pullResponse['server_time'] as String?;

      // Reconcile pulled disasters
      final pulledDisasters = pullResponse['disasters'] as List<dynamic>? ?? [];
      for (final d in pulledDisasters) {
        final model = DisasterModel.fromMap(d as Map<String, dynamic>);
        await _disasterDao.insert(model);
        totalPulled++;
      }

      // Reconcile pulled shelters
      final pulledShelters = pullResponse['shelters'] as List<dynamic>? ?? [];
      for (final s in pulledShelters) {
        final model = ShelterModel.fromMap(s as Map<String, dynamic>);
        await _shelterDao.insert(model);
        totalPulled++;
      }

      // Reconcile pulled emergency requests
      final pulledRequests = pullResponse['emergency_requests'] as List<dynamic>? ?? [];
      for (final r in pulledRequests) {
        final model = EmergencyRequestModel.fromMap(r as Map<String, dynamic>);
        await _requestDao.insert(model);
        totalPulled++;
      }

      // Reconcile pulled disaster reports
      final pulledReports = pullResponse['disaster_reports'] as List<dynamic>? ?? [];
      for (final rep in pulledReports) {
        final model = DisasterReportModel.fromMap(rep as Map<String, dynamic>);
        await _reportDao.insert(model);
        totalPulled++;
      }

      // Reconcile pulled hospitals
      final pulledHospitals = pullResponse['hospitals'] as List<dynamic>? ?? [];
      for (final h in pulledHospitals) {
        final model = HospitalModel.fromMap(h as Map<String, dynamic>);
        await _hospitalDao.insert(model);
        totalPulled++;
      }

      // Reconcile pulled safe zones
      final pulledSafeZones = pullResponse['safe_zones'] as List<dynamic>? ?? [];
      for (final sz in pulledSafeZones) {
        final model = SafeZoneModel.fromMap(sz as Map<String, dynamic>);
        await _safeZoneDao.insert(model);
        totalPulled++;
      }

      // Reconcile pulled resources
      final pulledResources = pullResponse['resources'] as List<dynamic>? ?? [];
      for (final res in pulledResources) {
        final model = ResourceModel.fromMap(res as Map<String, dynamic>);
        await _resourceDao.insert(model);
        totalPulled++;
      }

      // Reconcile pulled emergency contacts
      final pulledContacts = pullResponse['emergency_contacts'] as List<dynamic>? ?? [];
      for (final c in pulledContacts) {
        final model = EmergencyContactModel.fromMap(c as Map<String, dynamic>);
        await _contactDao.insert(model);
        totalPulled++;
      }

      // Persist latest sync timestamp
      _lastSyncTimestamp = serverTime ?? DateUtilsHelper.nowUtcIso();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastSync, _lastSyncTimestamp!);
      } catch (_) {}

      notifyListeners();
    } catch (e) {
      return SyncResult(
        success: false,
        pushedCount: totalPushed,
        message: 'Pull sync failed: $e',
      );
    }

    return SyncResult(
      success: true,
      pushedCount: totalPushed,
      pulledCount: totalPulled,
      message: 'Sync complete: Pushed $totalPushed item(s), Pulled $totalPulled update(s).',
    );
  }
}
