import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/language_provider.dart';
import '../repositories/task_repository.dart';
import '../providers/task_providers.dart';
import '../providers/notify_provider.dart';
import '../services/notification_service.dart';

class TaskFab extends ConsumerStatefulWidget {
  final String selectedDate;
  const TaskFab({super.key, required this.selectedDate});

  @override
  ConsumerState<TaskFab> createState() => _TaskFabState();
}

class _TaskFabState extends ConsumerState<TaskFab> {
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
          _fabY = h - 80;
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
                    _fabX = (_fabX + details.delta.dx).clamp(0.0, w - 56);
                    _fabY = (_fabY + details.delta.dy).clamp(0.0, h - 56);
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
                  heroTag: 'task_fab',
                  onPressed: () {
                    if (_isDragging) return;
                    _showAddTaskDialog(context, tr);
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, String Function(String) tr) {
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

                final task = Task(
                  title: title,
                  date: widget.selectedDate,
                  time: selectedTime != null
                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                      : null,
                  isComplete: false,
                  createdAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                );

                try {
                  final repo = ref.read(taskRepositoryProvider);
                  final newId = await repo.insert(task);

                  debugPrint('TASK_FAB: inserted id=$newId, time="${task.time}", date="${task.date}"');

                  // Schedule notification if task has a time
                  if (task.time != null) {
                    final leadMinutesAsync =
                    ref.read(notifyLeadMinutesProvider);
                    final leadMinutes =
                        leadMinutesAsync.valueOrNull ?? 0;
                    debugPrint('TASK_FAB: scheduling notification, leadMinutes=$leadMinutes');
                    NotificationService.scheduleTaskNotification(
                      taskId: newId,
                      taskTitle: task.title,
                      date: task.date,
                      time: task.time!,
                      leadMinutes: leadMinutes,
                    );
                  } else {
                    debugPrint('TASK_FAB: no time set, skipping notification');
                  }

                  ref.invalidate(tasksForDateProvider(widget.selectedDate));
                } catch (e, stack) {
                  debugPrint('TASK_FAB ERROR: $e');
                  debugPrint('TASK_FAB STACK: $stack');
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
}