class Setting {
  final String key;
  final String value;

  const Setting({required this.key, required this.value});

  Setting copyWith({String? key, String? value}) {
    return Setting(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
    };
  }

  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(
      key: map['key'] as String,
      value: map['value'] as String,
    );
  }
}