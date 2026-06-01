import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_constants.dart';
import '../models/task.dart';
import '../providers/database_provider.dart';

class TaskRepository {
  final Database _db;

  TaskRepository(this._db);

  /// Insert a task. Returns the new id.
  Future<int> insert(Task task) async {
    try {
      return await _db.insert(DbTables.tasks, task.toMap()..remove('id'));
    } catch (e) {
      rethrow;
    }
  }

  /// Get all tasks for a specific date, sorted by time (nulls last).
  Future<List<Task>> getByDate(String date) async {
    try {
      final results = await _db.query(
        DbTables.tasks,
        where: '${DbCols.date} = ?',
        whereArgs: [date],
        orderBy:
        "CASE WHEN ${DbCols.time} IS NULL THEN 1 ELSE 0 END, ${DbCols.time} ASC",
      );
      return results.map((m) => Task.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all tasks.
  Future<List<Task>> getAll() async {
    try {
      final results = await _db.query(DbTables.tasks);
      return results.map((m) => Task.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single task by id.
  Future<Task?> getById(int id) async {
    try {
      final results = await _db.query(
        DbTables.tasks,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) return null;
      return Task.fromMap(results.first);
    } catch (e) {
      rethrow;
    }
  }

  /// Update a task. Returns number of rows affected.
  Future<int> update(Task task) async {
    try {
      return await _db.update(
        DbTables.tasks,
        task.toMap(),
        where: '${DbCols.id} = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a task by id.
  Future<int> delete(int id) async {
    try {
      return await _db.delete(
        DbTables.tasks,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all tasks for a specific date.
  Future<int> deleteByDate(String date) async {
    try {
      return await _db.delete(
        DbTables.tasks,
        where: '${DbCols.date} = ?',
        whereArgs: [date],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Nuke all tasks.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(DbTables.tasks);
    } catch (e) {
      rethrow;
    }
  }

  /// Bulk insert (for plan deployment).
  Future<void> bulkInsert(List<Task> tasks) async {
    try {
      final batch = _db.batch();
      for (final task in tasks) {
        batch.insert(DbTables.tasks, task.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle complete status.
  Future<int> toggleComplete(int id) async {
    try {
      final task = await getById(id);
      if (task == null) return 0;
      return await update(task.copyWith(isComplete: !task.isComplete));
    } catch (e) {
      rethrow;
    }
  }
}

/// Riverpod provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider).valueOrNull;
  if (db == null) throw StateError('Database not initialized');
  return TaskRepository(db);
});