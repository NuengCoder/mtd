class Homework {
  final int? id;
  final String name;
  final String deployDate; // DD/MM
  final String deadlineDate; // DD/MM
  final bool isSubmitted;
  final int? imageId;
  final String createdAt;
  final String updatedAt;

  const Homework({
    this.id,
    required this.name,
    required this.deployDate,
    required this.deadlineDate,
    this.isSubmitted = false,
    this.imageId,
    required this.createdAt,
    required this.updatedAt,
  });

  Homework copyWith({
    int? id,
    String? name,
    String? deployDate,
    String? deadlineDate,
    bool? isSubmitted,
    int? imageId,
    String? createdAt,
    String? updatedAt,
  }) {
    return Homework(
      id: id ?? this.id,
      name: name ?? this.name,
      deployDate: deployDate ?? this.deployDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      imageId: imageId ?? this.imageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'deploy_date': deployDate,
      'deadline_date': deadlineDate,
      'is_submitted': isSubmitted ? 1 : 0,
      'image_id': imageId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Homework.fromMap(Map<String, dynamic> map) {
    return Homework(
      id: map['id'] as int?,
      name: map['name'] as String,
      deployDate: map['deploy_date'] as String,
      deadlineDate: map['deadline_date'] as String,
      isSubmitted: (map['is_submitted'] as int) == 1,
      imageId: map['image_id'] as int?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}