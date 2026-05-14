import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skywing_tracker/core/supabase_client.dart';
import 'package:skywing_tracker/features/profile/models/user_settings.dart';
import 'package:skywing_tracker/features/profile/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final userSettingsProvider = FutureProvider<UserSettings>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    return UserSettings(userId: '');
  }
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getSettings(userId);
});
