import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/homework.dart';
import '../repositories/homework_repository.dart';

/// All homework, sorted by deadline.
final allHomeworkProvider = FutureProvider<List<Homework>>((ref) async {
  final repo = ref.watch(homeworkRepositoryProvider);
  return await repo.getAll();
});

/// Pending homework only (not submitted).
final pendingHomeworkProvider = FutureProvider<List<Homework>>((ref) async {
  final repo = ref.watch(homeworkRepositoryProvider);
  return await repo.getPending();
});

/// Count of pending homework — used for badge.
final pendingHomeworkCountProvider = FutureProvider<int>((ref) async {
  final pending = ref.watch(pendingHomeworkProvider);
  return pending.valueOrNull?.length ?? 0;
});