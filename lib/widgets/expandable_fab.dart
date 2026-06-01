import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/language_provider.dart';
import '../providers/task_providers.dart';
import '../providers/notify_provider.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';
import '../utils/duplicate_check.dart';
import 'plan_list_panel.dart';
import 'weekly_plan_list_panel.dart';
import '../screens/timetable_screen.dart';

class ExpandableFab extends ConsumerStatefulWidget {
  final String selectedDate;
  const ExpandableFab({super.key, required this.selectedDate});

  @override
  ConsumerState<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends ConsumerState<ExpandableFab>
    with SingleTickerProviderStateMixin {
  double _fabX = -1;
  double _fabY = -1;
  bool _isDragging = false;
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        if (_fabX < 0) {
          _fabX = w - 72;
          _fabY = h - 80;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Plan action button (top)
            if (_isExpanded)
              Positioned(
                right: w - _fabX - 56 + 4,
                top: _fabY - 120,
                child: Row(
                  children: [
                    Text(tr('plans'),
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _toggleExpand();
                        _showPlansPanel(context, tr);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.list_alt, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isExpanded)
              Positioned(
                right: w - _fabX - 56 + 4,
                top: _fabY - 64,
                child: Row(
                  children: [
                    Text(tr('tab_tasks'),
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _toggleExpand();
                        _showAddTaskDialog(context, tr);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.task_alt, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            // Weekly Plan action button (top)
            if (_isExpanded)
              Positioned(
                right: w - _fabX - 56 + 4,
                top: _fabY - 176,
                child: Row(
                  children: [
                    Text(tr('weekly_plans'),
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _toggleExpand();
                        _showWeeklyPlansPanel(context, tr);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_month, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            // Timetable button (top)
            if (_isExpanded)
              Positioned(
                right: w - _fabX - 56 + 4,
                top: _fabY - 232,
                child: Row(
                  children: [
                    Text(tr('timetable'),
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _toggleExpand();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TimetableScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.grid_on, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

            // Main FAB
            Positioned(
              left: _fabX,
              top: _fabY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (_isExpanded) return;
                  setState(() {
                    _isDragging = true;
                    _fabX = (_fabX + details.delta.dx)
                        .clamp(0.0, w - 56);
                    _fabY = (_fabY + details.delta.dy)
                        .clamp(0.0, h - 56);
                  });
                },
                onPanEnd: (_) {
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted) {
                      setState(() => _isDragging = false);
                    }
                  });
                },
                child: FloatingActionButton(
                  heroTag: 'expandable_fab',
                  onPressed: () {
                    if (_isDragging) return;
                    _toggleExpand();
                  },
                  child: RotationTransition(
                    turns: _rotateAnimation,
                    child: const Icon(Icons.close),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog(
      BuildContext context, String Function(String) tr) {
    final titleController = TextEditingController();
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('add_task')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: tr('task_title'),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(selectedTime != null
                      ? selectedTime!.format(ctx)
                      : tr('no_time')),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setDialogState(() => selectedTime = time);
                      }
                    },
                    child: Text(tr('task_time')),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final timeStr = selectedTime != null
                    ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                    : null;

                // Duplicate check
                final repo = ref.read(taskRepositoryProvider);
                final existingTasks =
                await repo.getByDate(widget.selectedDate);
                if (isDuplicateTask(existingTasks, title, timeStr)) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Duplicate task!')),
                    );
                  }
                  return;
                }

                final task = Task(
                  title: title,
                  date: widget.selectedDate,
                  time: timeStr,
                  isComplete: false,
                  createdAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                );

                try {
                  final repo = ref.read(taskRepositoryProvider);
                  final newId = await repo.insert(task);

                  if (task.time != null) {
                    final leadMinutesAsync =
                    ref.read(notifyLeadMinutesProvider);
                    final leadMinutes =
                        leadMinutesAsync.valueOrNull ?? 0;
                    NotificationService.scheduleTaskNotification(
                      taskId: newId,
                      taskTitle: task.title,
                      date: task.date,
                      time: task.time!,
                      leadMinutes: leadMinutes,
                    );
                  }

                  ref.invalidate(
                      tasksForDateProvider(widget.selectedDate));
                } catch (e) {
                  // Handle error
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(tr('add')),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlansPanel(
      BuildContext context, String Function(String) tr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => PlanListPanel(selectedDate: widget.selectedDate),
    );
  }

  void _showWeeklyPlansPanel(
      BuildContext context, String Function(String) tr) {
    // Get the current weekday from the selected date
    final date = DateTime.parse(widget.selectedDate);
    final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final weekday = weekdays[date.weekday - 1];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => WeeklyPlanListPanel(
        selectedDate: widget.selectedDate,
        selectedWeekday: weekday,
      ),
    );
  }
}