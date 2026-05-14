import 'dart:math' as math;

/// Returns the great-circle distance in kilometres between two coordinates.
double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
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
