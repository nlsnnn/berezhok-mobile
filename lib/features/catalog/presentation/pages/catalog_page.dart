import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/catalog/presentation/widgets/location_card.dart';
import 'package:berezhok/features/map/providers/map_providers.dart';

/// Sort order for the catalog list.
enum SortBy { distance, rating }

/// Provider for the current sort mode.
final sortByProvider = StateProvider<SortBy>((ref) => SortBy.distance);

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final sortBy = ref.watch(sortByProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Каталог', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Москва',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Category filter bar
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                children: [
                  _CategoryChip(
                    label: 'Все',
                    code: null,
                    selectedCode: selectedCategory,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CategoryChip(
                    label: 'Пекарни',
                    code: 'bakery',
                    icon: Icons.bakery_dining,
                    selectedCode: selectedCategory,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = 'bakery',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CategoryChip(
                    label: 'Кафе',
                    code: 'cafe',
                    icon: Icons.coffee,
                    selectedCode: selectedCategory,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = 'cafe',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CategoryChip(
                    label: 'Рестораны',
                    code: 'restaurant',
                    icon: Icons.restaurant,
                    selectedCode: selectedCategory,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = 'restaurant',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CategoryChip(
                    label: 'Магазины',
                    code: 'grocery',
                    icon: Icons.shopping_basket,
                    selectedCode: selectedCategory,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = 'grocery',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CategoryChip(
                    label: 'Отели',
                    code: 'hotel',
                    icon: Icons.hotel,
                    selectedCode: selectedCategory,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = 'hotel',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Sort controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  _SortOption(
                    label: 'По расстоянию',
                    isSelected: sortBy == SortBy.distance,
                    onTap: () =>
                        ref.read(sortByProvider.notifier).state =
                            SortBy.distance,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _SortOption(
                    label: 'По рейтингу',
                    isSelected: sortBy == SortBy.rating,
                    onTap: () =>
                        ref.read(sortByProvider.notifier).state = SortBy.rating,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Content
            Expanded(
              child: locationsAsync.when(
                loading: () => Padding(
                  padding: AppSpacing.screenPadding,
                  child: const ShimmerList(itemCount: 4, imageHeight: 80),
                ),
                error: (error, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Ошибка загрузки',
                  subtitle: 'Не удалось загрузить список заведений',
                  actionLabel: 'Повторить',
                  onAction: () =>
                      ref.read(locationsProvider.notifier).refresh(),
                ),
                data: (locations) {
                  if (locations.isEmpty) {
                    return const EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Заведений не найдено',
                      subtitle: 'Попробуйте изменить фильтры или район поиска',
                    );
                  }

                  // Apply sort
                  final sorted = List.of(locations);
                  switch (sortBy) {
                    case SortBy.distance:
                      sorted.sort((a, b) => (a.distance ?? double.infinity)
                          .compareTo(b.distance ?? double.infinity));
                    case SortBy.rating:
                      sorted.sort((a, b) =>
                          (b.rating?.average ?? 0).compareTo(a.rating?.average ?? 0));
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        ref.read(locationsProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: LocationCard(location: sorted[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single category filter chip.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.code,
    required this.selectedCode,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String? code;
  final String? selectedCode;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      icon: icon,
      isSelected: code == selectedCode,
      onTap: onTap,
    );
  }
}

/// A compact sort option toggle.
class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textHint,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
