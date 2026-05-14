# SkyWing Tracker — Design Specification
_Date: 2026-05-13_

## Overview

SkyWing Tracker is a Flutter mobile application (Android + iOS) for advanced pigeon flight tracking and analytics. It provides realtime synchronization, AI-assisted insights, geolocation, weather integration, offline support, and rich statistics.

---

## Credentials

| Service | Value |
|---|---|
| Supabase URL | `https://ijivwljdoqakvsmpgcja.supabase.co` |
| Supabase Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqaXZ3bGpkb3Fha3ZzbXBnY2phIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MjgxMzgsImV4cCI6MjA5NDIwNDEzOH0.KqgvEHNcyspGNq6fzhQ5y16fB5xX1YHH5c4YKuoyG4k` |
| Google Maps API Key | `AIzaSyC0OodGvpucgVgF--2EXD6YbT9EO5t_8jM` |
| OpenAI API Key | placeholder — add later |
| WeatherAPI.com Key | `4bb181ab954644aea0671433261305` |

---

## Architecture

**Pattern**: Feature-first modular architecture with Repository pattern and Riverpod state management.

```
lib/
  core/
    supabase_client.dart
    router.dart
    theme.dart
    constants.dart
    hive_boxes.dart
  features/
    auth/
      models/
      repositories/
      providers/
      screens/
    pigeons/
      models/
      repositories/
      providers/
      screens/
    flights/
      models/
      repositories/
      providers/
      screens/
    analytics/
      models/
      repositories/
      providers/
      screens/
    profile/
      models/
      repositories/
      providers/
      screens/
  shared/
    widgets/
    services/
    utils/
```

---

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (AsyncNotifier pattern)
- **Routing**: GoRouter with auth-gated redirect + bottom nav shell
- **Backend**: Supabase (Auth, PostgreSQL, Realtime, Storage, RLS)
- **Local Storage**: Hive (offline cache + pending actions queue)
- **Maps**: google_maps_flutter
- **Charts**: fl_chart
- **Notifications**: Firebase Cloud Messaging
- **Weather**: WeatherAPI.com REST
- **AI**: OpenAI Chat Completions API
- **Image Caching**: cached_network_image
- **Animations**: flutter_animate

### pubspec dependencies
`supabase_flutter`, `flutter_riverpod`, `riverpod_annotation`, `go_router`, `google_maps_flutter`, `fl_chart`, `hive_flutter`, `cached_network_image`, `firebase_messaging`, `http`, `geolocator`, `image_picker`, `intl`, `uuid`, `shimmer`, `flutter_animate`, `connectivity_plus`, `flutter_local_notifications`, `geocoding`

---

## Section 1: Core Layer

- `supabase_client.dart` — singleton Supabase init
- `router.dart` — GoRouter, auth redirect, bottom nav shell (Dashboard / Pigeons / Flights / Analytics / Profile)
- `theme.dart` — dark + light ThemeData, Rajdhani headings + Inter body
- `constants.dart` — all API keys and env values
- `hive_boxes.dart` — all Hive box registrations and adapters

**Color Palette**:
- Primary: `#0A1628` (deep navy)
- Accent: `#F5A623` (amber/gold)
- Success: `#2ECC71`, Warning: `#F39C12`, Error: `#E74C3C`
- Surface: `#121F3D`, Card: `#1A2F4A`

---

## Section 2: Authentication Module

**Screens**: LoginScreen, RegisterScreen, ForgotPasswordScreen

**Flow**:
- GoRouter redirect: unauthenticated → `/login`, authenticated → `/dashboard`
- Supabase `onAuthStateChange` stream drives auth state
- Profile upsert into `profiles` table on first sign-up
- Google Sign-In behind feature flag

**Validation**: email format, password min 8 chars, inline error display

---

## Section 3: Pigeon Management Module

**Screens**: PigeonListScreen, PigeonDetailScreen, CreateEditPigeonScreen, PigeonAchievementsScreen, PigeonStatisticsScreen

**Models**: `Pigeon`, `PigeonStatistics`, `Achievement`

**Tables**: `pigeons`, `pigeon_statistics`, `pigeon_achievements`

**Repository methods**: `getPigeons`, `getPigeonById`, `createPigeon`, `updatePigeon`, `deletePigeon`, `getPigeonStatistics`, `getAchievements`

**Offline**: writes through to Hive on every fetch

**UI**:
- List: search + filter chips (breed, sex, active/inactive, performance), card grid, shimmer skeletons, pull-to-refresh
- Detail: hero image, stats row, tabs (Overview / Flights / Achievements / Statistics)
- Create/Edit: image picker, ring number, name, sex, breed, color, hatch date, health notes
- Statistics: fl_chart line charts (speed over time, distance trends)

---

## Section 4: Flight Session Module

**Screens**: FlightListScreen, CreateFlightScreen, FlightDetailScreen, LiveFlightTrackingScreen, FlightReturnRegistrationScreen, FlightMapVisualizationScreen

**Models**: `FlightSession`, `FlightParticipant`
**Enums**: `FlightStatus` (released/returned/missing/injured), `FlightType` (training/competition)
**Tables**: `flight_sessions`, `flight_participants`

**Realtime**: Supabase Realtime channel on `flight_participants` filtered by `flight_session_id` — live participant status updates

**Offline queue**: write operations serialized to `pending_actions_box`, replayed on reconnect

**UI**:
- List: filter tabs (All/Active/Training/Competition), status badges, elapsed time ticker
- Create: Google Maps location picker, pigeon multi-select, weather auto-fetched on location confirm
- Live tracking: elapsed timer, swipe-to-return gesture, % returned progress bar
- Return registration: auto-timestamp, condition notes, photo upload
- Map: release marker, loft marker, polyline route

---

## Section 5: Analytics & AI Insights Module

**Screens**: AnalyticsDashboardScreen, RankingsScreen, SeasonStatisticsScreen, AIInsightsScreen

**Charts**:
- Line: average speed over time
- Bar: monthly flight count (training vs competition)
- Donut: return reliability breakdown
- Line: cumulative distance per season
- Horizontal bar: top pigeons ranking

**Rankings**: best speed, highest reliability, total distance, monthly champion — podium-style cards

**AI Insights**: OpenAI Chat Completions with structured prompt (top 5 pigeons stats + last 10 flights + weather). Markdown rendered in-app. Cached per session, manual refresh. Placeholder when key not set.

**Cache**: `analytics_cache` Hive box, 1-hour TTL

---

## Section 6: Supporting Modules

### Weather
- WeatherAPI.com call on flight creation using coordinates
- `WeatherSnapshot` stored in `weather_snapshots` table
- Displayed on flight detail + fed into AI prompt

### Maps & Geolocation
- `geolocator` for device position
- Google Maps configured in AndroidManifest.xml + AppDelegate.swift
- Location picker bottom sheet, reverse geocode display
- Haversine distance calculation
- Route polyline on FlightMapVisualizationScreen

### Notifications
- FCM for Android + iOS
- Local triggers: flight started, pigeon overdue, expected return reminder
- Smart alerts: inactive 14+ days, declining performance
- Settings screen: per-category toggles

### Offline Sync
- Hive boxes: `pigeons_box`, `flights_box`, `participants_box`, `analytics_box`, `pending_actions_box`
- `connectivity_plus` network monitoring
- Newest-timestamp-wins conflict resolution

### Profile
- Edit display name, club name, breeder location, avatar (Supabase Storage)
- Loft location saved — used as default map destination
- Units toggle: km vs miles

---

## Section 7: UI/UX

**Shared Widgets**: AppButton, AppTextField, AppCard, SkeletonLoader, EmptyState, StatusBadge, StatRow, PullToRefresh

**Animations**: flutter_animate page transitions + card entrances, hero transitions on pigeon images, animated charts, pulsing live flight timer

**Navigation**: GoRouter bottom nav shell, 5 tabs, deep links for flight detail + pigeon detail

---

## Database Tables

`profiles`, `pigeons`, `pigeon_statistics`, `pigeon_achievements`, `flight_sessions`, `flight_participants`, `weather_snapshots`, `notifications`, `user_settings`, `analytics_cache`

All tables have Row Level Security enabled — users access only their own data via `owner_id = auth.uid()`.
