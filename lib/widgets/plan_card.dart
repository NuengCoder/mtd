import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan.dart';
import '../providers/language_provider.dart';
import '../providers/plan_providers.dart';
import '../providers/task_providers.dart';
import '../providers/theme_provider.dart';
import '../repositories/plan_repository.dart';
import '../screens/create_plan_screen.dart';

class PlanCard extends ConsumerWidget {
  final Plan plan;
  final String selectedDate;

  const PlanCard({
    super.key,
    required this.plan,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final tasksAsync = ref.watch(planTasksProvider(plan.id!));
    final taskCount = tasksAsync.valueOrNull?.length ?? 0;

    // Theme
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? 'light';
    final colorsAsync = ref.watch(themeColorsProvider(themeMode));
    final colors = colorsAsync.valueOrNull ?? {};
    final taskTextColor = colors['App Task Text'] ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE6E1E5)
            : const Color(0xFF1A1A1A));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.list_alt),
        title: Text(plan.name, style: TextStyle(color: taskTextColor)),
        subtitle: Text('$taskCount ${tr('tab_tasks')}',
            style: TextStyle(color: taskTextColor.withAlpha(180))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.upload, size: 20),
              tooltip: tr('deploy_plan'),
              onPressed: () async {
                final deploy = ref.read(deployPlanProvider);
                await deploy(plan.id!, selectedDate);
                ref.invalidate(tasksForDateProvider(selectedDate));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                        Text('${tr('deploy_plan')}: ${plan.name}')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: tr('edit_plan_name'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreatePlanScreen(planId: plan.id),
                  ),
                );
              },
            ),
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
                  final repo = ref.read(planRepositoryProvider);
                  await repo.deletePlan(plan.id!);
                  ref.invalidate(allPlansProvider);
                }
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreatePlanScreen(planId: plan.id),
            ),
          );
        },
      ),
    );
  }
}