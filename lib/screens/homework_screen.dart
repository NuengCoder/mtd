import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../providers/homework_providers.dart';
import '../widgets/homework_card.dart';
import '../widgets/homework_fab.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final homeworkAsync = ref.watch(allHomeworkProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        homeworkAsync.when(
          data: (homeworks) {
            if (homeworks.isEmpty) {
              return Center(
                child: Text(
                  tr('no_homework'),
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: homeworks.length,
              itemBuilder: (context, index) {
                return HomeworkCard(homework: homeworks[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('${tr('error')}: $e')),
        ),
        const HomeworkFab(),
      ],
    );
  }
}