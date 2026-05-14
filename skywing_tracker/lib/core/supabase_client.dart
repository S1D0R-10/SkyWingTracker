import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

SupabaseClient get supabase => Supabase.instance.client;

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
}
