import 'package:flutter/material.dart' ;
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/config_provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timetable_provider.dart';
import '../repositories/settings_repository.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border ;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportXlsx() async {
    final tr = ref.read(trProvider);

    try {
      final excel = Excel.createExcel();
      final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

      final themeModeAsync = ref.read(themeModeProvider);
      final themeMode = themeModeAsync.valueOrNull ?? 'light';
      final isDark = themeMode == 'dark';

      final headerBg = isDark ? 'FF2C2C2C' : 'FF4472C4';
      final headerText = 'FFFFFFFF';
      final timeColBg = isDark ? 'FF3A3A3A' : 'FFF2F2F2';
      final evenRowBg = isDark ? 'FF1E1E1E' : 'FFFFFFFF';
      final oddRowBg = isDark ? 'FF252525' : 'FFF8F8F8';
      final taskCellBg = isDark ? 'FF1A3A5C' : 'FFD6E4F0';
      final textColor = isDark ? 'FFFFFFFF' : 'FF333333';

      for (int week = 0; week < 2; week++) {
        final data = await ref.read(timetableProvider(week).future);
        final sheetName = week == 0 ? tr('this_week') : tr('next_week');
        final safeName = sheetName.length > 31 ? sheetName.substring(0, 31) : sheetName;
        final sheet = excel[safeName];

        sheet.setColumnWidth(0, 8.0);
        for (int i = 1; i <= 7; i++) {
          sheet.setColumnWidth(i, 18.0);
        }

        // Determine week type from DB
        final flippedStr = await ref.read(settingsRepositoryProvider).getValue('week_type_flipped');
        final flipped = flippedStr == '1';
        final now = DateTime.now().add(Duration(days: week * 7));
        final dayOfYear = int.parse(DateFormat('D').format(now));
        final isoWeek = ((dayOfYear - now.weekday + 10) / 7).floor();
        final isOdd = isoWeek % 2 != 0;
        final effectiveOdd = flipped ? !isOdd : isOdd;
        final weekLabel = '$safeName (${effectiveOdd ? tr('badge_odd') : tr('badge_even')})';

        // Title row
        final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
        titleCell.value = TextCellValue(weekLabel);
        titleCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 14,
          fontColorHex: ExcelColor.fromHexString(headerText),
          backgroundColorHex: ExcelColor.fromHexString('FF1F4E79'),
          horizontalAlign: HorizontalAlign.Center,
        );
        sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
            CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0));

        // Header row
        final headerRow = <String>['Time'];
        for (final wd in weekdays) {
          headerRow.add(tr(wd));
        }
        for (int col = 0; col < headerRow.length; col++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1),
          );
          cell.value = TextCellValue(headerRow[col]);
          cell.cellStyle = CellStyle(
            bold: true,
            fontSize: 11,
            fontColorHex: ExcelColor.fromHexString(headerText),
            backgroundColorHex: ExcelColor.fromHexString(headerBg),
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }

        // Data rows
        for (int row = 0; row < data.timeSlots.length; row++) {
          final ts = data.timeSlots[row];
          final isEvenRow = row % 2 == 0;

          final timeCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 2),
          );
          timeCell.value = TextCellValue(ts);
          timeCell.cellStyle = CellStyle(
            bold: true,
            fontSize: 10,
            fontColorHex: ExcelColor.fromHexString(textColor),
            backgroundColorHex: ExcelColor.fromHexString(timeColBg),
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );

          for (int col = 0; col < weekdays.length; col++) {
            final tasks = data.grid[weekdays[col]]?[ts] ?? [];
            final hasTasks = tasks.isNotEmpty;
            final taskNames = tasks.map((t) => t.title).join('\n');

            final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: col + 1, rowIndex: row + 2),
            );
            cell.value = TextCellValue(taskNames);
            cell.cellStyle = CellStyle(
              fontSize: 9,
              fontColorHex: ExcelColor.fromHexString(textColor),
              backgroundColorHex: ExcelColor.fromHexString(
                hasTasks ? taskCellBg : (isEvenRow ? evenRowBg : oddRowBg),
              ),
              horizontalAlign: HorizontalAlign.Left,
              verticalAlign: VerticalAlign.Center,
              textWrapping: TextWrapping.WrapText,
            );
          }
        }
      }

      if (excel.sheets.containsKey('Sheet1') && excel.sheets.length > 2) {
        excel.delete('Sheet1');
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/mytodo_timetable_$timestamp.xlsx');
      await file.writeAsBytes(excel.encode()!);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'MyTodo Timetable',
        text: '${tr('timetable')} - MyTodo',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('export_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('timetable')),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: tr('export_xlsx'),
            onPressed: () => _exportXlsx(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr('this_week')),
            Tab(text: tr('next_week')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TimetableGrid(
            weekOffset: 0,
            taskTextColor: taskTextColor,
          ),
          _TimetableGrid(
            weekOffset: 1,
            taskTextColor: taskTextColor,
          ),
        ],
      ),
    );
  }
}

class _TimetableGrid extends ConsumerWidget {
  final int weekOffset;
  final Color taskTextColor;

  const _TimetableGrid({
    required this.weekOffset,
    required this.taskTextColor,
  });

  bool _isEffectiveOdd(WidgetRef ref) {
    final flippedAsync = ref.read(weekTypeFlippedProvider);
    final flipped = flippedAsync.valueOrNull ?? false;
    final now = DateTime.now().add(Duration(days: weekOffset * 7));
    final dayOfYear = int.parse(DateFormat('D').format(now));
    final isoWeek = ((dayOfYear - now.weekday + 10) / 7).floor();
    final isOdd = isoWeek % 2 != 0;
    return flipped ? !isOdd : isOdd;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final dataAsync = ref.watch(timetableProvider(weekOffset));

    // Theme colors
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? 'light';
    final colorsAsync = ref.watch(themeColorsProvider(themeMode));
    final colors = colorsAsync.valueOrNull ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = colors['App Task Card'] ??
        (isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD));
    final headerColor = colors['App Secondary Primary'] ??
        (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8E0F0));

    return dataAsync.when(
      data: (data) {
        if (data.timeSlots.isEmpty) {
          return Center(
              child: Text(tr('no_tasks'),
                  style: TextStyle(color: taskTextColor)));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        color: headerColor,
                      ),
                      child: Center(
                        child: Text(
                          _isEffectiveOdd(ref) ? tr('badge_odd') : tr('badge_even'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: taskTextColor,
                          ),
                        ),
                      ),
                    ),
                    ...data.weekdays.map((wd) => Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        color: headerColor,
                      ),
                      child: Center(
                        child: Text(
                          tr(wd),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: taskTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
                ...data.timeSlots.map((ts) {
                  final isNow = _isCurrentTimeSlot(ts);
                  return Row(
                    children: [
                      Container(
                        width: 60,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          color: isNow
                              ? Colors.green.withAlpha(30)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            ts,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                              isNow ? FontWeight.bold : FontWeight.normal,
                              color: taskTextColor,
                            ),
                          ),
                        ),
                      ),
                      ...data.weekdays.map((wd) {
                        final tasks = data.grid[wd]?[ts] ?? [];
                        final hasTasks = tasks.isNotEmpty;
                        return Container(
                          width: 100,
                          height: hasTasks
                              ? (50.0 * tasks.length).clamp(50, 150)
                              : 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            color: hasTasks
                                ? isNow
                                ? Colors.green.withAlpha(50)
                                : (colors['App Task Card'] ??
                                (isDark
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFFF5F5F5)))
                                .withAlpha(200)
                                : isNow
                                ? Colors.green.withAlpha(20)
                                : null,
                          ),
                          child: hasTasks
                              ? Padding(
                            padding: const EdgeInsets.all(2),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: tasks
                                  .map((t) => Text(
                                t.title,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: taskTextColor,
                                ),
                                overflow:
                                TextOverflow.ellipsis,
                                maxLines: 1,
                              ))
                                  .toList(),
                            ),
                          )
                              : null,
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('${tr('error')}: $e',
              style: TextStyle(color: taskTextColor))),
    );
  }

  bool _isCurrentTimeSlot(String slot) {
    final now = DateTime.now();
    final parts = slot.split(':');
    final slotHour = int.parse(parts[0]);
    final slotMinute = int.parse(parts[1]);
    final slotTime =
    DateTime(now.year, now.month, now.day, slotHour, slotMinute);
    final nextSlot = slotTime.add(const Duration(minutes: 1));
    return now.isAfter(slotTime) && now.isBefore(nextSlot);
  }
}