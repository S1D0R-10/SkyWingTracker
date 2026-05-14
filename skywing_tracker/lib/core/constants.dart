class AppConstants {
  static const String supabaseUrl = 'https://ijivwljdoqakvsmpgcja.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqaXZ3bGpkb3Fha3ZzbXBnY2phIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MjgxMzgsImV4cCI6MjA5NDIwNDEzOH0.KqgvEHNcyspGNq6fzhQ5y16fB5xX1YHH5c4YKuoyG4k';
  static const String googleMapsApiKey =
      'AIzaSyC0OodGvpucgVgF--2EXD6YbT9EO5t_8jM';
  static const String weatherApiKey = '4bb181ab954644aea0671433261305';
  static const String openAiApiKey = ''; // Set when available

  // Hive box names
  static const String pigeonsBox = 'pigeons_box';
  static const String flightsBox = 'flights_box';
  static const String participantsBox = 'participants_box';
  static const String analyticsBox = 'analytics_box';
  static const String pendingActionsBox = 'pending_actions_box';

  // Analytics cache TTL
  static const Duration analyticsCacheTtl = Duration(hours: 1);
}
