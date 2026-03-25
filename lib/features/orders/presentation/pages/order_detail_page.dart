import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/utils/formatters.dart';
import 'package:berezhok/core/widgets/app_button.dart';
import 'package:berezhok/core/widgets/price_tag.dart';
import 'package:berezhok/core/widgets/status_badge.dart';
import 'package:berezhok/features/orders/domain/order.dart';
import 'package:berezhok/features/orders/providers/order_providers.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  bool _isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Заказ', style: AppTypography.heading3),
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text('Ошибка: $error', style: AppTypography.body2),
        ),
        data: (order) => _buildContent(order),
      ),
    );
  }

  Widget _buildContent(Order order) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      children: [
        // Status badge centered
        Center(child: StatusBadge(status: order.statusKey)),
        const SizedBox(height: AppSpacing.xxl),

        // Status timeline
        _StatusTimeline(order: order),
        const SizedBox(height: AppSpacing.xxl),

        // QR Code section
        if (order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.paid) ...[
          _QrCodeSection(pickupCode: order.pickupCode),
          const SizedBox(height: AppSpacing.xxl),
        ],

        // Box info
        _InfoSection(
          title: 'Бокс',
          child: Row(
            children: [
              Expanded(
                child: Text(order.box.name, style: AppTypography.subtitle1),
              ),
              PriceTag(discountPrice: order.amount),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Location info
        _InfoSection(
          title: 'Заведение',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.location.name, style: AppTypography.subtitle1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                order.location.address,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatPickupTime(
                  order.pickupTimeStart,
                  order.pickupTimeEnd,
                ),
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  AppButton(
                    label: 'Маршрут',
                    icon: Icons.directions_outlined,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.small,
                    onPressed: () => _openMaps(order.location),
                  ),
                  if (order.location.phone != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      label: 'Позвонить',
                      icon: Icons.phone_outlined,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.small,
                      onPressed: () => _makeCall(order.location.phone!),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Action buttons
        _buildActions(order),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _buildActions(Order order) {
    return switch (order.status) {
      OrderStatus.pickedUp => Column(
          children: [
            AppButton(
              label: 'Подтвердить получение',
              fullWidth: true,
              isLoading: _isActionLoading,
              onPressed: () => _confirmPickup(order.id),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Не получил',
              variant: AppButtonVariant.text,
              fullWidth: true,
              onPressed: () => _showDisputeDialog(order.id),
            ),
          ],
        ),
      OrderStatus.completed when order.canReview => AppButton(
          label: 'Оставить отзыв',
          variant: AppButtonVariant.outline,
          fullWidth: true,
          onPressed: () => _showReviewSheet(order.id),
        ),
      OrderStatus.disputed => Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Спор на рассмотрении',
                style: AppTypography.body2.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _confirmPickup(String orderId) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(ordersProvider.notifier).confirmPickup(orderId);
      ref.invalidate(orderDetailProvider(orderId));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showDisputeDialog(String orderId) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Сообщить о проблеме', style: AppTypography.heading3),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Опишите проблему...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(ordersProvider.notifier)
                  .openDispute(orderId, controller.text.trim());
              ref.invalidate(orderDetailProvider(orderId));
            },
            child: Text(
              'Отправить',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewSheet(String orderId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => _ReviewBottomSheet(
        onSubmit: (rating, comment) async {
          await ref
              .read(ordersProvider.notifier)
              .createReview(orderId, rating, comment);
          ref.invalidate(orderDetailProvider(orderId));
        },
      ),
    );
  }

  Future<void> _openMaps(OrderLocation location) async {
    final uri = Uri.parse(
      'https://yandex.ru/maps/?pt=${location.longitude},${location.latitude}&z=17&l=map',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// --- Status Timeline ---

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.order});

  final Order order;

  static const _steps = [
    (status: OrderStatus.paid, label: 'Оплачен'),
    (status: OrderStatus.confirmed, label: 'Подтверждён'),
    (status: OrderStatus.pickedUp, label: 'Выдан'),
    (status: OrderStatus.completed, label: 'Завершён'),
  ];

  int get _currentIndex => switch (order.status) {
        OrderStatus.paid => 0,
        OrderStatus.confirmed => 1,
        OrderStatus.pickedUp => 2,
        OrderStatus.completed => 3,
        OrderStatus.cancelled || OrderStatus.refunded => -1,
        OrderStatus.disputed => 2,
        _ => -1,
      };

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;

    // Don't show timeline for cancelled/refunded orders
    if (current < 0 && order.status != OrderStatus.disputed) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            _TimelineStep(
              label: _steps[i].label,
              isCompleted: i <= current,
              isActive: i == current,
              timestamp: _timestampForStep(i),
            ),
            if (i < _steps.length - 1)
              _TimelineConnector(isCompleted: i < current),
          ],
        ],
      ),
    );
  }

  String? _timestampForStep(int index) {
    final step = _steps[index];
    if (index > _currentIndex) return null;

    return switch (step.status) {
      OrderStatus.paid => _formatTimestamp(order.createdAt),
      OrderStatus.confirmed => order.confirmedAt != null
          ? _formatTimestamp(order.confirmedAt!)
          : null,
      _ => null,
    };
  }

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.isCompleted,
    required this.isActive,
    this.timestamp,
  });

  final String label;
  final bool isCompleted;
  final bool isActive;
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? AppColors.primary : AppColors.divider;
    final textColor = isCompleted ? AppColors.textPrimary : AppColors.textHint;

    return Row(
      children: [
        // Dot
        Container(
          width: isActive ? 16 : 12,
          height: isActive ? 16 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : color,
            border: isActive
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 3,
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Label
        Expanded(
          child: Text(
            label,
            style: AppTypography.body2.copyWith(
              color: textColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),

        // Timestamp
        if (timestamp != null)
          Text(
            timestamp!,
            style: AppTypography.caption,
          ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 1.5,
          height: 24,
          color: isCompleted ? AppColors.primary : AppColors.divider,
        ),
      ),
    );
  }
}

// --- QR Code Section ---

class _QrCodeSection extends StatelessWidget {
  const _QrCodeSection({required this.pickupCode});

  final String pickupCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          QrImageView(
            data: pickupCode,
            version: QrVersions.auto,
            size: 200,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.textPrimary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            pickupCode,
            style: AppTypography.heading2.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Покажите код сотруднику при получении',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- Info Section ---

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.label.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

// --- Review Bottom Sheet ---

class _ReviewBottomSheet extends StatefulWidget {
  const _ReviewBottomSheet({required this.onSubmit});

  final Future<void> Function(int rating, String? comment) onSubmit;

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xxl,
        bottom: bottomInset + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          Text('Оставить отзыв', style: AppTypography.heading3),
          const SizedBox(height: AppSpacing.xxl),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _rating = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Icon(
                      i <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 40,
                      color: AppColors.ratingStar,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Comment field
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Комментарий (необязательно)',
              hintStyle: AppTypography.body2.copyWith(
                color: AppColors.textHint,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: AppSpacing.cardPadding,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Submit button
          AppButton(
            label: 'Отправить',
            fullWidth: true,
            isLoading: _isSubmitting,
            onPressed: _rating > 0
                ? () async {
                    setState(() => _isSubmitting = true);
                    final comment = _commentController.text.trim();
                    await widget.onSubmit(
                      _rating,
                      comment.isEmpty ? null : comment,
                    );
                    if (mounted) Navigator.pop(context);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
