import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/analytics/models/analytics_data.dart';
import 'package:skywing_tracker/features/analytics/providers/analytics_provider.dart';
import 'package:skywing_tracker/shared/widgets/app_card.dart';
import 'package:skywing_tracker/shared/widgets/skeleton_loader.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(analyticsDataProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const _LoadingSkeleton(),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (data) => _DashboardContent(data: data),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final AnalyticsData data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalFlights = data.monthlyFlights.fold<int>(
      0,
      (sum, m) => sum + m.training + m.competition,
    );
    final bestPigeon = data.rankings.isNotEmpty
        ? data.rankings.first.pigeonName
        : 'N/A';
    final avgSpeed = data.speedOverTime.isNotEmpty
        ? data.speedOverTime.map((s) => s.speedKmh).reduce((a, b) => a + b) /
              data.speedOverTime.length
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _SummaryCard(
                icon: Icons.flight_takeoff,
                label: 'Total Flights',
                value: '$totalFlights',
                color: AppColors.accent,
              ),
              _SummaryCard(
                icon: Icons.route,
                label: 'Season Distance',
                value: '${data.totalSeasonDistance.toStringAsFixed(0)} km',
                color: AppColors.success,
              ),
              _SummaryCard(
                icon: Icons.speed,
                label: 'Avg Speed',
                value: '${avgSpeed.toStringAsFixed(1)} km/h',
                color: const Color(0xFF4A90D9),
              ),
              _SummaryCard(
                icon: Icons.emoji_events,
                label: 'Best Pigeon',
                value: bestPigeon,
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Speed over time chart
          Text(
            'Speed Over Time (Last 30 Days)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: SizedBox(
              height: 200,
              child: data.speedOverTime.isEmpty
                  ? const Center(
                      child: Text(
                        'No data yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : _SpeedLineChart(points: data.speedOverTime),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly flights bar chart
          Text(
            'Monthly Flights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: SizedBox(
              height: 200,
              child: data.monthlyFlights.isEmpty
                  ? const Center(
                      child: Text(
                        'No data yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : _MonthlyBarChart(months: data.monthlyFlights),
            ),
          ),
          const SizedBox(height: 24),

          // Navigation chips
          Text('Explore', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _NavChip(
                label: 'Rankings',
                icon: Icons.leaderboard,
                onTap: () => context.push('/analytics/rankings'),
              ),
              _NavChip(
                label: 'Season Stats',
                icon: Icons.bar_chart,
                onTap: () => context.push('/analytics/season'),
              ),
              _NavChip(
                label: 'AI Insights',
                icon: Icons.auto_awesome,
                onTap: () => context.push('/analytics/ai-insights'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedLineChart extends StatelessWidget {
  final List<SpeedDataPoint> points;

  const _SpeedLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.speedKmh);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.divider, strokeWidth: 0.5),
          getDrawingVerticalLine: (_) =>
              const FlLine(color: AppColors.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
            dotData: const FlDotData(show: false),
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

class _MonthlyBarChart extends StatelessWidget {
  final List<MonthlyFlightCount> months;

  const _MonthlyBarChart({required this.months});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.divider, strokeWidth: 0.5),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= months.length) {
                  return const SizedBox.shrink();
                }
                final parts = months[idx].month.split('-');
                return Text(
                  parts.length > 1 ? parts[1] : months[idx].month,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
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
        barGroups: months.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.training.toDouble(),
                color: const Color(0xFF4A90D9),
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: e.value.competition.toDouble(),
                color: AppColors.accent,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.accent),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: List.generate(4, (_) => const SkeletonCard()),
          ),
          const SizedBox(height: 24),
          const SkeletonLoader(height: 200),
          const SizedBox(height: 24),
          const SkeletonLoader(height: 200),
        ],
      ),
    );
  }
}
