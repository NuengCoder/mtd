import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_image.dart';
import '../models/user_sound.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/media_providers.dart';
import '../repositories/user_image_repository.dart';
import '../repositories/user_sound_repository.dart';
import '../services/custom_notification_plugin.dart';
import 'dart:io' as dart_io;

class MediaSettingsScreen extends ConsumerStatefulWidget {
  const MediaSettingsScreen({super.key});

  @override
  ConsumerState<MediaSettingsScreen> createState() =>
      _MediaSettingsScreenState();
}

class _MediaSettingsScreenState extends ConsumerState<MediaSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _mediaDir;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initMediaDir();
  }

  Future<void> _initMediaDir() async {
    final dir = await getApplicationDocumentsDirectory();
    _mediaDir = '${dir.path}/media';
    await dart_io.Directory('$_mediaDir/images').create(recursive: true);
    await dart_io.Directory('$_mediaDir/sounds').create(recursive: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'img_$timestamp.${picked.name.split('.').last}';
    final file = dart_io.File('$_mediaDir/images/$fileName');
    await file.writeAsBytes(bytes);

    final repo = ref.read(userImageRepositoryProvider);
    await repo.insert(UserImage(
      name: picked.name,
      filePath: file.path,
      createdAt: DateTime.now().toIso8601String(),
    ));
    ref.invalidate(allUserImagesProvider);
  }

  Future<void> _addSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final sourcePath = picked.path;
    if (sourcePath == null) return;

    final sourceFile = dart_io.File(sourcePath);
    final bytes = await sourceFile.readAsBytes();

    int durationMs = 0;
    try {
      await _audioPlayer.setSourceDeviceFile(sourcePath);
      final duration = await _audioPlayer.getDuration();
      if (duration != null) {
        durationMs = duration.inMilliseconds;
      }
    } catch (_) {}

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = picked.name.split('.').last;
    final fileName = 'snd_$timestamp.$ext';
    final file = dart_io.File('$_mediaDir/sounds/$fileName');
    await file.writeAsBytes(bytes);

    // Register with MediaStore for notification access
    String? mediaUri;
    try {
      mediaUri = await CustomNotificationPlugin.registerSound(file.path);
      debugPrint('[MediaStore] Sound registered: $mediaUri');
    } catch (e) {
      debugPrint('[MediaStore] Register failed: $e');
    }

    final repo = ref.read(userSoundRepositoryProvider);
    await repo.insert(UserSound(
      name: picked.name,
      filePath: file.path,
      mediaUri: mediaUri,
      durationMs: durationMs,
      createdAt: DateTime.now().toIso8601String(),
    ));
    ref.invalidate(allUserSoundsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

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
        title: Text(tr('media_settings')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr('images')),
            Tab(text: tr('sounds')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ImagesTab(taskTextColor: taskTextColor, onAdd: _addImage),
          _SoundsTab(
            taskTextColor: taskTextColor,
            onAdd: _addSound,
            audioPlayer: _audioPlayer,
          ),
        ],
      ),
    );
  }
}

String _truncate(String s, int max) =>
    s.length > max ? '${s.substring(0, max)}...' : s;

class _ImagesTab extends ConsumerWidget {
  final Color taskTextColor;
  final VoidCallback onAdd;

  const _ImagesTab({required this.taskTextColor, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final imagesAsync = ref.watch(allUserImagesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(tr('add_image')),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: imagesAsync.when(
            data: (images) {
              if (images.isEmpty) {
                return Center(
                    child: Text(tr('no_image'),
                        style: TextStyle(color: taskTextColor)));
              }
              return ListView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final img = images[index];
                  final file = dart_io.File(img.filePath);
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: file.existsSync()
                          ? Image.file(file, width: 48, height: 48, fit: BoxFit.cover)
                          : Container(
                              width: 48, height: 48,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image)),
                    ),
                    title: Text(img.name, style: TextStyle(color: taskTextColor)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () async {
                        final repo = ref.read(userImageRepositoryProvider);
                        await repo.delete(img.id!);
                        ref.invalidate(allUserImagesProvider);
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('${tr('error')}: $e', style: TextStyle(color: taskTextColor))),
          ),
        ),
      ],
    );
  }
}

class _SoundsTab extends ConsumerStatefulWidget {
  final Color taskTextColor;
  final VoidCallback onAdd;
  final AudioPlayer audioPlayer;

  const _SoundsTab({
    required this.taskTextColor,
    required this.onAdd,
    required this.audioPlayer,
  });

  @override
  ConsumerState<_SoundsTab> createState() => _SoundsTabState();
}

class _SoundsTabState extends ConsumerState<_SoundsTab> {
  int? _playingId;

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final soundsAsync = ref.watch(allUserSoundsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(tr('add_sound')),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: soundsAsync.when(
            data: (sounds) {
              if (sounds.isEmpty) {
                return Center(
                    child: Text(tr('no_sound'),
                        style: TextStyle(color: widget.taskTextColor)));
              }
              return ListView.builder(
                itemCount: sounds.length,
                itemBuilder: (context, index) {
                  final snd = sounds[index];
                  final isPlaying = _playingId == snd.id;
                  final fileExists = dart_io.File(snd.filePath).existsSync();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(
                        isPlaying ? Icons.volume_up : Icons.music_note,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: Text(_truncate(snd.name, 20),
                        style: TextStyle(color: widget.taskTextColor)),
                    subtitle: Text(
                      '${(snd.durationMs / 1000).toStringAsFixed(1)}s',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (fileExists)
                          IconButton(
                            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow, size: 20),
                            onPressed: () async {
                              if (isPlaying) {
                                await widget.audioPlayer.stop();
                                setState(() => _playingId = null);
                              } else {
                                await widget.audioPlayer.stop();
                                await widget.audioPlayer.play(DeviceFileSource(snd.filePath));
                                setState(() => _playingId = snd.id);
                                widget.audioPlayer.onPlayerComplete.first.then((_) {
                                  if (mounted) setState(() => _playingId = null);
                                }).catchError((_) {});
                              }
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () async {
                            await widget.audioPlayer.stop();
                            setState(() => _playingId = null);
                            final repo = ref.read(userSoundRepositoryProvider);
                            await repo.delete(snd.id!);
                            ref.invalidate(allUserSoundsProvider);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('${tr('error')}: $e', style: TextStyle(color: widget.taskTextColor))),
          ),
        ),
      ],
    );
  }
}