import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/widgets/empty_state.dart';
import 'package:berezhok/core/widgets/shimmer_loading.dart';
import 'package:berezhok/features/orders/providers/order_providers.dart';
import 'package:berezhok/features/orders/presentation/widgets/order_card.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final activeOrders = ref.watch(activeOrdersProvider);
    final pastOrders = ref.watch(pastOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Заказы', style: AppTypography.heading2),
        centerTitle: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ordersAsync.when(
        loading: () => Padding(
          padding: AppSpacing.screenPadding,
          child: const ShimmerList(itemCount: 4, imageHeight: 80),
        ),
        error: (error, _) => Center(
          child: Text('Ошибка загрузки: $error', style: AppTypography.body2),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'У вас пока нет заказов',
              subtitle: 'Найдите заведение рядом и закажите сюрприз-бокс',
              actionLabel: 'Открыть каталог',
              onAction: () => context.go('/catalog'),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.xxxl,
              ),
              children: [
                if (activeOrders.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Активные',
                    count: activeOrders.length,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...activeOrders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: OrderCard(order: order),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (pastOrders.isNotEmpty) ...[
                  const _SectionHeader(title: 'История'),
                  const SizedBox(height: AppSpacing.md),
                  ...pastOrders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: OrderCard(order: order),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTypography.heading3),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '$count',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
