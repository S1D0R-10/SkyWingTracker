import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/pigeons/models/achievement.dart';
import 'package:skywing_tracker/features/pigeons/providers/pigeon_provider.dart';

class PigeonAchievementsScreen extends ConsumerWidget {
  final String pigeonId;

  const PigeonAchievementsScreen({super.key, required this.pigeonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(pigeonAchievementsProvider(pigeonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: achievementsAsync.when(
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
                'Failed to load achievements',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(pigeonAchievementsProvider(pigeonId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (achievements) {
          if (achievements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No achievements yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete flights to earn achievements',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (context, index) =>
                _AchievementCard(achievement: achievements[index]),
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.accent.withOpacity(0.05)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Icon(
              _getIconData(achievement.iconName),
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Earned ${dateFormat.format(achievement.earnedAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 12),
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

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'speed':
        return Icons.speed;
      case 'flight':
        return Icons.flight;
      case 'star':
        return Icons.star;
      case 'trophy':
        return Icons.emoji_events;
      case 'distance':
        return Icons.straighten;
      default:
        return Icons.emoji_events;
    }
  }
}
