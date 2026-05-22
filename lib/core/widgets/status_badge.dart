import 'package:flutter/material.dart';

import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, this.compact = false, super.key});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (:label, :color) = _resolve(status);

    final textStyle =
        (compact ? AppTypography.caption : AppTypography.subtitle2).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        );

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label, style: textStyle),
    );
  }

  static ({String label, Color color}) _resolve(String status) {
    return switch (status) {
      'pending' || 'pending_payment' => (
        label: 'Ожидает оплаты',
        color: const Color(0xFF757575),
      ),
      'paid' => (label: 'Оплачен', color: const Color(0xFFF9A825)),
      'confirmed' => (label: 'Подтверждён', color: const Color(0xFF1E88E5)),
      'picked_up' => (label: 'Выдан', color: const Color(0xFF3949AB)),
      'completed' => (label: 'Завершён', color: const Color(0xFF43A047)),
      'cancelled' => (label: 'Отменён', color: const Color(0xFF757575)),
      'refunded' => (label: 'Возврат', color: const Color(0xFFF57C00)),
      'disputed' => (label: 'Спор', color: const Color(0xFFE53935)),
      _ => (label: status, color: const Color(0xFF757575)),
    };
  }
}
