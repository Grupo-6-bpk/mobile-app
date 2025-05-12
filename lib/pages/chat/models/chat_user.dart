class ChatUser {
  final String id;
  final String name;
  final String imageUrl;
  final String? lastMessage;

  ChatUser({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.lastMessage,
  });
} 