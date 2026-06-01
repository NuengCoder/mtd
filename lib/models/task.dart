class Task {
  final int? id;
  final String title;
  final String date; // YYYY-MM-DD
  final String? time; // HH:mm, nullable
  final String? notifyTime; // HH:mm, nullable
  final bool isComplete;
  final int? imageId;
  final int? soundId;
  final String createdAt;
  final String updatedAt;

  const Task({
    this.id,
    required this.title,
    required this.date,
    this.time,
    this.notifyTime,
    this.isComplete = false,
    this.imageId,
    this.soundId,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    int? id,
    String? title,
    String? date,
    String? time,
    String? notifyTime,
    bool? isComplete,
    int? imageId,
    int? soundId,
    String? createdAt,
    String? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      notifyTime: notifyTime ?? this.notifyTime,
      isComplete: isComplete ?? this.isComplete,
      imageId: imageId ?? this.imageId,
      soundId: soundId ?? this.soundId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'notify_time': notifyTime,
      'is_complete': isComplete ? 1 : 0,
      'image_id': imageId,
      'sound_id': soundId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      date: map['date'] as String,
      time: map['time'] as String?,
      notifyTime: map['notify_time'] as String?,
      isComplete: (map['is_complete'] as int) == 1,
      imageId: map['image_id'] as int?,
      soundId: map['sound_id'] as int?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  /// For sorting: parses time to comparable value.
  /// null times return max int to sink to bottom.
  int get timeInMinutes {
    if (time == null) return 1440; // 24 * 60 = sentinel for null
    final parts = time!.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}