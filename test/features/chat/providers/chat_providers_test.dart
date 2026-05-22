import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berezhok/features/chat/data/realtime/chat_realtime_client.dart';
import 'package:berezhok/features/chat/data/repositories/chat_repository.dart';
import 'package:berezhok/features/chat/domain/chat_message.dart';
import 'package:berezhok/features/chat/providers/chat_providers.dart';

void main() {
  group('chatControllerProvider', () {
    test('loads history and appends unique realtime messages', () async {
      final repository = _FakeChatRepository([
        _message('msg_1', 'customer', DateTime(2026, 5, 13, 10)),
      ]);
      final realtime = _FakeRealtimeClient();
      final container = _container(repository, realtime);
      addTearDown(container.dispose);

      final initial = await container.read(
        chatControllerProvider('ord_1').future,
      );

      expect(initial.messages.map((m) => m.id), ['msg_1']);
      realtime.emit(
        ChatMessageCreated(
          _message('msg_2', 'partner', DateTime(2026, 5, 13, 10, 1)),
        ),
      );
      realtime.emit(
        ChatMessageCreated(
          _message('msg_2', 'partner', DateTime(2026, 5, 13, 10, 1)),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(chatControllerProvider('ord_1')).value!;
      expect(state.messages.map((m) => m.id), ['msg_1', 'msg_2']);
    });

    test('marks state closed when realtime emits chat.closed', () async {
      final repository = _FakeChatRepository([]);
      final realtime = _FakeRealtimeClient();
      final container = _container(repository, realtime);
      addTearDown(container.dispose);

      await container.read(chatControllerProvider('ord_1').future);
      realtime.emit(const ChatClosed(orderId: 'ord_1', status: 'completed'));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(chatControllerProvider('ord_1')).value!;
      expect(state.connectionStatus, ChatConnectionStatus.closed);
      expect(state.isClosed, isTrue);
    });

    test('does not add optimistic message while sending', () async {
      final repository = _FakeChatRepository([
        _message('msg_1', 'customer', DateTime(2026, 5, 13, 10)),
      ]);
      final realtime = _FakeRealtimeClient();
      final container = _container(repository, realtime);
      addTearDown(container.dispose);

      await container.read(chatControllerProvider('ord_1').future);
      final sending = container
          .read(chatControllerProvider('ord_1').notifier)
          .sendMessage('Здравствуйте');

      var state = container.read(chatControllerProvider('ord_1')).value!;
      expect(state.isSending, isTrue);
      expect(state.messages.map((m) => m.id), ['msg_1']);

      realtime.completeSend();
      await sending;

      state = container.read(chatControllerProvider('ord_1')).value!;
      expect(state.isSending, isFalse);
      expect(state.messages.map((m) => m.id), ['msg_1']);
    });
  });
}

ProviderContainer _container(
  ChatRepository repository,
  ChatRealtimeClient realtime,
) {
  return ProviderContainer(
    overrides: [
      chatRepositoryProvider.overrideWithValue(repository),
      chatRealtimeClientProvider.overrideWithValue(realtime),
    ],
  );
}

ChatMessage _message(String id, String senderType, DateTime createdAt) {
  return ChatMessage(
    id: id,
    orderId: 'ord_1',
    senderType: senderType == 'customer'
        ? ChatSenderType.customer
        : ChatSenderType.partner,
    senderId: '${senderType}_1',
    message: 'message $id',
    createdAt: createdAt,
  );
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository(this.messages);

  final List<ChatMessage> messages;
  final List<String> readMessageIds = [];

  @override
  Future<List<ChatMessage>> getMessages(
    String orderId, {
    int limit = 50,
    String? before,
  }) async {
    return messages;
  }

  @override
  Future<void> markRead(String orderId, String messageId) async {
    readMessageIds.add(messageId);
  }
}

class _FakeRealtimeClient implements ChatRealtimeClient {
  final _controller = StreamController<ChatRealtimeEvent>.broadcast();
  final _sendCompleter = Completer<void>();

  @override
  Future<ChatRealtimeConnection> connect(String orderId) async {
    return _FakeRealtimeConnection(
      events: _controller.stream,
      onSend: () => _sendCompleter.future,
    );
  }

  void emit(ChatRealtimeEvent event) {
    _controller.add(event);
  }

  void completeSend() {
    _sendCompleter.complete();
  }
}

class _FakeRealtimeConnection implements ChatRealtimeConnection {
  _FakeRealtimeConnection({required this.events, required this.onSend});

  @override
  final Stream<ChatRealtimeEvent> events;

  final Future<void> Function() onSend;

  @override
  Future<void> sendMessage(String message) {
    return onSend();
  }

  @override
  Future<void> markRead(String messageId) async {}

  @override
  Future<void> close() async {}
}
