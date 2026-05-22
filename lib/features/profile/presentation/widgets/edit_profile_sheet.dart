import 'package:flutter/material.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/widgets/app_button.dart';
import 'package:berezhok/core/widgets/app_text_field.dart';

/// Bottom sheet for editing name.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    required this.initialFirstName,
    required this.initialLastName,
    required this.initialEmail,
    required this.onSave,
    super.key,
  });

  final String initialFirstName;
  final String initialLastName;
  final String initialEmail;
  final Future<void> Function(String firstName, String lastName, String email)
  onSave;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFirstName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _nameController.text.trim().isNotEmpty;
  }

  Future<void> _save() async {
    if (!_isValid) {
      setState(() => _error = 'Имя не может быть пустым');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.onSave(_nameController.text.trim(), '', '');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Не удалось сохранить: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: bottomInset + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Редактировать профиль', style: AppTypography.heading3),
          const SizedBox(height: AppSpacing.xxl),

          AppTextField(
            label: 'Имя',
            hint: 'Иван Иванов',
            controller: _nameController,
            textInputAction: TextInputAction.done,
            enabled: !_isSaving,
            onEditingComplete: _save,
          ),

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          AppButton(
            label: 'Сохранить',
            onPressed: _isSaving ? null : _save,
            isLoading: _isSaving,
            fullWidth: true,
            size: AppButtonSize.large,
          ),
        ],
      ),
    );
  }
}
