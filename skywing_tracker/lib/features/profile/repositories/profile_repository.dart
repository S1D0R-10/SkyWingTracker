import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skywing_tracker/core/supabase_client.dart';
import 'package:skywing_tracker/features/auth/models/user_profile.dart';
import 'package:skywing_tracker/features/profile/models/user_settings.dart';

class ProfileRepository {
  Future<void> updateProfile(UserProfile profile) async {
    await supabase.from('profiles').upsert(profile.toJson());
  }

  Future<String?> uploadAvatar(String userId, Uint8List bytes) async {
    final path = 'avatars/$userId.jpg';
    await supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<UserSettings> getSettings(String userId) async {
    final response = await supabase
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return UserSettings(userId: userId);
    }
    return UserSettings.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateSettings(UserSettings settings) async {
    await supabase.from('user_settings').upsert(settings.toJson());
  }
}
