class ChatParticipant {
  final int userId;
  final String name;
  final String? avatarUrl;
  final bool isAdmin;
  final bool isBlocked;
  final DateTime joinedAt;

  ChatParticipant({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.isAdmin = false,
    this.isBlocked = false,
    required this.joinedAt,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['userId'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['avatar'],
      isAdmin: json['isAdmin'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'isAdmin': isAdmin,
      'isBlocked': isBlocked,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ChatParticipant{userId: $userId, name: $name, isAdmin: $isAdmin}';
  }
} 