class UserImage {
  final int? id;
  final String name;
  final String filePath;
  final String createdAt;

  const UserImage({
    this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
  });

  UserImage copyWith({
    int? id,
    String? name,
    String? filePath,
    String? createdAt,
  }) {
    return UserImage(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
      'created_at': createdAt,
    };
  }

  factory UserImage.fromMap(Map<String, dynamic> map) {
    return UserImage(
      id: map['id'] as int?,
      name: map['name'] as String,
      filePath: (map['file_path'] ?? '') as String,
      createdAt: map['created_at'] as String,
    );
  }
}