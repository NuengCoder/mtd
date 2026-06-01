import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// Provides the SQLite Database instance.
///
/// Usage in widgets:
///   final db = ref.watch(databaseProvider);
///
/// Usage in repositories:
///   final db = await ref.read(databaseProvider.future);
final databaseProvider = FutureProvider<Database>((ref) async {
  final dbHelper = DatabaseHelper.instance;
  return await dbHelper.database;
});