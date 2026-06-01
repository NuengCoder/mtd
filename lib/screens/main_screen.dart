import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../providers/config_provider.dart';
import '../repositories/task_repository.dart';
import '../providers/task_providers.dart';
import '../providers/homework_providers.dart';
import '../providers/notify_provider.dart';
import '../repositories/user_sound_repository.dart';
import '../services/notification_service.dart';
import 'task_screen.dart';
import 'homework_screen.dart';
import 'settings_screen.dart';
import '../providers/plan_providers.dart';
import '../providers/weekly_plan_providers.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rescheduleNotifications();
    }
  }

  Future<void> _rescheduleNotifications() async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      final tasks = await repo.getAll();
      final leadMinutesAsync = ref.read(notifyLeadMinutesProvider);
      final leadMinutes = leadMinutesAsync.valueOrNull ?? 0;

      final soundRepo = ref.read(userSoundRepositoryProvider);
      final allSounds = await soundRepo.getAll();
      final soundUriMap = <int, String?>{};
      for (final task in tasks) {
        if (task.soundId != null) {
          final sound = allSounds.where((s) => s.id == task.soundId).firstOrNull;
          soundUriMap[task.id!] = sound?.mediaUri;
        }
      }

      NotificationService.rescheduleAll(
        tasks: tasks,
        leadMinutes: leadMinutes,
        soundUris: soundUriMap,
      );
    } catch (_) {}
  }

  List<Widget> _buildTabs(bool homeworkActive) {
    final tabs = <Widget>[
      const TaskScreen(),
      if (homeworkActive) const HomeworkScreen(),
      const SettingsScreen(),
    ];
    return tabs;
  }

  List<BottomNavigationBarItem> _buildNavItems(
      String Function(String) tr, bool homeworkActive) {
    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.check_circle_outline),
        label: tr('tab_tasks'),
      ),
      if (homeworkActive)
        BottomNavigationBarItem(
          icon: _HomeworkBadge(),
          label: tr('tab_homework'),
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings_outlined),
        label: tr('tab_settings'),
      ),
    ];
    return items;
  }

  Future<void> _nukeAllTasks() async {
    final tr = ref.read(trProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('nuke_all')),
        content: Text(tr('nuke_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('yes')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(taskRepositoryProvider);
        await repo.deleteAll();
        ref.invalidate(tasksForDateProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('nuke_all'))),
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
  }



  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final homeworkActiveAsync = ref.watch(homeworkActiveProvider);
    final homeworkActive = homeworkActiveAsync.valueOrNull ?? true;

    final tabs = _buildTabs(homeworkActive);
    final navItems = _buildNavItems(tr, homeworkActive);

    // Clamp index immediately when tabs change
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);
    if (safeIndex != _currentIndex) {
      _currentIndex = safeIndex;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('MyTodo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Notify',
            onPressed: () {
              NotificationService.showTestNotification(
                id: DateTime.now().millisecondsSinceEpoch % 100000,
                title: 'Test Notification',
                body: 'Notification system is working!',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr('refresh'),
            onPressed: () async {
              // Cancel all notifications
              await NotificationService.cancelAll();

              // Reschedule all active task notifications
              final taskRepo = ref.read(taskRepositoryProvider);
              final allTasks = await taskRepo.getAll();
              final leadAsync = ref.read(notifyLeadMinutesProvider);
              final leadMinutes = leadAsync.valueOrNull ?? 0;

              final soundRepo = ref.read(userSoundRepositoryProvider);
              final allSounds = await soundRepo.getAll();

              for (final task in allTasks) {
                if (!task.isComplete && task.time != null) {
                  String? soundUri;
                  if (task.soundId != null) {
                    final sound = allSounds.where((s) => s.id == task.soundId).firstOrNull;
                    soundUri = sound?.mediaUri;
                  }
                  NotificationService.scheduleTaskNotification(
                    taskId: task.id!,
                    taskTitle: task.title,
                    date: task.date,
                    time: task.time!,
                    leadMinutes: leadMinutes,
                    soundUri: soundUri,
                  );
                }
              }

              // Invalidate config providers to re-read settings
              ref.invalidate(weekTypeFlippedProvider);
              ref.invalidate(homeworkActiveProvider);
              ref.invalidate(notifyLeadMinutesProvider);

              // Invalidate all task/homework providers
              ref.invalidate(tasksForDateProvider);
              ref.invalidate(allTasksProvider);
              ref.invalidate(allHomeworkProvider);
              ref.invalidate(pendingHomeworkProvider);
              ref.invalidate(allPlansProvider);
              ref.invalidate(allWeeklyPlansProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('refresh'))),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: tr('nuke_all'),
            onPressed: _nukeAllTasks,
          ),
        ],
      ),
      body: IndexedStack(
        index: safeIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class _HomeworkBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(pendingHomeworkCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    return Badge(
      isLabelVisible: count > 0,
      label: Text(count.toString()),
      child: const Icon(Icons.school_outlined),
    );
  }
}