import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/homework.dart';
import '../providers/language_provider.dart';
import '../repositories/homework_repository.dart';
import '../providers/homework_providers.dart';

class HomeworkFab extends ConsumerStatefulWidget {
  const HomeworkFab({super.key});

  @override
  ConsumerState<HomeworkFab> createState() => _HomeworkFabState();
}

class _HomeworkFabState extends ConsumerState<HomeworkFab> {
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
                child: FloatingActionButton(
                  heroTag: 'homework_fab',
                  onPressed: () {
                    if (_isDragging) return;
                    _showAddHomeworkDialog(context, tr);
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

  void _showAddHomeworkDialog(
      BuildContext context, String Function(String) tr) {
    final nameController = TextEditingController();
    final deadlineController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_homework')),
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
                // Auto-insert / after 2 digits
                final cleaned = value.replaceAll('/', '');
                if (cleaned.length >= 2) {
                  final newValue = '${cleaned.substring(0, 2)}/${cleaned.length > 2 ? cleaned.substring(2) : ''}';
                  if (newValue != value) {
                    deadlineController.value = TextEditingValue(
                      text: newValue,
                      selection: TextSelection.collapsed(offset: newValue.length),
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

              // Validate deadline DD/MM
              final parts = deadline.split('/');
              if (parts.length != 2) return;
              final day = int.tryParse(parts[0]);
              final month = int.tryParse(parts[1]);
              if (day == null || month == null) return;
              if (month < 1 || month > 12) return;
              if (day < 1 || day > 31) return;

              // Auto deploy date = today
              final now = DateTime.now();
              final deployDate =
                  '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';

              final homework = Homework(
                name: name,
                deployDate: deployDate,
                deadlineDate: deadline,
                isSubmitted: false,
                createdAt: DateTime.now().toIso8601String(),
                updatedAt: DateTime.now().toIso8601String(),
              );

              try {
                final repo = ref.read(homeworkRepositoryProvider);
                await repo.insert(homework);
                ref.invalidate(allHomeworkProvider);
                ref.invalidate(pendingHomeworkProvider);
              } catch (_) {}

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(tr('add')),
          ),
        ],
      ),
    );
  }
}