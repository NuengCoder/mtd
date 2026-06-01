import 'dart:math';
import 'dart:io' as dart_io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/language_provider.dart';
import '../repositories/task_repository.dart';
import '../providers/task_providers.dart';
import '../providers/notify_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/media_providers.dart';
import '../services/notification_service.dart';

class TaskCard extends ConsumerWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  Color _randomColor(String title) {
    if (title.isEmpty) return Colors.grey;
    final hash = title.codeUnits.fold(0, (sum, c) => sum + c);
    final random = Random(hash);
    return Color.fromARGB(
      255,
      random.nextInt(200) + 30,
      random.nextInt(200) + 30,
      random.nextInt(200) + 30,
    );
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}...' : s;

  Future<String?> _getSoundUri(WidgetRef ref, int? soundId) async {
    if (soundId == null) return null;
    final soundsAsync = ref.read(allUserSoundsProvider);
    final sounds = soundsAsync.valueOrNull ?? [];
    final snd = sounds.where((s) => s.id == soundId).firstOrNull;
    return snd?.mediaUri;
  }

  Future<void> _rescheduleNotification(WidgetRef ref, int? soundId) async {
    if (task.time == null || task.isComplete) return;
    final leadMinutesAsync = ref.read(notifyLeadMinutesProvider);
    final leadMinutes = leadMinutesAsync.valueOrNull ?? 0;
    final soundUri = await _getSoundUri(ref, soundId);

    NotificationService.scheduleTaskNotification(
      taskId: task.id!,
      taskTitle: task.title,
      date: task.date,
      time: task.time!,
      leadMinutes: leadMinutes,
      soundUri: soundUri,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final hasImage = task.imageId != null;

    // Theme
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? 'light';
    final colorsAsync = ref.watch(themeColorsProvider(themeMode));
    final colors = colorsAsync.valueOrNull ?? {};
    final taskTextColor = colors['App Task Text'] ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE6E1E5)
            : const Color(0xFF1A1A1A));

    // Get image file path if set
    String? imagePath;
    if (hasImage) {
      final imagesAsync = ref.watch(allUserImagesProvider);
      final images = imagesAsync.valueOrNull ?? [];
      final img = images.where((i) => i.id == task.imageId).firstOrNull;
      if (img != null) imagePath = img.filePath;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (hasImage && imagePath != null) ? null : _randomColor(task.title),
          backgroundImage: (hasImage && imagePath != null)
              ? FileImage(dart_io.File(imagePath))
              : null,
          child: (hasImage && imagePath != null)
              ? null
              : Text(
                  task.title.isNotEmpty
                      ? task.title[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isComplete ? TextDecoration.lineThrough : null,
            color: task.isComplete ? Colors.grey : taskTextColor,
          ),
        ),
        subtitle: Text(
          task.time ?? tr('no_time'),
          style: TextStyle(fontSize: 13, color: taskTextColor.withAlpha(180)),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          onSelected: (value) async {
            final repo = ref.read(taskRepositoryProvider);
            final currentDate = task.date;

            switch (value) {
              case 'complete':
                await repo.toggleComplete(task.id!);
                if (task.time != null) {
                  NotificationService.cancelNotification(task.id!);
                }
                ref.invalidate(tasksForDateProvider(currentDate));
                break;
              case 'time':
                _showSetTimeDialog(context, ref, tr);
                break;
              case 'edit':
                _showEditDialog(context, ref, tr);
                break;
              case 'image':
                _showImagePicker(context, ref, tr);
                break;
              case 'sound':
                _showSoundPicker(context, ref, tr);
                break;
              case 'delete':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr('delete_task')),
                    content: Text(task.title),
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
                  await repo.delete(task.id!);
                  if (task.time != null) {
                    NotificationService.cancelNotification(task.id!);
                  }
                  ref.invalidate(tasksForDateProvider(currentDate));
                }
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'complete',
              child: Row(
                children: [
                  Icon(
                    task.isComplete
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(tr('mark_complete')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'time',
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 20),
                  SizedBox(width: 8),
                  Text(tr('set_time')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text(tr('edit_task')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'image',
              child: Row(
                children: [
                  const Icon(Icons.image, size: 20),
                  const SizedBox(width: 8),
                  Text(task.imageId != null ? 'Change Image' : tr('select_image')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'sound',
              child: Row(
                children: [
                  const Icon(Icons.music_note, size: 20),
                  const SizedBox(width: 8),
                  Text(task.soundId != null ? 'Change Sound' : tr('select_sound')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(tr('delete_task'),
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetTimeDialog(
      BuildContext context, WidgetRef ref, String Function(String) tr) {
    TimeOfDay? selectedTime;
    if (task.time != null) {
      final parts = task.time!.split(':');
      selectedTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('set_time')),
          content: Row(
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
              TextButton(
                onPressed: () => setDialogState(() => selectedTime = null),
                child: const Text('✕'),
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
                final updatedTask = task.copyWith(
                  time: selectedTime != null
                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                      : null,
                  updatedAt: DateTime.now().toIso8601String(),
                );

                try {
                  final repo = ref.read(taskRepositoryProvider);
                  await repo.update(updatedTask);
                  ref.invalidate(tasksForDateProvider(task.date));

                  if (updatedTask.time != null && !updatedTask.isComplete) {
                    final leadMinutesAsync =
                        ref.read(notifyLeadMinutesProvider);
                    final leadMinutes = leadMinutesAsync.valueOrNull ?? 0;
                    final soundUri = await _getSoundUri(ref, task.soundId);
                    NotificationService.scheduleTaskNotification(
                      taskId: updatedTask.id!,
                      taskTitle: updatedTask.title,
                      date: updatedTask.date,
                      time: updatedTask.time!,
                      leadMinutes: leadMinutes,
                      soundUri: soundUri,
                    );
                  } else if (updatedTask.time == null) {
                    NotificationService.cancelNotification(updatedTask.id!);
                  }
                } catch (_) {}

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, String Function(String) tr) {
    final titleController = TextEditingController(text: task.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('edit_task')),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: tr('task_title'),
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
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final updatedTask = task.copyWith(
                title: title,
                updatedAt: DateTime.now().toIso8601String(),
              );

              try {
                final repo = ref.read(taskRepositoryProvider);
                await repo.update(updatedTask);
                ref.invalidate(tasksForDateProvider(task.date));

                if (updatedTask.time != null && !updatedTask.isComplete) {
                  final leadMinutesAsync =
                      ref.read(notifyLeadMinutesProvider);
                  final leadMinutes = leadMinutesAsync.valueOrNull ?? 0;
                  final soundUri = await _getSoundUri(ref, task.soundId);
                  NotificationService.scheduleTaskNotification(
                    taskId: updatedTask.id!,
                    taskTitle: updatedTask.title,
                    date: updatedTask.date,
                    time: updatedTask.time!,
                    leadMinutes: leadMinutes,
                    soundUri: soundUri,
                  );
                }
              } catch (_) {}

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  void _showImagePicker(
      BuildContext context, WidgetRef ref, String Function(String) tr) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final imagesAsync = ref.watch(allUserImagesProvider);
          final images = imagesAsync.valueOrNull ?? [];

          return AlertDialog(
            title: Text(tr('select_image')),
            content: SizedBox(
              width: double.maxFinite,
              child: images.isEmpty
                  ? Text(tr('no_image'))
                  : GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: images.length + 1,
                      itemBuilder: (context, index) {
                        if (index == images.length) {
                          return GestureDetector(
                            onTap: () async {
                              final repo = ref.read(taskRepositoryProvider);
                              await repo.update(task.copyWith(
                                imageId: null,
                                updatedAt: DateTime.now().toIso8601String(),
                              ));
                              ref.invalidate(tasksForDateProvider(task.date));
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.remove_circle, color: Colors.red, size: 32),
                                  Text('Remove', style: TextStyle(color: Colors.red, fontSize: 10)),
                                ],
                              ),
                            ),
                          );
                        }

                        final img = images[index];
                        final file = dart_io.File(img.filePath);
                        final isSelected = task.imageId == img.id;

                        return GestureDetector(
                          onTap: () async {
                            final repo = ref.read(taskRepositoryProvider);
                            await repo.update(task.copyWith(
                              imageId: img.id,
                              updatedAt: DateTime.now().toIso8601String(),
                            ));
                            ref.invalidate(tasksForDateProvider(task.date));
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: file.existsSync()
                                  ? Image.file(file, fit: BoxFit.cover)
                                  : const Icon(Icons.broken_image),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('cancel')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSoundPicker(
      BuildContext context, WidgetRef ref, String Function(String) tr) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final soundsAsync = ref.watch(allUserSoundsProvider);
          final sounds = soundsAsync.valueOrNull ?? [];

          return AlertDialog(
            title: Text(tr('select_sound')),
            content: SizedBox(
              width: double.maxFinite,
              child: sounds.isEmpty
                  ? Text(tr('no_sound'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: sounds.length,
                      itemBuilder: (context, index) {
                        final snd = sounds[index];
                        final isSelected = task.soundId == snd.id;

                        return ListTile(
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                          title: Text(_truncate(snd.name, 10)),
                          subtitle: Text('${(snd.durationMs / 1000).toStringAsFixed(1)}s'),
                          onTap: () async {
                            final repo = ref.read(taskRepositoryProvider);
                            await repo.update(task.copyWith(
                              soundId: snd.id,
                              updatedAt: DateTime.now().toIso8601String(),
                            ));
                            ref.invalidate(tasksForDateProvider(task.date));
                            await _rescheduleNotification(ref, snd.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              if (task.soundId != null)
                TextButton(
                  onPressed: () async {
                    final repo = ref.read(taskRepositoryProvider);
                    await repo.update(task.copyWith(
                      soundId: null,
                      updatedAt: DateTime.now().toIso8601String(),
                    ));
                    ref.invalidate(tasksForDateProvider(task.date));
                    await _rescheduleNotification(ref, null);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text('Remove', style: TextStyle(color: Colors.red.shade300)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('cancel')),
              ),
            ],
          );
        },
      ),
    );
  }
}