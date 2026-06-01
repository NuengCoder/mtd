import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' as dart_io;
import '../models/weekly_plan_task.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/weekly_plan_providers.dart';
import '../providers/media_providers.dart';
import '../repositories/weekly_plan_repository.dart';

class CreateWeeklyPlanScreen extends ConsumerStatefulWidget {
  final int? planId;
  const CreateWeeklyPlanScreen({super.key, this.planId});

  @override
  ConsumerState<CreateWeeklyPlanScreen> createState() =>
      _CreateWeeklyPlanScreenState();
}

class _CreateWeeklyPlanScreenState
    extends ConsumerState<CreateWeeklyPlanScreen> {
  final _nameController = TextEditingController();
  int? _currentPlanId;
  String _selectedWeekday = 'monday';
  final _weekdays = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday', 'all_days'
  ];

  String _weekdayToDb(String key) {
    const map = {
      'monday': 'mon', 'tuesday': 'tue', 'wednesday': 'wed',
      'thursday': 'thu', 'friday': 'fri', 'saturday': 'sat',
      'sunday': 'sun', 'all_days': 'all',
    };
    return map[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    if (widget.planId != null) {
      _currentPlanId = widget.planId;
      _loadExistingPlan();
    }
  }

  Future<void> _loadExistingPlan() async {
    final repo = ref.read(weeklyPlanRepositoryProvider);
    final plan = await repo.getById(widget.planId!);
    if (plan != null && mounted) {
      _nameController.text = plan.name;
    }
  }

  Future<void> _savePlanName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _currentPlanId == null) return;
    final repo = ref.read(weeklyPlanRepositoryProvider);
    final existing = await repo.getById(_currentPlanId!);
    if (existing != null) {
      await repo.update(existing.copyWith(
        name: name,
        updatedAt: DateTime.now().toIso8601String(),
      ));
    }
    ref.invalidate(allWeeklyPlansProvider);
  }

  Future<void> _addTask() async {
    if (_currentPlanId == null) return;
    final tr = ref.read(trProvider);
    final titleController = TextEditingController();
    TimeOfDay? selectedTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('${tr('add_task')} (${tr(_selectedWeekday)})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                    hintText: tr('task_title'),
                    border: const OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text(selectedTime != null ? selectedTime!.format(ctx) : tr('no_time')),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                        context: ctx, initialTime: selectedTime ?? TimeOfDay.now());
                    if (time != null) setDialogState(() => selectedTime = time);
                  },
                  child: Text(tr('task_time')),
                ),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('add'))),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      final title = titleController.text.trim();
      if (title.isEmpty) return;
      final task = WeeklyPlanTask(
        weeklyPlanId: _currentPlanId!,
        title: title,
        time: selectedTime != null
            ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
            : null,
        weekday: _weekdayToDb(_selectedWeekday),
        createdAt: DateTime.now().toIso8601String(),
      );
      final repo = ref.read(weeklyPlanRepositoryProvider);
      await repo.insertTask(task);
      ref.invalidate(weeklyPlanTasksProvider(_currentPlanId!));
      ref.invalidate(weeklyPlanTasksByWeekdayProvider(_currentPlanId!));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}...' : s;

  Color _randomColor(String title) {
    if (title.isEmpty) return Colors.grey;
    final hash = title.codeUnits.fold(0, (sum, c) => sum + c);
    return Color.fromARGB(255, (hash * 7) % 200 + 30, (hash * 13) % 200 + 30, (hash * 17) % 200 + 30);
  }

  void _showSetTimeDialog(BuildContext context, WidgetRef ref,
      String Function(String) tr, WeeklyPlanTask wt, WeeklyPlanRepository repo) {
    TimeOfDay? selectedTime;
    if (wt.time != null) {
      final parts = wt.time!.split(':');
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('set_time')),
          content: Row(children: [
            Text(selectedTime != null ? selectedTime!.format(ctx) : tr('no_time')),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final time = await showTimePicker(context: ctx, initialTime: selectedTime ?? TimeOfDay.now());
                if (time != null) setDialogState(() => selectedTime = time);
              },
              child: Text(tr('task_time')),
            ),
            TextButton(onPressed: () => setDialogState(() => selectedTime = null), child: const Text('✕')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
            FilledButton(
              onPressed: () async {
                await repo.updateTask(wt.copyWith(
                  time: selectedTime != null
                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                      : null,
                ));
                ref.invalidate(weeklyPlanTasksProvider(_currentPlanId!));
                ref.invalidate(weeklyPlanTasksByWeekdayProvider(_currentPlanId!));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTitleDialog(BuildContext context, WidgetRef ref,
      String Function(String) tr, WeeklyPlanTask wt, WeeklyPlanRepository repo) {
    final controller = TextEditingController(text: wt.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('edit_task')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: tr('task_title'), border: const OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          FilledButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              await repo.updateTask(wt.copyWith(title: title));
              ref.invalidate(weeklyPlanTasksProvider(_currentPlanId!));
              ref.invalidate(weeklyPlanTasksByWeekdayProvider(_currentPlanId!));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context, WidgetRef ref,
      String Function(String) tr, WeeklyPlanTask wt, WeeklyPlanRepository repo) {
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: images.length + 1,
                      itemBuilder: (context, index) {
                        if (index == images.length) {
                          return GestureDetector(
                            onTap: () async {
                              await repo.updateTask(wt.copyWith(imageId: null));
                              ref.invalidate(weeklyPlanTasksProvider(_currentPlanId!));
                              ref.invalidate(weeklyPlanTasksByWeekdayProvider(_currentPlanId!));
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.remove_circle, color: Colors.red, size: 32),
                                Text('Remove', style: TextStyle(color: Colors.red, fontSize: 10)),
                              ]),
                            ),
                          );
                        }
                        final img = images[index];
                        final file = dart_io.File(img.filePath);
                        final isSelected = wt.imageId == img.id;
                        return GestureDetector(
                          onTap: () async {
                            await repo.updateTask(wt.copyWith(imageId: img.id));
                            ref.invalidate(weeklyPlanTasksProvider(_currentPlanId!));
                            ref.invalidate(weeklyPlanTasksByWeekdayProvider(_currentPlanId!));
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                                    width: isSelected ? 3 : 1),
                                borderRadius: BorderRadius.circular(8)),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: file.existsSync() ? Image.file(file, fit: BoxFit.cover) : const Icon(Icons.broken_image)),
                          ),
                        );
                      },
                    ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel')))],
          );
        },
      ),
    );
  }

  void _showSoundPicker(BuildContext context, WidgetRef ref,
      String Function(String) tr, WeeklyPlanTask wt, WeeklyPlanRepository repo) {
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
                        final isSelected = wt.soundId == snd.id;
                        return ListTile(
                          leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? Colors.blue : Colors.grey),
                          title: Text(_truncate(snd.name, 10)),
                          subtitle: Text('${(snd.durationMs / 1000).toStringAsFixed(1)}s'),
                          onTap: () async {
                            await repo.updateTask(wt.copyWith(soundId: snd.id));
                            ref.invalidate(weeklyPlanTasksProvider(_currentPlanId!));
                            ref.invalidate(weeklyPlanTasksByWeekdayProvider(_currentPlanId!));
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              if (wt.soundId != null)
                TextButton(
                  onPressed: () async {
                    await repo.updateTask(wt.copyWith(soundId: null));
                    ref.invalidate(weeklyPlanTasksProvider(_currentPlanId!));
                    ref.invalidate(weeklyPlanTasksByWeekdayProvider(_currentPlanId!));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text('Remove', style: TextStyle(color: Colors.red.shade300)),
                ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final tasksByWeekdayAsync = _currentPlanId != null
        ? ref.watch(weeklyPlanTasksByWeekdayProvider(_currentPlanId!))
        : null;

    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? 'light';
    final colorsAsync = ref.watch(themeColorsProvider(themeMode));
    final colors = colorsAsync.valueOrNull ?? {};
    final taskTextColor = colors['App Task Text'] ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE6E1E5)
            : const Color(0xFF1A1A1A));

    return Scaffold(
      appBar: AppBar(title: Text(tr('create_weekly_plan'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: tr('plan_name'), border: const OutlineInputBorder()),
              onChanged: (_) => _savePlanName(),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weekdays.length,
              itemBuilder: (context, index) {
                final d = _weekdays[index];
                final isSelected = d == _selectedWeekday;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: Text(tr(d)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedWeekday = d),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: tasksByWeekdayAsync != null
                ? tasksByWeekdayAsync.when(
                    data: (map) {
                      final dbKey = _weekdayToDb(_selectedWeekday);
                      final tasks = map[dbKey] ?? [];
                      if (tasks.isEmpty) {
                        return Center(child: Text(tr('no_tasks'), style: TextStyle(color: taskTextColor)));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final wt = tasks[index];
                          final hasImage = wt.imageId != null;

                          String? imagePath;
                          if (hasImage) {
                            final imagesAsync = ref.watch(allUserImagesProvider);
                            final images = imagesAsync.valueOrNull ?? [];
                            final img = images.where((i) => i.id == wt.imageId).firstOrNull;
                            if (img != null) imagePath = img.filePath;
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (hasImage && imagePath != null) ? null : _randomColor(wt.title),
                              backgroundImage: (hasImage && imagePath != null)
                                  ? FileImage(dart_io.File(imagePath))
                                  : null,
                              child: (hasImage && imagePath != null)
                                  ? null
                                  : Text(
                                      wt.title.isNotEmpty ? wt.title[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(wt.title, style: TextStyle(color: taskTextColor)),
                            subtitle: Text(wt.time ?? tr('no_time'),
                                style: TextStyle(color: taskTextColor.withAlpha(180))),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.settings),
                              onSelected: (value) async {
                                final repo = ref.read(weeklyPlanRepositoryProvider);
                                switch (value) {
                                  case 'time':
                                    _showSetTimeDialog(context, ref, tr, wt, repo);
                                    break;
                                  case 'edit':
                                    _showEditTitleDialog(context, ref, tr, wt, repo);
                                    break;
                                  case 'image':
                                    _showImagePicker(context, ref, tr, wt, repo);
                                    break;
                                  case 'sound':
                                    _showSoundPicker(context, ref, tr, wt, repo);
                                    break;
                                  case 'delete':
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(tr('delete_task')),
                                        content: Text(wt.title),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('yes'))),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await repo.deleteTask(wt.id!);
                                      ref.invalidate(weeklyPlanTasksProvider(_currentPlanId!));
                                      ref.invalidate(weeklyPlanTasksByWeekdayProvider(_currentPlanId!));
                                    }
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'time',
                                  child: Row(children: [
                                    Icon(Icons.access_time, size: 20),
                                    SizedBox(width: 8),
                                    Text(tr('set_time')),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    const Icon(Icons.edit, size: 20),
                                    const SizedBox(width: 8),
                                    Text(tr('edit_task')),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'image',
                                  child: Row(children: [
                                    const Icon(Icons.image, size: 20),
                                    const SizedBox(width: 8),
                                    Text(wt.imageId != null ? 'Change Image' : tr('select_image')),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'sound',
                                  child: Row(children: [
                                    const Icon(Icons.music_note, size: 20),
                                    const SizedBox(width: 8),
                                    Text(wt.soundId != null ? 'Change Sound' : tr('select_sound')),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    const Icon(Icons.delete, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Text(tr('delete_task'), style: const TextStyle(color: Colors.red)),
                                  ]),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('${tr('error')}: $e', style: TextStyle(color: taskTextColor))),
                  )
                : Center(child: Text(tr('no_tasks'), style: TextStyle(color: taskTextColor))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_weekly_fab',
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}