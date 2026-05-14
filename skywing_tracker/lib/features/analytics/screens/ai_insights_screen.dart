import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/analytics/providers/analytics_provider.dart';
import 'package:skywing_tracker/shared/widgets/skeleton_loader.dart';

class AIInsightsScreen extends ConsumerWidget {
  const AIInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(aiInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(analyticsDataProvider);
              ref.invalidate(aiInsightsProvider);
            },
          ),
        ],
      ),
      body: insightsAsync.when(
        loading: () => const _InsightsSkeleton(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(analyticsDataProvider);
                    ref.invalidate(aiInsightsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (insights) => _InsightsContent(insights: insights),
      ),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  final String insights;

  const _InsightsContent({required this.insights});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withOpacity(0.2), AppColors.card],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.accent,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Coach Analysis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Text(
                        'Powered by GPT-4o-mini',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Insights text rendered as rich text
          _MarkdownText(text: insights),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Simple markdown-like renderer for headers and bullet points.
class _MarkdownText extends StatelessWidget {
  final String text;

  const _MarkdownText({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) => _renderLine(context, line)).toList(),
      ),
    );
  }

  Widget _renderLine(BuildContext context, String line) {
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(
          line.substring(3),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      );
    }
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          line.substring(4),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }
    if (line.startsWith('**') && line.endsWith('**')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          line.replaceAll('**', ''),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '• ',
              style: TextStyle(color: AppColors.accent, fontSize: 16),
            ),
            Expanded(
              child: Text(
                line.substring(2),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (line.trim().isEmpty) {
      return const SizedBox(height: 4);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        line,
        style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
      ),
    );
  }
}

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 80),
          const SizedBox(height: 24),
          const SkeletonLoader(width: 200, height: 20),
          const SizedBox(height: 12),
          ...List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SkeletonLoader(height: 14),
            ),
          ),
          const SizedBox(height: 16),
          const SkeletonLoader(width: 180, height: 20),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SkeletonLoader(height: 14),
            ),
          ),
        ],
      ),
    );
  }
}
