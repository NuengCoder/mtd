import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/homework.dart';
import '../providers/language_provider.dart';
import '../repositories/homework_repository.dart';
import '../providers/homework_providers.dart';
import '../providers/theme_provider.dart';


class HomeworkCard extends ConsumerWidget {
  final Homework homework;

  const HomeworkCard({super.key, required this.homework});

  Color _randomColor(String name) {
    if (name.isEmpty) return Colors.grey;
    final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
    final random = Random(hash);
    return Color.fromARGB(
      255,
      random.nextInt(200) + 30,
      random.nextInt(200) + 30,
      random.nextInt(200) + 30,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final hasImage = homework.imageId != null;
    final isSubmitted = homework.isSubmitted;
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
        leading: CircleAvatar(
          backgroundColor: hasImage ? null : _randomColor(homework.name),
          child: hasImage
              ? const Icon(Icons.image, color: Colors.white)
              : Text(
            homework.name.isNotEmpty
                ? homework.name[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          homework.name,
          style: TextStyle(
            decoration: isSubmitted ? TextDecoration.lineThrough : null,
            color: isSubmitted ? Colors.grey : taskTextColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tr('deploy_date')}: ${homework.deployDate}',
              style: TextStyle(fontSize: 12, color: taskTextColor.withAlpha(180)),
            ),
            Text(
              '${tr('deadline_date')}: ${homework.deadlineDate}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSubmitted ? Colors.green : Colors.red.shade400,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          onSelected: (value) async {
            final repo = ref.read(homeworkRepositoryProvider);
            switch (value) {
              case 'submit':
                if (!isSubmitted) {
                  await repo.submit(homework.id!);
                  ref.invalidate(allHomeworkProvider);
                  ref.invalidate(pendingHomeworkProvider);
                }
                break;
              case 'edit':
                _showEditDialog(context, ref, tr);
                break;
              case 'delete':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr('delete_task')),
                    content: Text(homework.name),
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
                  await repo.delete(homework.id!);
                  ref.invalidate(allHomeworkProvider);
                  ref.invalidate(pendingHomeworkProvider);
                }
                break;
            }
          },
          itemBuilder: (context) => [
            if (!isSubmitted)
              PopupMenuItem(
                value: 'submit',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(tr('submit')),
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

  void _showEditDialog(
      BuildContext context, WidgetRef ref, String Function(String) tr) {
    final nameController = TextEditingController(text: homework.name);
    final deadlineController =
    TextEditingController(text: homework.deadlineDate);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('edit_task')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: tr('homework_name'),
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                hintText: '${tr('deadline_date')} (DD/MM)',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 5,
              onChanged: (value) {
                final cleaned = value.replaceAll('/', '');
                if (cleaned.length >= 2) {
                  final newValue =
                      '${cleaned.substring(0, 2)}/${cleaned.length > 2 ? cleaned.substring(2) : ''}';
                  if (newValue != value) {
                    deadlineController.value = TextEditingValue(
                      text: newValue,
                      selection:
                      TextSelection.collapsed(offset: newValue.length),
                    );
                  }
                }
              },
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
              final name = nameController.text.trim();
              final deadline = deadlineController.text.trim();
              if (name.isEmpty || deadline.isEmpty) return;

              final parts = deadline.split('/');
              if (parts.length != 2) return;
              final day = int.tryParse(parts[0]);
              final month = int.tryParse(parts[1]);
              if (day == null || month == null) return;
              if (month < 1 || month > 12) return;
              if (day < 1 || day > 31) return;

              final updated = homework.copyWith(
                name: name,
                deadlineDate: deadline,
                updatedAt: DateTime.now().toIso8601String(),
              );

              try {
                final repo = ref.read(homeworkRepositoryProvider);
                await repo.update(updated);
                ref.invalidate(allHomeworkProvider);
                ref.invalidate(pendingHomeworkProvider);
              } catch (_) {}

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }
}