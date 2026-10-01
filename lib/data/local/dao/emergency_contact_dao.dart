import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactDao {
  final DatabaseHelper _dbHelper;

  EmergencyContactDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(EmergencyContactModel contact) async {
    final db = await _dbHelper.database;
    await db.insert('emergency_contacts', contact.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<EmergencyContactModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('emergency_contacts', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return EmergencyContactModel.fromMap(results.first);
  }

  Future<List<EmergencyContactModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('emergency_contacts', where: 'is_deleted = 0', orderBy: 'is_primary DESC, name ASC');
    return results.map((m) => EmergencyContactModel.fromMap(m)).toList();
  }

  Future<void> update(EmergencyContactModel contact) async {
    final db = await _dbHelper.database;
    await db.update('emergency_contacts', contact.toMap(), where: 'id = ?', whereArgs: [contact.id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('emergency_contacts', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
