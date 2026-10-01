import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/bluetooth_peer_model.dart';

class BluetoothPeerDao {
  final DatabaseHelper _dbHelper;

  BluetoothPeerDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> upsert(BluetoothPeerModel peer) async {
    final db = await _dbHelper.database;
    await db.insert('bluetooth_peers', peer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BluetoothPeerModel>> getAll() async {
    final db = await _dbHelper.database;
    final results = await db.query('bluetooth_peers', orderBy: 'last_seen DESC');
    return results.map((m) => BluetoothPeerModel.fromMap(m)).toList();
  }

  Future<BluetoothPeerModel?> getByAddress(String address) async {
    final db = await _dbHelper.database;
    final results = await db.query('bluetooth_peers', where: 'device_address = ?', whereArgs: [address]);
    if (results.isEmpty) return null;
    return BluetoothPeerModel.fromMap(results.first);
  }

  Future<void> updateSyncStatus(String id, String status) async {
    final db = await _dbHelper.database;
    await db.update('bluetooth_peers', {'sync_status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('bluetooth_peers', where: 'id = ?', whereArgs: [id]);
  }
}
