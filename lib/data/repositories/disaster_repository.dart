import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/date_formatter.dart';
import '../local/dao/disaster_dao.dart';
import '../local/dao/disaster_report_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../local/models/disaster_model.dart';
import '../local/models/disaster_report_model.dart';
import '../local/models/sync_queue_model.dart';

class DisasterRepository {
  final DisasterDao _disasterDao;
  final DisasterReportDao _reportDao;
  final SyncQueueDao _syncQueueDao;
  final Uuid _uuid = const Uuid();

  DisasterRepository({
    DisasterDao? disasterDao,
    DisasterReportDao? reportDao,
    SyncQueueDao? syncQueueDao,
  })  : _disasterDao = disasterDao ?? DisasterDao(),
        _reportDao = reportDao ?? DisasterReportDao(),
        _syncQueueDao = syncQueueDao ?? SyncQueueDao();

  Future<List<DisasterModel>> getAllDisasters() async {
    return await _disasterDao.getAll();
  }

  Future<List<DisasterModel>> getActiveDisasters() async {
    return await _disasterDao.getActive();
  }

  Future<DisasterModel?> getDisasterById(String id) async {
    return await _disasterDao.getById(id);
  }

  Future<List<DisasterReportModel>> getAllReports() async {
    return await _reportDao.getAll();
  }

  Future<DisasterReportModel> submitReport({
    String? userId,
    required String title,
    required String disasterType,
    required String description,
    required String severity,
    required String location,
    double? latitude,
    double? longitude,
    int casualtiesCount = 0,
    int injuredCount = 0,
    String? mediaPath,
  }) async {
    if (title.trim().isEmpty) {
      throw const ValidationException('Report title is required');
    }
    if (description.trim().isEmpty) {
      throw const ValidationException('Report description is required');
    }
    if (location.trim().isEmpty) {
      throw const ValidationException('Incident location is required');
    }

    final id = _uuid.v4();
    final now = DateUtilsHelper.nowUtcIso();

    final report = DisasterReportModel(
      id: id,
      userId: userId,
      title: title.trim(),
      disasterType: disasterType,
      description: description.trim(),
      severity: severity,
      location: location.trim(),
      latitude: latitude,
      longitude: longitude,
      casualtiesCount: casualtiesCount,
      injuredCount: injuredCount,
      mediaPath: mediaPath,
      status: 'submitted',
      createdAt: now,
      updatedAt: now,
      syncStatus: AppConstants.syncPending,
    );

    await _reportDao.insert(report);

    final queueItem = SyncQueueModel(
      id: _uuid.v4(),
      entityType: 'disaster_report',
      entityId: id,
      operation: AppConstants.syncOpCreate,
      payload: jsonEncode(report.toMap()),
      version: 1,
      createdAt: now,
      status: AppConstants.syncPending,
    );
    await _syncQueueDao.enqueue(queueItem);

    return report;
  }
}
