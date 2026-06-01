import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import 'backup_settings_screen.dart';
import 'notify_settings_screen.dart';
import 'config_settings_screen.dart';
import 'language_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'media_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
    final secondaryPrimary = colors['App Secondary Primary'] ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF4F378B)
            : const Color(0xFFEADDFF));

    return ListView(
      children: [
        _SettingsTile(
          icon: Icons.tune,
          title: tr('config_settings'),
          textColor: taskTextColor,
          bgColor: secondaryPrimary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ConfigSettingsScreen(),
              ),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          title: tr('notify_settings'),
          textColor: taskTextColor,
          bgColor: secondaryPrimary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotifySettingsScreen(),
              ),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.palette_outlined,
          title: tr('theme_settings'),
          textColor: taskTextColor,
          bgColor: secondaryPrimary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ThemeSettingsScreen(),
              ),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.language_outlined,
          title: tr('language_settings'),
          textColor: taskTextColor,
          bgColor: secondaryPrimary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LanguageSettingsScreen(),
              ),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.backup_outlined,
          title: tr('backup_settings'),
          textColor: taskTextColor,
          bgColor: secondaryPrimary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BackupSettingsScreen(),
              ),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.perm_media_outlined,
          title: tr('media_settings'),
          textColor: taskTextColor,
          bgColor: secondaryPrimary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MediaSettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.textColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: bgColor,
        child: Icon(icon, color: textColor),
      ),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.chevron_right, color: textColor.withAlpha(150)),
      onTap: onTap,
    );
  }
}