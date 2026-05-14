import 'package:flutter/material.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/flights/models/flight_session.dart';

class FlightStatusBadge extends StatelessWidget {
  final FlightStatus status;

  const FlightStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return _StatusChip(label: _label(status), color: _color(status));
  }

  String _label(FlightStatus s) {
    switch (s) {
      case FlightStatus.released:
        return 'Released';
      case FlightStatus.returned:
        return 'Returned';
      case FlightStatus.missing:
        return 'Missing';
      case FlightStatus.injured:
        return 'Injured';
    }
  }

  Color _color(FlightStatus s) {
    switch (s) {
      case FlightStatus.released:
        return AppColors.accent;
      case FlightStatus.returned:
        return AppColors.success;
      case FlightStatus.missing:
        return AppColors.error;
      case FlightStatus.injured:
        return AppColors.warning;
    }
  }
}

class FlightTypeBadge extends StatelessWidget {
  final FlightType type;

  const FlightTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return _StatusChip(
      label: type == FlightType.training ? 'Training' : 'Competition',
      color: type == FlightType.training
          ? const Color(0xFF4A90D9)
          : AppColors.accent,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
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
