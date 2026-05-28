import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/utils/formatters.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:berezhok/features/map/data/services/user_location_service.dart';
import 'package:berezhok/features/map/providers/map_providers.dart';
import 'package:berezhok/features/map/providers/user_location_provider.dart';

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

  // Animate to user location once when it first becomes available.
  void _onUserLocationLoaded(
    AsyncValue<UserLocationResult>? prev,
    AsyncValue<UserLocationResult> next,
  ) {
    final prevHas = prev?.valueOrNull?.hasLocation ?? false;
    final nextPosition = next.valueOrNull?.position;
    if (!prevHas && nextPosition != null) {
      _mapController.move(
        LatLng(nextPosition.latitude, nextPosition.longitude),
        _initialZoom,
      );
    }
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
    final position = ref.read(userPositionProvider);
    if (position != null) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _initialZoom,
      );
    } else {
      ref.read(userLocationProvider.notifier).refresh();
    }
  }

  List<Marker> _buildUserMarker(Position position) {
    return [
      Marker(
        point: LatLng(position.latitude, position.longitude),
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userLocationProvider, _onUserLocationLoaded);

    final locationsAsync = ref.watch(locationsProvider);
    final selectedLocation = ref.watch(selectedMapLocationProvider);
    final userPosition = ref.watch(userPositionProvider);
    final locationResult = ref.watch(userLocationProvider).valueOrNull;

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
                onTap: (_, _) {
                  ref.read(selectedMapLocationProvider.notifier).state = null;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ru.berezhok.berezhok',
                ),
                MarkerLayer(markers: _buildMarkers(locations)),
                if (userPosition != null)
                  MarkerLayer(markers: _buildUserMarker(userPosition)),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('Ошибка загрузки: $e', style: AppTypography.body2),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: const _MapTopOverlay(),
          ),

          // Permission denied banner — shown below the filter chips
          if (locationResult != null &&
              locationResult.status == LocationStatus.deniedForever)
            Positioned(
              top: MediaQuery.of(context).padding.top + 122,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: _LocationDeniedBanner(
                onTap: () =>
                    ref.read(userLocationProvider.notifier).openSettings(),
              ),
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
              bottom: AppSpacing.md,
              child: _LocationPreviewCard(
                location: selectedLocation,
                onTap: () => context.go('/catalog/${selectedLocation.id}'),
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
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
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

class _MapTopOverlay extends ConsumerWidget {
  const _MapTopOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(userLocationProvider);
    final hasLocation = locationAsync.valueOrNull?.hasLocation ?? false;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: AppColors.divider),
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Row(
              children: [
                Icon(
                  hasLocation
                      ? Icons.near_me_rounded
                      : Icons.search_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    hasLocation ? 'Еда рядом с вами' : 'Еда рядом в Москве',
                    style: AppTypography.subtitle2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.limeSoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'сегодня',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _CategoryFilterBar(),
      ],
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
          child: Opacity(opacity: (1 - offset / 80).clamp(0, 1), child: child),
        );
      },
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: location.category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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

            const SizedBox(height: AppSpacing.lg),

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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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

// ---------------------------------------------------------------------------
// Location permission denied banner
// ---------------------------------------------------------------------------

class _LocationDeniedBanner extends StatelessWidget {
  const _LocationDeniedBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Доступ к геолокации отключён. Нажмите, чтобы открыть настройки.',
                style: AppTypography.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
