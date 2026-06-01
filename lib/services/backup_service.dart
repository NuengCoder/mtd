import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_constants.dart';
import '../database/database_helper.dart';

class BackupService {
  static Future<String> exportToJson() async {
    final db = await DatabaseHelper.instance.database;

    final plans = await db.query(DbTables.plans);
    final planTasks = await db.query(DbTables.planTasks);
    final weeklyPlans = await db.query(DbTables.weeklyPlans);
    final weeklyPlanTasks = await db.query(DbTables.weeklyPlanTasks);
    final userImages = await db.query(DbTables.userImages);
    final userSounds = await db.query(DbTables.userSounds);

    // Convert file data to base64
    final imagesExport = <Map<String, dynamic>>[];
    for (final img in userImages) {
      final filePath = img['file_path'] as String? ?? '';
      String? base64Str;
      if (filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          base64Str = base64Encode(await file.readAsBytes());
        }
      }
      imagesExport.add({
        'id': img['id'],
        'name': img['name'],
        'data_base64': base64Str,
        'created_at': img['created_at'],
      });
    }

    final soundsExport = <Map<String, dynamic>>[];
    for (final snd in userSounds) {
      final filePath = snd['file_path'] as String? ?? '';
      String? base64Str;
      if (filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          base64Str = base64Encode(await file.readAsBytes());
        }
      }
      soundsExport.add({
        'id': snd['id'],
        'name': snd['name'],
        'data_base64': base64Str,
        'duration_ms': snd['duration_ms'],
        'created_at': snd['created_at'],
      });
    }

    final exportData = {
      'version': 2, // bumped for file-based storage
      'exported_at': DateTime.now().toIso8601String(),
      'plans': plans,
      'plan_tasks': planTasks,
      'weekly_plans': weeklyPlans,
      'weekly_plan_tasks': weeklyPlanTasks,
      'user_images': imagesExport,
      'user_sounds': soundsExport,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/mytodo_backup_$timestamp.mtd');
    await file.writeAsString(jsonString);

    return file.path;
  }

  static Future<void> shareExport() async {
    final path = await exportToJson();
    await Share.shareXFiles(
      [XFile(path)],
      subject: 'MyTodo Backup',
      text: 'MyTodo backup file',
    );
  }

  static Future<bool> importFromFile({
    Future<bool> Function(bool hasOdd, bool hasEven)? onReplaceSystemPlans,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      final db = await DatabaseHelper.instance.database;
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/media/images');
      final soundsDir = Directory('${dir.path}/media/sounds');
      await imagesDir.create(recursive: true);
      await soundsDir.create(recursive: true);

      final weeklyPlans = (data['weekly_plans'] as List?) ?? [];
      final hasOdd = weeklyPlans.any((wp) =>
      wp['name'] == 'Class (Odd)' && (wp['is_system'] as int?) == 1);
      final hasEven = weeklyPlans.any((wp) =>
      wp['name'] == 'Class (Even)' && (wp['is_system'] as int?) == 1);

      bool replaceSystem = true;
      if (onReplaceSystemPlans != null && (hasOdd || hasEven)) {
        replaceSystem = await onReplaceSystemPlans(hasOdd, hasEven);
      }

      await db.transaction((txn) async {
        final existingPlans = await txn.query(DbTables.plans, columns: ['name']);
        final existingPlanNames = existingPlans.map((p) => p['name'] as String).toSet();

        final existingWps = await txn.query(DbTables.weeklyPlans,
            columns: ['name'], where: '${DbCols.isSystem} = 0');
        final existingWpNames = existingWps.map((p) => p['name'] as String).toSet();

        final existingImgs = await txn.query(DbTables.userImages, columns: ['name']);
        final existingImgNames = existingImgs.map((p) => p['name'] as String).toSet();

        final existingSnds = await txn.query(DbTables.userSounds, columns: ['name']);
        final existingSndNames = existingSnds.map((p) => p['name'] as String).toSet();

        String uniqueName(String base, Set<String> existing) {
          if (!existing.contains(base)) return base;
          int counter = 1;
          while (existing.contains('${base}_import_$counter')) {
            counter++;
          }
          return '${base}_import_$counter';
        }

        // Plans
        final plans = (data['plans'] as List?) ?? [];
        final planOldToNew = <int, int>{};
        for (final p in plans) {
          final planMap = Map<String, dynamic>.from(p as Map);
          final oldId = planMap['id'] as int?;
          planMap.remove('id');
          final originalName = planMap['name'] as String? ?? '';
          if (existingPlanNames.contains(originalName)) {
            planMap['name'] = uniqueName(originalName, existingPlanNames);
            existingPlanNames.add(planMap['name']);
          } else {
            existingPlanNames.add(originalName);
          }
          final newId = await txn.insert(DbTables.plans, planMap);
          if (oldId != null) planOldToNew[oldId] = newId;
        }

        // Plan tasks
        final planTasks = (data['plan_tasks'] as List?) ?? [];
        for (final t in planTasks) {
          final taskMap = Map<String, dynamic>.from(t as Map);
          taskMap.remove('id');
          final oldPlanId = taskMap['plan_id'] as int?;
          if (oldPlanId != null && planOldToNew.containsKey(oldPlanId)) {
            taskMap['plan_id'] = planOldToNew[oldPlanId];
          }
          await txn.insert(DbTables.planTasks, taskMap);
        }

        // Weekly plans
        final wpOldToNew = <int, int>{};
        for (final wp in weeklyPlans) {
          final wpMap = Map<String, dynamic>.from(wp as Map);
          final oldId = wpMap['id'] as int?;
          wpMap.remove('id');
          final isSystem = (wpMap[DbCols.isSystem] as int?) == 1;

          if (isSystem) {
            if (replaceSystem) {
              final existing = await txn.query(
                DbTables.weeklyPlans,
                where: '${DbCols.name} = ? AND ${DbCols.isSystem} = 1',
                whereArgs: [wpMap[DbCols.name]],
              );
              if (existing.isNotEmpty) {
                final existingId = existing.first['id'] as int;
                if (oldId != null) wpOldToNew[oldId] = existingId;
                await txn.delete(DbTables.weeklyPlanTasks,
                    where: '${DbCols.weeklyPlanId} = ?', whereArgs: [existingId]);
                await txn.update(DbTables.weeklyPlans, wpMap,
                    where: '${DbCols.id} = ?', whereArgs: [existingId]);
              }
            } else {
              continue;
            }
          } else {
            final originalName = wpMap['name'] as String? ?? '';
            if (existingWpNames.contains(originalName)) {
              wpMap['name'] = uniqueName(originalName, existingWpNames);
              existingWpNames.add(wpMap['name']);
            } else {
              existingWpNames.add(originalName);
            }
            final newId = await txn.insert(DbTables.weeklyPlans, wpMap);
            if (oldId != null) wpOldToNew[oldId] = newId;
          }
        }

        // Weekly plan tasks
        final weeklyPlanTasks = (data['weekly_plan_tasks'] as List?) ?? [];
        for (final t in weeklyPlanTasks) {
          final taskMap = Map<String, dynamic>.from(t as Map);
          taskMap.remove('id');
          final oldWpId = taskMap['weekly_plan_id'] as int?;
          if (oldWpId != null && wpOldToNew.containsKey(oldWpId)) {
            taskMap['weekly_plan_id'] = wpOldToNew[oldWpId];
          }
          await txn.insert(DbTables.weeklyPlanTasks, taskMap);
        }

        // User images — decode base64, write to file, store path
        final userImages = (data['user_images'] as List?) ?? [];
        for (final img in userImages) {
          final imgMap = Map<String, dynamic>.from(img as Map);
          imgMap.remove('id');
          final originalName = imgMap['name'] as String? ?? '';
          final name = existingImgNames.contains(originalName)
              ? uniqueName(originalName, existingImgNames)
              : originalName;
          existingImgNames.add(name);
          imgMap['name'] = name;

          final base64Str = imgMap['data_base64'] as String?;
          if (base64Str != null) {
            final bytes = base64Decode(base64Str);
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final ext = name.split('.').last;
            final file = File('${imagesDir.path}/img_import_$timestamp.$ext');
            await file.writeAsBytes(bytes);
            imgMap['file_path'] = file.path;
          } else {
            imgMap['file_path'] = '';
          }
          imgMap.remove('data_base64');
          await txn.insert(DbTables.userImages, imgMap);
        }

        // User sounds — decode base64, write to file, store path
        final userSounds = (data['user_sounds'] as List?) ?? [];
        for (final snd in userSounds) {
          final sndMap = Map<String, dynamic>.from(snd as Map);
          sndMap.remove('id');
          final originalName = sndMap['name'] as String? ?? '';
          final name = existingSndNames.contains(originalName)
              ? uniqueName(originalName, existingSndNames)
              : originalName;
          existingSndNames.add(name);
          sndMap['name'] = name;

          final base64Str = sndMap['data_base64'] as String?;
          if (base64Str != null) {
            final bytes = base64Decode(base64Str);
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final ext = name.split('.').last;
            final file = File('${soundsDir.path}/snd_import_$timestamp.$ext');
            await file.writeAsBytes(bytes);
            sndMap['file_path'] = file.path;
          } else {
            sndMap['file_path'] = '';
          }
          sndMap.remove('data_base64');
          await txn.insert(DbTables.userSounds, sndMap);
        }
      });

      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }

  static Future<String> localBackup() async {
    return await exportToJson();
  }
}