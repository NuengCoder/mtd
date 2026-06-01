import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../providers/notify_provider.dart';
import '../providers/theme_provider.dart';

class NotifySettingsScreen extends ConsumerWidget {
  const NotifySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final leadMinutesAsync = ref.watch(notifyLeadMinutesProvider);
    final setLeadMinutes = ref.read(setNotifyLeadMinutesProvider);

    final leadMinutes = leadMinutesAsync.valueOrNull ?? 0;

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
        title: Text(tr('notify_settings')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('notify_lead_time'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: taskTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('0', style: TextStyle(color: taskTextColor.withAlpha(150), fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: leadMinutes.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 60,
                    label: '$leadMinutes',
                    onChanged: (value) {
                      setLeadMinutes(value.toInt());
                    },
                  ),
                ),
                Text('60', style: TextStyle(color: taskTextColor.withAlpha(150), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$leadMinutes ${tr('notify_lead_time').split('(').last.replaceAll(')', '')}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: taskTextColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr('notify_lead_time'),
              style: TextStyle(color: taskTextColor.withAlpha(150), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}