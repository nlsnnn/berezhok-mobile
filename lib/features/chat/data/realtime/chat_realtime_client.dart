import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:berezhok/core/api/api_client.dart';
import 'package:berezhok/features/chat/domain/chat_message.dart';

abstract class ChatRealtimeClient {
  Future<ChatRealtimeConnection> connect(String orderId);
}

abstract class ChatRealtimeConnection {
  Stream<ChatRealtimeEvent> get events;
  Future<void> sendMessage(String message);
  Future<void> markRead(String messageId);
  Future<void> close();
}

sealed class ChatRealtimeEvent {
  const ChatRealtimeEvent();
}

class ChatMessageCreated extends ChatRealtimeEvent {
  final ChatMessage message;

  const ChatMessageCreated(this.message);
}

class ChatClosed extends ChatRealtimeEvent {
  final String orderId;
  final String status;

  const ChatClosed({required this.orderId, required this.status});
}

class ChatRealtimeError extends ChatRealtimeEvent {
  final String? requestId;
  final String code;
  final String message;

  const ChatRealtimeError({
    this.requestId,
    required this.code,
    required this.message,
  });
}

class WebSocketChatRealtimeClient implements ChatRealtimeClient {
  final String _chatWsBaseUrl;
  final AuthTokenProvider _authTokenProvider;

  WebSocketChatRealtimeClient({
    required String chatWsBaseUrl,
    required AuthTokenProvider authTokenProvider,
  }) : _chatWsBaseUrl = chatWsBaseUrl,
       _authTokenProvider = authTokenProvider;

  @override
  Future<ChatRealtimeConnection> connect(String orderId) async {
    final token = await _authTokenProvider();
    if (token == null || token.isEmpty) {
      throw StateError('Missing auth token');
    }

    final wsUri = _buildWsUri(orderId, token);
    final channel = WebSocketChannel.connect(wsUri);
    return _WebSocketChatRealtimeConnection(channel);
  }

  Uri _buildWsUri(String orderId, String token) {
    final base = Uri.parse(_chatWsBaseUrl);
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;

    return base.replace(
      path: '$basePath/orders/$orderId',
      queryParameters: {'token': token},
    );
  }
}

class _WebSocketChatRealtimeConnection implements ChatRealtimeConnection {
  final WebSocketChannel _channel;
  late final Stream<ChatRealtimeEvent> _events;

  _WebSocketChatRealtimeConnection(this._channel) {
    _events = _channel.stream
        .map(_parseEvent)
        .where((event) => event != null)
        .cast();
  }

  @override
  Stream<ChatRealtimeEvent> get events => _events;

  @override
  Future<void> sendMessage(String message) async {
    _send({
      'type': 'message.send',
      'request_id': _requestId(),
      'message': message,
    });
  }

  @override
  Future<void> markRead(String messageId) async {
    _send({
      'type': 'message.read',
      'request_id': _requestId(),
      'message_id': messageId,
    });
  }

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }

  void _send(Map<String, dynamic> payload) {
    _channel.sink.add(jsonEncode(payload));
  }

  String _requestId() => DateTime.now().microsecondsSinceEpoch.toString();

  ChatRealtimeEvent? _parseEvent(dynamic raw) {
    if (raw is! String) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final type = json['type'] as String?;

    return switch (type) {
      'message.created' => ChatMessageCreated(
        ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
      ),
      'chat.closed' => ChatClosed(
        orderId: json['order_id'] as String,
        status: json['status'] as String? ?? '',
      ),
      'error' => ChatRealtimeError(
        requestId: json['request_id'] as String?,
        code: json['code'] as String? ?? 'unknown',
        message: json['message'] as String? ?? 'Unknown chat error',
      ),
      _ => null,
    };
  }
}
