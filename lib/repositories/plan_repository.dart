import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_constants.dart';
import '../models/plan.dart';
import '../models/plan_task.dart';
import '../providers/database_provider.dart';

class PlanRepository {
  final Database _db;

  PlanRepository(this._db);

  // ─── Plans ───────────────────────────────────

  Future<int> insertPlan(Plan plan) async {
    try {
      return await _db.insert(DbTables.plans, plan.toMap()..remove('id'));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Plan>> getAllPlans() async {
    try {
      final results = await _db.query(DbTables.plans, orderBy: '${DbCols.name} ASC');
      return results.map((m) => Plan.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Plan?> getPlanById(int id) async {
    try {
      final results = await _db.query(
        DbTables.plans,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) return null;
      return Plan.fromMap(results.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> updatePlan(Plan plan) async {
    try {
      return await _db.update(
        DbTables.plans,
        plan.toMap(),
        where: '${DbCols.id} = ?',
        whereArgs: [plan.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deletePlan(int id) async {
    try {
      // Plan tasks cascade-delete via FK
      return await _db.delete(
        DbTables.plans,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  // ─── Plan Tasks ──────────────────────────────

  Future<int> insertPlanTask(PlanTask task) async {
    try {
      return await _db.insert(DbTables.planTasks, task.toMap()..remove('id'));
    } catch (e) {
      rethrow;
    }
  }

  /// Get tasks for a plan, sorted by time (nulls last).
  Future<List<PlanTask>> getTasksByPlanId(int planId) async {
    try {
      final results = await _db.query(
        DbTables.planTasks,
        where: '${DbCols.planId} = ?',
        whereArgs: [planId],
        orderBy:
        "CASE WHEN ${DbCols.time} IS NULL THEN 1 ELSE 0 END, ${DbCols.time} ASC",
      );
      return results.map((m) => PlanTask.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<PlanTask?> getPlanTaskById(int id) async {
    try {
      final results = await _db.query(
        DbTables.planTasks,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) return null;
      return PlanTask.fromMap(results.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> updatePlanTask(PlanTask task) async {
    try {
      return await _db.update(
        DbTables.planTasks,
        task.toMap(),
        where: '${DbCols.id} = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deletePlanTask(int id) async {
    try {
      return await _db.delete(
        DbTables.planTasks,
        where: '${DbCols.id} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Bulk insert tasks into a plan.
  Future<void> bulkInsertTasks(List<PlanTask> tasks) async {
    try {
      final batch = _db.batch();
      for (final task in tasks) {
        batch.insert(DbTables.planTasks, task.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteAllPlanTasks(int planId) async {
    try {
      return await _db.delete(
        DbTables.planTasks,
        where: '${DbCols.planId} = ?',
        whereArgs: [planId],
      );
    } catch (e) {
      rethrow;
    }
  }
}

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final db = ref.watch(databaseProvider).valueOrNull;
  if (db == null) throw StateError('Database not initialized');
  return PlanRepository(db);
});