import 'package:skywing_tracker/core/supabase_client.dart';
import 'package:skywing_tracker/core/hive_boxes.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon_statistics.dart';
import 'package:skywing_tracker/features/pigeons/models/achievement.dart';

class PigeonRepository {
  Future<List<Pigeon>> getPigeons() async {
    final response = await supabase
        .from('pigeons')
        .select()
        .order('created_at', ascending: false);

    final pigeons = (response as List)
        .map((json) => Pigeon.fromJson(json as Map<String, dynamic>))
        .toList();

    // Cache in Hive
    final box = pigeonsBox;
    for (final pigeon in pigeons) {
      await box.put(pigeon.id, pigeon.toJson());
    }

    return pigeons;
  }

  Future<Pigeon?> getPigeonById(String id) async {
    final response = await supabase
        .from('pigeons')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Pigeon.fromJson(response as Map<String, dynamic>);
  }

  Future<Pigeon> createPigeon(Pigeon pigeon) async {
    final data = pigeon.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');

    final response = await supabase
        .from('pigeons')
        .insert(data)
        .select()
        .single();

    final created = Pigeon.fromJson(response as Map<String, dynamic>);
    await pigeonsBox.put(created.id, created.toJson());
    return created;
  }

  Future<Pigeon> updatePigeon(Pigeon pigeon) async {
    final data = pigeon.toJson()
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    final response = await supabase
        .from('pigeons')
        .update(data)
        .eq('id', pigeon.id)
        .select()
        .single();

    final updated = Pigeon.fromJson(response as Map<String, dynamic>);
    await pigeonsBox.put(updated.id, updated.toJson());
    return updated;
  }

  Future<void> deletePigeon(String id) async {
    await supabase.from('pigeons').delete().eq('id', id);
    await pigeonsBox.delete(id);
  }

  Future<PigeonStatistics?> getPigeonStatistics(String pigeonId) async {
    final response = await supabase
        .from('pigeon_statistics')
        .select()
        .eq('pigeon_id', pigeonId)
        .maybeSingle();

    if (response == null) return null;
    return PigeonStatistics.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Achievement>> getAchievements(String pigeonId) async {
    final response = await supabase
        .from('pigeon_achievements')
        .select()
        .eq('pigeon_id', pigeonId)
        .order('earned_at', ascending: false);

    return (response as List)
        .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  List<Pigeon> getCachedPigeons() {
    final box = pigeonsBox;
    return box.values
        .map(
          (value) => Pigeon.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
  }
}
