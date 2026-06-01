import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

/// Fetches tasks for a specific date.
/// Used by both task_screen and task_fab.
final tasksForDateProvider =
FutureProvider.family<List<Task>, String>((ref, date) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getByDate(date);
});

/// Fetches all tasks (for reschedule, nuke, etc.)
final allTasksProvider = FutureProvider<List<Task>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getAll();
});