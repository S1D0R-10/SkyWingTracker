class PigeonStatistics {
  final String pigeonId;
  final int totalFlights;
  final double avgSpeedKmh;
  final double totalDistanceKm;
  final double returnRate; // 0.0-1.0
  final double? bestSpeedKmh;
  final DateTime? lastFlightDate;

  const PigeonStatistics({
    required this.pigeonId,
    required this.totalFlights,
    required this.avgSpeedKmh,
    required this.totalDistanceKm,
    required this.returnRate,
    this.bestSpeedKmh,
    this.lastFlightDate,
  });

  factory PigeonStatistics.fromJson(Map<String, dynamic> json) {
    return PigeonStatistics(
      pigeonId: json['pigeon_id'] as String,
      totalFlights: (json['total_flights'] as num?)?.toInt() ?? 0,
      avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble() ?? 0.0,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      returnRate: (json['return_rate'] as num?)?.toDouble() ?? 0.0,
      bestSpeedKmh: (json['best_speed_kmh'] as num?)?.toDouble(),
      lastFlightDate: json['last_flight_date'] != null
          ? DateTime.parse(json['last_flight_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pigeon_id': pigeonId,
      'total_flights': totalFlights,
      'avg_speed_kmh': avgSpeedKmh,
      'total_distance_km': totalDistanceKm,
      'return_rate': returnRate,
      'best_speed_kmh': bestSpeedKmh,
      'last_flight_date': lastFlightDate?.toIso8601String(),
    };
  }
}
