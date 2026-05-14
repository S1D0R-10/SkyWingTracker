import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skywing_tracker/features/analytics/models/analytics_data.dart';
import 'package:skywing_tracker/features/analytics/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});

final analyticsDataProvider = FutureProvider<AnalyticsData>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAnalytics();
});

final aiInsightsProvider = FutureProvider<String>((ref) async {
  final analyticsAsync = await ref.watch(analyticsDataProvider.future);
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAIInsights(analyticsAsync);
});
