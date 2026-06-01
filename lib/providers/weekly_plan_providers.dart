import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_plan.dart';
import '../models/weekly_plan_task.dart';
import '../models/task.dart';
import '../repositories/settings_repository.dart';
import '../repositories/weekly_plan_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_sound_repository.dart';
import '../services/notification_service.dart';
import '../providers/notify_provider.dart';
import '../utils/duplicate_check.dart';
import 'package:intl/intl.dart';

/// All weekly plans.
final allWeeklyPlansProvider = FutureProvider<List<WeeklyPlan>>((ref) async {
  final repo = ref.watch(weeklyPlanRepositoryProvider);
  return await repo.getAll();
});

/// System weekly plans (Class Odd, Class Even).
final systemWeeklyPlansProvider = FutureProvider<List<WeeklyPlan>>((ref) async {
  final repo = ref.watch(weeklyPlanRepositoryProvider);
  return await repo.getSystemPlans();
});

/// Tasks for a specific weekly plan.
final weeklyPlanTasksProvider =
FutureProvider.family<List<WeeklyPlanTask>, int>((ref, planId) async {
  final repo = ref.watch(weeklyPlanRepositoryProvider);
  return await repo.getTasksByPlanId(planId);
});

/// Tasks for a weekly plan grouped by weekday.
final weeklyPlanTasksByWeekdayProvider =
FutureProvider.family<Map<String, List<WeeklyPlanTask>>, int>(
        (ref, planId) async {
      final repo = ref.watch(weeklyPlanRepositoryProvider);
      final tasks = await repo.getTasksByPlanId(planId);
      final map = <String, List<WeeklyPlanTask>>{};
      for (final t in tasks) {
        map.putIfAbsent(t.weekday, () => []).add(t);
      }
      // Sort each weekday list by time
      for (final list in map.values) {
        list.sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));
      }
      return map;
    });

/// Deploy a single weekly plan to a specific date.
final deployWeeklyPlanProvider =
Provider<Future<int> Function(int planId, String date, String weekday)>(
        (ref) {
      final wpRepo = ref.watch(weeklyPlanRepositoryProvider);
      final taskRepo = ref.read(taskRepositoryProvider);
      final leadProvider = ref.read(notifyLeadMinutesProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final soundRepo = ref.read(userSoundRepositoryProvider);
      return (int planId, String date, String weekday) async {
        final plan = await wpRepo.getById(planId);
        if (plan == null) return 0;

        // Check odd/even for system plans — read fresh from DB
        if (plan.isSystem) {
          final flippedStr = await settingsRepo.getValue('week_type_flipped');
          final flipped = flippedStr == '1';
          final dateObj = DateTime.parse(date);
          final dayOfYear = int.parse(DateFormat('D').format(dateObj));
          final isoWeek = ((dayOfYear - dateObj.weekday + 10) / 7).floor();
          final isOddWeek = isoWeek % 2 != 0;
          final effectiveOdd = flipped ? !isOddWeek : isOddWeek;

          if (plan.name == 'Class (Odd)' && !effectiveOdd) return 0;
          if (plan.name == 'Class (Even)' && effectiveOdd) return 0;
        }

        final tasks = await wpRepo.getTasksByPlanId(planId);
        final existingTasks = await taskRepo.getByDate(date);
        final leadMinutes = leadProvider.valueOrNull ?? 0;

        // Preload sounds
        final sounds = await soundRepo.getAll();

        final now = DateTime.now().toIso8601String();
        int deployed = 0;

        for (final wt in tasks) {
          if (wt.weekday != weekday && wt.weekday != 'all') continue;
          if (isDuplicateTask(existingTasks, wt.title, wt.time)) continue;

          final task = Task(
            title: wt.title,
            date: date,
            time: wt.time,
            notifyTime: wt.notifyTime,
            imageId: wt.imageId,
            soundId: wt.soundId,
            isComplete: false,
            createdAt: now,
            updatedAt: now,
          );
          final newId = await taskRepo.insert(task);
          deployed++;

          if (task.time != null) {
            String? soundUri;
            if (wt.soundId != null) {
              final snd = sounds.where((s) => s.id == wt.soundId).firstOrNull;
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
        return deployed;
      };
    });

/// Deploy ALL weekly plans (for "Deploy All" button and auto-deploy).
final deployAllWeeklyPlansProvider =
Provider<Future<int> Function(String date, String weekday)>((ref) {
  final deploy = ref.read(deployWeeklyPlanProvider);
  final wpRepo = ref.read(weeklyPlanRepositoryProvider);
  return (String date, String weekday) async {
    final allPlans = await wpRepo.getAll();
    int total = 0;
    for (final plan in allPlans) {
      total += await deploy(plan.id!, date, weekday);
    }
    debugPrint('[WeeklyDeployAll] date=$date weekday=$weekday total=$total');
    return total;
  };
});

final deployAutoWeeklyPlansProvider =
Provider<Future<int> Function(String date, String weekday)>((ref) {
  final deploy = ref.read(deployWeeklyPlanProvider);
  final wpRepo = ref.read(weeklyPlanRepositoryProvider);
  return (String date, String weekday) async {
    final allPlans = await wpRepo.getAll();
    int total = 0;
    for (final plan in allPlans) {
      if (!plan.autoDeploy) continue;
      total += await deploy(plan.id!, date, weekday);
    }
    debugPrint('[WeeklyAutoDeploy] date=$date weekday=$weekday total=$total');
    return total;
  };
});

/// Toggle auto_deploy on a weekly plan.
final toggleWeeklyPlanAutoDeployProvider =
Provider<Future<void> Function(int planId)>((ref) {
  final repo = ref.read(weeklyPlanRepositoryProvider);
  return (int planId) async {
    await repo.toggleAutoDeploy(planId);
    ref.invalidate(allWeeklyPlansProvider);
  };
});