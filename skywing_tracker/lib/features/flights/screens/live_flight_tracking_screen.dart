import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/flights/models/flight_session.dart';
import 'package:skywing_tracker/features/flights/models/flight_participant.dart';
import 'package:skywing_tracker/features/flights/providers/flight_provider.dart';

class LiveFlightTrackingScreen extends ConsumerStatefulWidget {
  final String flightId;
  const LiveFlightTrackingScreen({super.key, required this.flightId});

  @override
  ConsumerState<LiveFlightTrackingScreen> createState() =>
      _LiveFlightTrackingScreenState();
}

class _LiveFlightTrackingScreenState
    extends ConsumerState<LiveFlightTrackingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flightAsync = ref.watch(flightByIdProvider(widget.flightId));
    final liveAsync = ref.watch(liveParticipantsProvider(widget.flightId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.go('/flights/${widget.flightId}/map'),
          ),
        ],
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
          final elapsed = DateTime.now().difference(flight.releaseTime);

          return liveAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            data: (participants) {
              final returned = participants
                  .where((p) => p.status == FlightStatus.returned)
                  .length;
              final total = participants.length;
              final filtered = _filterParticipants(participants);

              return Column(
                children: [
                  // Elapsed timer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    color: AppColors.surface,
                    child: Column(
                      children: [
                        const Text(
                          'ELAPSED TIME',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Text(
                            _formatElapsed(elapsed),
                            style: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? returned / total : 0,
                            backgroundColor: AppColors.divider,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.success,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$returned of $total returned',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children:
                          [
                            'all',
                            'released',
                            'returned',
                            'missing',
                            'injured',
                          ].map((f) {
                            final sel = _statusFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  f[0].toUpperCase() + f.substring(1),
                                  style: TextStyle(
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                                selected: sel,
                                onSelected: (_) =>
                                    setState(() => _statusFilter = f),
                                selectedColor: AppColors.accent,
                                backgroundColor: AppColors.card,
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Participant list
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No participants',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return _SwipeableParticipantTile(
                                participant: filtered[index],
                                flightId: widget.flightId,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<FlightParticipant> _filterParticipants(
    List<FlightParticipant> participants,
  ) {
    if (_statusFilter == 'all') return participants;
    return participants.where((p) => p.status.name == _statusFilter).toList();
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _SwipeableParticipantTile extends ConsumerWidget {
  final FlightParticipant participant;
  final String flightId;

  const _SwipeableParticipantTile({
    required this.participant,
    required this.flightId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReturned = participant.status == FlightStatus.returned;

    return Dismissible(
      key: Key(participant.id),
      direction: isReturned
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text('Mark Returned', style: TextStyle(color: AppColors.success)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        context.go('/flights/$flightId/return/${participant.id}');
        return false;
      },
      child: GestureDetector(
        onTap: () => context.go('/flights/$flightId/return/${participant.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _statusColor(participant.status).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _statusColor(participant.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
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
              if (participant.returnTime != null)
                Text(
                  _formatTime(participant.returnTime!),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                  ),
                )
              else if (!isReturned)
                const Icon(
                  Icons.swipe_right_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(FlightStatus status) {
    switch (status) {
      case FlightStatus.released:
        return AppColors.accent;
      case FlightStatus.returned:
        return AppColors.success;
      case FlightStatus.missing:
        return AppColors.warning;
      case FlightStatus.injured:
        return AppColors.error;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
