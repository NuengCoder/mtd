import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../providers/config_provider.dart';
import '../providers/theme_provider.dart';

class ConfigSettingsScreen extends ConsumerWidget {
  const ConfigSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final weekFlippedAsync = ref.watch(weekTypeFlippedProvider);
    final homeworkActiveAsync = ref.watch(homeworkActiveProvider);
    final toggleWeekFlip = ref.read(toggleWeekTypeFlippedProvider);
    final toggleHomework = ref.read(toggleHomeworkActiveProvider);

    final weekFlipped = weekFlippedAsync.valueOrNull ?? false;
    final homeworkActive = homeworkActiveAsync.valueOrNull ?? true;

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
        title: Text(tr('config_settings')),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(tr('week_type_flip'),
                style: TextStyle(color: taskTextColor)),
            subtitle: Text(
              weekFlipped ? tr('badge_even') : tr('badge_odd'),
              style: TextStyle(color: taskTextColor.withAlpha(180)),
            ),
            value: weekFlipped,
            onChanged: (_) => toggleWeekFlip(),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(tr('homework_active'),
                style: TextStyle(color: taskTextColor)),
            subtitle: Text(
              homeworkActive ? tr('yes') : tr('no'),
              style: TextStyle(color: taskTextColor.withAlpha(180)),
            ),
            value: homeworkActive,
            onChanged: (_) => toggleHomework(),
          ),
        ],
      ),
    );
  }
}