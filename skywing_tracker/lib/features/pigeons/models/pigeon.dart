class Pigeon {
  final String id;
  final String ownerId;
  final String ringNumber;
  final String name;
  final String sex; // 'male' | 'female'
  final String breed;
  final String? color;
  final DateTime? hatchDate;
  final String? healthNotes;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Pigeon({
    required this.id,
    required this.ownerId,
    required this.ringNumber,
    required this.name,
    required this.sex,
    required this.breed,
    this.color,
    this.hatchDate,
    this.healthNotes,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pigeon.fromJson(Map<String, dynamic> json) {
    return Pigeon(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      ringNumber: json['ring_number'] as String,
      name: json['name'] as String,
      sex: json['sex'] as String,
      breed: json['breed'] as String,
      color: json['color'] as String?,
      hatchDate: json['hatch_date'] != null
          ? DateTime.parse(json['hatch_date'] as String)
          : null,
      healthNotes: json['health_notes'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'ring_number': ringNumber,
      'name': name,
      'sex': sex,
      'breed': breed,
      'color': color,
      'hatch_date': hatchDate?.toIso8601String(),
      'health_notes': healthNotes,
      'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Pigeon copyWith({
    String? id,
    String? ownerId,
    String? ringNumber,
    String? name,
    String? sex,
    String? breed,
    String? color,
    DateTime? hatchDate,
    String? healthNotes,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pigeon(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ringNumber: ringNumber ?? this.ringNumber,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      hatchDate: hatchDate ?? this.hatchDate,
      healthNotes: healthNotes ?? this.healthNotes,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
