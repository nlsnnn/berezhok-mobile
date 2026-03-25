import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/utils/formatters.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:berezhok/features/map/providers/map_providers.dart';

// ---------------------------------------------------------------------------
// Map page — the first tab of the bottom navigation.
// ---------------------------------------------------------------------------

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with TickerProviderStateMixin {
  late final MapController _mapController;

  static const _moscowCenter = LatLng(55.7558, 37.6173);
  static const _initialZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ------ Markers ------

  List<Marker> _buildMarkers(List<FoodLocation> locations) {
    final selected = ref.read(selectedMapLocationProvider);

    return locations.map((loc) {
      final isSelected = selected?.id == loc.id;
      final size = isSelected ? 40.0 : 30.0;

      return Marker(
        point: LatLng(loc.latitude, loc.longitude),
        width: size,
        height: size,
        child: GestureDetector(
          onTap: () {
            ref.read(selectedMapLocationProvider.notifier).state = loc;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: loc.category.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.cardWhite : Colors.transparent,
                width: isSelected ? 3 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: loc.category.color.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              loc.category.icon,
              size: isSelected ? 20 : 15,
              color: Colors.white,
            ),
          ),
        ),
      );
    }).toList();
  }

  // ------ Actions ------

  void _goToMyLocation() {
    // In production, get real location via geolocator.
    // For now, animate to Moscow center.
    _mapController.move(_moscowCenter, _initialZoom);
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final selectedLocation = ref.watch(selectedMapLocationProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ---------- Map ----------
          locationsAsync.when(
            data: (locations) => FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _moscowCenter,
                initialZoom: _initialZoom,
                onTap: (_, __) {
                  ref.read(selectedMapLocationProvider.notifier).state = null;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ru.berezhok.berezhok',
                ),
                MarkerLayer(markers: _buildMarkers(locations)),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('Ошибка загрузки: $e', style: AppTypography.body2),
            ),
          ),

          // ---------- Category chips ----------
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: const _CategoryFilterBar(),
          ),

          // ---------- My location button ----------
          Positioned(
            right: AppSpacing.lg,
            bottom: selectedLocation != null ? 220 : 24,
            child: _MyLocationButton(onTap: _goToMyLocation),
          ),

          // ---------- Preview card ----------
          if (selectedLocation != null)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: _LocationPreviewCard(
                location: selectedLocation,
                onTap: () =>
                    context.go('/catalog/${selectedLocation.id}'),
                onClose: () {
                  ref.read(selectedMapLocationProvider.notifier).state = null;
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category filter bar
// ---------------------------------------------------------------------------

class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  static const _categories = [
    (code: null, label: 'Все', icon: Icons.apps),
    (code: 'bakery', label: 'Пекарня', icon: Icons.bakery_dining),
    (code: 'cafe', label: 'Кафе', icon: Icons.coffee),
    (code: 'restaurant', label: 'Ресторан', icon: Icons.restaurant),
    (code: 'grocery', label: 'Магазин', icon: Icons.shopping_basket),
    (code: 'hotel', label: 'Отель', icon: Icons.hotel),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final cat = _categories[index];
          final isSelected = selected == cat.code;

          return AppChip(
            label: cat.label,
            icon: cat.icon,
            isSelected: isSelected,
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = cat.code;
              // Clear selected pin when changing category
              ref.read(selectedMapLocationProvider.notifier).state = null;
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location preview card (slides up when a marker is tapped)
// ---------------------------------------------------------------------------

class _LocationPreviewCard extends StatelessWidget {
  const _LocationPreviewCard({
    required this.location,
    required this.onTap,
    required this.onClose,
  });

  final FoodLocation location;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 80, end: 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, offset),
          child: Opacity(
            opacity: (1 - offset / 80).clamp(0, 1),
            child: child,
          ),
        );
      },
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                // Category icon circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: location.category.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    location.category.icon,
                    color: location.category.color,
                    size: 22,
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Name + category + address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: AppTypography.subtitle1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${location.category.name} · ${location.address}',
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Close button
                GestureDetector(
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Info row: rating | distance | boxes
            Row(
              children: [
                if (location.rating != null)
                  RatingStars(
                    rating: location.rating!.average,
                    size: 14,
                    showValue: true,
                  ),
                const SizedBox(width: AppSpacing.md),
                if (location.distance != null) ...[
                  Icon(
                    Icons.directions_walk,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    formatDistance(location.distance!),
                    style: AppTypography.caption,
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${location.activeBoxesCount} боксов',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My location FAB
// ---------------------------------------------------------------------------

class _MyLocationButton extends StatelessWidget {
  const _MyLocationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }
}
