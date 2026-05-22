import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/router/app_router.dart';
import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/onboarding/providers/onboarding_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isFinishing = false;

  static const _steps = [
    _OnboardingStep(
      title: 'Спасай еду рядом',
      description: 'Находи наборы от кафе и магазинов поблизости.',
    ),
    _OnboardingStep(
      title: 'Бронируй за минуту',
      description: 'Выбирай предложение и оформляй заказ в пару тапов.',
    ),
    _OnboardingStep(
      title: 'Забирай в удобное время',
      description: 'Приходи в точку выдачи и получай заказ без очереди.',
    ),
    _OnboardingStep(
      title: 'Выгодно тебе и природе',
      description: 'Плати меньше и помогай сокращать пищевые отходы.',
    ),
  ];

  bool get _isLastStep => _currentStep == _steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeAndOpenAuth() async {
    if (_isFinishing) return;

    setState(() => _isFinishing = true);

    try {
      await ref.read(onboardingStateProvider.notifier).completeOnboarding();
      if (mounted) {
        context.go(AppRoutes.authPhone);
      }
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }
  }

  Future<void> _onNextPressed() async {
    if (_isLastStep) {
      await _completeAndOpenAuth();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isFinishing ? null : _completeAndOpenAuth,
                  child: Text(
                    'Пропустить',
                    style: AppTypography.subtitle2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (index) => setState(() => _currentStep = index),
                  itemBuilder: (_, index) {
                    final step = _steps[index];
                    return _OnboardingStepView(step: step);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentStep == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentStep == index
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: _isLastStep ? 'Начать' : 'Далее',
                onPressed: _isFinishing ? null : _onNextPressed,
                size: AppButtonSize.large,
                fullWidth: true,
                isLoading: _isFinishing,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStepView extends StatelessWidget {
  const _OnboardingStepView({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(
            'assets/images/mascot/hi.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: AppTypography.heading2,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _OnboardingStep { 
  const _OnboardingStep({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
