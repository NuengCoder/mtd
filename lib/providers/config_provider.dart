import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';

/// Reads the week_type_flipped setting reactively.
/// Returns true if weeks are flipped.
final weekTypeFlippedProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  final value = await repo.getValue('week_type_flipped');
  return value == '1';
});

/// Reads the homework_active setting reactively.
/// Returns true if homework feature is enabled.
final homeworkActiveProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  final value = await repo.getValue('homework_active');
  return value != '0'; // default true if null
});

/// Toggles week_type_flipped.
final toggleWeekTypeFlippedProvider = Provider<Future<void> Function()>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return () async {
    final current = await repo.getValue('week_type_flipped');
    final newValue = current == '1' ? '0' : '1';
    await repo.setValue('week_type_flipped', newValue);
    ref.invalidate(weekTypeFlippedProvider);
  };
});

/// Toggles homework_active.
final toggleHomeworkActiveProvider = Provider<Future<void> Function()>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return () async {
    final current = await repo.getValue('homework_active');
    final newValue = current == '0' ? '1' : '0';
    await repo.setValue('homework_active', newValue);
    ref.invalidate(homeworkActiveProvider);
  };
});