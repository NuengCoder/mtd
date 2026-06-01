import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_constants.dart';
import '../models/user_sound.dart';
import '../providers/database_provider.dart';

class UserSoundRepository {
  final Database _db;

  UserSoundRepository(this._db);

  Future<int> insert(UserSound sound) async {
    try {
      return await _db.insert(DbTables.userSounds, sound.toMap()..remove('id'));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserSound>> getAll() async {
    try {
      final results = await _db.query(DbTables.userSounds, orderBy: '${DbCols.createdAt} DESC');
      return results.map((m) => UserSound.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserSound?> getById(int id) async {
    try {
      final results = await _db.query(DbTables.userSounds, where: '${DbCols.id} = ?', whereArgs: [id]);
      if (results.isEmpty) return null;
      return UserSound.fromMap(results.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> update(UserSound sound) async {
    try {
      return await _db.update(DbTables.userSounds, sound.toMap(), where: '${DbCols.id} = ?', whereArgs: [sound.id]);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    try {
      final item = await getById(id);
      if (item != null && item.filePath.isNotEmpty) {
        final file = File(item.filePath);
        if (await file.exists()) await file.delete();
      }
      return await _db.delete(DbTables.userSounds, where: '${DbCols.id} = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }
}

final userSoundRepositoryProvider = Provider<UserSoundRepository>((ref) {
  final db = ref.watch(databaseProvider).valueOrNull;
  if (db == null) throw StateError('Database not initialized');
  return UserSoundRepository(db);
});