import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? 'light';
    final colorsAsync = ref.watch(themeColorsProvider(themeMode));
    final colors = colorsAsync.valueOrNull ?? {};
    final setMode = ref.read(setThemeModeProvider);

    // Theme
    final taskTextColor = colors['App Task Text'] ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE6E1E5)
            : const Color(0xFF1A1A1A));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('theme_settings')),
      ),
      body: ListView(
        children: [
          // Light/Dark toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'light',
                  label: Text(tr('light_mode')),
                  icon: const Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: 'dark',
                  label: Text(tr('dark_mode')),
                  icon: const Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (value) {
                setMode(value.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr('reset_theme')),
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
                  ref.read(resetThemeProvider)(themeMode);
                }
              },
              icon: const Icon(Icons.restore),
              label: Text(tr('reset_theme')),
            ),
          ),
          const Divider(),
          // Color pickers
          for (final key in colorKeys)
            _ColorTile(
              label: tr(_colorKeyToTrKey(key)),
              color: colors[key] ?? Colors.grey,
              mode: themeMode,
              colorKey: key,
              textColor: taskTextColor,
            ),
        ],
      ),
    );
  }
}

String _colorKeyToTrKey(String key) {
  switch (key) {
    case 'App Text': return 'color_app_text';
    case 'App Primary': return 'color_app_primary';
    case 'App Secondary Text': return 'color_secondary_text';
    case 'App Odd Badge': return 'color_odd_badge';
    case 'App Even Badge': return 'color_even_badge';
    case 'App Normal Badge': return 'color_normal_badge';
    case 'App Secondary Primary': return 'color_secondary_primary';
    case 'App Card': return 'color_app_card';
    case 'App Task Card': return 'color_app_task_card';
    case 'App Background': return 'color_app_background';
    case 'App Task Text': return 'color_app_task_text';
    default: return key;
  }
}

class _ColorTile extends ConsumerWidget {
  final String label;
  final Color color;
  final String mode;
  final String colorKey;
  final Color textColor;

  const _ColorTile({
    required this.label,
    required this.color,
    required this.mode,
    required this.colorKey,
    required this.textColor,
  });

  static const _presets = [
    Colors.black, Colors.white, Colors.grey,
    Colors.red, Colors.pink, Colors.purple,
    Colors.deepPurple, Colors.indigo, Colors.blue,
    Colors.lightBlue, Colors.cyan, Colors.teal,
    Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange,
    Colors.deepOrange, Colors.brown,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setColor = ref.read(setThemeColorProvider);

    return ListTile(
      leading: CircleAvatar(backgroundColor: color),
      title: Text(label, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.chevron_right, color: textColor.withAlpha(150)),
      onTap: () {
        int a = (color.a * 255).round();
        int r = (color.r * 255).round();
        int g = (color.g * 255).round();
        int b = (color.b * 255).round();

        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              Color pickedColor = Color.fromARGB(a, r, g, b);

              return AlertDialog(
                title: Text(label),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: pickedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '#${pickedColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _SliderRow(label: 'A', value: a, max: 255, onChanged: (v) {
                        a = v.round();
                        pickedColor = Color.fromARGB(a, r, g, b);
                        setDialogState(() {});
                        setColor(mode, colorKey, pickedColor);
                      }),
                      _SliderRow(label: 'R', value: r, max: 255, onChanged: (v) {
                        r = v.round();
                        pickedColor = Color.fromARGB(a, r, g, b);
                        setDialogState(() {});
                        setColor(mode, colorKey, pickedColor);
                      }),
                      _SliderRow(label: 'G', value: g, max: 255, onChanged: (v) {
                        g = v.round();
                        pickedColor = Color.fromARGB(a, r, g, b);
                        setDialogState(() {});
                        setColor(mode, colorKey, pickedColor);
                      }),
                      _SliderRow(label: 'B', value: b, max: 255, onChanged: (v) {
                        b = v.round();
                        pickedColor = Color.fromARGB(a, r, g, b);
                        setDialogState(() {});
                        setColor(mode, colorKey, pickedColor);
                      }),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _presets.map((c) {
                          final isSelected = c.toARGB32() == pickedColor.toARGB32();
                          return GestureDetector(
                            onTap: () {
                              a = (c.a * 255).round();
                              r = (c.r * 255).round();
                              g = (c.g * 255).round();
                              b = (c.b * 255).round();
                              pickedColor = c;
                              setDialogState(() {});
                              setColor(mode, colorKey, c);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: c.withAlpha(128), blurRadius: 6)]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: max.toDouble(),
            divisions: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(value.toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}