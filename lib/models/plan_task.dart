class PlanTask {
  final int? id;
  final int planId;
  final String title;
  final String? time; // HH:mm, nullable
  final String? notifyTime; // HH:mm, nullable
  final int? soundId;
  final int? imageId;
  final String createdAt;

  const PlanTask({
    this.id,
    required this.planId,
    required this.title,
    this.time,
    this.notifyTime,
    this.soundId,
    this.imageId,
    required this.createdAt,
  });

  PlanTask copyWith({
    int? id,
    int? planId,
    String? title,
    String? time,
    String? notifyTime,
    int? soundId,
    int? imageId,
    String? createdAt,
  }) {
    return PlanTask(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      title: title ?? this.title,
      time: time ?? this.time,
      notifyTime: notifyTime ?? this.notifyTime,
      soundId: soundId ?? this.soundId,
      imageId: imageId ?? this.imageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'title': title,
      'time': time,
      'notify_time': notifyTime,
      'sound_id': soundId,
      'image_id': imageId,
      'created_at': createdAt,
    };
  }

  factory PlanTask.fromMap(Map<String, dynamic> map) {
    return PlanTask(
      id: map['id'] as int?,
      planId: map['plan_id'] as int,
      title: map['title'] as String,
      time: map['time'] as String?,
      notifyTime: map['notify_time'] as String?,
      soundId: map['sound_id'] as int?,
      imageId: map['image_id'] as int?,
      createdAt: map['created_at'] as String,
    );
  }

  int get timeInMinutes {
    if (time == null) return 1440;
    final parts = time!.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}