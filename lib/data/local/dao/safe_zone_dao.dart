import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/safe_zone_model.dart';

class SafeZoneDao {
  final DatabaseHelper _dbHelper;

  SafeZoneDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(SafeZoneModel zone) async {
    final db = await _dbHelper.database;
    await db.insert('safe_zones', zone.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<SafeZoneModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('safe_zones', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return SafeZoneModel.fromMap(results.first);
  }

  Future<List<SafeZoneModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('safe_zones', where: 'is_deleted = 0', orderBy: 'name ASC');
    return results.map((m) => SafeZoneModel.fromMap(m)).toList();
  }

  Future<void> update(SafeZoneModel zone) async {
    final db = await _dbHelper.database;
    await db.update('safe_zones', zone.toMap(), where: 'id = ?', whereArgs: [zone.id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('safe_zones', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
