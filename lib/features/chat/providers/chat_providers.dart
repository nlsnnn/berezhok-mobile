import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:berezhok/core/api/api_client.dart';
import 'package:berezhok/core/api/api_providers.dart';
import 'package:berezhok/features/chat/data/realtime/chat_realtime_client.dart';
import 'package:berezhok/features/chat/data/realtime/mock_chat_realtime_client.dart';
import 'package:berezhok/features/chat/data/repositories/api_chat_repository.dart';
import 'package:berezhok/features/chat/data/repositories/chat_repository.dart';
import 'package:berezhok/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:berezhok/features/chat/domain/chat_message.dart';

enum ChatConnectionStatus {
  connecting,
  connected,
  reconnecting,
  disconnected,
  closed,
}

const _messagePageSize = 50;

class ChatState {
  final List<ChatMessage> messages;
  final ChatConnectionStatus connectionStatus;
  final bool isSending;
  final bool isLoadingOlder;
  final bool hasOlderMessages;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.connectionStatus = ChatConnectionStatus.connecting,
    this.isSending = false,
    this.isLoadingOlder = false,
    this.hasOlderMessages = false,
    this.errorMessage,
  });

  bool get isClosed => connectionStatus == ChatConnectionStatus.closed;

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatConnectionStatus? connectionStatus,
    bool? isSending,
    bool? isLoadingOlder,
    bool? hasOlderMessages,
    String? errorMessage,
    bool clearError = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    connectionStatus: connectionStatus ?? this.connectionStatus,
    isSending: isSending ?? this.isSending,
    isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
    hasOlderMessages: hasOlderMessages ?? this.hasOlderMessages,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

final chatBaseUrlProvider = Provider<String>((ref) {
  return dotenv.get('CHAT_BASE_URL', fallback: 'http://localhost:8090');
});

final chatApiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(chatBaseUrlProvider);
  final environment = ref.watch(environmentProvider);
  final tokenProvider = ref.watch(authTokenProvider);

  return ApiClient(
    baseUrl: '$baseUrl/api/v1',
    authTokenProvider: tokenProvider,
    extraInterceptors: [
      if (environment == 'dev')
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
    ],
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final useMock = ref.watch(useMockApiProvider);
  if (useMock) return MockChatRepository();
  return ApiChatRepository(apiClient: ref.watch(chatApiClientProvider));
});

final chatRealtimeClientProvider = Provider<ChatRealtimeClient>((ref) {
  final useMock = ref.watch(useMockApiProvider);
  if (useMock) return MockChatRealtimeClient();

  return WebSocketChatRealtimeClient(
    chatBaseUrl: ref.watch(chatBaseUrlProvider),
    authTokenProvider: ref.watch(authTokenProvider),
  );
});

final chatControllerProvider =
    AsyncNotifierProviderFamily<ChatController, ChatState, String>(
      ChatController.new,
    );

class ChatController extends FamilyAsyncNotifier<ChatState, String> {
  ChatRealtimeConnection? _connection;
  StreamSubscription<ChatRealtimeEvent>? _eventsSubscription;
  bool _disposed = false;

  @override
  Future<ChatState> build(String orderId) async {
    ref.onDispose(() {
      _disposed = true;
      _eventsSubscription?.cancel();
      _connection?.close();
    });

    final page = await _fetchMessages(orderId);
    final connectionStatus = await _connect(orderId);
    return ChatState(
      messages: page.messages,
      hasOlderMessages: page.hasOlderMessages,
      connectionStatus: connectionStatus,
    );
  }

  Future<void> loadOlder() async {
    final current = state.valueOrNull;
    if (current == null ||
        current.isLoadingOlder ||
        current.messages.isEmpty ||
        !current.hasOlderMessages ||
        current.isClosed) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingOlder: true, clearError: true));
    try {
      final page = await _fetchMessages(arg, before: current.messages.first.id);
      state = AsyncData(
        current.copyWith(
          messages: _mergeMessages([...page.messages, ...current.messages]),
          isLoadingOlder: false,
          hasOlderMessages: page.hasOlderMessages,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingOlder: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    final current = state.valueOrNull;
    if (trimmed.isEmpty ||
        current == null ||
        current.isSending ||
        current.isClosed) {
      return;
    }

    state = AsyncData(current.copyWith(isSending: true, clearError: true));
    try {
      await _connection?.sendMessage(trimmed);
    } catch (error) {
      state = AsyncData(
        (state.valueOrNull ?? current).copyWith(errorMessage: error.toString()),
      );
    } finally {
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isSending: false));
      }
    }
  }

  Future<void> markRead(String messageId) async {
    if (state.valueOrNull?.isClosed ?? true) return;
    try {
      await _connection?.markRead(messageId);
      await ref.read(chatRepositoryProvider).markRead(arg, messageId);
    } catch (_) {
      // Read receipts are best-effort and should not interrupt the chat.
    }
  }

  Future<void> reconnect() async {
    final current = state.valueOrNull;
    if (current == null || current.isClosed) return;

    state = AsyncData(
      current.copyWith(
        connectionStatus: ChatConnectionStatus.reconnecting,
        clearError: true,
      ),
    );

    try {
      final page = await _fetchMessages(arg);
      final status = await _connect(arg);
      state = AsyncData(
        current.copyWith(
          messages: page.messages,
          hasOlderMessages: page.hasOlderMessages,
          connectionStatus: status,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          connectionStatus: ChatConnectionStatus.disconnected,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<ChatConnectionStatus> _connect(String orderId) async {
    await _eventsSubscription?.cancel();
    await _connection?.close();

    try {
      final realtimeClient = ref.read(chatRealtimeClientProvider);
      final connection = await realtimeClient.connect(orderId);
      _connection = connection;
      _eventsSubscription = connection.events.listen(
        _handleEvent,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );
      return ChatConnectionStatus.connected;
    } catch (_) {
      return ChatConnectionStatus.disconnected;
    }
  }

  void _handleEvent(ChatRealtimeEvent event) {
    final current = state.valueOrNull;
    if (current == null) return;

    switch (event) {
      case ChatMessageCreated(:final message):
        state = AsyncData(
          current.copyWith(
            messages: _mergeMessages([...current.messages, message]),
            clearError: true,
          ),
        );
      case ChatClosed():
        state = AsyncData(
          current.copyWith(connectionStatus: ChatConnectionStatus.closed),
        );
      case ChatRealtimeError(:final message):
        state = AsyncData(current.copyWith(errorMessage: message));
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    final current = state.valueOrNull;
    if (current == null || current.isClosed) return;
    state = AsyncData(
      current.copyWith(connectionStatus: ChatConnectionStatus.disconnected),
    );
    unawaited(reconnect());
  }

  List<ChatMessage> _mergeMessages(List<ChatMessage> messages) {
    final byId = <String, ChatMessage>{};
    for (final message in messages) {
      byId[message.id] = message;
    }
    return _sortMessages(byId.values);
  }

  List<ChatMessage> _sortMessages(Iterable<ChatMessage> messages) {
    final sorted = messages.toList();
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  Future<({List<ChatMessage> messages, bool hasOlderMessages})> _fetchMessages(
    String orderId, {
    String? before,
  }) async {
    final messages = await ref
        .read(chatRepositoryProvider)
        .getMessages(orderId, limit: _messagePageSize + 1, before: before);
    final sorted = _sortMessages(messages);
    final hasOlderMessages = sorted.length > _messagePageSize;
    final visibleMessages = hasOlderMessages
        ? sorted.sublist(sorted.length - _messagePageSize)
        : sorted;

    return (messages: visibleMessages, hasOlderMessages: hasOlderMessages);
  }
}
