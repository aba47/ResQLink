import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatter.dart';
import '../local/dao/disaster_dao.dart';
import '../local/dao/emergency_request_dao.dart';
import '../local/dao/shelter_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../local/models/disaster_model.dart';
import '../local/models/emergency_request_model.dart';
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

class SyncRepository {
  final SyncQueueDao _syncQueueDao;
  final ApiClient _apiClient;
  final EmergencyRequestDao _requestDao;
  final DisasterDao _disasterDao;
  final ShelterDao _shelterDao;

  String? lastSyncTimestamp;
  String deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';

  SyncRepository({
    SyncQueueDao? syncQueueDao,
    ApiClient? apiClient,
    EmergencyRequestDao? requestDao,
    DisasterDao? disasterDao,
    ShelterDao? shelterDao,
  })  : _syncQueueDao = syncQueueDao ?? SyncQueueDao(),
        _apiClient = apiClient ?? ApiClient(),
        _requestDao = requestDao ?? EmergencyRequestDao(),
        _disasterDao = disasterDao ?? DisasterDao(),
        _shelterDao = shelterDao ?? ShelterDao();

  ApiClient get apiClient => _apiClient;

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

  /// Full 2-Way Push + Pull Sync Engine
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
        final pushResponse = await _apiClient.pushSync(deviceId, pendingItems);
        final acks = pushResponse['acknowledgements'] as List<dynamic>? ?? [];

        for (final ack in acks) {
          final queueId = ack['queue_id'] as String;
          final status = ack['status'] as String;
          final error = ack['error'] as String?;

          if (status == 'SYNCED') {
            await markSynced(queueId);
            totalPushed++;
          } else if (status == 'CONFLICT') {
            // Documented conflict handling: mark synced but preserve conflict note
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

    // 2. PULL STEP
    try {
      final pullResponse = await _apiClient.pullSync(deviceId, sinceTimestamp: lastSyncTimestamp);
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

      lastSyncTimestamp = serverTime ?? DateUtilsHelper.nowUtcIso();
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
