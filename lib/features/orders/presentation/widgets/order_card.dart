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
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: box name + status badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.boxName,
                            style: AppTypography.subtitle1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusBadge(status: order.statusKey, compact: true),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Row 2: location name
                    Text(
                      order.locationName,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Row 3: price + pickup time + code
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${formatPrice(order.amount)}  ·  '
                            '${formatPickupTimeStart(order.pickupTimeStart)}',
                            style: AppTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          order.pickupCode,
                          style: AppTypography.caption.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
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
