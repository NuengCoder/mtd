import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan.dart';
import '../models/plan_task.dart';
import '../models/task.dart';
import '../repositories/plan_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_sound_repository.dart';
import '../services/notification_service.dart';
import '../utils/duplicate_check.dart';
import 'notify_provider.dart';

/// All plans, sorted by name.
final allPlansProvider = FutureProvider<List<Plan>>((ref) async {
  final repo = ref.watch(planRepositoryProvider);
  return await repo.getAllPlans();
});

/// Plan tasks for a specific plan, sorted by time (nulls last).
final planTasksProvider =
FutureProvider.family<List<PlanTask>, int>((ref, planId) async {
  final repo = ref.watch(planRepositoryProvider);
  return await repo.getTasksByPlanId(planId);
});

/// Deploy a plan's tasks to a specific date in the task list.
final deployPlanProvider =
Provider<Future<void> Function(int planId, String date)>((ref) {
  final planRepo = ref.watch(planRepositoryProvider);
  final taskRepo = ref.read(taskRepositoryProvider);
  final notifyLeadProvider = ref.read(notifyLeadMinutesProvider);
  final soundRepo = ref.read(userSoundRepositoryProvider);
  return (int planId, String date) async {
    final planTasks = await planRepo.getTasksByPlanId(planId);

    // Preload sounds for all referenced soundIds
    final sounds = await soundRepo.getAll();

    // Get existing tasks for this date
    final existingTasks = await taskRepo.getByDate(date);

    final now = DateTime.now().toIso8601String();
    final leadMinutes = notifyLeadProvider.valueOrNull ?? 0;

    int deployed = 0;
    int skipped = 0;

    for (final pt in planTasks) {
      // Check for duplicate: same title AND same time on same date
      final isDuplicate = isDuplicateTask(existingTasks, pt.title, pt.time);

      if (isDuplicate) {
        skipped++;
        continue;
      }

      final task = Task(
        title: pt.title,
        date: date,
        time: pt.time,
        notifyTime: pt.notifyTime,
        imageId: pt.imageId,
        soundId: pt.soundId,
        isComplete: false,
        createdAt: now,
        updatedAt: now,
      );
      final newId = await taskRepo.insert(task);
      deployed++;

      // Schedule notification if task has time
      if (task.time != null) {
        String? soundUri;
        if (pt.soundId != null) {
          final snd = sounds.where((s) => s.id == pt.soundId).firstOrNull;
          soundUri = snd?.mediaUri;
        }
        NotificationService.scheduleTaskNotification(
          taskId: newId,
          taskTitle: task.title,
          date: task.date,
          time: task.time!,
          leadMinutes: leadMinutes,
          soundUri: soundUri,
        );
      }
    }

    debugPrint('[Deploy] plan=$planId deployed=$deployed skipped=$skipped');
  };
});