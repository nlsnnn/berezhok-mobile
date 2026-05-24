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
          ? const EdgeInsets.symmetric(horizontal: 9, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(label, style: textStyle),
    );
  }

  static ({String label, Color color}) _resolve(String status) {
    return switch (status) {
      'pending' || 'pending_payment' => (
        label: 'Ожидает оплаты',
        color: const Color(0xFF69736C),
      ),
      'paid' => (label: 'Оплачен', color: const Color(0xFFE59722)),
      'confirmed' => (label: 'Подтверждён', color: const Color(0xFF247BA0)),
      'picked_up' => (label: 'Выдан', color: const Color(0xFF5F55C8)),
      'completed' => (label: 'Завершён', color: const Color(0xFF2DA44E)),
      'cancelled' => (label: 'Отменён', color: const Color(0xFF69736C)),
      'refunded' => (label: 'Возврат', color: const Color(0xFFEF8A34)),
      'disputed' => (label: 'Спор', color: const Color(0xFFD92D20)),
      _ => (label: status, color: const Color(0xFF69736C)),
    };
  }
}
