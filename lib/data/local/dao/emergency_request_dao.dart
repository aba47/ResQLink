import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/emergency_request_model.dart';

class EmergencyRequestDao {
  final DatabaseHelper _dbHelper;

  EmergencyRequestDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(EmergencyRequestModel request) async {
    final db = await _dbHelper.database;
    await db.insert('emergency_requests', request.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<EmergencyRequestModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('emergency_requests', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return EmergencyRequestModel.fromMap(results.first);
  }

  Future<List<EmergencyRequestModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('emergency_requests', where: 'is_deleted = 0', orderBy: 'created_at DESC');
    return results.map((m) => EmergencyRequestModel.fromMap(m)).toList();
  }

  Future<List<EmergencyRequestModel>> getPendingSync() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'emergency_requests',
      where: 'sync_status = ? AND is_deleted = 0',
      whereArgs: ['PENDING'],
      orderBy: 'created_at ASC',
    );
    return results.map((m) => EmergencyRequestModel.fromMap(m)).toList();
  }

  Future<void> update(EmergencyRequestModel request) async {
    final db = await _dbHelper.database;
    await db.update('emergency_requests', request.toMap(), where: 'id = ?', whereArgs: [request.id]);
  }

  Future<void> updateStatus(String id, String status, String updatedAt) async {
    final db = await _dbHelper.database;
    await db.update(
      'emergency_requests',
      {'status': status, 'updated_at': updatedAt, 'sync_status': 'PENDING'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSyncStatus(String id, String syncStatus) async {
    final db = await _dbHelper.database;
    await db.update('emergency_requests', {'sync_status': syncStatus}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('emergency_requests', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
