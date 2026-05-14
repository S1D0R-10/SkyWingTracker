import 'package:skywing_tracker/features/flights/models/flight_session.dart';

class FlightParticipant {
  final String id;
  final String flightSessionId;
  final String pigeonId;
  final String pigeonName;
  final String pigeonRingNumber;
  final FlightStatus status;
  final DateTime? returnTime;
  final String? conditionNotes;
  final String? photoUrl;
  final double? distanceKm;
  final double? speedKmh;

  const FlightParticipant({
    required this.id,
    required this.flightSessionId,
    required this.pigeonId,
    required this.pigeonName,
    required this.pigeonRingNumber,
    required this.status,
    this.returnTime,
    this.conditionNotes,
    this.photoUrl,
    this.distanceKm,
    this.speedKmh,
  });

  factory FlightParticipant.fromJson(Map<String, dynamic> json) {
    return FlightParticipant(
      id: json['id'] as String,
      flightSessionId: json['flight_session_id'] as String,
      pigeonId: json['pigeon_id'] as String,
      pigeonName: json['pigeon_name'] as String,
      pigeonRingNumber: json['pigeon_ring_number'] as String,
      status: FlightStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => FlightStatus.released,
      ),
      returnTime: json['return_time'] != null
          ? DateTime.parse(json['return_time'] as String)
          : null,
      conditionNotes: json['condition_notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      speedKmh: json['speed_kmh'] != null
          ? (json['speed_kmh'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flight_session_id': flightSessionId,
      'pigeon_id': pigeonId,
      'pigeon_name': pigeonName,
      'pigeon_ring_number': pigeonRingNumber,
      'status': status.name,
      'return_time': returnTime?.toIso8601String(),
      'condition_notes': conditionNotes,
      'photo_url': photoUrl,
      'distance_km': distanceKm,
      'speed_kmh': speedKmh,
    };
  }

  FlightParticipant copyWith({
    String? id,
    String? flightSessionId,
    String? pigeonId,
    String? pigeonName,
    String? pigeonRingNumber,
    FlightStatus? status,
    DateTime? returnTime,
    String? conditionNotes,
    String? photoUrl,
    double? distanceKm,
    double? speedKmh,
  }) {
    return FlightParticipant(
      id: id ?? this.id,
      flightSessionId: flightSessionId ?? this.flightSessionId,
      pigeonId: pigeonId ?? this.pigeonId,
      pigeonName: pigeonName ?? this.pigeonName,
      pigeonRingNumber: pigeonRingNumber ?? this.pigeonRingNumber,
      status: status ?? this.status,
      returnTime: returnTime ?? this.returnTime,
      conditionNotes: conditionNotes ?? this.conditionNotes,
      photoUrl: photoUrl ?? this.photoUrl,
      distanceKm: distanceKm ?? this.distanceKm,
      speedKmh: speedKmh ?? this.speedKmh,
    );
  }
}
