import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan.dart';
import '../providers/language_provider.dart';
import '../providers/plan_providers.dart';
import '../repositories/plan_repository.dart';
import '../screens/create_plan_screen.dart';
import 'plan_card.dart';

class PlanListPanel extends ConsumerWidget {
  final String selectedDate;
  const PlanListPanel({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final plansAsync = ref.watch(allPlansProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(tr('plans'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final tr = ref.read(trProvider);
                      final nameController = TextEditingController();

                      final name = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(tr('create_plan')),
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
                                final text = nameController.text.trim();
                                if (text.isNotEmpty) Navigator.pop(ctx, text);
                              },
                              child: Text(tr('add')),
                            ),
                          ],
                        ),
                      );

                      if (name != null && name.isNotEmpty && context.mounted) {
                        final repo = ref.read(planRepositoryProvider);
                        try {
                          final plan = Plan(
                            name: name,
                            createdAt: DateTime.now().toIso8601String(),
                            updatedAt: DateTime.now().toIso8601String(),
                          );
                          final id = await repo.insertPlan(plan);
                          ref.invalidate(allPlansProvider);
                          if(!context.mounted) return;
                          // Close bottom sheet
                          Navigator.pop(context);

                          // Navigate to create plan screen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreatePlanScreen(planId: id),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${tr('plan_name')} "$name" ${tr('error')}'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(tr('create_plan')),
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
                      return PlanCard(
                        plan: plans[index],
                        selectedDate: selectedDate,
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