import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';

/// Reads notify_lead_minutes from settings. Default 0.
final notifyLeadMinutesProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  final value = await repo.getValue('notify_lead_minutes');
  return int.tryParse(value ?? '0') ?? 0;
});

/// Updates notify_lead_minutes.
final setNotifyLeadMinutesProvider = Provider<Future<void> Function(int)>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return (int minutes) async {
    await repo.setValue('notify_lead_minutes', minutes.toString());
    ref.invalidate(notifyLeadMinutesProvider);
  };
});