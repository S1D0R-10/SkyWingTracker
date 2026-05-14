import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/flights/models/flight_session.dart';
import 'package:skywing_tracker/features/flights/models/flight_participant.dart';
import 'package:skywing_tracker/features/flights/providers/flight_provider.dart';

class FlightDetailScreen extends ConsumerWidget {
  final String flightId;
  const FlightDetailScreen({super.key, required this.flightId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightAsync = ref.watch(flightByIdProvider(flightId));
    final participantsAsync = ref.watch(participantsProvider(flightId));

    return Scaffold(
      appBar: AppBar(
        title: flightAsync.maybeWhen(
          data: (f) => Text(f?.name ?? 'Flight Detail'),
          orElse: () => const Text('Flight Detail'),
        ),
      ),
      body: flightAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (flight) {
          if (flight == null) {
            return const Center(child: Text('Flight not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(flight: flight),
              const SizedBox(height: 16),
              _WeatherCard(weatherJson: flight.weatherConditions),
              const SizedBox(height: 16),
              _ParticipantsSection(participantsAsync: participantsAsync),
              const SizedBox(height: 24),
              _ActionButtons(flightId: flightId, flight: flight),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final FlightSession flight;
  const _InfoCard({required this.flight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  flight.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              _StatusChip(status: flight.status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Type',
            value: flight.type == FlightType.training
                ? 'Training'
                : 'Competition',
          ),
          _InfoRow(
            icon: Icons.schedule,
            label: 'Released',
            value: _formatDateTime(flight.releaseTime),
          ),
          if (flight.endTime != null)
            _InfoRow(
              icon: Icons.flag_outlined,
              label: 'Ended',
              value: _formatDateTime(flight.endTime!),
            ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value:
                flight.releaseLocationName ??
                '${flight.releaseLatitude.toStringAsFixed(4)}, '
                    '${flight.releaseLongitude.toStringAsFixed(4)}',
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final FlightStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case FlightStatus.released:
        color = AppColors.accent;
        label = 'Active';
        break;
      case FlightStatus.returned:
        color = AppColors.success;
        label = 'Returned';
        break;
      case FlightStatus.missing:
        color = AppColors.warning;
        label = 'Missing';
        break;
      case FlightStatus.injured:
        color = AppColors.error;
        label = 'Injured';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final String? weatherJson;
  const _WeatherCard({this.weatherJson});

  @override
  Widget build(BuildContext context) {
    if (weatherJson == null) return const SizedBox.shrink();

    String summary = 'Weather data available';
    try {
      final data = jsonDecode(weatherJson!) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final condition =
          (current['condition'] as Map<String, dynamic>)['text'] as String;
      final tempC = current['temp_c'];
      final humidity = current['humidity'];
      final windKph = current['wind_kph'];
      summary =
          '$condition • ${tempC}°C • Humidity: $humidity% • Wind: ${windKph} km/h';
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_outlined, color: AppColors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather at Release',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  final AsyncValue<List<FlightParticipant>> participantsAsync;
  const _ParticipantsSection({required this.participantsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Participants',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        participantsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: AppColors.error)),
          data: (participants) {
            if (participants.isEmpty) {
              return const Text(
                'No participants',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            return Column(
              children: participants
                  .map((p) => _ParticipantTile(participant: p))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final FlightParticipant participant;
  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (participant.status) {
      case FlightStatus.released:
        statusColor = AppColors.accent;
        break;
      case FlightStatus.returned:
        statusColor = AppColors.success;
        break;
      case FlightStatus.missing:
        statusColor = AppColors.warning;
        break;
      case FlightStatus.injured:
        statusColor = AppColors.error;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.pigeonName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  participant.pigeonRingNumber,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            participant.status.name[0].toUpperCase() +
                participant.status.name.substring(1),
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerStatefulWidget {
  final String flightId;
  final FlightSession flight;
  const _ActionButtons({required this.flightId, required this.flight});

  @override
  ConsumerState<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends ConsumerState<_ActionButtons> {
  bool _ending = false;

  Future<void> _endFlight() async {
    setState(() => _ending = true);
    try {
      final repo = ref.read(flightRepositoryProvider);
      final updated = widget.flight.copyWith(
        status: FlightStatus.returned,
        endTime: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.updateFlight(updated);
      ref.invalidate(flightByIdProvider(widget.flightId));
      ref.invalidate(flightsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flight ended'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  void _confirmEndFlight() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'End Flight',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to end this flight session?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endFlight();
            },
            child: const Text('End', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/flights/${widget.flightId}/map'),
            icon: const Icon(Icons.map_outlined),
            label: const Text('View Map'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.flight.status == FlightStatus.released) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/flights/${widget.flightId}/live'),
              icon: const Icon(Icons.radar),
              label: const Text('View Live Tracking'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _ending ? null : _confirmEndFlight,
              icon: _ending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(
                      Icons.stop_circle_outlined,
                      color: AppColors.error,
                    ),
              label: const Text(
                'End Flight',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
