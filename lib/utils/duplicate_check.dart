import '../models/task.dart';

/// Returns true if a task with the same title AND time already exists in the list.
bool isDuplicateTask(List<Task> existingTasks, String title, String? time) {
  return existingTasks.any((t) => t.title == title && t.time == time);
}