import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';

/// The 8 color keys used in the app.
const colorKeys = [
  'App Text',
  'App Primary',
  'App Secondary Text',
  'App Odd Badge',
  'App Even Badge',
  'App Normal Badge',
  'App Secondary Primary',
  'App Card',
  'App Task Card',
  'App Background',
  'App Task Text',
];

/// Current theme mode (light/dark).
final themeModeProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  final value = await repo.getValue('theme_mode');
  return value ?? 'light';
});

/// Theme colors for a given mode.
final themeColorsProvider =
FutureProvider.family<Map<String, Color>, String>((ref, mode) async {
  final repo = ref.watch(settingsRepositoryProvider);
  final settings = await repo.getTheme(mode);
  final map = <String, Color>{};
  for (final s in settings) {
    final hex = s.argbValue;
    if (hex.length == 8) {
      final alpha = int.parse(hex.substring(0, 2), radix: 16);
      final red = int.parse(hex.substring(2, 4), radix: 16);
      final green = int.parse(hex.substring(4, 6), radix: 16);
      final blue = int.parse(hex.substring(6, 8), radix: 16);
      map[s.colorKey] = Color.fromARGB(
        alpha.clamp(0, 255),
        red.clamp(0, 255),
        green.clamp(0, 255),
        blue.clamp(0, 255),
      );
    }
  }
  return map;
});

/// Set a theme color.
final setThemeColorProvider =
Provider<Future<void> Function(String mode, String key, Color)>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return (String mode, String key, Color color) async {
    final hex =
        '${((color.a * 255.0).round().clamp(0, 255)).toRadixString(16).padLeft(2, '0')}'
        '${((color.r * 255.0).round().clamp(0, 255)).toRadixString(16).padLeft(2, '0')}'
        '${((color.g * 255.0).round().clamp(0, 255)).toRadixString(16).padLeft(2, '0')}'
        '${((color.b * 255.0).round().clamp(0, 255)).toRadixString(16).padLeft(2, '0')}';
    await repo.setThemeColor(mode, key, hex.toUpperCase());
    ref.invalidate(themeColorsProvider(mode));
  };
});

/// Set theme mode.
final setThemeModeProvider = Provider<Future<void> Function(String)>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return (String mode) async {
    await repo.setValue('theme_mode', mode);
    ref.invalidate(themeModeProvider);
  };
});

/// Reset theme to defaults.
final resetThemeProvider = Provider<Future<void> Function(String mode)>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return (String mode) async {
    final defaults = mode == 'light'
        ? {
      'App Text': 'FF1A1A1A',
      'App Primary': 'FF6750A4',
      'App Secondary Text': 'FF625B71',
      'App Odd Badge': 'FF4CAF50',
      'App Even Badge': 'FF2196F3',
      'App Normal Badge': 'FF9E9E9E',
      'App Secondary Primary': 'FFEADDFF',
      'App Card': 'FFFFFFFF',
      'App Task Card': 'FFF5F5F5',
      'App Background': 'FFF8F8F8',
      'App Task Text': 'FF1A1A1A',
    }
        : {
      'App Text': 'FFE6E1E5',
      'App Primary': 'FFD0BCFF',
      'App Secondary Text': 'FFCCC2DC',
      'App Odd Badge': 'FF81C784',
      'App Even Badge': 'FF64B5F6',
      'App Normal Badge': 'FF757575',
      'App Secondary Primary': 'FF4F378B',
      'App Card': 'FF1E1E1E',
      'App Task Card': 'FF2C2C2C',
      'App Background': 'FF121212',
      'App Task Text': 'FFE6E1E5',
    };
    await repo.bulkSetTheme(mode, defaults);
    ref.invalidate(themeColorsProvider(mode));
  };
});