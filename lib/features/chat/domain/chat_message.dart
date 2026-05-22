enum ChatSenderType { customer, partner }

class ChatMessage {
  final String id;
  final String orderId;
  final ChatSenderType senderType;
  final String senderId;
  final String message;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  String get senderTypeKey => switch (senderType) {
    ChatSenderType.customer => 'customer',
    ChatSenderType.partner => 'partner',
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    orderId: json['order_id'] as String,
    senderType: _parseSenderType(json['sender_type'] as String),
    senderId: json['sender_id'] as String,
    message: json['message'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'sender_type': senderTypeKey,
    'sender_id': senderId,
    'message': message,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  ChatMessage copyWith({
    String? id,
    String? orderId,
    ChatSenderType? senderType,
    String? senderId,
    String? message,
    DateTime? createdAt,
  }) => ChatMessage(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    senderType: senderType ?? this.senderType,
    senderId: senderId ?? this.senderId,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
  );

  static ChatSenderType _parseSenderType(String value) => switch (value) {
    'customer' => ChatSenderType.customer,
    'partner' => ChatSenderType.partner,
    _ => ChatSenderType.customer,
  };

  @override
  String toString() =>
      'ChatMessage(id: $id, orderId: $orderId, senderType: $senderTypeKey)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
