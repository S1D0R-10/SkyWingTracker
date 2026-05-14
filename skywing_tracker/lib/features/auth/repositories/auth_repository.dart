import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skywing_tracker/core/supabase_client.dart';
import 'package:skywing_tracker/features/auth/models/user_profile.dart';

class AuthRepository {
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String displayName) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    if (response.user != null) {
      final profile = UserProfile(
        id: response.user!.id,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );
      await upsertProfile(profile);
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await supabase.from('profiles').upsert(profile.toJson());
  }

  Future<UserProfile?> getProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }
}
