import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/shelter_model.dart';

class ShelterDao {
  final DatabaseHelper _dbHelper;

  ShelterDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(ShelterModel shelter) async {
    final db = await _dbHelper.database;
    await db.insert('shelters', shelter.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ShelterModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('shelters', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return ShelterModel.fromMap(results.first);
  }

  Future<List<ShelterModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('shelters', where: 'is_deleted = 0', orderBy: 'name ASC');
    return results.map((m) => ShelterModel.fromMap(m)).toList();
  }

  Future<List<ShelterModel>> getOpenShelters() async {
    final db = await _dbHelper.database;
    final results = await db.query('shelters', where: 'status = ? AND is_deleted = 0', whereArgs: ['open'], orderBy: 'name ASC');
    return results.map((m) => ShelterModel.fromMap(m)).toList();
  }

  Future<void> update(ShelterModel shelter) async {
    final db = await _dbHelper.database;
    await db.update('shelters', shelter.toMap(), where: 'id = ?', whereArgs: [shelter.id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('shelters', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
