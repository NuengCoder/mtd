class WeeklyPlanTask {
  final int? id;
  final int weeklyPlanId;
  final String title;
  final String? time; // HH:mm, nullable
  final String weekday; // mon, tue, wed, thu, fri, sat, sun, all
  final String? notifyTime;
  final int? soundId;
  final int? imageId;
  final String createdAt;

  const WeeklyPlanTask({
    this.id,
    required this.weeklyPlanId,
    required this.title,
    this.time,
    required this.weekday,
    this.notifyTime,
    this.soundId,
    this.imageId,
    required this.createdAt,
  });

  WeeklyPlanTask copyWith({
    int? id,
    int? weeklyPlanId,
    String? title,
    String? time,
    String? weekday,
    String? notifyTime,
    int? soundId,
    int? imageId,
    String? createdAt,
  }) {
    return WeeklyPlanTask(
      id: id ?? this.id,
      weeklyPlanId: weeklyPlanId ?? this.weeklyPlanId,
      title: title ?? this.title,
      time: time ?? this.time,
      weekday: weekday ?? this.weekday,
      notifyTime: notifyTime ?? this.notifyTime,
      soundId: soundId ?? this.soundId,
      imageId: imageId ?? this.imageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weekly_plan_id': weeklyPlanId,
      'title': title,
      'time': time,
      'weekday': weekday,
      'notify_time': notifyTime,
      'sound_id': soundId,
      'image_id': imageId,
      'created_at': createdAt,
    };
  }

  factory WeeklyPlanTask.fromMap(Map<String, dynamic> map) {
    return WeeklyPlanTask(
      id: map['id'] as int?,
      weeklyPlanId: map['weekly_plan_id'] as int,
      title: map['title'] as String,
      time: map['time'] as String?,
      weekday: map['weekday'] as String,
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