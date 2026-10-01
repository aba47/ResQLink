import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/date_formatter.dart';
import '../local/dao/emergency_request_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../local/models/emergency_request_model.dart';
import '../local/models/sync_queue_model.dart';

class EmergencyRepository {
  final EmergencyRequestDao _requestDao;
  final SyncQueueDao _syncQueueDao;
  final Uuid _uuid = const Uuid();

  EmergencyRepository({
    EmergencyRequestDao? requestDao,
    SyncQueueDao? syncQueueDao,
  })  : _requestDao = requestDao ?? EmergencyRequestDao(),
        _syncQueueDao = syncQueueDao ?? SyncQueueDao();

  Future<List<EmergencyRequestModel>> getAllRequests() async {
    return await _requestDao.getAll();
  }

  Future<EmergencyRequestModel?> getRequestById(String id) async {
    return await _requestDao.getById(id);
  }

  /// Create an emergency request locally in SQLite and enqueue for sync
  Future<EmergencyRequestModel> createEmergencyRequest({
    String? userId,
    required String userName,
    required String phone,
    String? disasterId,
    required String requestType,
    required String priority,
    required String description,
    int peopleCount = 1,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    if (userName.trim().isEmpty) {
      throw const ValidationException('User name is required');
    }
    if (phone.trim().isEmpty) {
      throw const ValidationException('Contact phone is required');
    }
    if (description.trim().isEmpty) {
      throw const ValidationException('Emergency description is required');
    }
    if (location.trim().isEmpty) {
      throw const ValidationException('Location is required');
    }

    final id = _uuid.v4();
    final now = DateUtilsHelper.nowUtcIso();

    final model = EmergencyRequestModel(
      id: id,
      userId: userId,
      userName: userName.trim(),
      phone: phone.trim(),
      disasterId: disasterId,
      requestType: requestType,
      priority: priority,
      status: AppConstants.statusRequested,
      description: description.trim(),
      peopleCount: peopleCount > 0 ? peopleCount : 1,
      location: location.trim(),
      latitude: latitude,
      longitude: longitude,
      createdAt: now,
      updatedAt: now,
      syncStatus: AppConstants.syncPending,
    );

    // 1. Save directly into SQLite
    await _requestDao.insert(model);

    // 2. Enqueue into sync_queue
    final queueItem = SyncQueueModel(
      id: _uuid.v4(),
      entityType: 'emergency_request',
      entityId: id,
      operation: AppConstants.syncOpCreate,
      payload: jsonEncode(model.toMap()),
      version: 1,
      createdAt: now,
      status: AppConstants.syncPending,
    );
    await _syncQueueDao.enqueue(queueItem);

    return model;
  }

  Future<void> updateRequestStatus(String id, String newStatus, {String? assignedTeam}) async {
    final existing = await _requestDao.getById(id);
    if (existing == null) {
      throw const DatabaseException('Emergency request not found');
    }

    final now = DateUtilsHelper.nowUtcIso();
    final updated = existing.copyWith(
      status: newStatus,
      assignedTeam: assignedTeam ?? existing.assignedTeam,
      updatedAt: now,
      syncStatus: AppConstants.syncPending,
    );

    await _requestDao.update(updated);

    final queueItem = SyncQueueModel(
      id: _uuid.v4(),
      entityType: 'emergency_request',
      entityId: id,
      operation: AppConstants.syncOpUpdate,
      payload: jsonEncode(updated.toMap()),
      version: 2,
      createdAt: now,
      status: AppConstants.syncPending,
    );
    await _syncQueueDao.enqueue(queueItem);
  }
}
