import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/disaster_model.dart';

class DisasterDao {
  final DatabaseHelper _dbHelper;

  DisasterDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(DisasterModel disaster) async {
    final db = await _dbHelper.database;
    await db.insert('disasters', disaster.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DisasterModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('disasters', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return DisasterModel.fromMap(results.first);
  }

  Future<List<DisasterModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('disasters', where: 'is_deleted = 0', orderBy: 'reported_at DESC');
    return results.map((m) => DisasterModel.fromMap(m)).toList();
  }

  Future<List<DisasterModel>> getActive() async {
    final db = await _dbHelper.database;
    final results = await db.query('disasters', where: 'status = ? AND is_deleted = 0', whereArgs: ['active'], orderBy: 'reported_at DESC');
    return results.map((m) => DisasterModel.fromMap(m)).toList();
  }

  Future<void> update(DisasterModel disaster) async {
    final db = await _dbHelper.database;
    await db.update('disasters', disaster.toMap(), where: 'id = ?', whereArgs: [disaster.id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('disasters', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
