import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon.dart';
import 'package:skywing_tracker/features/pigeons/providers/pigeon_provider.dart';

class PigeonListScreen extends ConsumerStatefulWidget {
  const PigeonListScreen({super.key});

  @override
  ConsumerState<PigeonListScreen> createState() => _PigeonListScreenState();
}

class _PigeonListScreenState extends ConsumerState<PigeonListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Male', 'Female', 'Active', 'Inactive'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Pigeon> _applyFilters(List<Pigeon> pigeons) {
    var filtered = pigeons;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.ringNumber.toLowerCase().contains(query) ||
            p.breed.toLowerCase().contains(query);
      }).toList();
    }

    switch (_selectedFilter) {
      case 'Male':
        filtered = filtered.where((p) => p.sex == 'male').toList();
        break;
      case 'Female':
        filtered = filtered.where((p) => p.sex == 'female').toList();
        break;
      case 'Active':
        filtered = filtered.where((p) => p.isActive).toList();
        break;
      case 'Inactive':
        filtered = filtered.where((p) => !p.isActive).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final pigeonsAsync = ref.watch(pigeonsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Pigeons')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/pigeons/create'),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.primary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search by name, ring number, breed...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                  selectedColor: AppColors.accent.withOpacity(0.3),
                  checkmarkColor: AppColors.accent,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: pigeonsAsync.when(
              loading: () => _buildShimmerGrid(),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load pigeons',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.refresh(pigeonsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (pigeons) {
                final filtered = _applyFilters(pigeons);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(pigeonsProvider),
                  color: AppColors.accent,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _PigeonCard(pigeon: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.surface,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flutter_dash,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'No pigeons match your filters'
                : 'No pigeons yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'Try adjusting your search or filters'
                : 'Add your first pigeon to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_searchQuery.isEmpty && _selectedFilter == 'All') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/pigeons/create'),
              icon: const Icon(Icons.add),
              label: const Text('Add Pigeon'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PigeonCard extends StatelessWidget {
  final Pigeon pigeon;

  const _PigeonCard({required this.pigeon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/pigeons/${pigeon.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                color: AppColors.surface,
                child: pigeon.imageUrl != null
                    ? Image.network(
                        pigeon.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _PigeonPlaceholder(),
                      )
                    : const _PigeonPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pigeon.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusBadge(isActive: pigeon.isActive),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pigeon.ringNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pigeon.breed,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        pigeon.sex == 'male' ? Icons.male : Icons.female,
                        size: 14,
                        color: pigeon.sex == 'male'
                            ? Colors.blue
                            : Colors.pinkAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pigeon.sex == 'male' ? 'Male' : 'Female',
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
      ),
    );
  }
}

class _PigeonPlaceholder extends StatelessWidget {
  const _PigeonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.flutter_dash, size: 48, color: AppColors.textSecondary),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.2)
            : AppColors.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
