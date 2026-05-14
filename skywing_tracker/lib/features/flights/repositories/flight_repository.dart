import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skywing_tracker/core/supabase_client.dart';
import 'package:skywing_tracker/core/hive_boxes.dart';
import 'package:skywing_tracker/features/flights/models/flight_session.dart';
import 'package:skywing_tracker/features/flights/models/flight_participant.dart';

class FlightRepository {
  // ─── Flight Sessions ────────────────────────────────────────────────────────

  Future<List<FlightSession>> getFlights() async {
    try {
      final response = await supabase
          .from('flight_sessions')
          .select()
          .order('release_time', ascending: false);

      final flights = (response as List)
          .map((json) => FlightSession.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache in Hive
      final box = flightsBox;
      for (final flight in flights) {
        await box.put(flight.id, jsonEncode(flight.toJson()));
      }

      return flights;
    } catch (_) {
      // Fallback to cache
      final box = flightsBox;
      return box.values
          .map(
            (v) => FlightSession.fromJson(
              jsonDecode(v as String) as Map<String, dynamic>,
            ),
          )
          .toList();
    }
  }

  Future<FlightSession?> getFlightById(String id) async {
    try {
      final response = await supabase
          .from('flight_sessions')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      final flight = FlightSession.fromJson(response as Map<String, dynamic>);

      // Update cache
      await flightsBox.put(id, jsonEncode(flight.toJson()));
      return flight;
    } catch (_) {
      final cached = flightsBox.get(id);
      if (cached == null) return null;
      return FlightSession.fromJson(
        jsonDecode(cached as String) as Map<String, dynamic>,
      );
    }
  }

  Future<FlightSession> createFlight(FlightSession flight) async {
    final response = await supabase
        .from('flight_sessions')
        .insert(flight.toJson())
        .select()
        .single();

    final created = FlightSession.fromJson(response as Map<String, dynamic>);
    await flightsBox.put(created.id, jsonEncode(created.toJson()));
    return created;
  }

  Future<FlightSession> updateFlight(FlightSession flight) async {
    final response = await supabase
        .from('flight_sessions')
        .update(flight.toJson())
        .eq('id', flight.id)
        .select()
        .single();

    final updated = FlightSession.fromJson(response as Map<String, dynamic>);
    await flightsBox.put(updated.id, jsonEncode(updated.toJson()));
    return updated;
  }

  Future<void> deleteFlight(String id) async {
    await supabase.from('flight_sessions').delete().eq('id', id);
    await flightsBox.delete(id);
  }

  // ─── Participants ────────────────────────────────────────────────────────────

  Future<List<FlightParticipant>> getParticipants(String flightId) async {
    try {
      final response = await supabase
          .from('flight_participants')
          .select()
          .eq('flight_session_id', flightId);

      final participants = (response as List)
          .map(
            (json) => FlightParticipant.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      // Cache participants
      final box = participantsBox;
      for (final p in participants) {
        await box.put(p.id, jsonEncode(p.toJson()));
      }

      return participants;
    } catch (_) {
      final box = participantsBox;
      return box.values
          .map(
            (v) => FlightParticipant.fromJson(
              jsonDecode(v as String) as Map<String, dynamic>,
            ),
          )
          .where((p) => p.flightSessionId == flightId)
          .toList();
    }
  }

  Future<FlightParticipant> insertParticipant(FlightParticipant p) async {
    final response = await supabase
        .from('flight_participants')
        .insert(p.toJson())
        .select()
        .single();

    final created = FlightParticipant.fromJson(
      response as Map<String, dynamic>,
    );
    await participantsBox.put(created.id, jsonEncode(created.toJson()));
    return created;
  }

  Future<FlightParticipant> updateParticipant(FlightParticipant p) async {
    final response = await supabase
        .from('flight_participants')
        .update(p.toJson())
        .eq('id', p.id)
        .select()
        .single();

    final updated = FlightParticipant.fromJson(
      response as Map<String, dynamic>,
    );
    await participantsBox.put(updated.id, jsonEncode(updated.toJson()));
    return updated;
  }

  Stream<List<FlightParticipant>> watchParticipants(String flightId) {
    return supabase
        .from('flight_participants')
        .stream(primaryKey: ['id'])
        .eq('flight_session_id', flightId)
        .map(
          (rows) =>
              rows.map((json) => FlightParticipant.fromJson(json)).toList(),
        );
  }

  // ─── Offline Pending Actions ─────────────────────────────────────────────────

  Future<void> addPendingAction(Map<String, dynamic> action) async {
    final box = pendingActionsBox;
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(key, jsonEncode(action));
  }

  Future<void> replayPendingActions() async {
    final box = pendingActionsBox;
    final keys = box.keys.toList();

    for (final key in keys) {
      final raw = box.get(key);
      if (raw == null) continue;

      try {
        final action = jsonDecode(raw as String) as Map<String, dynamic>;
        final table = action['table'] as String;
        final method = action['method'] as String;
        final data = action['data'] as Map<String, dynamic>;

        switch (method) {
          case 'insert':
            await supabase.from(table).insert(data);
            break;
          case 'update':
            final id = data['id'] as String;
            await supabase.from(table).update(data).eq('id', id);
            break;
          case 'delete':
            final id = data['id'] as String;
            await supabase.from(table).delete().eq('id', id);
            break;
        }

        await box.delete(key);
      } catch (_) {
        // Leave in queue for next retry
      }
    }
  }
}
