import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../repositories/settings_repository.dart';

/// The current language code.
final languageProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString('language');
  if (cached != null && AppLanguages.all.contains(cached)) return cached;

  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final lang = await settingsRepo.getValue('language');
  if (lang != null && AppLanguages.all.contains(lang)) {
    await prefs.setString('language', lang);
    return lang;
  }
  return AppLanguages.en;
});

/// Synchronous fallback for initial render.
final currentLanguageProvider = Provider<String>((ref) {
  final asyncLang = ref.watch(languageProvider);
  return asyncLang.valueOrNull ?? AppLanguages.en;
});

/// Convenience: translate a key using the current language.
final trProvider = Provider<String Function(String)>((ref) {
  final lang = ref.watch(currentLanguageProvider);
  return (String key) => tr(key, lang);
});

/// Convenience: get greeting using the current language.
final greetingProvider = Provider<String>((ref) {
  final lang = ref.watch(currentLanguageProvider);
  return getGreeting(lang);
});

/// Change the language.
final setLanguageProvider = Provider<Future<void> Function(String)>((ref) {
  final settingsRepo = ref.read(settingsRepositoryProvider);
  return (String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    await settingsRepo.setValue('language', lang);
    ref.invalidate(languageProvider);
    ref.invalidate(currentLanguageProvider);
    ref.invalidate(trProvider);
    ref.invalidate(greetingProvider);
  };
});