import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skywing_tracker/features/flights/models/flight_session.dart';
import 'package:skywing_tracker/features/flights/models/flight_participant.dart';
import 'package:skywing_tracker/features/flights/repositories/flight_repository.dart';

final flightRepositoryProvider = Provider<FlightRepository>((ref) {
  return FlightRepository();
});

final flightsProvider = FutureProvider<List<FlightSession>>((ref) async {
  final repo = ref.watch(flightRepositoryProvider);
  return repo.getFlights();
});

final flightByIdProvider = FutureProvider.family<FlightSession?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(flightRepositoryProvider);
  return repo.getFlightById(id);
});

final participantsProvider =
    FutureProvider.family<List<FlightParticipant>, String>((
      ref,
      flightId,
    ) async {
      final repo = ref.watch(flightRepositoryProvider);
      return repo.getParticipants(flightId);
    });

final liveParticipantsProvider =
    StreamProvider.family<List<FlightParticipant>, String>((ref, flightId) {
      final repo = ref.watch(flightRepositoryProvider);
      return repo.watchParticipants(flightId);
    });

/// Filter: 'all' | 'active' | 'training' | 'competition'
final flightFilterProvider = StateProvider<String>((ref) => 'all');
