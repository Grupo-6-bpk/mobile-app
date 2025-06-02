class Message {
  final int messageId;
  final int chatId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime sentAt;
  final bool isFromCurrentUser;

  Message({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.sentAt,
    this.isFromCurrentUser = false,
  });

  factory Message.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    return Message(
      messageId: json['messageId'] ?? json['id'] ?? 0,
      chatId: json['chatId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? '',
      senderAvatar: json['senderAvatar'],
      content: json['content'] ?? '',
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      isFromCurrentUser: currentUserId != null && (json['senderId'] ?? 0) == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  Message copyWith({
    int? messageId,
    int? chatId,
    int? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? sentAt,
    bool? isFromCurrentUser,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
    );
  }

  @override
  String toString() {
    return 'Message{messageId: $messageId, senderId: $senderId, content: $content}';
  }
} 