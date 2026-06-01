import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_constants.dart';
import '../models/user_image.dart';
import '../providers/database_provider.dart';

class UserImageRepository {
  final Database _db;

  UserImageRepository(this._db);

  Future<int> insert(UserImage image) async {
    try {
      return await _db.insert(DbTables.userImages, image.toMap()..remove('id'));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserImage>> getAll() async {
    try {
      final results = await _db.query(DbTables.userImages, orderBy: '${DbCols.createdAt} DESC');
      return results.map((m) => UserImage.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserImage?> getById(int id) async {
    try {
      final results = await _db.query(DbTables.userImages, where: '${DbCols.id} = ?', whereArgs: [id]);
      if (results.isEmpty) return null;
      return UserImage.fromMap(results.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> update(UserImage image) async {
    try {
      return await _db.update(DbTables.userImages, image.toMap(), where: '${DbCols.id} = ?', whereArgs: [image.id]);
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
      return await _db.delete(DbTables.userImages, where: '${DbCols.id} = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }
}

final userImageRepositoryProvider = Provider<UserImageRepository>((ref) {
  final db = ref.watch(databaseProvider).valueOrNull;
  if (db == null) throw StateError('Database not initialized');
  return UserImageRepository(db);
});