import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/flights/models/flight_session.dart';
import 'package:skywing_tracker/features/flights/providers/flight_provider.dart';

class FlightListScreen extends ConsumerStatefulWidget {
  const FlightListScreen({super.key});

  @override
  ConsumerState<FlightListScreen> createState() => _FlightListScreenState();
}

class _FlightListScreenState extends ConsumerState<FlightListScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flightsAsync = ref.watch(flightsProvider);
    final filter = ref.watch(flightFilterProvider);

    final filters = ['all', 'active', 'training', 'competition'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flights'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: filters.map((f) {
                final selected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      f[0].toUpperCase() + f.substring(1),
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(flightFilterProvider.notifier).state = f,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.card,
                    side: BorderSide(
                      color: selected ? AppColors.accent : AppColors.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/flights/create'),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.primary),
      ),
      body: flightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (flights) {
          final filtered = _applyFilter(flights, filter);
          if (filtered.isEmpty) {
            return const Center(
              child: Text(
                'No flights found.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(flightsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return _FlightCard(
                  flight: filtered[index],
                  onTap: () => context.go('/flights/${filtered[index].id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<FlightSession> _applyFilter(List<FlightSession> flights, String filter) {
    switch (filter) {
      case 'active':
        return flights.where((f) => f.status == FlightStatus.released).toList();
      case 'training':
        return flights.where((f) => f.type == FlightType.training).toList();
      case 'competition':
        return flights.where((f) => f.type == FlightType.competition).toList();
      default:
        return flights;
    }
  }
}

class _FlightCard extends StatelessWidget {
  final FlightSession flight;
  final VoidCallback onTap;

  const _FlightCard({required this.flight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(flight.releaseTime);
    final isActive = flight.status == FlightStatus.released;

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? AppColors.accent.withOpacity(0.4)
              : AppColors.divider,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      flight.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _TypeBadge(type: flight.type),
                  const SizedBox(width: 8),
                  _StatusBadge(status: flight.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? _formatElapsed(elapsed) : 'Ended',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      flight.releaseLocationName ?? 'Unknown location',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';
  }
}

class _TypeBadge extends StatelessWidget {
  final FlightType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isComp = type == FlightType.competition;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isComp
            ? AppColors.accent.withOpacity(0.2)
            : AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComp ? AppColors.accent : AppColors.success,
          width: 0.8,
        ),
      ),
      child: Text(
        isComp ? 'Competition' : 'Training',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isComp ? AppColors.accent : AppColors.success,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final FlightStatus status;
  const _StatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
