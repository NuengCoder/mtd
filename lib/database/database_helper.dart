import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';

class DatabaseHelper {
  static const String _dbName = 'mytodo.db';
  static const int _dbVersion = 7;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON;');
    } catch (_) {}
    try {
      await db.execute('PRAGMA journal_mode = WAL;');
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(DbCreate.tasks);
    await db.execute(DbCreate.tasksIndexDate);
    await db.execute(DbCreate.tasksIndexTime);

    await db.execute(DbCreate.homeworks);
    await db.execute(DbCreate.homeworksIndexDeploy);
    await db.execute(DbCreate.homeworksIndexDeadline);

    await db.execute(DbCreate.plans);
    await db.execute(DbCreate.planTasks);
    await db.execute(DbCreate.planTasksIndexPlan);

    await db.execute(DbCreate.weeklyPlans);
    await db.execute(DbCreate.weeklyPlanTasks);
    await db.execute(DbCreate.weeklyPlanTasksIndexPlan);
    await db.execute(DbCreate.weeklyPlanTasksIndexWeekday);

    await db.execute(DbCreate.userImages);
    await db.execute(DbCreate.userSounds);

    await db.execute(DbCreate.settings);
    await db.execute(DbCreate.themeSettings);

    await _seedData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.insert(DbTables.themeSettings, {
        DbCols.mode: 'light',
        DbCols.colorKey: 'App Task Card',
        DbCols.argbValue: 'FFF5F5F5',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert(DbTables.themeSettings, {
        DbCols.mode: 'dark',
        DbCols.colorKey: 'App Task Card',
        DbCols.argbValue: 'FF2C2C2C',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (oldVersion < 3) {
      for (final mode in ['light', 'dark']) {
        await db.insert(DbTables.themeSettings, {
          DbCols.mode: mode,
          DbCols.colorKey: 'App Background',
          DbCols.argbValue: mode == 'light' ? 'FFF8F8F8' : 'FF121212',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    if (oldVersion < 4) {
      for (final mode in ['light', 'dark']) {
        await db.insert(DbTables.themeSettings, {
          DbCols.mode: mode,
          DbCols.colorKey: 'App Task Text',
          DbCols.argbValue: mode == 'light' ? 'FF1A1A1A' : 'FFE6E1E5',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    if (oldVersion < 5) {
      await _migrateMediaToFiles(db);
    }
    if (oldVersion < 6) {
      // Add media_uri column to user_sounds
      try {
        await db.execute('ALTER TABLE ${DbTables.userSounds} ADD COLUMN ${DbCols.mediaUri} TEXT;');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      // media_uri column added in v6, no v7 schema changes
    }
  }



  Future<void> _seedData(Database db) async {
    // Seed system weekly plans
    await db.insert(DbTables.weeklyPlans, {
      DbCols.name: 'Class (Odd)',
      DbCols.isSystem: 1,
      DbCols.autoDeploy: 0,
    });
    await db.insert(DbTables.weeklyPlans, {
      DbCols.name: 'Class (Even)',
      DbCols.isSystem: 1,
      DbCols.autoDeploy: 0,
    });

    // Seed default settings
    final defaultSettings = {
      'language': 'en',
      'notify_lead_minutes': '0',
      'week_type_flipped': '0',
      'homework_active': '1',
    };
    for (final entry in defaultSettings.entries) {
      await db.insert(DbTables.settings, {
        DbCols.key: entry.key,
        DbCols.value: entry.value,
      });
    }

    // Seed default theme (light mode)
    final defaultLightTheme = {
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
    };
    for (final entry in defaultLightTheme.entries) {
      await db.insert(DbTables.themeSettings, {
        DbCols.mode: 'light',
        DbCols.colorKey: entry.key,
        DbCols.argbValue: entry.value,
      });
    }

    // Seed default theme (dark mode)
    final defaultDarkTheme = {
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
    for (final entry in defaultDarkTheme.entries) {
      await db.insert(DbTables.themeSettings, {
        DbCols.mode: 'dark',
        DbCols.colorKey: entry.key,
        DbCols.argbValue: entry.value,
      });
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// For backup/export: returns the database file path
  Future<String> get databasePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _dbName);
  }

  Future<void> _migrateMediaToFiles(Database db) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/media/images');
    final soundsDir = Directory('${dir.path}/media/sounds');
    await imagesDir.create(recursive: true);
    await soundsDir.create(recursive: true);

    // Migrate images
    final images = await db.query(DbTables.userImages);
    for (final img in images) {
      final bytes = img['data'] as List<int>?;
      if (bytes != null) {
        final fileName = '${img['id']}_${img['name']}';
        final file = File('${imagesDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await db.update(
          DbTables.userImages,
          {'file_path': file.path},
          where: 'id = ?',
          whereArgs: [img['id']],
        );
      }
    }

    // Migrate sounds
    final sounds = await db.query(DbTables.userSounds);
    for (final snd in sounds) {
      final bytes = snd['data'] as List<int>?;
      if (bytes != null) {
        final fileName = '${snd['id']}_${snd['name']}';
        final file = File('${soundsDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await db.update(
          DbTables.userSounds,
          {'file_path': file.path},
          where: 'id = ?',
          whereArgs: [snd['id']],
        );
      }
    }
  }
}