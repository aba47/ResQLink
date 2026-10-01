import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../models/sync_queue_model.dart';

class SyncQueueDao {
  final DatabaseHelper _dbHelper;

  SyncQueueDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> enqueue(SyncQueueModel item) async {
    final db = await _dbHelper.database;
    await db.insert('sync_queue', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SyncQueueModel>> getPendingItems({int limit = 50}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'sync_queue',
      where: 'status = ? OR status = ?',
      whereArgs: [AppConstants.syncPending, AppConstants.syncFailed],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return results.map((m) => SyncQueueModel.fromMap(m)).toList();
  }

  Future<int> getPendingCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE status = ? OR status = ?',
      [AppConstants.syncPending, AppConstants.syncFailed],
    );
    if (result.isEmpty) return 0;
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> updateStatus(String id, String status, {String? error}) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> values = {'status': status};
    if (error != null) {
      values['last_error'] = error;
      // Increment retry_count on failure
      if (status == AppConstants.syncFailed) {
        await db.rawUpdate('UPDATE sync_queue SET retry_count = retry_count + 1, status = ?, last_error = ? WHERE id = ?', [status, error, id]);
        return;
      }
    }
    await db.update('sync_queue', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<SyncQueueModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('sync_queue', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return SyncQueueModel.fromMap(results.first);
  }

  Future<List<SyncQueueModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('sync_queue', orderBy: 'created_at ASC');
    return results.map((m) => SyncQueueModel.fromMap(m)).toList();
  }

  Future<void> clearSynced() async {
    final db = await _dbHelper.database;
    await db.delete('sync_queue', where: 'status = ?', whereArgs: [AppConstants.syncCompleted]);
  }
}
