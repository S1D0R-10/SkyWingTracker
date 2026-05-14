class SpeedDataPoint {
  final DateTime date;
  final double speedKmh;

  const SpeedDataPoint({required this.date, required this.speedKmh});

  factory SpeedDataPoint.fromJson(Map<String, dynamic> json) {
    return SpeedDataPoint(
      date: DateTime.parse(json['date'] as String),
      speedKmh: (json['speed_kmh'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'speed_kmh': speedKmh,
  };
}

class MonthlyFlightCount {
  final String month;
  final int training;
  final int competition;

  const MonthlyFlightCount({
    required this.month,
    required this.training,
    required this.competition,
  });

  factory MonthlyFlightCount.fromJson(Map<String, dynamic> json) {
    return MonthlyFlightCount(
      month: json['month'] as String,
      training: json['training'] as int,
      competition: json['competition'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'training': training,
    'competition': competition,
  };
}

class PigeonRanking {
  final String pigeonId;
  final String pigeonName;
  final double avgSpeed;
  final double totalDistance;
  final double returnRate;
  final int totalFlights;

  const PigeonRanking({
    required this.pigeonId,
    required this.pigeonName,
    required this.avgSpeed,
    required this.totalDistance,
    required this.returnRate,
    required this.totalFlights,
  });

  factory PigeonRanking.fromJson(Map<String, dynamic> json) {
    return PigeonRanking(
      pigeonId: json['pigeon_id'] as String,
      pigeonName: json['pigeon_name'] as String,
      avgSpeed: (json['avg_speed'] as num).toDouble(),
      totalDistance: (json['total_distance'] as num).toDouble(),
      returnRate: (json['return_rate'] as num).toDouble(),
      totalFlights: json['total_flights'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'pigeon_id': pigeonId,
    'pigeon_name': pigeonName,
    'avg_speed': avgSpeed,
    'total_distance': totalDistance,
    'return_rate': returnRate,
    'total_flights': totalFlights,
  };
}

class AnalyticsData {
  final List<SpeedDataPoint> speedOverTime;
  final List<MonthlyFlightCount> monthlyFlights;
  final double returnReliability;
  final double totalSeasonDistance;
  final List<PigeonRanking> rankings;
  final DateTime fetchedAt;

  const AnalyticsData({
    required this.speedOverTime,
    required this.monthlyFlights,
    required this.returnReliability,
    required this.totalSeasonDistance,
    required this.rankings,
    required this.fetchedAt,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      speedOverTime: (json['speed_over_time'] as List<dynamic>)
          .map((e) => SpeedDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyFlights: (json['monthly_flights'] as List<dynamic>)
          .map((e) => MonthlyFlightCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      returnReliability: (json['return_reliability'] as num).toDouble(),
      totalSeasonDistance: (json['total_season_distance'] as num).toDouble(),
      rankings: (json['rankings'] as List<dynamic>)
          .map((e) => PigeonRanking.fromJson(e as Map<String, dynamic>))
          .toList(),
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'speed_over_time': speedOverTime.map((e) => e.toJson()).toList(),
    'monthly_flights': monthlyFlights.map((e) => e.toJson()).toList(),
    'return_reliability': returnReliability,
    'total_season_distance': totalSeasonDistance,
    'rankings': rankings.map((e) => e.toJson()).toList(),
    'fetched_at': fetchedAt.toIso8601String(),
  };
}
