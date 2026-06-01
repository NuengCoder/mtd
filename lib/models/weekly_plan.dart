class WeeklyPlan {
  final int? id;
  final String name;
  final bool isSystem;
  final bool autoDeploy;
  final String createdAt;
  final String updatedAt;

  const WeeklyPlan({
    this.id,
    required this.name,
    this.isSystem = false,
    this.autoDeploy = false,
    required this.createdAt,
    required this.updatedAt,
  });

  WeeklyPlan copyWith({
    int? id,
    String? name,
    bool? isSystem,
    bool? autoDeploy,
    String? createdAt,
    String? updatedAt,
  }) {
    return WeeklyPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      isSystem: isSystem ?? this.isSystem,
      autoDeploy: autoDeploy ?? this.autoDeploy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_system': isSystem ? 1 : 0,
      'auto_deploy': autoDeploy ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory WeeklyPlan.fromMap(Map<String, dynamic> map) {
    return WeeklyPlan(
      id: map['id'] as int?,
      name: map['name'] as String,
      isSystem: (map['is_system'] as int) == 1,
      autoDeploy: (map['auto_deploy'] as int) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}