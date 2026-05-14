import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/analytics/models/analytics_data.dart';
import 'package:skywing_tracker/features/analytics/providers/analytics_provider.dart';
import 'package:skywing_tracker/shared/widgets/app_card.dart';
import 'package:skywing_tracker/shared/widgets/skeleton_loader.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rankings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Speed'),
            Tab(text: 'Distance'),
            Tab(text: 'Reliability'),
            Tab(text: 'Champion'),
          ],
        ),
      ),
      body: analyticsAsync.when(
        loading: () => const _LoadingSkeleton(),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (data) => TabBarView(
          controller: _tabController,
          children: [
            _RankingTab(
              rankings: List.from(data.rankings)
                ..sort((a, b) => b.avgSpeed.compareTo(a.avgSpeed)),
              valueLabel: 'Avg Speed',
              valueFormatter: (r) => '${r.avgSpeed.toStringAsFixed(1)} km/h',
            ),
            _RankingTab(
              rankings: List.from(data.rankings)
                ..sort((a, b) => b.totalDistance.compareTo(a.totalDistance)),
              valueLabel: 'Total Distance',
              valueFormatter: (r) => '${r.totalDistance.toStringAsFixed(0)} km',
            ),
            _RankingTab(
              rankings: List.from(data.rankings)
                ..sort((a, b) => b.returnRate.compareTo(a.returnRate)),
              valueLabel: 'Return Rate',
              valueFormatter: (r) => '${r.returnRate.toStringAsFixed(1)}%',
            ),
            _MonthlyChampionTab(data: data),
          ],
        ),
      ),
    );
  }
}

class _RankingTab extends StatelessWidget {
  final List<PigeonRanking> rankings;
  final String valueLabel;
  final String Function(PigeonRanking) valueFormatter;

  const _RankingTab({
    required this.rankings,
    required this.valueLabel,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const Center(
        child: Text(
          'No data yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Podium for top 3
        if (rankings.length >= 3)
          _Podium(
            first: rankings[0],
            second: rankings[1],
            third: rankings[2],
            valueFormatter: valueFormatter,
          ),
        const SizedBox(height: 16),
        // Full list
        ...rankings.asMap().entries.map(
          (e) => _RankRow(
            rank: e.key + 1,
            ranking: e.value,
            valueLabel: valueLabel,
            valueFormatter: valueFormatter,
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final PigeonRanking first;
  final PigeonRanking second;
  final PigeonRanking third;
  final String Function(PigeonRanking) valueFormatter;

  const _Podium({
    required this.first,
    required this.second,
    required this.third,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumCard(
            rank: 2,
            ranking: second,
            color: const Color(0xFFC0C0C0),
            height: 100,
            valueFormatter: valueFormatter,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumCard(
            rank: 1,
            ranking: first,
            color: const Color(0xFFFFD700),
            height: 130,
            valueFormatter: valueFormatter,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumCard(
            rank: 3,
            ranking: third,
            color: const Color(0xFFCD7F32),
            height: 80,
            valueFormatter: valueFormatter,
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int rank;
  final PigeonRanking ranking;
  final Color color;
  final double height;
  final String Function(PigeonRanking) valueFormatter;

  const _PodiumCard({
    required this.rank,
    required this.ranking,
    required this.color,
    required this.height,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$rank',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ranking.pigeonName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            valueFormatter(ranking),
            style: TextStyle(color: color, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final PigeonRanking ranking;
  final String valueLabel;
  final String Function(PigeonRanking) valueFormatter;

  const _RankRow({
    required this.rank,
    required this.ranking,
    required this.valueLabel,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank <= 3 ? AppColors.accent : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.pigeonName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${ranking.totalFlights} flights',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            valueFormatter(ranking),
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyChampionTab extends StatelessWidget {
  final AnalyticsData data;

  const _MonthlyChampionTab({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.rankings.isEmpty) {
      return const Center(
        child: Text(
          'No data yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Show overall champion with most flights
    final champion = data.rankings.reduce(
      (a, b) => a.totalFlights > b.totalFlights ? a : b,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Season Champion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  champion.pigeonName,
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(color: AppColors.accent),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Flights',
                      value: '${champion.totalFlights}',
                    ),
                    _StatItem(
                      label: 'Avg Speed',
                      value: '${champion.avgSpeed.toStringAsFixed(1)} km/h',
                    ),
                    _StatItem(
                      label: 'Return Rate',
                      value: '${champion.returnRate.toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
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
          const SkeletonLoader(height: 130),
          const SizedBox(height: 16),
          ...List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SkeletonLoader(height: 60),
            ),
          ),
        ],
      ),
    );
  }
}
