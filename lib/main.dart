import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app/app.dart';
import 'core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop SQLite FFI factory when running on Windows/Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Pre-initialize local database
  try {
    await DatabaseHelper.instance.database;
  } catch (e) {
    debugPrint('Database initialization warning: $e');
  }

  runApp(const DisasterReadyApp());
}
