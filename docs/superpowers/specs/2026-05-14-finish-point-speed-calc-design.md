# Design: Finish Point + Average Speed Calculation

**Date:** 2026-05-14  
**Status:** Approved

---

## Overview

Add a finish location marker to flight creation, a "Pigeon Arrived!" button on the live tracking screen, and automatic average speed calculation based on straight-line distance (haversine) and elapsed flight time.

---

## Architecture

No new screens or providers needed. Changes touch three existing layers:

1. **Model** — `FlightSession` gets finish location fields
2. **Create flight screen** — map gains a two-mode tap toggle (Start / Finish)
3. **Live tracking screen** — "Pigeon Arrived!" button + result card

---

## Components

### 1. `FlightSession` model (`flight_session.dart`)

Add three nullable fields:

| Field | Type | Description |
|---|---|---|
| `finishLatitude` | `double?` | Finish point latitude |
| `finishLongitude` | `double?` | Finish point longitude |
| `finishLocationName` | `String?` | Human-readable finish location label |

`fromJson` / `toJson` / `copyWith` updated accordingly.  
Supabase table `flight_sessions` needs matching nullable columns.

Distance is **not stored** — computed on the fly from haversine(start → finish) whenever needed. The existing `shared/utils/haversine.dart` utility is used.

---

### 2. Create flight screen (`create_flight_screen.dart`)

**State additions:**
- `_mapMode: MapMode` — enum `{ start, finish }`
- `_finishLocation: LatLng?`
- `_finishLocationName: String`

**UX:**
- Toggle bar above the map with two buttons: "Start" (red) and "Finish" (green). Active mode is highlighted.
- Default mode when screen opens: `start`.
- `_onMapTap(LatLng pos)` sets `_selectedLocation` when mode is `start`, sets `_finishLocation` when mode is `finish`. Same reverse-geocoding logic applied to finish point for `_finishLocationName`.
- Map renders two markers:
  - Red `BitmapDescriptor.hueRed` at `_selectedLocation` (unchanged)
  - Green `BitmapDescriptor.hueGreen` at `_finishLocation` (new)
- **Validation:** form cannot be submitted unless both `_selectedLocation` and `_finishLocation` are set. Error snackbar: "Please set both start and finish locations."
- On save, `FlightSession` is created with the new finish fields populated.

---

### 3. Live tracking screen (`live_flight_tracking_screen.dart`)

**State additions:**
- `_flightEnded: bool` — false until button pressed
- `_endTime: DateTime?`
- `_resultSpeed: double?`
- `_resultDistanceKm: double?`

**Map section (existing map widget or new miniature):**
- Shows red start marker, green finish marker, and a polyline between them.
- A small label on the polyline shows `XX.X km`.

**Timer:**
- While `!_flightEnded`: counts up from `flight.releaseTime` as today (unchanged).
- After `_flightEnded`: timer stops; displays frozen elapsed time.

**"Pigeon Arrived!" button:**
- Large, prominent button at the bottom of the screen.
- Visible only while `!_flightEnded`.
- On tap:
  1. `_endTime = DateTime.now()`
  2. `elapsed = _endTime!.difference(flight.releaseTime)`
  3. `_resultDistanceKm = haversine(releaseLatitude, releaseLongitude, finishLatitude, finishLongitude)`
  4. `_resultSpeed = _resultDistanceKm / elapsed.inSeconds * 3600`
  5. `flight.endTime` persisted via `flightRepository.updateFlight(flight.copyWith(endTime: _endTime))`
  6. `setState(() { _flightEnded = true; })`
  7. Result card shown (see below).

**Result card (shown after arrival):**
- Displayed inline below the timer or as a bottom sheet.
- Content:
  ```
  Flight time:  02:34:17
  Distance:     142.3 km
  Avg speed:    55.4 km/h
  ```
- Card persists on screen; user can navigate away normally.

---

## Data Flow

```
create_flight_screen
  → user taps map in "Finish" mode
  → _finishLocation set, green marker shown
  → on save: FlightSession created with finishLatitude/Longitude/Name

live_flight_tracking_screen
  → loads FlightSession (has finish coords)
  → map shows start + finish markers + polyline
  → timer counts up from releaseTime
  → user taps "Pigeon Arrived!"
  → elapsed computed, haversine(start, finish) computed
  → speedKmh = distanceKm / elapsedHours
  → flight.endTime persisted to Supabase + Hive
  → result card displayed, timer frozen
```

---

## Error Handling

- If `finishLatitude` / `finishLongitude` are null on live tracking screen (older flight records): hide finish marker, hide polyline, hide "Pigeon Arrived!" button, show info text "No finish point set for this flight."
- If haversine returns 0 (start == finish): show speed as "—" instead of 0.0 km/h.
- Supabase update failure on endTime: show snackbar "Could not save arrival time. Please try again." Result card still shown locally.

---

## Testing

- Unit test: haversine(start, finish) returns correct distance for known coordinates.
- Unit test: speed formula gives correct result for known distance + elapsed time.
- Widget test: toggle between Start/Finish modes sets correct marker.
- Widget test: "Pigeon Arrived!" button is absent when `finishLatitude` is null.
- Widget test: result card shows correct values after button tap.
