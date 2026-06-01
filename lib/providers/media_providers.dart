import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_image.dart';
import '../models/user_sound.dart';
import '../repositories/user_image_repository.dart';
import '../repositories/user_sound_repository.dart';

final allUserImagesProvider = FutureProvider<List<UserImage>>((ref) async {
  final repo = ref.watch(userImageRepositoryProvider);
  return await repo.getAll();
});

final allUserSoundsProvider = FutureProvider<List<UserSound>>((ref) async {
  final repo = ref.watch(userSoundRepositoryProvider);
  return await repo.getAll();
});