import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/resource_model.dart';

class ResourceDao {
  final DatabaseHelper _dbHelper;

  ResourceDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(ResourceModel resource) async {
    final db = await _dbHelper.database;
    await db.insert('resources', resource.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ResourceModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('resources', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return ResourceModel.fromMap(results.first);
  }

  Future<List<ResourceModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('resources', where: 'is_deleted = 0', orderBy: 'category ASC, name ASC');
    return results.map((m) => ResourceModel.fromMap(m)).toList();
  }

  Future<List<ResourceModel>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'resources',
      where: 'category = ? AND is_deleted = 0',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return results.map((m) => ResourceModel.fromMap(m)).toList();
  }

  Future<void> update(ResourceModel resource) async {
    final db = await _dbHelper.database;
    await db.update('resources', resource.toMap(), where: 'id = ?', whereArgs: [resource.id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('resources', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
