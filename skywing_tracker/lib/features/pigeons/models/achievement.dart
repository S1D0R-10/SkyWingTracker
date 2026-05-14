class Achievement {
  final String id;
  final String pigeonId;
  final String title;
  final String description;
  final String? iconName;
  final DateTime earnedAt;

  const Achievement({
    required this.id,
    required this.pigeonId,
    required this.title,
    required this.description,
    this.iconName,
    required this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      pigeonId: json['pigeon_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String?,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pigeon_id': pigeonId,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'earned_at': earnedAt.toIso8601String(),
    };
  }
}
