import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/user_model.dart';

class UserDao {
  final DatabaseHelper _dbHelper;

  UserDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(UserModel user) async {
    final db = await _dbHelper.database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query('users', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<UserModel?> getActiveUser() async {
    final db = await _dbHelper.database;
    final results = await db.query('users', where: 'status = ? AND is_deleted = 0', whereArgs: ['active'], limit: 1);
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<List<UserModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('users', where: 'is_deleted = 0', orderBy: 'name ASC');
    return results.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<void> update(UserModel user) async {
    final db = await _dbHelper.database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> deleteSoft(String id) async {
    final db = await _dbHelper.database;
    await db.update('users', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
