class UserSound {
  final int? id;
  final String name;
  final String filePath;
  final String? mediaUri;
  final int durationMs;
  final String createdAt;

  const UserSound({
    this.id,
    required this.name,
    required this.filePath,
    this.mediaUri,
    required this.durationMs,
    required this.createdAt,
  });

  UserSound copyWith({
    int? id,
    String? name,
    String? filePath,
    String? mediaUri,
    int? durationMs,
    String? createdAt,
  }) {
    return UserSound(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      mediaUri: mediaUri ?? this.mediaUri,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
      'media_uri': mediaUri,
      'duration_ms': durationMs,
      'created_at': createdAt,
    };
  }

  factory UserSound.fromMap(Map<String, dynamic> map) {
    return UserSound(
      id: map['id'] as int?,
      name: map['name'] as String,
      filePath: (map['file_path'] ?? '') as String,
      mediaUri: map['media_uri'] as String?,
      durationMs: map['duration_ms'] as int,
      createdAt: map['created_at'] as String,
    );
  }
}