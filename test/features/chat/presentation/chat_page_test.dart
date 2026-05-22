import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berezhok/features/chat/data/realtime/chat_realtime_client.dart';
import 'package:berezhok/features/chat/data/repositories/chat_repository.dart';
import 'package:berezhok/features/chat/domain/chat_message.dart';
import 'package:berezhok/features/chat/presentation/pages/chat_page.dart';
import 'package:berezhok/features/chat/providers/chat_providers.dart';

void main() {
  testWidgets('disables composer while message is sending', (tester) async {
    final realtime = _SlowRealtimeClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(_EmptyChatRepository()),
          chatRealtimeClientProvider.overrideWithValue(realtime),
        ],
        child: const MaterialApp(home: ChatPage(orderId: 'ord_1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Здравствуйте');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    realtime.completeSend();
    await tester.pumpAndSettle();

    final enabledTextField = tester.widget<TextField>(find.byType(TextField));
    expect(enabledTextField.enabled, isTrue);
  });
}

class _EmptyChatRepository implements ChatRepository {
  @override
  Future<List<ChatMessage>> getMessages(
    String orderId, {
    int limit = 50,
    String? before,
  }) async {
    return [];
  }

  @override
  Future<void> markRead(String orderId, String messageId) async {}
}

class _SlowRealtimeClient implements ChatRealtimeClient {
  final _sendCompleter = Completer<void>();

  @override
  Future<ChatRealtimeConnection> connect(String orderId) async {
    return _SlowRealtimeConnection(_sendCompleter);
  }

  void completeSend() {
    _sendCompleter.complete();
  }
}

class _SlowRealtimeConnection implements ChatRealtimeConnection {
  _SlowRealtimeConnection(this.sendCompleter);

  final Completer<void> sendCompleter;
  final _eventsController = StreamController<ChatRealtimeEvent>.broadcast();

  @override
  Stream<ChatRealtimeEvent> get events => _eventsController.stream;

  @override
  Future<void> sendMessage(String message) {
    return sendCompleter.future;
  }

  @override
  Future<void> markRead(String messageId) async {}

  @override
  Future<void> close() async {
    await _eventsController.close();
  }
}
