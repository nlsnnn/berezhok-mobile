import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/router/app_router.dart';
import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/auth/providers/auth_providers.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  bool _personalDataAccepted = false;
  bool _marketingAccepted = true;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool get _isNameValid => _nameController.text.trim().length >= 2;

  bool get _canSubmit => _isNameValid && _personalDataAccepted && !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref
          .read(authStateProvider.notifier)
          .updateName(_nameController.text.trim());

      if (!mounted) return;
      context.go(AppRoutes.map);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText = 'Не удалось сохранить. Попробуйте ещё раз.';
        });
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
              const SizedBox(height: AppSpacing.xxxl),

              Text('Почти готово', style: AppTypography.heading2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Как вас зовут? Это имя будут видеть точки при выдаче заказа.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              AppTextField(
                label: 'Имя',
                hint: 'Иван',
                controller: _nameController,
                focusNode: _nameFocusNode,
                textInputAction: TextInputAction.done,
                enabled: !_isSubmitting,
                maxLength: 60,
                onChanged: (_) => setState(() => _errorText = null),
                onEditingComplete: _submit,
              ),

              const SizedBox(height: AppSpacing.xl),

              _ConsentTile(
                value: _personalDataAccepted,
                onChanged: _isSubmitting
                    ? null
                    : (v) => setState(() => _personalDataAccepted = v),
                richText: TextSpan(
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: 'Я согласен на '),
                    TextSpan(
                      text: 'обработку персональных данных',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' — обязательно'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              _ConsentTile(
                value: _marketingAccepted,
                onChanged: _isSubmitting
                    ? null
                    : (v) => setState(() => _marketingAccepted = v),
                richText: TextSpan(
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  children: const [
                    TextSpan(
                      text:
                          'Я хочу получать новости, акции и маркетинговые рассылки',
                    ),
                  ],
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorText!,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              ],

              const Spacer(),

              AppButton(
                label: 'Продолжить',
                onPressed: _canSubmit ? _submit : null,
                isLoading: _isSubmitting,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                fullWidth: true,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.value,
    required this.onChanged,
    required this.richText,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final TextSpan richText;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return InkWell(
      onTap: enabled ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: enabled ? (v) => onChanged!(v ?? false) : null,
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text.rich(richText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
