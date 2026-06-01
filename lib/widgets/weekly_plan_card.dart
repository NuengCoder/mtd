import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_plan.dart';
import '../providers/language_provider.dart';
import '../providers/weekly_plan_providers.dart';
import '../providers/task_providers.dart';
import '../providers/theme_provider.dart';
import '../repositories/weekly_plan_repository.dart';
import '../screens/create_weekly_plan_screen.dart';

class WeeklyPlanCard extends ConsumerWidget {
  final WeeklyPlan plan;
  final String selectedDate;
  final String selectedWeekday;

  const WeeklyPlanCard({
    super.key,
    required this.plan,
    required this.selectedDate,
    required this.selectedWeekday,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final tasksAsync = ref.watch(weeklyPlanTasksProvider(plan.id!));
    final tasks = tasksAsync.valueOrNull ?? [];
    final taskCount = tasks.length;

    // Theme
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? 'light';
    final colorsAsync = ref.watch(themeColorsProvider(themeMode));
    final colors = colorsAsync.valueOrNull ?? {};
    final taskTextColor = colors['App Task Text'] ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE6E1E5)
            : const Color(0xFF1A1A1A));

    // Count tasks per weekday (db uses short codes)
    final counts = <String, int>{};
    for (final d in ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun', 'all']) {
      counts[d] = tasks.where((t) => t.weekday == d).length;
    }

    // Map for display: translation key -> db short code
    final weekdayMap = [
      {'key': 'monday', 'db': 'mon'},
      {'key': 'tuesday', 'db': 'tue'},
      {'key': 'wednesday', 'db': 'wed'},
      {'key': 'thursday', 'db': 'thu'},
      {'key': 'friday', 'db': 'fri'},
      {'key': 'saturday', 'db': 'sat'},
      {'key': 'sunday', 'db': 'sun'},
      {'key': 'all_days', 'db': 'all'},
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: plan.isSystem
                ? (plan.name.contains('Odd')
                ? const Color(0xFF00008B)
                : const Color(0xFF004040))
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: plan.isSystem
                ? Border.all(
              color: const Color(0xFF00FFFF),
              width: 2,
            )
                : null,
          ),
          child: Icon(
            plan.isSystem ? Icons.school : Icons.calendar_month,
            color: plan.isSystem
                ? const Color(0xFF00FFFF)
                : Colors.grey.shade700,
          ),
        ),
        title: Text(plan.name, style: TextStyle(color: taskTextColor)),
        subtitle: Text('$taskCount ${tr('tab_tasks')}',
            style: TextStyle(color: taskTextColor.withAlpha(180))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!plan.isSystem)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: tr('delete_plan'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(tr('delete_plan')),
                      content: Text(plan.name),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(tr('cancel')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(tr('yes')),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final repo = ref.read(weeklyPlanRepositoryProvider);
                    await repo.delete(plan.id!);
                    ref.invalidate(allWeeklyPlansProvider);
                  }
                },
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday chips with counts
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: weekdayMap
                      .map((d) => Chip(
                    label: Text(
                      '${tr(d['key']!)} (${counts[d['db']!] ?? 0})',
                      style: const TextStyle(fontSize: 10),
                    ),
                    materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                // Auto-deploy toggle
                SwitchListTile(
                  title: Text(tr('auto_deploy'),
                      style: const TextStyle(fontSize: 13)),
                  value: plan.autoDeploy,
                  onChanged: (_) {
                    ref.read(toggleWeeklyPlanAutoDeployProvider)(plan.id!);
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                // Manual deploy button
                FilledButton.icon(
                  onPressed: () async {
                    final deploy = ref.read(deployWeeklyPlanProvider);
                    final weekdays = [
                      'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'
                    ];
                    final now = DateTime.now();
                    int total = 0;
                    for (int i = 0; i < 7; i++) {
                      final date =
                      DateTime(now.year, now.month, now.day + i);
                      final dateStr =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final weekday = weekdays[date.weekday - 1];
                      total += await deploy(plan.id!, dateStr, weekday);
                    }
                    ref.invalidate(tasksForDateProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${tr('deploy_plan')}: $total ${tr('tab_tasks')}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.upload, size: 16),
                  label: Text(tr('manual_deploy')),
                ),
                const SizedBox(height: 4),
                // Edit button
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateWeeklyPlanScreen(planId: plan.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(tr('edit_task')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}