import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:berezhok/core/router/app_router.dart';
import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/auth/providers/auth_providers.dart';

class PhoneInputPage extends ConsumerStatefulWidget {
  const PhoneInputPage({super.key});

  @override
  ConsumerState<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends ConsumerState<PhoneInputPage> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  bool _isSending = false;

  final _phoneMask = MaskTextInputFormatter(
    mask: '(###) ###-##-##',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool get _isPhoneValid {
    final digits = _phoneMask.getUnmaskedText();
    return digits.length == 10;
  }

  String get _fullPhone {
    return '+7${_phoneMask.getUnmaskedText()}';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_isPhoneValid || _isSending) return;

    setState(() => _isSending = true);

    try {
      final notifier = ref.read(authStateProvider.notifier);
      await notifier.sendCode(_fullPhone);

      if (mounted) {
        context.push('${AppRoutes.authCode}?phone=${Uri.encodeComponent(_fullPhone)}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // App name
              Text('Бережок', style: AppTypography.heading1),
              const SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                'Спасай еду, экономь деньги',
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.huge),

              // Phone input
              AppTextField(
                label: 'Номер телефона',
                hint: '(900) 123-45-67',
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  _phoneMask,
                ],
                prefix: Text(
                  '+7',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.done,
                onEditingComplete: _onSubmit,
              ),

              const Spacer(flex: 3),

              // Submit button
              AppButton(
                label: 'Продолжить',
                onPressed: _isPhoneValid ? _onSubmit : null,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                fullWidth: true,
                isLoading: _isSending,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
