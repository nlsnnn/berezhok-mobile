import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/utils/formatters.dart';
import 'package:berezhok/core/widgets/app_card.dart';
import 'package:berezhok/core/widgets/status_badge.dart';
import 'package:berezhok/features/orders/domain/order.dart';
import 'package:berezhok/features/orders/domain/order_list_item.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, super.key});

  final OrderListItem order;

  Color get _accentColor => switch (order.status) {
    OrderStatus.paid => const Color(0xFFF9A825),
    OrderStatus.confirmed => const Color(0xFF1E88E5),
    OrderStatus.pickedUp => const Color(0xFF3949AB),
    OrderStatus.completed => const Color(0xFF43A047),
    OrderStatus.cancelled => const Color(0xFF757575),
    OrderStatus.refunded => const Color(0xFFF57C00),
    OrderStatus.disputed => const Color(0xFFE53935),
    OrderStatus.pending => const Color(0xFF757575),
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/orders/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: _accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.boxName,
                      style: AppTypography.subtitle1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      order.locationName,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(status: order.statusKey, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                _OrderMeta(
                  icon: Icons.payments_outlined,
                  label: formatPrice(order.amount),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _OrderMeta(
                    icon: Icons.schedule_rounded,
                    label: formatPickupTimeStart(order.pickupTimeStart),
                  ),
                ),
                Text(
                  order.pickupCode,
                  style: AppTypography.caption.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
