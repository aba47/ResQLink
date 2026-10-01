import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/hospital_model.dart';

class HospitalDao {
  final DatabaseHelper _dbHelper;

  HospitalDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(HospitalModel hospital) async {
    final db = await _dbHelper.database;
    await db.insert('hospitals', hospital.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<HospitalModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('hospitals', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return HospitalModel.fromMap(results.first);
  }

  Future<List<HospitalModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('hospitals', where: 'is_deleted = 0', orderBy: 'name ASC');
    return results.map((m) => HospitalModel.fromMap(m)).toList();
  }

  Future<void> update(HospitalModel hospital) async {
    final db = await _dbHelper.database;
    await db.update('hospitals', hospital.toMap(), where: 'id = ?', whereArgs: [hospital.id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('hospitals', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
