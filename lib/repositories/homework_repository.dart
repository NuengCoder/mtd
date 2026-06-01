import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_constants.dart';
import '../models/homework.dart';
import '../providers/database_provider.dart';

class HomeworkRepository {
  final Database _db;

  HomeworkRepository(this._db);

  Future<int> insert(Homework homework) async {
    try {
      return await _db.insert(DbTables.homeworks, homework.toMap()..remove('id'));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Homework>> getAll() async {
    try {
      final results = await _db.query(
        DbTables.homeworks,
        orderBy: '${DbCols.deadlineDate} ASC',
      );
      return results.map((m) => Homework.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get homework not yet submitted.
  Future<List<Homework>> getPending() async {
    try {
      final results = await _db.query(
        DbTables.homeworks,
        where: '${DbCols.isSubmitted} = ?',
        whereArgs: [0],
        orderBy: '${DbCols.deadlineDate} ASC',
      );
      return results.map((m) => Homework.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Homework?> getById(int id) async {
    try {
      final results = await _db.query(
        DbTables.homeworks,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) return null;
      return Homework.fromMap(results.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> update(Homework homework) async {
    try {
      return await _db.update(
        DbTables.homeworks,
        homework.toMap(),
        where: '${DbCols.id} = ?',
        whereArgs: [homework.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    try {
      return await _db.delete(
        DbTables.homeworks,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Mark as submitted.
  Future<int> submit(int id) async {
    try {
      final hw = await getById(id);
      if (hw == null) return 0;
      return await update(hw.copyWith(isSubmitted: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteAll() async {
    try {
      return await _db.delete(DbTables.homeworks);
    } catch (e) {
      rethrow;
    }
  }
}

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  final db = ref.watch(databaseProvider).valueOrNull;
  if (db == null) throw StateError('Database not initialized');
  return HomeworkRepository(db);
});