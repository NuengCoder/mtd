import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../providers/task_providers.dart';
import '../providers/config_provider.dart';
import '../widgets/expandable_fab.dart';
import '../widgets/task_card.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalDays = 7;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _dateForOffset(int offset) {
    final date = DateTime.now().add(Duration(days: offset));
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _dateDisplay(int offset) {
    final date = DateTime.now().add(Duration(days: offset));
    return DateFormat('dd/MM').format(date);
  }

  String _weekdayDisplay(int offset, String Function(String) tr) {
    final date = DateTime.now().add(Duration(days: offset));
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return tr(weekdays[date.weekday - 1]);
  }

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return weekNumber;
  }

  bool _isOddWeek(int offset) {
    final date = DateTime.now().add(Duration(days: offset));
    final isoWeek = _isoWeekNumber(date);
    return isoWeek % 2 != 0;
  }

  String _badgeText(int offset, String Function(String) tr, bool flipped) {
    final isOdd = _isOddWeek(offset);
    final effectiveOdd = flipped ? !isOdd : isOdd;
    return effectiveOdd ? tr('badge_odd') : tr('badge_even');
  }

  Color _badgeColor(int offset, bool flipped) {
    final isOdd = _isOddWeek(offset);
    final effectiveOdd = flipped ? !isOdd : isOdd;
    return effectiveOdd ? Colors.green : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final weekFlippedAsync = ref.watch(weekTypeFlippedProvider);
    final weekFlipped = weekFlippedAsync.valueOrNull ?? false;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _totalDays,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentPage;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentPage = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 76,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            index == 0
                                ? tr('today')
                                : _weekdayDisplay(index, tr),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            _dateDisplay(index),
                            style: const TextStyle(fontSize: 9),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _badgeColor(index, weekFlipped),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _badgeText(index, tr, weekFlipped),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalDays,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) {
                  final date = _dateForOffset(index);
                  return _TaskListForDate(date: date);
                },
              ),
            ),
          ],
        ),
        ExpandableFab(selectedDate: _dateForOffset(_currentPage)),
      ],
    );
  }
}

class _TaskListForDate extends ConsumerWidget {
  final String date;
  const _TaskListForDate({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final tasksAsync = ref.watch(tasksForDateProvider(date));

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Text(
              tr('no_tasks'),
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return TaskCard(task: tasks[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${tr('error')}: $e')),
    );
  }
}