import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/features/chat/domain/chat_message.dart';
import 'package:berezhok/features/chat/providers/chat_providers.dart';
import 'package:berezhok/features/orders/providers/order_providers.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatControllerProvider(widget.orderId), (previous, next) {
      final previousClosed = previous?.valueOrNull?.isClosed ?? false;
      final nextClosed = next.valueOrNull?.isClosed ?? false;
      if (!previousClosed && nextClosed && mounted) {
        ref.invalidate(orderDetailProvider(widget.orderId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Чат закрыт')));
        Navigator.of(context).maybePop();
      }
    });

    final chatAsync = ref.watch(chatControllerProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Чат с заведением', style: AppTypography.heading3),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: chatAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _ChatError(
          message: 'Не удалось открыть чат',
          onRetry: () => ref.invalidate(chatControllerProvider(widget.orderId)),
        ),
        data: (state) => Column(
          children: [
            _ConnectionBanner(
              status: state.connectionStatus,
              errorMessage: state.errorMessage,
              onReconnect: () => ref
                  .read(chatControllerProvider(widget.orderId).notifier)
                  .reconnect(),
            ),
            Expanded(
              child: _MessagesList(
                state: state,
                scrollController: _scrollController,
                onLoadOlder: () => ref
                    .read(chatControllerProvider(widget.orderId).notifier)
                    .loadOlder(),
                onMarkRead: (messageId) => ref
                    .read(chatControllerProvider(widget.orderId).notifier)
                    .markRead(messageId),
              ),
            ),
            _MessageComposer(
              controller: _messageController,
              state: state,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await ref
        .read(chatControllerProvider(widget.orderId).notifier)
        .sendMessage(text);
    if (mounted &&
        ref
                .read(chatControllerProvider(widget.orderId))
                .valueOrNull
                ?.errorMessage ==
            null) {
      _messageController.clear();
    }
  }
}

class _MessagesList extends StatefulWidget {
  const _MessagesList({
    required this.state,
    required this.scrollController,
    required this.onLoadOlder,
    required this.onMarkRead,
  });

  final ChatState state;
  final ScrollController scrollController;
  final VoidCallback onLoadOlder;
  final ValueChanged<String> onMarkRead;

  @override
  State<_MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<_MessagesList> {
  String? _lastReadMessageId;

  @override
  void didUpdateWidget(_MessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _markLastPartnerMessageRead();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _markLastPartnerMessageRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.state.messages;

    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Сообщений пока нет',
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final historyActionCount = widget.state.hasOlderMessages ? 1 : 0;

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      itemCount: messages.length + historyActionCount,
      itemBuilder: (context, index) {
        if (widget.state.hasOlderMessages && index == 0) {
          return Center(
            child: TextButton(
              onPressed: widget.state.isLoadingOlder
                  ? null
                  : widget.onLoadOlder,
              child: widget.state.isLoadingOlder
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Загрузить раньше'),
            ),
          );
        }

        final message = messages[index - historyActionCount];
        return _MessageBubble(message: message);
      },
    );
  }

  void _markLastPartnerMessageRead() {
    final partnerMessages = widget.state.messages.where(
      (message) => message.senderType == ChatSenderType.partner,
    );
    if (partnerMessages.isEmpty) return;

    final messageId = partnerMessages.last.id;
    if (_lastReadMessageId == messageId) return;

    _lastReadMessageId = messageId;
    widget.onMarkRead(messageId);
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.senderType == ChatSenderType.customer;
    final background = isMine ? AppColors.primary : AppColors.cardWhite;
    final textColor = isMine ? Colors.white : AppColors.textPrimary;
    final timeColor = isMine
        ? Colors.white.withValues(alpha: 0.72)
        : AppColors.textSecondary;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg).copyWith(
            bottomRight: isMine ? const Radius.circular(4) : null,
            bottomLeft: isMine ? null : const Radius.circular(4),
          ),
          boxShadow: isMine ? null : AppSpacing.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.message,
              style: AppTypography.body2.copyWith(color: textColor),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt),
              style: AppTypography.caption.copyWith(color: timeColor),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MessageComposer extends StatefulWidget {
  const _MessageComposer({
    required this.controller,
    required this.state,
    required this.onSend,
  });

  final TextEditingController controller;
  final ChatState state;
  final Future<void> Function() onSend;

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  bool _hasText = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(_MessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSending = widget.state.isSending || _isSubmitting;
    final isEnabled = !isSending && !widget.state.isClosed;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: isEnabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onChanged: (_) => _handleTextChanged(),
                onSubmitted: (_) => _submitIfPossible(),
                decoration: InputDecoration(
                  hintText: widget.state.isClosed
                      ? 'Чат закрыт'
                      : 'Напишите сообщение',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 44,
              height: 44,
              child: isSending
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: isEnabled ? _submitIfPossible : null,
                      icon: const Icon(Icons.send_rounded),
                      color: AppColors.primary,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTextChanged() {
    final nextHasText = widget.controller.text.trim().isNotEmpty;
    if (_hasText != nextHasText) {
      setState(() => _hasText = nextHasText);
    }
  }

  Future<void> _submitIfPossible() async {
    if (widget.controller.text.trim().isEmpty ||
        widget.state.isSending ||
        _isSubmitting ||
        widget.state.isClosed) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSend();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.status,
    required this.errorMessage,
    required this.onReconnect,
  });

  final ChatConnectionStatus status;
  final String? errorMessage;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      ChatConnectionStatus.connected => null,
      ChatConnectionStatus.connecting => 'Подключаемся...',
      ChatConnectionStatus.reconnecting => 'Восстанавливаем соединение...',
      ChatConnectionStatus.disconnected => 'Нет соединения',
      ChatConnectionStatus.closed => 'Чат закрыт',
    };

    if (text == null && errorMessage == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              errorMessage ?? text!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (status == ChatConnectionStatus.disconnected)
            TextButton(onPressed: onReconnect, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: AppTypography.subtitle1),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
