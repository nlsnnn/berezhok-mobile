import 'package:berezhok/core/api/api_client.dart';
import 'package:berezhok/features/chat/data/repositories/chat_repository.dart';
import 'package:berezhok/features/chat/domain/chat_message.dart';

class ApiChatRepository implements ChatRepository {
  final ApiClient _apiClient;

  ApiChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<ChatMessage>> getMessages(
    String orderId, {
    int limit = 50,
    String? before,
  }) async {
    final response = await _apiClient.get<_ChatMessagesResponse>(
      '/orders/$orderId/messages',
      fromJson: _ChatMessagesResponse.fromJson,
      queryParameters: {'limit': limit, 'before': ?before},
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch messages');
    }

    return response.data!.items;
  }

  @override
  Future<void> markRead(String orderId, String messageId) async {
    await _apiClient.dio.post<void>(
      '/orders/$orderId/read',
      data: {'message_id': messageId},
    );
  }
}

class _ChatMessagesResponse {
  final List<ChatMessage> items;

  const _ChatMessagesResponse({required this.items});

  factory _ChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return _ChatMessagesResponse(
      items: rawItems
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(growable: false),
    );
  }
}
