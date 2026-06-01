class ThemeSetting {
  final int? id;
  final String mode; // light, dark
  final String colorKey; // App Text, App Primary, etc.
  final String argbValue; // 8-char hex

  const ThemeSetting({
    this.id,
    required this.mode,
    required this.colorKey,
    required this.argbValue,
  });

  ThemeSetting copyWith({
    int? id,
    String? mode,
    String? colorKey,
    String? argbValue,
  }) {
    return ThemeSetting(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      colorKey: colorKey ?? this.colorKey,
      argbValue: argbValue ?? this.argbValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mode': mode,
      'color_key': colorKey,
      'argb_value': argbValue,
    };
  }

  factory ThemeSetting.fromMap(Map<String, dynamic> map) {
    return ThemeSetting(
      id: map['id'] as int?,
      mode: map['mode'] as String,
      colorKey: map['color_key'] as String,
      argbValue: map['argb_value'] as String,
    );
  }
}