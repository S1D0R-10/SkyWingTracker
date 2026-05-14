import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/pigeons/screens/pigeon_list_screen.dart';
import '../features/pigeons/screens/pigeon_detail_screen.dart';
import '../features/pigeons/screens/create_edit_pigeon_screen.dart';
import '../features/pigeons/screens/pigeon_achievements_screen.dart';
import '../features/pigeons/screens/pigeon_statistics_screen.dart';
import '../features/flights/screens/flight_list_screen.dart';
import '../features/flights/screens/create_flight_screen.dart';
import '../features/flights/screens/flight_detail_screen.dart';
import '../features/flights/screens/live_flight_tracking_screen.dart';
import '../features/flights/screens/flight_return_registration_screen.dart';
import '../features/flights/screens/flight_map_visualization_screen.dart';
import '../features/analytics/screens/analytics_dashboard_screen.dart';
import '../features/analytics/screens/rankings_screen.dart';
import '../features/analytics/screens/season_statistics_screen.dart';
import '../features/analytics/screens/ai_insights_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import 'shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password');

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const AnalyticsDashboardScreen(),
          ),
          GoRoute(
            path: '/pigeons',
            builder: (_, __) => const PigeonListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateEditPigeonScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    PigeonDetailScreen(pigeonId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => CreateEditPigeonScreen(
                      pigeonId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'achievements',
                    builder: (_, state) => PigeonAchievementsScreen(
                      pigeonId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'statistics',
                    builder: (_, state) => PigeonStatisticsScreen(
                      pigeonId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/flights',
            builder: (_, __) => const FlightListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateFlightScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    FlightDetailScreen(flightId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'live',
                    builder: (_, state) => LiveFlightTrackingScreen(
                      flightId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'return/:participantId',
                    builder: (_, state) => FlightReturnRegistrationScreen(
                      flightId: state.pathParameters['id']!,
                      participantId: state.pathParameters['participantId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'map',
                    builder: (_, state) => FlightMapVisualizationScreen(
                      flightId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, __) => const AnalyticsDashboardScreen(),
            routes: [
              GoRoute(
                path: 'rankings',
                builder: (_, __) => const RankingsScreen(),
              ),
              GoRoute(
                path: 'season',
                builder: (_, __) => const SeasonStatisticsScreen(),
              ),
              GoRoute(
                path: 'ai-insights',
                builder: (_, __) => const AIInsightsScreen(),
              ),
            ],
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
