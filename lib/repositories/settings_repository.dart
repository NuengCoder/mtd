import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_constants.dart';
import '../models/setting.dart';
import '../models/theme_setting.dart';
import '../providers/database_provider.dart';

class SettingsRepository {
  final Database _db;

  SettingsRepository(this._db);

  // ─── Generic Settings (SQLite + SharedPrefs) ──

  /// Get a setting value. Tries SharedPrefs first, falls back to SQLite.
  Future<String?> getValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached != null) return cached;

      final results = await _db.query(
        DbTables.settings,
        where: '${DbCols.key} = ?',
        whereArgs: [key],
      );
      if (results.isEmpty) return null;
      final value = results.first[DbCols.value] as String;
      await prefs.setString(key, value); // cache for next read
      return value;
    } catch (e) {
      rethrow;
    }
  }

  /// Set a setting value. Writes to both SQLite and SharedPrefs.
  Future<void> setValue(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);

      await _db.insert(
        DbTables.settings,
        {DbCols.key: key, DbCols.value: value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get all settings.
  Future<List<Setting>> getAll() async {
    try {
      final results = await _db.query(DbTables.settings);
      return results.map((m) => Setting.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Bulk replace settings (for import).
  Future<void> bulkSet(Map<String, String> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final batch = _db.batch();
      batch.delete(DbTables.settings);
      for (final entry in settings.entries) {
        await prefs.setString(entry.key, entry.value);
        batch.insert(DbTables.settings, {
          DbCols.key: entry.key,
          DbCols.value: entry.value,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Theme Settings ──────────────────────────

  /// Get all theme colors for a mode.
  Future<List<ThemeSetting>> getTheme(String mode) async {
    try {
      final results = await _db.query(
        DbTables.themeSettings,
        where: '${DbCols.mode} = ?',
        whereArgs: [mode],
      );
      return results.map((m) => ThemeSetting.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific theme color.
  Future<String?> getThemeColor(String mode, String colorKey) async {
    try {
      final results = await _db.query(
        DbTables.themeSettings,
        where: '${DbCols.mode} = ? AND ${DbCols.colorKey} = ?',
        whereArgs: [mode, colorKey],
      );
      if (results.isEmpty) return null;
      return results.first[DbCols.argbValue] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Set a theme color.
  Future<void> setThemeColor(String mode, String colorKey, String argb) async {
    try {
      await _db.insert(
        DbTables.themeSettings,
        {
          DbCols.mode: mode,
          DbCols.colorKey: colorKey,
          DbCols.argbValue: argb,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Bulk replace theme for a mode (for import).
  Future<void> bulkSetTheme(String mode, Map<String, String> colors) async {
    try {
      final batch = _db.batch();
      batch.delete(
        DbTables.themeSettings,
        where: '${DbCols.mode} = ?',
        whereArgs: [mode],
      );
      for (final entry in colors.entries) {
        batch.insert(DbTables.themeSettings, {
          DbCols.mode: mode,
          DbCols.colorKey: entry.key,
          DbCols.argbValue: entry.value,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      rethrow;
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider).valueOrNull;
  if (db == null) throw StateError('Database not initialized');
  return SettingsRepository(db);
});