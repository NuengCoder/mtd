import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _filteredLanguages() {
    if (_query.isEmpty) return AppLanguages.all;
    return AppLanguages.all.where((code) {
      final name = AppLanguages.displayNames[code] ?? code;
      final codeMatch = code.toLowerCase().contains(_query.toLowerCase());
      final nameMatch = name.toLowerCase().contains(_query.toLowerCase());
      return codeMatch || nameMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final currentLangAsync = ref.watch(languageProvider);
    final currentLang = currentLangAsync.valueOrNull ?? 'en';
    final setLanguage = ref.read(setLanguageProvider);
    final filtered = _filteredLanguages();

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
        title: Text(tr('language_settings')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('search_language'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _query = value);
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                child: Text(tr('no_tasks'),
                    style: TextStyle(color: taskTextColor)))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final code = filtered[index];
                final name =
                    AppLanguages.displayNames[code] ?? code;
                final isSelected = code == currentLang;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade200,
                    child: Text(
                      code.toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(name,
                      style: TextStyle(color: taskTextColor)),
                  trailing: isSelected
                      ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () async {
                    await setLanguage(code);
                    await Future.delayed(
                        const Duration(milliseconds: 100));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text('$name (${tr('ok')})')),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}