import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/disaster_report_model.dart';

class DisasterReportDao {
  final DatabaseHelper _dbHelper;

  DisasterReportDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(DisasterReportModel report) async {
    final db = await _dbHelper.database;
    await db.insert('disaster_reports', report.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DisasterReportModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('disaster_reports', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return DisasterReportModel.fromMap(results.first);
  }

  Future<List<DisasterReportModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('disaster_reports', where: 'is_deleted = 0', orderBy: 'created_at DESC');
    return results.map((m) => DisasterReportModel.fromMap(m)).toList();
  }

  Future<void> update(DisasterReportModel report) async {
    final db = await _dbHelper.database;
    await db.update('disaster_reports', report.toMap(), where: 'id = ?', whereArgs: [report.id]);
  }

  Future<void> updateSyncStatus(String id, String syncStatus) async {
    final db = await _dbHelper.database;
    await db.update('disaster_reports', {'sync_status': syncStatus}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('disaster_reports', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
