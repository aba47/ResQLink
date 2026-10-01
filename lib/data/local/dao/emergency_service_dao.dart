import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/emergency_service_model.dart';

class EmergencyServiceDao {
  final DatabaseHelper _dbHelper;

  EmergencyServiceDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(EmergencyServiceModel service) async {
    final db = await _dbHelper.database;
    await db.insert('emergency_services', service.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<EmergencyServiceModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('emergency_services', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return EmergencyServiceModel.fromMap(results.first);
  }

  Future<List<EmergencyServiceModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('emergency_services', where: 'is_deleted = 0', orderBy: 'service_type ASC, name ASC');
    return results.map((m) => EmergencyServiceModel.fromMap(m)).toList();
  }

  Future<List<EmergencyServiceModel>> getByType(String serviceType) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'emergency_services',
      where: 'service_type = ? AND is_deleted = 0',
      whereArgs: [serviceType],
      orderBy: 'name ASC',
    );
    return results.map((m) => EmergencyServiceModel.fromMap(m)).toList();
  }

  Future<void> update(EmergencyServiceModel service) async {
    final db = await _dbHelper.database;
    await db.update('emergency_services', service.toMap(), where: 'id = ?', whereArgs: [service.id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('emergency_services', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
