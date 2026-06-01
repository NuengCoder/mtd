import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../providers/notify_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/plan_providers.dart';
import '../providers/weekly_plan_providers.dart';
import '../providers/config_provider.dart';
import '../services/backup_service.dart';

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    // Theme
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? 'light';
    final colorsAsync = ref.watch(themeColorsProvider(themeMode));
    final colors = colorsAsync.valueOrNull ?? {};
    final taskTextColor = colors['App Task Text'] ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE6E1E5)
            : const Color(0xFF1A1A1A));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('backup_settings')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Export
            Card(
              child: ListTile(
                leading: Icon(Icons.upload_file, color: taskTextColor),
                title: Text(tr('export_backup'),
                    style: TextStyle(color: taskTextColor)),
                subtitle: Text('.mtd',
                    style: TextStyle(color: taskTextColor.withAlpha(150))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  try {
                    await BackupService.shareExport();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('export_success'))),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${tr('error')}: $e')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            // Import
            Card(
              child: ListTile(
                leading: Icon(Icons.download, color: taskTextColor),
                title: Text(tr('import_backup'),
                    style: TextStyle(color: taskTextColor)),
                subtitle: Text('.mtd',
                    style: TextStyle(color: taskTextColor.withAlpha(150))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(tr('import_backup')),
                      content: Text(tr('nuke_confirm')),
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
                    try {
                      final success = await BackupService.importFromFile(
                        onReplaceSystemPlans: (hasOdd, hasEven) async {
                          // Show system plans dialog
                          if (!context.mounted) return true;
                          final replace = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(tr('weekly_plans')),
                              content: Text(
                                'Found ${hasOdd ? '"Class (Odd)"' : ''}'
                                    '${hasOdd && hasEven ? ' and ' : ''}'
                                    '${hasEven ? '"Class (Even)"' : ''} in backup.\n'
                                    'Replace current tasks?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: Text(tr('no')),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: Text(tr('yes')),
                                ),
                              ],
                            ),
                          );
                          return replace ?? true;
                        },
                      );
                      if (context.mounted) {
                        ref.invalidate(allPlansProvider);
                        ref.invalidate(allWeeklyPlansProvider);
                        ref.invalidate(weekTypeFlippedProvider);
                        ref.invalidate(homeworkActiveProvider);
                        ref.invalidate(notifyLeadMinutesProvider);
                        ref.invalidate(themeModeProvider);
                        ref.invalidate(themeColorsProvider('light'));
                        ref.invalidate(themeColorsProvider('dark'));

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? tr('import_success')
                                : tr('error')),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                              Text('${tr('error')}: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            // Backup
            Card(
              child: ListTile(
                leading: Icon(Icons.save, color: taskTextColor),
                title: Text(tr('backup'),
                    style: TextStyle(color: taskTextColor)),
                subtitle: Text('.mtd',
                    style: TextStyle(color: taskTextColor.withAlpha(150))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  try {
                    await BackupService.shareExport(); // Same as Export — shares the file
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('backup_success'))),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${tr('error')}: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}