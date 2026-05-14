import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon_statistics.dart';
import 'package:skywing_tracker/features/pigeons/models/achievement.dart';
import 'package:skywing_tracker/features/pigeons/providers/pigeon_provider.dart';

class PigeonDetailScreen extends ConsumerWidget {
  final String pigeonId;

  const PigeonDetailScreen({super.key, required this.pigeonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pigeonAsync = ref.watch(pigeonByIdProvider(pigeonId));
    final statsAsync = ref.watch(pigeonStatisticsProvider(pigeonId));
    final achievementsAsync = ref.watch(pigeonAchievementsProvider(pigeonId));

    return pigeonAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Pigeon Details')),
        body: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (pigeon) {
        if (pigeon == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pigeon Details')),
            body: const Center(child: Text('Pigeon not found')),
          );
        }
        return _PigeonDetailContent(
          pigeon: pigeon,
          statsAsync: statsAsync,
          achievementsAsync: achievementsAsync,
        );
      },
    );
  }
}

class _PigeonDetailContent extends StatelessWidget {
  final Pigeon pigeon;
  final AsyncValue<PigeonStatistics?> statsAsync;
  final AsyncValue<List<Achievement>> achievementsAsync;

  const _PigeonDetailContent({
    required this.pigeon,
    required this.statsAsync,
    required this.achievementsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.go('/pigeons/${pigeon.id}/edit'),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(pigeon.name),
                background: _HeroImage(imageUrl: pigeon.imageUrl),
              ),
            ),
            SliverToBoxAdapter(child: _StatsRow(statsAsync: statsAsync)),
            const SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Flights'),
                    Tab(text: 'Achievements'),
                    Tab(text: 'Statistics'),
                  ],
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accent,
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _OverviewTab(pigeon: pigeon),
              _FlightsTab(pigeonId: pigeon.id),
              _AchievementsTab(achievementsAsync: achievementsAsync),
              _StatisticsTab(statsAsync: statsAsync),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;

  const _HeroImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const _ImagePlaceholder(),
        errorWidget: (_, __, ___) => const _ImagePlaceholder(),
      );
    }
    return const _ImagePlaceholder();
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.flutter_dash,
          size: 80,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AsyncValue<PigeonStatistics?> statsAsync;

  const _StatsRow({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: statsAsync.when(
        loading: () => const Center(
          child: SizedBox(
            height: 48,
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (stats) {
          if (stats == null) {
            return _buildStatsRow(context, 0, 0.0, 0.0, 0.0);
          }
          return _buildStatsRow(
            context,
            stats.totalFlights,
            stats.avgSpeedKmh,
            stats.returnRate,
            stats.totalDistanceKm,
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    int flights,
    double avgSpeed,
    double returnRate,
    double distance,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(label: 'Flights', value: '$flights'),
        _StatDivider(),
        _StatItem(
          label: 'Avg Speed',
          value: '${avgSpeed.toStringAsFixed(1)} km/h',
        ),
        _StatDivider(),
        _StatItem(
          label: 'Return Rate',
          value: '${(returnRate * 100).toStringAsFixed(0)}%',
        ),
        _StatDivider(),
        _StatItem(
          label: 'Distance',
          value: '${distance.toStringAsFixed(0)} km',
        ),
      ],
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
            fontFamily: 'Rajdhani',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 1, color: AppColors.divider);
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.primary, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _OverviewTab extends StatelessWidget {
  final Pigeon pigeon;

  const _OverviewTab({required this.pigeon});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Basic Information',
          children: [
            _InfoRow(label: 'Ring Number', value: pigeon.ringNumber),
            _InfoRow(label: 'Breed', value: pigeon.breed),
            _InfoRow(
              label: 'Sex',
              value: pigeon.sex == 'male' ? 'Male' : 'Female',
            ),
            if (pigeon.color != null)
              _InfoRow(label: 'Color', value: pigeon.color!),
            if (pigeon.hatchDate != null)
              _InfoRow(
                label: 'Hatch Date',
                value:
                    '${pigeon.hatchDate!.day}/${pigeon.hatchDate!.month}/${pigeon.hatchDate!.year}',
              ),
            _InfoRow(
              label: 'Status',
              value: pigeon.isActive ? 'Active' : 'Inactive',
            ),
          ],
        ),
        if (pigeon.healthNotes != null && pigeon.healthNotes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Health Notes',
            children: [
              Text(
                pigeon.healthNotes!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _FlightsTab extends StatelessWidget {
  final String pigeonId;

  const _FlightsTab({required this.pigeonId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Flight history coming soon',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  final AsyncValue<List<Achievement>> achievementsAsync;

  const _AchievementsTab({required this.achievementsAsync});

  @override
  Widget build(BuildContext context) {
    return achievementsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (achievements) {
        if (achievements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'No achievements yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: achievements.length,
          itemBuilder: (context, index) =>
              _AchievementTile(achievement: achievements[index]),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsTab extends StatelessWidget {
  final AsyncValue<PigeonStatistics?> statsAsync;

  const _StatisticsTab({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        if (stats == null) {
          return const Center(
            child: Text(
              'No statistics available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatCard(label: 'Total Flights', value: '${stats.totalFlights}'),
            _StatCard(
              label: 'Average Speed',
              value: '${stats.avgSpeedKmh.toStringAsFixed(1)} km/h',
            ),
            _StatCard(
              label: 'Total Distance',
              value: '${stats.totalDistanceKm.toStringAsFixed(1)} km',
            ),
            _StatCard(
              label: 'Return Rate',
              value: '${(stats.returnRate * 100).toStringAsFixed(1)}%',
            ),
            if (stats.bestSpeedKmh != null)
              _StatCard(
                label: 'Best Speed',
                value: '${stats.bestSpeedKmh!.toStringAsFixed(1)} km/h',
              ),
            if (stats.lastFlightDate != null)
              _StatCard(
                label: 'Last Flight',
                value:
                    '${stats.lastFlightDate!.day}/${stats.lastFlightDate!.month}/${stats.lastFlightDate!.year}',
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
