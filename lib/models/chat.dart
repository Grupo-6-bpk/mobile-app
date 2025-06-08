import 'chat_participant.dart';

class Chat {
  final int chatId;
  final bool isGroup;
  final String? name;
  final String? chatName;
  final String? chatAvatar;
  final int? adminId;
  final List<ChatParticipant> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final int unreadCount;

  Chat({
    required this.chatId,
    required this.isGroup,
    this.name,
    this.chatName,
    this.chatAvatar,
    this.adminId,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.unreadCount = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      chatId: json['chatId'] ?? json['id'] ?? 0,
      isGroup: json['isGroup'] ?? false,
      name: json['name'],
      chatName: json['chatName'],
      chatAvatar: json['chatAvatar'],
      adminId: json['adminId'],
      participants: (json['participants'] as List?)
          ?.map((p) => ChatParticipant.fromJson(p))
          .toList() ?? [],
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'isGroup': isGroup,
      'name': name,
      'chatName': chatName,
      'chatAvatar': chatAvatar,
      'adminId': adminId,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }

  String getDisplayName(int currentUserId) {
    if (isGroup) {
      return name ?? chatName ?? 'Grupo';
    } else {
      if (participants.isEmpty) {
        return chatName ?? 'Chat';
      }
      
      ChatParticipant? otherParticipant;
      try {
        otherParticipant = participants.firstWhere(
          (p) => p.userId != currentUserId,
        );
      } catch (e) {
        otherParticipant = participants.first;
      }
      
      return chatName ?? otherParticipant.name;
    }
  }

  String? getDisplayAvatar(int currentUserId) {
    if (isGroup) {
      return chatAvatar;
    } else {
      if (participants.isEmpty) {
        return chatAvatar;
      }
      
      ChatParticipant? otherParticipant;
      try {
        otherParticipant = participants.firstWhere(
          (p) => p.userId != currentUserId,
        );
      } catch (e) {
        otherParticipant = participants.first;
      }
      
      return chatAvatar ?? otherParticipant.avatarUrl;
    }
  }

  Chat copyWith({
    int? chatId,
    bool? isGroup,
    String? name,
    String? chatName,
    String? chatAvatar,
    int? adminId,
    List<ChatParticipant>? participants,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    int? unreadCount,
  }) {
    return Chat(
      chatId: chatId ?? this.chatId,
      isGroup: isGroup ?? this.isGroup,
      name: name ?? this.name,
      chatName: chatName ?? this.chatName,
      chatAvatar: chatAvatar ?? this.chatAvatar,
      adminId: adminId ?? this.adminId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  String toString() {
    return 'Chat{chatId: $chatId, isGroup: $isGroup, name: $name}';
  }
} 