import 'package:flutter/material.dart';
import 'package:skywing_tracker/core/theme.dart';

class StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
}

class StatRow extends StatelessWidget {
  final List<StatItem> items;

  const StatRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) => Expanded(child: _StatCell(item: item)))
          .toList(),
    );
  }
}

class _StatCell extends StatelessWidget {
  final StatItem item;

  const _StatCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(item.icon, size: 20, color: item.color ?? AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: item.color ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
