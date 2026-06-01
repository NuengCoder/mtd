import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/weekly_plan_task.dart';
import '../repositories/weekly_plan_repository.dart';
import '../repositories/settings_repository.dart';

class TimetableData {
  final List<String> weekdays;
  final List<String> timeSlots;
  final Map<String, Map<String, List<WeeklyPlanTask>>> grid;

  const TimetableData({
    required this.weekdays,
    required this.timeSlots,
    required this.grid,
  });
}

final timetableProvider =
FutureProvider.family<TimetableData, int>((ref, weekOffset) async {
  final wpRepo = ref.watch(weeklyPlanRepositoryProvider);
  final settingsRepo = ref.read(settingsRepositoryProvider);
  final allTasks = <WeeklyPlanTask>[];

  // Get week type
  final flippedStr = await settingsRepo.getValue('week_type_flipped');
  final flipped = flippedStr == '1';
  final now = DateTime.now().add(Duration(days: weekOffset * 7));
  final dayOfYear = int.parse(DateFormat('D').format(now));
  final isoWeek = ((dayOfYear - now.weekday + 10) / 7).floor();
  final isOddWeek = isoWeek % 2 != 0;
  final effectiveOdd = flipped ? !isOddWeek : isOddWeek;

  final plans = await wpRepo.getAll();
  for (final plan in plans) {
    // Skip system plans that don't match week type
    if (plan.isSystem) {
      if (plan.name == 'Class (Odd)' && !effectiveOdd) continue;
      if (plan.name == 'Class (Even)' && effectiveOdd) continue;
    }
    final tasks = await wpRepo.getTasksByPlanId(plan.id!);
    allTasks.addAll(tasks);
  }

  final timedTasks = allTasks.where((t) => t.time != null).toList();

  final timeSet = <String>{};
  for (final task in timedTasks) {
    timeSet.add(task.time!);
  }
  final timeSlots = timeSet.toList()..sort();

  const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  final grid = <String, Map<String, List<WeeklyPlanTask>>>{};
  for (final wd in weekdays) {
    grid[wd] = {};
    for (final ts in timeSlots) {
      grid[wd]![ts] = [];
    }
  }

  for (final task in timedTasks) {
    final wd = task.weekday;
    if (wd == 'all') {
      for (final d in weekdays) {
        _addTask(grid[d]!, task);
      }
    } else if (grid.containsKey(wd)) {
      _addTask(grid[wd]!, task);
    }
  }

  for (final wd in weekdays) {
    for (final ts in timeSlots) {
      grid[wd]![ts]!.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    }
  }

  return TimetableData(
    weekdays: weekdays,
    timeSlots: timeSlots,
    grid: grid,
  );
});

void _addTask(Map<String, List<WeeklyPlanTask>> dayGrid, WeeklyPlanTask task) {
  if (task.time == null) return;
  if (dayGrid.containsKey(task.time!)) {
    dayGrid[task.time!]!.add(task);
  } else {
    dayGrid[task.time!] = [task];
  }
}