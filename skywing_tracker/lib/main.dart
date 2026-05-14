import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase_client.dart';
import 'core/hive_boxes.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  await initHive();
  // Firebase / FCM initialised separately once GoogleService-Info.plist
  // is linked in Xcode — not required for core app functionality.
  runApp(const ProviderScope(child: SkyWingApp()));
}

class SkyWingApp extends ConsumerWidget {
  const SkyWingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SkyWing Tracker',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
