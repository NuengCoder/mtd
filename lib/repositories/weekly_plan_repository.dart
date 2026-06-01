import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_constants.dart';
import '../models/weekly_plan.dart';
import '../models/weekly_plan_task.dart';
import '../providers/database_provider.dart';

class WeeklyPlanRepository {
  final Database _db;

  WeeklyPlanRepository(this._db);

  // ─── Weekly Plans ────────────────────────────

  Future<int> insert(WeeklyPlan plan) async {
    try {
      return await _db.insert(DbTables.weeklyPlans, plan.toMap()..remove('id'));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<WeeklyPlan>> getAll() async {
    try {
      final results = await _db.query(DbTables.weeklyPlans);
      return results.map((m) => WeeklyPlan.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<WeeklyPlan?> getById(int id) async {
    try {
      final results = await _db.query(
        DbTables.weeklyPlans,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) return null;
      return WeeklyPlan.fromMap(results.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<WeeklyPlan?> getByName(String name) async {
    try {
      final results = await _db.query(
        DbTables.weeklyPlans,
        where: '${DbCols.name} = ?',
        whereArgs: [name],
      );
      if (results.isEmpty) return null;
      return WeeklyPlan.fromMap(results.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> update(WeeklyPlan plan) async {
    try {
      return await _db.update(
        DbTables.weeklyPlans,
        plan.toMap(),
        where: '${DbCols.id} = ?',
        whereArgs: [plan.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Only non-system plans can be deleted.
  Future<int> delete(int id) async {
    try {
      final plan = await getById(id);
      if (plan == null || plan.isSystem) return 0;
      return await _db.delete(
        DbTables.weeklyPlans,
        where: '${DbCols.id} = ? AND ${DbCols.isSystem} = 0',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get system plans (Class Odd, Class Even).
  Future<List<WeeklyPlan>> getSystemPlans() async {
    try {
      final results = await _db.query(
        DbTables.weeklyPlans,
        where: '${DbCols.isSystem} = ?',
        whereArgs: [1],
      );
      return results.map((m) => WeeklyPlan.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get plans with auto_deploy enabled.
  Future<List<WeeklyPlan>> getAutoDeployPlans() async {
    try {
      final results = await _db.query(
        DbTables.weeklyPlans,
        where: '${DbCols.autoDeploy} = ?',
        whereArgs: [1],
      );
      return results.map((m) => WeeklyPlan.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle auto_deploy.
  Future<int> toggleAutoDeploy(int id) async {
    try {
      final plan = await getById(id);
      if (plan == null) return 0;
      return await update(plan.copyWith(autoDeploy: !plan.autoDeploy));
    } catch (e) {
      rethrow;
    }
  }

  // ─── Weekly Plan Tasks ───────────────────────

  Future<int> insertTask(WeeklyPlanTask task) async {
    try {
      return await _db.insert(DbTables.weeklyPlanTasks, task.toMap()..remove('id'));
    } catch (e) {
      rethrow;
    }
  }

  /// Get tasks for a weekly plan, sorted by time (nulls last).
  Future<List<WeeklyPlanTask>> getTasksByPlanId(int weeklyPlanId) async {
    try {
      final results = await _db.query(
        DbTables.weeklyPlanTasks,
        where: '${DbCols.weeklyPlanId} = ?',
        whereArgs: [weeklyPlanId],
        orderBy:
        "CASE WHEN ${DbCols.time} IS NULL THEN 1 ELSE 0 END, ${DbCols.time} ASC",
      );
      return results.map((m) => WeeklyPlanTask.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get tasks for a specific weekday across all weekly plans.
  Future<List<WeeklyPlanTask>> getTasksByWeekday(String weekday) async {
    try {
      final results = await _db.query(
        DbTables.weeklyPlanTasks,
        where: '${DbCols.weekday} = ? OR ${DbCols.weekday} = ?',
        whereArgs: [weekday, 'all'],
        orderBy:
        "CASE WHEN ${DbCols.time} IS NULL THEN 1 ELSE 0 END, ${DbCols.time} ASC",
      );
      return results.map((m) => WeeklyPlanTask.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<WeeklyPlanTask?> getTaskById(int id) async {
    try {
      final results = await _db.query(
        DbTables.weeklyPlanTasks,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) return null;
      return WeeklyPlanTask.fromMap(results.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> updateTask(WeeklyPlanTask task) async {
    try {
      return await _db.update(
        DbTables.weeklyPlanTasks,
        task.toMap(),
        where: '${DbCols.id} = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteTask(int id) async {
    try {
      return await _db.delete(
        DbTables.weeklyPlanTasks,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> bulkInsertTasks(List<WeeklyPlanTask> tasks) async {
    try {
      final batch = _db.batch();
      for (final task in tasks) {
        batch.insert(DbTables.weeklyPlanTasks, task.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);
    } catch (e) {
      rethrow;
    }
  }
}

final weeklyPlanRepositoryProvider = Provider<WeeklyPlanRepository>((ref) {
  final db = ref.watch(databaseProvider).valueOrNull;
  if (db == null) throw StateError('Database not initialized');
  return WeeklyPlanRepository(db);
});