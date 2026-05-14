import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skywing_tracker/features/auth/repositories/auth_repository.dart';
import 'package:skywing_tracker/features/auth/models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges.map(
    (authState) => authState.session?.user,
  );
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repository = ref.read(authRepositoryProvider);
  return repository.getProfile(user.id);
});
