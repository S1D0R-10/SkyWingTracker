import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/analytics/models/analytics_data.dart';
import 'package:skywing_tracker/features/analytics/providers/analytics_provider.dart';
import 'package:skywing_tracker/shared/widgets/app_card.dart';
import 'package:skywing_tracker/shared/widgets/skeleton_loader.dart';

class SeasonStatisticsScreen extends ConsumerWidget {
  const SeasonStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Season Statistics')),
      body: analyticsAsync.when(
        loading: () => const _LoadingSkeleton(),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (data) => _SeasonContent(data: data),
      ),
    );
  }
}

class _SeasonContent extends StatelessWidget {
  final AnalyticsData data;

  const _SeasonContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalFlights = data.monthlyFlights.fold<int>(
      0,
      (sum, m) => sum + m.training + m.competition,
    );
    final totalTraining = data.monthlyFlights.fold<int>(
      0,
      (sum, m) => sum + m.training,
    );
    final totalCompetition = data.monthlyFlights.fold<int>(
      0,
      (sum, m) => sum + m.competition,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season summary
          Text('Season Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _StatTile(label: 'Total Flights', value: '$totalFlights'),
                _StatTile(label: 'Training Flights', value: '$totalTraining'),
                _StatTile(
                  label: 'Competition Flights',
                  value: '$totalCompetition',
                ),
                _StatTile(
                  label: 'Total Distance',
                  value: '${data.totalSeasonDistance.toStringAsFixed(1)} km',
                ),
                _StatTile(
                  label: 'Return Reliability',
                  value: '${data.returnReliability.toStringAsFixed(1)}%',
                ),
                _StatTile(
                  label: 'Pigeons Tracked',
                  value: '${data.rankings.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cumulative distance line chart
          Text(
            'Cumulative Distance',
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
                  : _CumulativeDistanceChart(data: data),
            ),
          ),
          const SizedBox(height: 24),

          // Return reliability donut
          Text(
            'Return Reliability',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: SizedBox(
              height: 220,
              child: _ReturnDonutChart(returnRate: data.returnReliability),
            ),
          ),
          const SizedBox(height: 24),

          // Month-by-month table
          Text('Month by Month', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AppCard(
            child: data.monthlyFlights.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No data yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.divider),
                          ),
                        ),
                        children: [
                          _TableHeader('Month'),
                          _TableHeader('Train'),
                          _TableHeader('Comp'),
                          _TableHeader('Total'),
                        ],
                      ),
                      ...data.monthlyFlights.map(
                        (m) => TableRow(
                          children: [
                            _TableCell(m.month),
                            _TableCell('${m.training}'),
                            _TableCell('${m.competition}'),
                            _TableCell('${m.training + m.competition}'),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CumulativeDistanceChart extends StatelessWidget {
  final AnalyticsData data;

  const _CumulativeDistanceChart({required this.data});

  @override
  Widget build(BuildContext context) {
    double cumulative = 0;
    final spots = data.monthlyFlights.asMap().entries.map((e) {
      // Approximate: distribute total distance evenly across months
      final fraction =
          (e.value.training + e.value.competition) /
          data.monthlyFlights.fold<int>(
            1,
            (s, m) => s + m.training + m.competition,
          );
      cumulative += data.totalSeasonDistance * fraction;
      return FlSpot(e.key.toDouble(), cumulative);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.divider, strokeWidth: 0.5),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()} km',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.monthlyFlights.length) {
                  return const SizedBox.shrink();
                }
                final parts = data.monthlyFlights[idx].month.split('-');
                return Text(
                  parts.length > 1 ? parts[1] : '',
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
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.success,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnDonutChart extends StatelessWidget {
  final double returnRate;

  const _ReturnDonutChart({required this.returnRate});

  @override
  Widget build(BuildContext context) {
    final returned = returnRate.clamp(0.0, 100.0);
    final notReturned = 100.0 - returned;

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  value: returned,
                  color: AppColors.success,
                  title: '${returned.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  radius: 40,
                ),
                PieChartSectionData(
                  value: notReturned,
                  color: AppColors.error,
                  title: '${notReturned.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  radius: 40,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Legend(color: AppColors.success, label: 'Returned'),
            const SizedBox(height: 8),
            _Legend(color: AppColors.error, label: 'Not Returned'),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;

  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
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
          const SkeletonLoader(height: 200),
          const SizedBox(height: 16),
          const SkeletonLoader(height: 200),
          const SizedBox(height: 16),
          const SkeletonLoader(height: 200),
        ],
      ),
    );
  }
}
