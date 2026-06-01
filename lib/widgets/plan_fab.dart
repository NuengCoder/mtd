import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../providers/plan_providers.dart';
import '../screens/create_plan_screen.dart';
import 'plan_card.dart';

class PlanFab extends ConsumerStatefulWidget {
  final String selectedDate;
  const PlanFab({super.key, required this.selectedDate});

  @override
  ConsumerState<PlanFab> createState() => _PlanFabState();
}

class _PlanFabState extends ConsumerState<PlanFab> {
  double _fabX = -1;
  double _fabY = -1;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        if (_fabX < 0) {
          _fabX = w - 72;
          _fabY = h - 140;
        }

        return Stack(
          children: [
            Positioned(
              left: _fabX,
              top: _fabY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _isDragging = true;
                    _fabX =
                        (_fabX + details.delta.dx).clamp(0.0, w - 56);
                    _fabY =
                        (_fabY + details.delta.dy).clamp(0.0, h - 56);
                  });
                },
                onPanEnd: (_) {
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted) {
                      setState(() => _isDragging = false);
                    }
                  });
                },
                child: FloatingActionButton.small(
                  heroTag: 'plan_fab',
                  onPressed: () {
                    if (_isDragging) return;
                    _showPlansPanel(context, tr);
                  },
                  child: const Icon(Icons.list_alt),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPlansPanel(
      BuildContext context, String Function(String) tr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
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
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                const CreatePlanScreen(),
                              ),
                            );
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
                          return Center(
                            child: Text(tr('no_tasks')),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: plans.length,
                          itemBuilder: (context, index) {
                            return PlanCard(
                              plan: plans[index],
                              selectedDate: widget.selectedDate,
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Center(child: Text('${tr('error')}: $e')),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}