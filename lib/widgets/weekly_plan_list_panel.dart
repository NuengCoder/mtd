import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_plan.dart';
import '../providers/language_provider.dart';
import '../providers/weekly_plan_providers.dart';
import '../providers/task_providers.dart';
import '../repositories/weekly_plan_repository.dart';
import '../screens/create_weekly_plan_screen.dart';
import '../services/notification_service.dart';
import 'weekly_plan_card.dart';

class WeeklyPlanListPanel extends ConsumerWidget {
  final String selectedDate;
  final String selectedWeekday;

  const WeeklyPlanListPanel({
    super.key,
    required this.selectedDate,
    required this.selectedWeekday,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final plansAsync = ref.watch(allWeeklyPlansProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(tr('weekly_plans'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  // Deploy All button
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final deployAll =
                      ref.read(deployAllWeeklyPlansProvider);
                      final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
                      final now = DateTime.now();
                      int total = 0;
                      for (int i = 0; i < 7; i++) {
                        final date = DateTime(now.year, now.month, now.day + i);
                        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        final weekday = weekdays[date.weekday - 1];
                        total += await deployAll(dateStr, weekday);
                      }
                      // Invalidate all date providers
                      ref.invalidate(tasksForDateProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${tr('deploy_all')}: $total ${tr('tab_tasks')}')),
                        );
                      }
                    },
                    icon: const Icon(Icons.upload, size: 16),
                    label: Text(tr('deploy_all'),
                        style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.flash_on, size: 20),
                    tooltip: tr('auto_deploy_test'),
                    onPressed: () async {
                      final deployAuto = ref.read(deployAutoWeeklyPlansProvider);
                      final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
                      final now = DateTime.now();
                      int total = 0;
                      for (int i = 0; i < 7; i++) {
                        final date = DateTime(now.year, now.month, now.day + i);
                        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        final weekday = weekdays[date.weekday - 1];
                        total += await deployAuto(dateStr, weekday);
                      }
                      ref.invalidate(tasksForDateProvider);

                      NotificationService.showTestNotification(
                        id: 9999,
                        title: 'MyTodo',
                        body: 'Auto weekly deploy! ($total)',
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${tr('auto_deploy_test')}: $total ${tr('tab_tasks')}')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final tr = ref.read(trProvider);
                      final nameController = TextEditingController();

                      final name = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(tr('create_weekly_plan')),
                          content: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: tr('plan_name'),
                              border: const OutlineInputBorder(),
                            ),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(tr('cancel')),
                            ),
                            FilledButton(
                              onPressed: () {
                                final text =
                                nameController.text.trim();
                                if (text.isNotEmpty) {
                                  Navigator.pop(ctx, text);
                                }
                              },
                              child: Text(tr('add')),
                            ),
                          ],
                        ),
                      );

                      if (name != null && name.isNotEmpty && context.mounted) {
                        final repo = ref.read(weeklyPlanRepositoryProvider);
                        try {
                          final plan = WeeklyPlan(
                            name: name,
                            createdAt:
                            DateTime.now().toIso8601String(),
                            updatedAt:
                            DateTime.now().toIso8601String(),
                          );
                          final id = await repo.insert(plan);
                          ref.invalidate(allWeeklyPlansProvider);
                          if(!context.mounted) return;
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateWeeklyPlanScreen(
                                      planId: id),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '$name ${tr('error')}')),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(tr('create_weekly_plan')),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: plansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) {
                    return Center(child: Text(tr('no_tasks')));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      return WeeklyPlanCard(
                        plan: plans[index],
                        selectedDate: selectedDate,
                        selectedWeekday: selectedWeekday,
                      );
                    },
                  );
                },
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('${tr('error')}: $e')),
              ),
            ),
          ],
        );
      },
    );
  }
}