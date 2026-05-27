import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/router/app_router.dart';
import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/features/auth/providers/auth_providers.dart';

class CodeVerificationPage extends ConsumerStatefulWidget {
  const CodeVerificationPage({required this.phone, super.key});

  final String phone;

  @override
  ConsumerState<CodeVerificationPage> createState() =>
      _CodeVerificationPageState();
}

class _CodeVerificationPageState extends ConsumerState<CodeVerificationPage>
    with SingleTickerProviderStateMixin {
  static const _codeLength = 6;
  static const _resendSeconds = 60;

  final List<TextEditingController> _controllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  bool _isVerifying = false;
  int _resendTimer = _resendSeconds;
  Timer? _timer;
  String? _errorText;

  // Shake animation
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _focusNodes[0].requestFocus();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = _resendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _code {
    return _controllers.map((c) => c.text).join();
  }

  void _onDigitChanged(int index, String value) {
    // Clear error on new input
    if (_errorText != null) {
      setState(() => _errorText = null);
    }

    if (value.length == 1 && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all digits entered
    if (_code.length == _codeLength) {
      _verifyCode();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      final notifier = ref.read(authStateProvider.notifier);
      await notifier.verifyCode(widget.phone, _code);

      // AsyncValue.guard catches exceptions and sets state to AsyncError
      // so we need to check the resulting state
      final authState = ref.read(authStateProvider);
      if (authState.hasError) {
        throw authState.error!;
      }

      // Navigation is handled by ref.listen in build
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = 'Неверный код');
        _shakeController.forward(from: 0);
        _clearCode();
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendCode() async {
    if (_resendTimer > 0) return;

    try {
      final notifier = ref.read(authStateProvider.notifier);
      await notifier.sendCode(widget.phone);
      _startResendTimer();
      _clearCode();
      setState(() => _errorText = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  String get _formattedTimer {
    final minutes = _resendTimer ~/ 60;
    final seconds = _resendTimer % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user != null && mounted) {
        final needsSetup = user.name.trim().isEmpty;
        context.go(needsSetup ? AppRoutes.authSetup : AppRoutes.map);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // Title
              Text('Код подтверждения', style: AppTypography.heading2),
              const SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                'Отправили 6 цифр на ${widget.phone}',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // Code input boxes
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: AppSpacing.cardShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_codeLength, (index) {
                      return SizedBox(
                        width: 44,
                        height: 54,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) => _onKeyEvent(index, event),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: AppTypography.heading2,
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                borderSide: BorderSide(
                                  color: _errorText != null
                                      ? AppColors.error
                                      : AppColors.divider,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                borderSide: BorderSide(
                                  color: _errorText != null
                                      ? AppColors.error
                                      : AppColors.divider,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onDigitChanged(index, value),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Error text
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    _errorText!,
                    style: AppTypography.body2.copyWith(color: AppColors.error),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // Loading indicator
              if (_isVerifying)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),

              const SizedBox(height: AppSpacing.xxl),

              // Resend timer / button
              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Отправить повторно через $_formattedTimer',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textHint,
                        ),
                      )
                    : GestureDetector(
                        onTap: _resendCode,
                        child: Text(
                          'Отправить повторно',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
