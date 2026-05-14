import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon_statistics.dart';
import 'package:skywing_tracker/features/pigeons/models/achievement.dart';
import 'package:skywing_tracker/features/pigeons/repositories/pigeon_repository.dart';

final pigeonRepositoryProvider = Provider<PigeonRepository>((ref) {
  return PigeonRepository();
});

final pigeonsProvider = FutureProvider<List<Pigeon>>((ref) async {
  final repository = ref.watch(pigeonRepositoryProvider);
  return repository.getPigeons();
});

final pigeonByIdProvider = FutureProvider.family<Pigeon?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(pigeonRepositoryProvider);
  return repository.getPigeonById(id);
});

final pigeonStatisticsProvider =
    FutureProvider.family<PigeonStatistics?, String>((ref, pigeonId) async {
      final repository = ref.watch(pigeonRepositoryProvider);
      return repository.getPigeonStatistics(pigeonId);
    });

final pigeonAchievementsProvider =
    FutureProvider.family<List<Achievement>, String>((ref, pigeonId) async {
      final repository = ref.watch(pigeonRepositoryProvider);
      return repository.getAchievements(pigeonId);
    });
