import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/widgets/app_button.dart';
import 'package:berezhok/core/widgets/shimmer_loading.dart';
import 'package:berezhok/features/auth/providers/auth_providers.dart';
import 'package:berezhok/features/profile/providers/profile_providers.dart';
import 'package:berezhok/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:berezhok/features/profile/presentation/widgets/stat_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const _ProfileShimmer(),
        error: (error, _) => Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Не удалось загрузить профиль',
                  style: AppTypography.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$error',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Повторить',
                  onPressed: () => ref.read(profileProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
        data: (profile) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(profileProvider.notifier).refresh(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // --- Header ---
              _ProfileHeader(
                initials: profile.initials,
                displayName: profile.displayName,
                phone: profile.phone,
                memberSince: profile.createdAt,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // --- Stats ---
              // TODO: Stats need to be calculated from orders list or added to API
              Padding(
                padding: AppSpacing.screenPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.shopping_bag_outlined,
                        value: '—',
                        label: 'Заказов',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        icon: Icons.star_outline_rounded,
                        value: '—',
                        label: 'Отзывов',
                        color: AppColors.ratingStar,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        icon: Icons.savings_outlined,
                        value: '—',
                        label: 'Сэкономлено',
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // --- Menu ---
              Padding(
                padding: AppSpacing.screenPadding,
                child: Text('НАСТРОЙКИ', style: AppTypography.label),
              ),
              const SizedBox(height: AppSpacing.md),
              _MenuTile(
                icon: Icons.person_outline_rounded,
                title: 'Редактировать профиль',
                subtitle: profile.displayName,
                onTap: () => _showEditSheet(context, ref),
              ),
              _MenuTile(
                icon: Icons.notifications_none_rounded,
                title: 'Уведомления',
                subtitle: 'Включены',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Скоро будет доступно'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              Padding(
                padding: AppSpacing.screenPadding,
                child: Text('ИНФОРМАЦИЯ', style: AppTypography.label),
              ),
              const SizedBox(height: AppSpacing.md),
              _MenuTile(
                icon: Icons.help_outline_rounded,
                title: 'Как это работает',
                onTap: () {
                  _showAboutSheet(context);
                },
              ),
              _MenuTile(
                icon: Icons.description_outlined,
                title: 'Политика конфиденциальности',
                onTap: () {},
              ),
              _MenuTile(
                icon: Icons.info_outline_rounded,
                title: 'О приложении',
                subtitle: 'Бережок v1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Бережок',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        'Спасаем еду от утилизации\n\n© 2025 Бережок',
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // --- Logout ---
              Padding(
                padding: AppSpacing.screenPadding,
                child: AppButton(
                  label: 'Выйти из аккаунта',
                  variant: AppButtonVariant.outline,
                  fullWidth: true,
                  icon: Icons.logout_rounded,
                  onPressed: () => _confirmLogout(context, ref),
                ),
              ),

              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        initialFirstName: profile.name,
        initialLastName: '',
        initialEmail: '',
        onSave: (firstName, lastName, email) async {
          // API only supports updating name field
          await ref
              .read(profileProvider.notifier)
              .updateProfile(name: firstName);
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('Выход', style: AppTypography.heading3),
        content: Text(
          'Вы уверены, что хотите выйти из аккаунта?',
          style: AppTypography.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Отмена',
              style: AppTypography.subtitle2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authStateProvider.notifier).logout();
            },
            child: Text(
              'Выйти',
              style: AppTypography.subtitle2.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Как работает Бережок?', style: AppTypography.heading3),
            const SizedBox(height: AppSpacing.lg),
            _AboutStep(
              number: '1',
              title: 'Найдите заведение',
              description:
                  'Откройте карту или каталог и выберите '
                  'заведение рядом с вами.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _AboutStep(
              number: '2',
              title: 'Закажите сюрприз-бокс',
              description: 'Выберите бокс со скидкой до 70%. Состав — сюрприз!',
            ),
            const SizedBox(height: AppSpacing.lg),
            _AboutStep(
              number: '3',
              title: 'Заберите заказ',
              description:
                  'Придите в указанное время, покажите QR-код и заберите еду.',
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Понятно',
                onPressed: () => Navigator.of(context).pop(),
                fullWidth: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Header
// =============================================================================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.displayName,
    required this.phone,
    this.memberSince,
  });

  final String initials;
  final String displayName;
  final String phone;
  final DateTime? memberSince;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          child: Column(
            children: [
              Text(
                'Профиль',
                style: AppTypography.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Avatar circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTypography.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                displayName,
                style: AppTypography.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                phone,
                style: AppTypography.body2.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              if (memberSince != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'С нами с ${_formatDate(memberSince!)}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// =============================================================================
// Menu tile
// =============================================================================

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 20, color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.body1),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTypography.caption),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// About step
// =============================================================================

class _AboutStep extends StatelessWidget {
  const _AboutStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.subtitle2.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.subtitle2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Shimmer loading placeholder
// =============================================================================

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fake header
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + AppSpacing.lg,
            bottom: AppSpacing.xxxl,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              ShimmerLoading(
                width: 80,
                height: 24,
                borderRadius: AppSpacing.radiusSm,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ShimmerLoading(width: 80, height: 80, borderRadius: 40),
              const SizedBox(height: AppSpacing.lg),
              ShimmerLoading(
                width: 120,
                height: 18,
                borderRadius: AppSpacing.radiusSm,
              ),
              const SizedBox(height: AppSpacing.sm),
              ShimmerLoading(
                width: 160,
                height: 14,
                borderRadius: AppSpacing.radiusSm,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Fake stats
        Padding(
          padding: AppSpacing.screenPadding,
          child: Row(
            children: [
              Expanded(
                child: ShimmerLoading(
                  height: 80,
                  borderRadius: AppSpacing.radiusMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ShimmerLoading(
                  height: 80,
                  borderRadius: AppSpacing.radiusMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ShimmerLoading(
                  height: 80,
                  borderRadius: AppSpacing.radiusMd,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        // Fake menu items
        Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              for (int i = 0; i < 4; i++) ...[
                ShimmerLoading(height: 52, borderRadius: AppSpacing.radiusMd),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
