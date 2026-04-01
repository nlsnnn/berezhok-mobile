import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:berezhok/core/api/api_exceptions.dart';
import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/utils/formatters.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:berezhok/features/catalog/presentation/widgets/review_card.dart';
import 'package:berezhok/features/catalog/presentation/widgets/surprise_box_card.dart';
import 'package:berezhok/features/map/providers/map_providers.dart';
import 'package:berezhok/features/orders/providers/order_providers.dart';

/// Weekday code labels for working-hours display.
const _dayLabels = <String, String>{
  'mon': 'Пн',
  'tue': 'Вт',
  'wed': 'Ср',
  'thu': 'Чт',
  'fri': 'Пт',
  'sat': 'Сб',
  'sun': 'Вс',
};

/// Map of short day codes to [DateTime.weekday] values.
const _dayToWeekday = <String, int>{
  'mon': 1,
  'tue': 2,
  'wed': 3,
  'thu': 4,
  'fri': 5,
  'sat': 6,
  'sun': 7,
};

class LocationDetailPage extends ConsumerStatefulWidget {
  const LocationDetailPage({required this.locationId, super.key});

  final String locationId;

  @override
  ConsumerState<LocationDetailPage> createState() =>
      _LocationDetailPageState();
}

class _LocationDetailPageState extends ConsumerState<LocationDetailPage> {
  String? _bookingBoxId;
  DateTime? _lastBookingTime;

  static const _debounceDuration = Duration(seconds: 2);

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(locationDetailProvider(widget.locationId));
    final reviewsAsync = ref.watch(locationReviewsProvider(widget.locationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Ошибка загрузки',
          subtitle: 'Не удалось загрузить информацию о заведении',
          actionLabel: 'Повторить',
          onAction: () =>
              ref.invalidate(locationDetailProvider(widget.locationId)),
        ),
        data: (location) {
          final boxes = location.activeBoxes;

          return CustomScrollView(
            slivers: [
              // Cover image area
              _CoverSection(location: location),

              // Body content
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),

                      // Name
                      Text(location.name, style: AppTypography.heading2),
                      const SizedBox(height: AppSpacing.sm),

                      // Category chip + address
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  location.category.color.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  location.category.icon,
                                  size: 14,
                                  color: location.category.color,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  location.category.name,
                                  style: AppTypography.caption.copyWith(
                                    color: location.category.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              location.address,
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Rating row
                      if (location.rating != null)
                        _RatingSection(rating: location.rating!),

                      const SizedBox(height: AppSpacing.lg),

                      // Working hours
                      if (location.workingHours != null)
                        _WorkingHoursSection(
                          workingHours: location.workingHours!,
                        ),

                      // Phone
                      if (location.phone != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _PhoneRow(phone: location.phone!),
                      ],

                      const SizedBox(height: AppSpacing.xxl),

                      // Surprise boxes section
                      Text('Доступные боксы', style: AppTypography.heading3),
                      const SizedBox(height: AppSpacing.md),

                      if (boxes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            'Нет доступных боксов',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...boxes.map((box) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: SurpriseBoxCard(
                                box: box,
                                isLoading: _bookingBoxId != null,
                                onBook: _bookingBoxId == null
                                    ? () => _bookBox(box.id)
                                    : null,
                              ),
                            )),

                      const SizedBox(height: AppSpacing.xxl),

                      // Reviews section
                      reviewsAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                        error: (_, __) => Text(
                          'Не удалось загрузить отзывы',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        data: (reviews) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Отзывы',
                                  style: AppTypography.heading3,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                if (location.rating != null)
                                  Text(
                                    '(${location.rating!.totalReviews})',
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                            if (reviews.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                child: Text(
                                  'Пока нет отзывов',
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ...reviews.map((review) => Column(
                                    children: [
                                      ReviewCard(review: review),
                                      const Divider(
                                        color: AppColors.divider,
                                        height: 1,
                                      ),
                                    ],
                                  )),
                          ],
                        ),
                      ),

                      // Bottom spacing
                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _bookBox(String boxId) async {
    if (_bookingBoxId != null) return;

    final now = DateTime.now();
    if (_lastBookingTime != null &&
        now.difference(_lastBookingTime!) < _debounceDuration) {
      return;
    }

    setState(() {
      _bookingBoxId = boxId;
      _lastBookingTime = now;
    });
    try {
      final result = await ref.read(ordersProvider.notifier).createOrder(boxId);
      final paymentUri = Uri.tryParse(result.paymentUrl);

      if (paymentUri == null) {
        throw const ValidationException(
          message: 'Некорректная ссылка на оплату',
        );
      }

      final launched = await launchUrl(
        paymentUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть страницу оплаты'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заказ создан. Завершите оплату в браузере'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось создать заказ. Попробуйте еще раз'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _bookingBoxId = null);
      }
    }
  }
}

/// Cover image / gradient area with back button.
class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.location});

  final FoodLocation location;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: location.category.color,
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image or gradient fallback
            if (location.coverImageUrl != null)
              Image.network(
                location.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _GradientFallback(location: location),
              )
            else
              _GradientFallback(location: location),

            // Bottom gradient overlay for text readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),

            // Category badge at bottom
            Positioned(
              left: AppSpacing.xl,
              bottom: AppSpacing.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      location.category.icon,
                      size: 16,
                      color: location.category.color,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      location.category.name,
                      style: AppTypography.subtitle2.copyWith(
                        color: location.category.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.location});

  final FoodLocation location;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            location.category.color,
            location.category.color.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          location.category.icon,
          size: 80,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// Rating display with optional distribution bars.
class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.rating});

  final LocationRating rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating stars + value
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingStars(
              rating: rating.average,
              size: 20,
              showValue: true,
              totalReviews: rating.totalReviews,
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.xl),

        // Distribution mini bars
        if (rating.distribution != null)
          Expanded(
            child: Column(
              children: [
                for (int i = 5; i >= 1; i--)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _RatingBar(
                      stars: i,
                      count: rating.distribution![i] ?? 0,
                      total: rating.totalReviews,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Single row in the rating distribution.
class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.stars,
    required this.count,
    required this.total,
  });

  final int stars;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 12,
          child: Text(
            '$stars',
            style: AppTypography.caption.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.ratingStar),
            ),
          ),
        ),
      ],
    );
  }
}

/// Expandable working-hours section.
class _WorkingHoursSection extends StatefulWidget {
  const _WorkingHoursSection({required this.workingHours});

  final Map<String, String> workingHours;

  @override
  State<_WorkingHoursSection> createState() => _WorkingHoursSectionState();
}

class _WorkingHoursSectionState extends State<_WorkingHoursSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final todayKey = _todayKey();
    final todayHours = widget.workingHours[todayKey] ?? 'Выходной';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Сегодня: $todayHours',
                style: AppTypography.body2,
              ),
              const Spacer(),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          ...widget.workingHours.entries.map((entry) {
            final label = _dayLabels[entry.key] ?? entry.key;
            final isToday = entry.key == todayKey;
            return Padding(
              padding: const EdgeInsets.only(
                left: 26,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        fontWeight:
                            isToday ? FontWeight.w600 : FontWeight.w400,
                        color: isToday
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    entry.value,
                    style: AppTypography.caption.copyWith(
                      fontWeight:
                          isToday ? FontWeight.w600 : FontWeight.w400,
                      color: isToday
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  String _todayKey() {
    final weekday = DateTime.now().weekday;
    return _dayToWeekday.entries
        .firstWhere((e) => e.value == weekday,
            orElse: () => const MapEntry('mon', 1))
        .key;
  }
}

/// Tappable phone row that opens the dialer.
class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Row(
        children: [
          const Icon(
            Icons.phone_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatPhone(phone),
            style: AppTypography.body2.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
