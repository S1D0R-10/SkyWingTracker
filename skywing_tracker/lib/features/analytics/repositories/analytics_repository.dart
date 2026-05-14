import 'dart:convert';
import 'dart:math' as math;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:skywing_tracker/core/constants.dart';
import 'package:skywing_tracker/core/hive_boxes.dart';
import 'package:skywing_tracker/core/supabase_client.dart';
import 'package:skywing_tracker/features/analytics/models/analytics_data.dart';

class AnalyticsRepository {
  static const String _cacheKey = 'analytics_cache';
  static const String _cacheTsKey = 'analytics_cache_ts';

  Future<AnalyticsData> getAnalytics() async {
    final box = analyticsBox;

    // Check cache TTL
    final cachedTs = box.get(_cacheTsKey) as String?;
    if (cachedTs != null) {
      final ts = DateTime.parse(cachedTs);
      if (DateTime.now().difference(ts) < AppConstants.analyticsCacheTtl) {
        final cached = box.get(_cacheKey) as String?;
        if (cached != null) {
          return AnalyticsData.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
          );
        }
      }
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return _emptyAnalytics();
    }

    // Fetch flight sessions
    final sessionsResponse = await supabase
        .from('flight_sessions')
        .select('*')
        .eq('owner_id', userId)
        .order('release_time', ascending: true);

    final sessions = sessionsResponse as List<dynamic>;

    // Fetch flight participants
    List<dynamic> participants = [];
    if (sessions.isNotEmpty) {
      final sessionIds = sessions.map((s) => s['id'] as String).toList();
      final participantsResponse = await supabase
          .from('flight_participants')
          .select('*, pigeons(id, name)')
          .inFilter('flight_session_id', sessionIds);
      participants = participantsResponse as List<dynamic>;
    }

    // Build speed over time (last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final speedPoints = <SpeedDataPoint>[];

    for (final session in sessions) {
      final releaseTime = DateTime.parse(session['release_time'] as String);
      if (releaseTime.isBefore(thirtyDaysAgo)) continue;

      final relLat = (session['release_latitude'] as num?)?.toDouble();
      final relLon = (session['release_longitude'] as num?)?.toDouble();
      final loftLat = (session['loft_latitude'] as num?)?.toDouble();
      final loftLon = (session['loft_longitude'] as num?)?.toDouble();
      final endTime = session['end_time'] != null
          ? DateTime.parse(session['end_time'] as String)
          : null;

      if (relLat != null &&
          relLon != null &&
          loftLat != null &&
          loftLon != null &&
          endTime != null) {
        final distKm = _haversine(relLat, relLon, loftLat, loftLon);
        final durationHours = endTime.difference(releaseTime).inMinutes / 60.0;
        if (durationHours > 0) {
          speedPoints.add(
            SpeedDataPoint(date: releaseTime, speedKmh: distKm / durationHours),
          );
        }
      }
    }

    // Build monthly flight counts
    final monthlyMap = <String, _MonthlyAccum>{};
    for (final session in sessions) {
      final releaseTime = DateTime.parse(session['release_time'] as String);
      final monthKey =
          '${releaseTime.year}-${releaseTime.month.toString().padLeft(2, '0')}';
      final type = session['type'] as String? ?? 'training';
      monthlyMap.putIfAbsent(monthKey, () => _MonthlyAccum(monthKey));
      if (type == 'training') {
        monthlyMap[monthKey]!.training++;
      } else {
        monthlyMap[monthKey]!.competition++;
      }
    }
    final monthlyFlights =
        monthlyMap.values
            .map(
              (m) => MonthlyFlightCount(
                month: m.month,
                training: m.training,
                competition: m.competition,
              ),
            )
            .toList()
          ..sort((a, b) => a.month.compareTo(b.month));

    // Return reliability
    final totalParticipants = participants.length;
    final returnedParticipants = participants
        .where((p) => p['status'] == 'returned')
        .length;
    final returnReliability = totalParticipants > 0
        ? returnedParticipants / totalParticipants * 100.0
        : 0.0;

    // Total season distance
    double totalDistance = 0.0;
    for (final session in sessions) {
      final relLat = (session['release_latitude'] as num?)?.toDouble();
      final relLon = (session['release_longitude'] as num?)?.toDouble();
      final loftLat = (session['loft_latitude'] as num?)?.toDouble();
      final loftLon = (session['loft_longitude'] as num?)?.toDouble();
      if (relLat != null &&
          relLon != null &&
          loftLat != null &&
          loftLon != null) {
        totalDistance += _haversine(relLat, relLon, loftLat, loftLon);
      }
    }

    // Build pigeon rankings
    final pigeonMap = <String, _PigeonAccum>{};
    for (final p in participants) {
      final pigeonId = p['pigeon_id'] as String?;
      if (pigeonId == null) continue;
      final pigeonName =
          (p['pigeons'] as Map<String, dynamic>?)?['name'] as String? ??
          'Unknown';
      final status = p['status'] as String? ?? '';
      final sessionId = p['flight_session_id'] as String?;

      final session = sessions.cast<Map<String, dynamic>?>().firstWhere(
        (s) => s?['id'] == sessionId,
        orElse: () => null,
      );

      double dist = 0.0;
      double speed = 0.0;
      if (session != null) {
        final relLat = (session['release_latitude'] as num?)?.toDouble();
        final relLon = (session['release_longitude'] as num?)?.toDouble();
        final loftLat = (session['loft_latitude'] as num?)?.toDouble();
        final loftLon = (session['loft_longitude'] as num?)?.toDouble();
        final releaseTime = DateTime.parse(session['release_time'] as String);
        final endTime = session['end_time'] != null
            ? DateTime.parse(session['end_time'] as String)
            : null;

        if (relLat != null &&
            relLon != null &&
            loftLat != null &&
            loftLon != null) {
          dist = _haversine(relLat, relLon, loftLat, loftLon);
          if (endTime != null) {
            final hours = endTime.difference(releaseTime).inMinutes / 60.0;
            if (hours > 0) speed = dist / hours;
          }
        }
      }

      pigeonMap.putIfAbsent(pigeonId, () => _PigeonAccum(pigeonId, pigeonName));
      pigeonMap[pigeonId]!.total++;
      if (status == 'returned') pigeonMap[pigeonId]!.returned++;
      if (speed > 0) pigeonMap[pigeonId]!.speeds.add(speed);
      if (dist > 0) pigeonMap[pigeonId]!.distances.add(dist);
    }

    final rankings = pigeonMap.values.map((acc) {
      final avgSpeed = acc.speeds.isEmpty
          ? 0.0
          : acc.speeds.reduce((a, b) => a + b) / acc.speeds.length;
      final totalDist = acc.distances.isEmpty
          ? 0.0
          : acc.distances.reduce((a, b) => a + b);
      return PigeonRanking(
        pigeonId: acc.id,
        pigeonName: acc.name,
        avgSpeed: avgSpeed,
        totalDistance: totalDist,
        returnRate: acc.total > 0 ? acc.returned / acc.total * 100.0 : 0.0,
        totalFlights: acc.total,
      );
    }).toList()..sort((a, b) => b.avgSpeed.compareTo(a.avgSpeed));

    final data = AnalyticsData(
      speedOverTime: speedPoints,
      monthlyFlights: monthlyFlights,
      returnReliability: returnReliability,
      totalSeasonDistance: totalDistance,
      rankings: rankings,
      fetchedAt: DateTime.now(),
    );

    // Cache result
    await box.put(_cacheKey, jsonEncode(data.toJson()));
    await box.put(_cacheTsKey, DateTime.now().toIso8601String());

    return data;
  }

  Future<String> getAIInsights(AnalyticsData data) async {
    final apiKey = AppConstants.openAiApiKey;
    if (apiKey.isEmpty) {
      return '''## AI Insights (Demo Mode)

**Configure your OpenAI API key** in `AppConstants.openAiApiKey` to enable personalized AI insights.

### Summary
- Total season distance: ${data.totalSeasonDistance.toStringAsFixed(1)} km
- Return reliability: ${data.returnReliability.toStringAsFixed(1)}%
- Top pigeon: ${data.rankings.isNotEmpty ? data.rankings.first.pigeonName : 'N/A'}

### Recommendations
- Track more flights to get meaningful trend data
- Monitor return rates to identify health issues early
- Compare training vs competition performance regularly
''';
    }

    final prompt =
        '''
You are an expert pigeon racing coach. Analyze this season data and provide actionable insights:

- Total season distance: ${data.totalSeasonDistance.toStringAsFixed(1)} km
- Return reliability: ${data.returnReliability.toStringAsFixed(1)}%
- Monthly flights: ${data.monthlyFlights.map((m) => '${m.month}: ${m.training} training, ${m.competition} competition').join('; ')}
- Top 3 pigeons by speed: ${data.rankings.take(3).map((r) => '${r.pigeonName} (${r.avgSpeed.toStringAsFixed(1)} km/h, ${r.returnRate.toStringAsFixed(0)}% return rate)').join(', ')}

Provide:
1. Performance summary
2. Key strengths
3. Areas for improvement
4. Training recommendations
5. Pigeon-specific notes

Format with markdown headers.
''';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 800,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>;
      if (choices.isNotEmpty) {
        return (choices.first as Map<String, dynamic>)['message']['content']
            as String;
      }
    }

    return 'Failed to fetch AI insights. Please try again later.';
  }

  Future<void> invalidateCache() async {
    final box = analyticsBox;
    await box.delete(_cacheTsKey);
    await box.delete(_cacheKey);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

  AnalyticsData _emptyAnalytics() {
    return AnalyticsData(
      speedOverTime: const [],
      monthlyFlights: const [],
      returnReliability: 0.0,
      totalSeasonDistance: 0.0,
      rankings: const [],
      fetchedAt: DateTime.now(),
    );
  }
}

class _MonthlyAccum {
  final String month;
  int training = 0;
  int competition = 0;
  _MonthlyAccum(this.month);
}

class _PigeonAccum {
  final String id;
  final String name;
  int total = 0;
  int returned = 0;
  final List<double> speeds = [];
  final List<double> distances = [];
  _PigeonAccum(this.id, this.name);
}
