import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon_statistics.dart';
import 'package:skywing_tracker/features/pigeons/providers/pigeon_provider.dart';

class PigeonStatisticsScreen extends ConsumerWidget {
  final String pigeonId;

  const PigeonStatisticsScreen({super.key, required this.pigeonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(pigeonStatisticsProvider(pigeonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load statistics',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(pigeonStatisticsProvider(pigeonId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) {
          if (stats == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 80,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No statistics available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete flights to see statistics',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }
          return _StatisticsContent(stats: stats);
        },
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  final PigeonStatistics stats;

  const _StatisticsContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        _SummaryGrid(stats: stats),
        const SizedBox(height: 24),

        // Speed line chart
        _ChartCard(
          title: 'Speed Over Recent Flights',
          child: _SpeedLineChart(avgSpeed: stats.avgSpeedKmh),
        ),
        const SizedBox(height: 16),

        // Monthly distance bar chart
        _ChartCard(
          title: 'Monthly Distance (km)',
          child: _MonthlyDistanceBarChart(totalDistance: stats.totalDistanceKm),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final PigeonStatistics stats;

  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _SummaryCard(
          label: 'Total Flights',
          value: '${stats.totalFlights}',
          icon: Icons.flight,
        ),
        _SummaryCard(
          label: 'Avg Speed',
          value: '${stats.avgSpeedKmh.toStringAsFixed(1)} km/h',
          icon: Icons.speed,
        ),
        _SummaryCard(
          label: 'Total Distance',
          value: '${stats.totalDistanceKm.toStringAsFixed(0)} km',
          icon: Icons.straighten,
        ),
        _SummaryCard(
          label: 'Return Rate',
          value: '${(stats.returnRate * 100).toStringAsFixed(0)}%',
          icon: Icons.loop,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }
}

class _SpeedLineChart extends StatelessWidget {
  final double avgSpeed;

  const _SpeedLineChart({required this.avgSpeed});

  @override
  Widget build(BuildContext context) {
    // Generate mock data points around the average speed
    final spots = List.generate(8, (i) {
      final variation = (i % 3 - 1) * avgSpeed * 0.1;
      return FlSpot(
        i.toDouble(),
        (avgSpeed + variation).clamp(0, double.infinity),
      );
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Text(
                'F${value.toInt() + 1}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 2,
            dotData: FlDotData(
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.accent,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyDistanceBarChart extends StatelessWidget {
  final double totalDistance;

  const _MonthlyDistanceBarChart({required this.totalDistance});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final values = [
      0.15,
      0.20,
      0.18,
      0.22,
      0.12,
      0.13,
    ].map((f) => f * totalDistance).toList();

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= months.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  months[index],
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          values.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: AppColors.accent,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
