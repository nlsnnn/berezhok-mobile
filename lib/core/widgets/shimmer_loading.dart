import 'package:flutter/material.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';

/// Low-level shimmer placeholder block.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppSpacing.radiusMd,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder for a card (image + title + subtitle).
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({this.imageHeight = 140, super.key});

  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(
            height: imageHeight,
            borderRadius: AppSpacing.radiusLg,
          ),
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(width: 160, height: 16),
                const SizedBox(height: AppSpacing.sm),
                ShimmerLoading(
                  width: 100,
                  height: 12,
                  borderRadius: AppSpacing.radiusSm,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const ShimmerLoading(width: 70, height: 20),
                    const Spacer(),
                    ShimmerLoading(
                      width: 50,
                      height: 20,
                      borderRadius: AppSpacing.radiusSm,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical list of shimmer cards.
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    this.itemCount = 3,
    this.imageHeight = 140,
    this.spacing = AppSpacing.lg,
    super.key,
  });

  final int itemCount;
  final double imageHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      itemBuilder: (context, index) => ShimmerCard(imageHeight: imageHeight),
      separatorBuilder: (_, __) => SizedBox(height: spacing),
    );
  }
}
