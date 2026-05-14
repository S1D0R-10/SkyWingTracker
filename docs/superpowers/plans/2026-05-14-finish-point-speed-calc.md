# Finish Point + Average Speed Calculation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a finish location marker to flight creation and a "Pigeon Arrived!" button on live tracking that calculates and displays average flight speed.

**Architecture:** Three-layer change — model gets finish coords, create screen gets two-mode map toggle, live tracking screen gets arrival button + result card. No new files needed.

**Tech Stack:** Flutter/Dart, Riverpod, Google Maps Flutter, existing haversineDistanceKm utility.

---

## Files modified

| File | Change |
|---|---|
| `lib/features/flights/models/flight_session.dart` | Add 3 finish fields + update fromJson/toJson/copyWith |
| `lib/features/flights/screens/create_flight_screen.dart` | Add MapMode enum, finish state, toggle UI, second marker, validation |
| `lib/features/flights/screens/live_flight_tracking_screen.dart` | Add arrival button, result card, freeze timer on arrival |

---

## Task 1: Add finish fields to FlightSession model

**Files:**
- Modify: `lib/features/flights/models/flight_session.dart`

- [ ] **Step 1: Add finish fields to class body and constructor**

Replace lines 16–40 (after `loftLongitude`):

```dart
  final double? loftLatitude;
  final double? loftLongitude;
  final double? finishLatitude;
  final double? finishLongitude;
  final String? finishLocationName;
  final String? weatherConditions;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FlightSession({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.status,
    required this.releaseTime,
    this.endTime,
    required this.releaseLatitude,
    required this.releaseLongitude,
    this.releaseLocationName,
    this.loftLatitude,
    this.loftLongitude,
    this.finishLatitude,
    this.finishLongitude,
    this.finishLocationName,
    this.weatherConditions,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
```

- [ ] **Step 2: Update fromJson to parse finish fields**

Inside `factory FlightSession.fromJson`, after the `loftLongitude` line (currently line 67), add:

```dart
      finishLatitude: json['finish_latitude'] != null
          ? (json['finish_latitude'] as num).toDouble()
          : null,
      finishLongitude: json['finish_longitude'] != null
          ? (json['finish_longitude'] as num).toDouble()
          : null,
      finishLocationName: json['finish_location_name'] as String?,
```

- [ ] **Step 3: Update toJson to serialize finish fields**

Inside `toJson()`, after the `'loft_longitude': loftLongitude,` line, add:

```dart
      'finish_latitude': finishLatitude,
      'finish_longitude': finishLongitude,
      'finish_location_name': finishLocationName,
```

- [ ] **Step 4: Update copyWith signature and body**

In `copyWith`, add parameters after `loftLongitude`:

```dart
    double? finishLatitude,
    double? finishLongitude,
    String? finishLocationName,
```

And in the returned `FlightSession(...)` constructor call, add:

```dart
      finishLatitude: finishLatitude ?? this.finishLatitude,
      finishLongitude: finishLongitude ?? this.finishLongitude,
      finishLocationName: finishLocationName ?? this.finishLocationName,
```

- [ ] **Step 5: Run flutter analyze to verify no errors**

```bash
cd skywing_tracker && flutter analyze lib/features/flights/models/flight_session.dart
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
cd skywing_tracker && git add lib/features/flights/models/flight_session.dart
git commit -m "feat: add finish location fields to FlightSession model"
```

---

## Task 2: Add finish point selector to create flight screen

**Files:**
- Modify: `lib/features/flights/screens/create_flight_screen.dart`

- [ ] **Step 1: Add MapMode enum at top of file (after imports)**

After the last import line (line 15), before `class CreateFlightScreen`:

```dart
enum _MapMode { start, finish }
```

- [ ] **Step 2: Add finish location state variables to _CreateFlightScreenState**

After `bool _fetchingWeather = false;` (line 31), add:

```dart
  _MapMode _mapMode = _MapMode.start;
  LatLng? _finishLocation;
  String _finishLocationName = '';
```

- [ ] **Step 3: Update _onMapTap to handle both modes**

Replace the entire `_onMapTap` method (lines 44–54):

```dart
  Future<void> _onMapTap(LatLng pos) async {
    if (_mapMode == _MapMode.start) {
      setState(() {
        _selectedLocation = pos;
        _locationName =
            '${pos.latitude.toStringAsFixed(4)}, '
            '${pos.longitude.toStringAsFixed(4)}';
        _fetchingWeather = true;
        _weatherJson = null;
      });
      await _fetchWeather(pos.latitude, pos.longitude);
    } else {
      setState(() {
        _finishLocation = pos;
        _finishLocationName =
            '${pos.latitude.toStringAsFixed(4)}, '
            '${pos.longitude.toStringAsFixed(4)}';
      });
    }
  }
```

- [ ] **Step 4: Update validation in _createFlight to require finish location**

Replace the start-location validation block (lines 93–98):

```dart
    if (_selectedLocation == null || _finishLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set both start and finish locations on the map'),
        ),
      );
      return;
    }
```

- [ ] **Step 5: Pass finish fields when creating FlightSession**

In `_createFlight`, update the `FlightSession(...)` constructor call to add finish fields after `releaseLocationName`:

```dart
        finishLatitude: _finishLocation!.latitude,
        finishLongitude: _finishLocation!.longitude,
        finishLocationName: _finishLocationName,
```

- [ ] **Step 6: Add mode toggle UI above the map**

Find the `// Map location picker` comment (line 239). Replace the section label with:

```dart
            // Map location picker
            const Text(
              'Locations',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            // Mode toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mapMode = _MapMode.start),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _mapMode == _MapMode.start
                            ? Colors.red.withOpacity(0.15)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _mapMode == _MapMode.start
                              ? Colors.red
                              : AppColors.divider,
                          width: _mapMode == _MapMode.start ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flag_outlined,
                              color: _mapMode == _MapMode.start
                                  ? Colors.red
                                  : AppColors.textSecondary,
                              size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Set Start',
                            style: TextStyle(
                              color: _mapMode == _MapMode.start
                                  ? Colors.red
                                  : AppColors.textPrimary,
                              fontWeight: _mapMode == _MapMode.start
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mapMode = _MapMode.finish),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _mapMode == _MapMode.finish
                            ? Colors.green.withOpacity(0.15)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _mapMode == _MapMode.finish
                              ? Colors.green
                              : AppColors.divider,
                          width: _mapMode == _MapMode.finish ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_score_outlined,
                              color: _mapMode == _MapMode.finish
                                  ? Colors.green
                                  : AppColors.textSecondary,
                              size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Set Finish',
                            style: TextStyle(
                              color: _mapMode == _MapMode.finish
                                  ? Colors.green
                                  : AppColors.textPrimary,
                              fontWeight: _mapMode == _MapMode.finish
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
```

- [ ] **Step 7: Add finish marker to the map markers set**

Replace the `markers:` property of `GoogleMap` (lines 256–266):

```dart
                  markers: {
                    if (_selectedLocation != null)
                      Marker(
                        markerId: const MarkerId('release'),
                        position: _selectedLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    if (_finishLocation != null)
                      Marker(
                        markerId: const MarkerId('finish'),
                        position: _finishLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                  },
```

- [ ] **Step 8: Show finish location label below the map**

After the existing start-location label block (after `const SizedBox(height: 16),` on line 283), add:

```dart
            if (_finishLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Finish: $_finishLocationName',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
```

- [ ] **Step 9: Run flutter analyze**

```bash
cd skywing_tracker && flutter analyze lib/features/flights/screens/create_flight_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
cd skywing_tracker && git add lib/features/flights/screens/create_flight_screen.dart
git commit -m "feat: add finish point toggle and marker to create flight screen"
```

---

## Task 3: Add "Pigeon Arrived!" button and result card to live tracking screen

**Files:**
- Modify: `lib/features/flights/screens/live_flight_tracking_screen.dart`

- [ ] **Step 1: Add haversine import**

After the existing imports (line 9), add:

```dart
import 'package:skywing_tracker/shared/utils/haversine.dart';
```

- [ ] **Step 2: Add arrival state variables to _LiveFlightTrackingScreenState**

After `String _statusFilter = 'all';` (line 25), add:

```dart
  bool _flightEnded = false;
  DateTime? _endTime;
  double? _resultDistanceKm;
  double? _resultSpeedKmh;
  bool _savingArrival = false;
```

- [ ] **Step 3: Add _onPigeonArrived method to the state class**

Add this method before the `build` method:

```dart
  Future<void> _onPigeonArrived(
    FlightSession flight,
    FlightRepository repo,
  ) async {
    final now = DateTime.now();
    final elapsed = now.difference(flight.releaseTime);

    final hasFinish =
        flight.finishLatitude != null && flight.finishLongitude != null;

    final distKm = hasFinish
        ? haversineDistanceKm(
            flight.releaseLatitude,
            flight.releaseLongitude,
            flight.finishLatitude!,
            flight.finishLongitude!,
          )
        : 0.0;

    final speedKmh =
        (distKm > 0 && elapsed.inSeconds > 0)
            ? distKm / elapsed.inSeconds * 3600
            : 0.0;

    setState(() {
      _savingArrival = true;
    });

    try {
      await repo.updateFlight(flight.copyWith(endTime: now));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save arrival time. Please try again.'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _flightEnded = true;
        _endTime = now;
        _resultDistanceKm = distKm;
        _resultSpeedKmh = speedKmh;
        _savingArrival = false;
      });
      _ticker?.cancel();
      _pulseController.stop();
    }
  }
```

Note: `FlightRepository` must be imported — add to imports:

```dart
import 'package:skywing_tracker/features/flights/repositories/flight_repository.dart';
```

- [ ] **Step 4: Update elapsed time calculation to freeze when flight ended**

Replace `final elapsed = DateTime.now().difference(flight.releaseTime);` (line 76) with:

```dart
          final elapsed = _flightEnded && _endTime != null
              ? _endTime!.difference(flight.releaseTime)
              : DateTime.now().difference(flight.releaseTime);
```

- [ ] **Step 5: Add result card widget method**

Add this method to the state class (before `_filterParticipants`):

```dart
  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: AppColors.success, size: 18),
              SizedBox(width: 6),
              Text(
                'FLIGHT COMPLETE',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _resultRow(
            'Flight time',
            _endTime != null
                ? _formatElapsed(_endTime!.difference(
                    // We need releaseTime here; pass it in
                    _endTime!, // placeholder — see step 6
                  ))
                : '--:--:--',
          ),
          _resultRow(
            'Distance',
            _resultDistanceKm != null && _resultDistanceKm! > 0
                ? '${_resultDistanceKm!.toStringAsFixed(1)} km'
                : '—',
          ),
          _resultRow(
            'Avg speed',
            _resultSpeedKmh != null && _resultSpeedKmh! > 0
                ? '${_resultSpeedKmh!.toStringAsFixed(1)} km/h'
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
```

- [ ] **Step 6: Fix result card to receive releaseTime and use stored elapsed**

The result card needs to display the frozen elapsed time. Replace the `_buildResultCard` method with this corrected version that takes `releaseTime` as a parameter:

```dart
  Widget _buildResultCard(DateTime releaseTime) {
    final elapsed = _endTime != null
        ? _endTime!.difference(releaseTime)
        : Duration.zero;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: AppColors.success, size: 18),
              SizedBox(width: 6),
              Text(
                'FLIGHT COMPLETE',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _resultRow('Flight time', _formatElapsed(elapsed)),
          _resultRow(
            'Distance',
            _resultDistanceKm != null && _resultDistanceKm! > 0
                ? '${_resultDistanceKm!.toStringAsFixed(1)} km'
                : '—',
          ),
          _resultRow(
            'Avg speed',
            _resultSpeedKmh != null && _resultSpeedKmh! > 0
                ? '${_resultSpeedKmh!.toStringAsFixed(1)} km/h'
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
```

Remove the placeholder `_buildResultCard()` method from step 5 entirely.

- [ ] **Step 7: Insert result card and "Pigeon Arrived!" button into the Column**

In the `build` method, inside the `Column(children: [...])` (the main body column), add after the elapsed timer container (after `),` on line ~150) and before the status filter chips:

```dart
                  // Result card — shown after arrival
                  if (_flightEnded)
                    _buildResultCard(flight.releaseTime),

                  // Pigeon Arrived button — shown before arrival
                  if (!_flightEnded &&
                      flight.finishLatitude != null &&
                      flight.finishLongitude != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _savingArrival
                              ? null
                              : () => _onPigeonArrived(
                                    flight,
                                    ref.read(flightRepositoryProvider),
                                  ),
                          icon: _savingArrival
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary),
                                )
                              : const Icon(Icons.sports_score_outlined),
                          label: Text(
                            _savingArrival ? 'Saving...' : 'Pigeon Arrived!',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),

                  // Info when no finish point set
                  if (!_flightEnded &&
                      (flight.finishLatitude == null ||
                          flight.finishLongitude == null))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        'No finish point set for this flight.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
```

- [ ] **Step 8: Run flutter analyze**

```bash
cd skywing_tracker && flutter analyze lib/features/flights/screens/live_flight_tracking_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 9: Run full project analyze**

```bash
cd skywing_tracker && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
cd skywing_tracker && git add lib/features/flights/screens/live_flight_tracking_screen.dart
git commit -m "feat: add Pigeon Arrived button and result card to live tracking screen"
```

---

## Task 4: Final build verification

- [ ] **Step 1: Run flutter build to verify no compile errors**

```bash
cd skywing_tracker && flutter build apk --debug 2>&1 | tail -20
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 2: Commit plan doc**

```bash
cd /Users/macszymon/Documents/TechniSchools/SkyWingTracker && git add docs/superpowers/plans/2026-05-14-finish-point-speed-calc.md && git commit -m "docs: add implementation plan for finish point + speed calc"
```
