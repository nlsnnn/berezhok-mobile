import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/features/profile/domain/eco_stats.dart';
import 'package:berezhok/features/profile/presentation/widgets/eco_stats_card.dart';

/// Bottom sheet that shows the eco-account card and lets the user share it.
class EcoStatsSheet extends StatefulWidget {
  const EcoStatsSheet({
    required this.stats,
    required this.displayName,
    super.key,
  });

  final EcoStats stats;
  final String displayName;

  static Future<void> show(
    BuildContext context, {
    required EcoStats stats,
    required String displayName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EcoStatsSheet(stats: stats, displayName: displayName),
    );
  }

  @override
  State<EcoStatsSheet> createState() => _EcoStatsSheetState();
}

class _EcoStatsSheetState extends State<EcoStatsSheet> {
  final _cardKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppSpacing.sheetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Card wrapped in RepaintBoundary for screenshot capture
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: RepaintBoundary(
              key: _cardKey,
              // Extra padding + bg so the captured image has breathing room
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                color: AppColors.background,
                child: EcoStatsCard(
                  stats: widget.stats,
                  displayName: widget.displayName,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl + bottomPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    key: _shareButtonKey,
                    icon: Icons.ios_share_rounded,
                    label: 'Поделиться',
                    loading: _sharing,
                    onTap: _shareCard,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.download_rounded,
                    label: 'Сохранить',
                    onTap: _saveCard,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Share / save
  // ---------------------------------------------------------------------------

  Future<Uint8List?> _captureCard() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('EcoStatsSheet: capture error — $e');
      return null;
    }
  }

  XFile _bytesToXFile(Uint8List bytes) => XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'berezhok_eco.png',
      );

  String _buildShareText() {
    final kg = widget.stats.totalKg.round();
    final meals = widget.stats.mealsEquivalent;
    final tier = widget.stats.tier.displayName;

    final mealsPart = meals > 0
        ? 'Это примерно $meals обедов, которые нашли своё место на столе.\n'
        : '';

    return '🌱 Уже спасено $kg кг еды!\n'
        '$mealsPart'
        'Мой уровень: $tier\n\n'
        'Спасай еду вместе со мной в приложении Бережок 🌿';
  }

  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _captureCard();
      if (bytes == null) {
        _showError('Не удалось создать изображение');
        return;
      }
      final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await Share.shareXFiles(
        [_bytesToXFile(bytes)],
        text: _buildShareText(),
        subject: 'Мой Эко-счёт в Бережок',
        sharePositionOrigin: origin,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _saveCard() async {
    final bytes = await _captureCard();
    if (bytes == null) {
      _showError('Не удалось создать изображение');
      return;
    }
    // Open native share sheet without caption — user picks "Save to Photos" /
    // "Save to Files" on iOS or the system handler on Android.
    await Share.shareXFiles(
      [_bytesToXFile(bytes)],
      subject: 'Эко-счёт',
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// =============================================================================
// Action button
// =============================================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.subtitle2.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
