enum FlightStatus { released, returned, missing, injured }

enum FlightType { training, competition }

class FlightSession {
  final String id;
  final String ownerId;
  final String name;
  final FlightType type;
  final FlightStatus status;
  final DateTime releaseTime;
  final DateTime? endTime;
  final double releaseLatitude;
  final double releaseLongitude;
  final String? releaseLocationName;
  final double? loftLatitude;
  final double? loftLongitude;
  final double? finishLatitude;
  final double? finishLongitude;
  final String? finishLocationName;
  final String? weatherConditions;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FlightSession({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.status,
    required this.releaseTime,
    this.endTime,
    required this.releaseLatitude,
    required this.releaseLongitude,
    this.releaseLocationName,
    this.loftLatitude,
    this.loftLongitude,
    this.finishLatitude,
    this.finishLongitude,
    this.finishLocationName,
    this.weatherConditions,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlightSession.fromJson(Map<String, dynamic> json) {
    return FlightSession(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      type: FlightType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
        orElse: () => FlightType.training,
      ),
      status: FlightStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => FlightStatus.released,
      ),
      releaseTime: DateTime.parse(json['release_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      releaseLatitude: (json['release_latitude'] as num).toDouble(),
      releaseLongitude: (json['release_longitude'] as num).toDouble(),
      releaseLocationName: json['release_location_name'] as String?,
      loftLatitude: json['loft_latitude'] != null
          ? (json['loft_latitude'] as num).toDouble()
          : null,
      loftLongitude: json['loft_longitude'] != null
          ? (json['loft_longitude'] as num).toDouble()
          : null,
      finishLatitude: json['finish_latitude'] != null
          ? (json['finish_latitude'] as num).toDouble()
          : null,
      finishLongitude: json['finish_longitude'] != null
          ? (json['finish_longitude'] as num).toDouble()
          : null,
      finishLocationName: json['finish_location_name'] as String?,
      weatherConditions: json['weather_conditions'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'type': type.name,
      'status': status.name,
      'release_time': releaseTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'release_latitude': releaseLatitude,
      'release_longitude': releaseLongitude,
      'release_location_name': releaseLocationName,
      'loft_latitude': loftLatitude,
      'loft_longitude': loftLongitude,
      'finish_latitude': finishLatitude,
      'finish_longitude': finishLongitude,
      'finish_location_name': finishLocationName,
      'weather_conditions': weatherConditions,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FlightSession copyWith({
    String? id,
    String? ownerId,
    String? name,
    FlightType? type,
    FlightStatus? status,
    DateTime? releaseTime,
    DateTime? endTime,
    double? releaseLatitude,
    double? releaseLongitude,
    String? releaseLocationName,
    double? loftLatitude,
    double? loftLongitude,
    double? finishLatitude,
    double? finishLongitude,
    String? finishLocationName,
    String? weatherConditions,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlightSession(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      releaseTime: releaseTime ?? this.releaseTime,
      endTime: endTime ?? this.endTime,
      releaseLatitude: releaseLatitude ?? this.releaseLatitude,
      releaseLongitude: releaseLongitude ?? this.releaseLongitude,
      releaseLocationName: releaseLocationName ?? this.releaseLocationName,
      loftLatitude: loftLatitude ?? this.loftLatitude,
      loftLongitude: loftLongitude ?? this.loftLongitude,
      finishLatitude: finishLatitude ?? this.finishLatitude,
      finishLongitude: finishLongitude ?? this.finishLongitude,
      finishLocationName: finishLocationName ?? this.finishLocationName,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
