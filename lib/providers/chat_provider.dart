import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import 'package:flutter/foundation.dart';

enum ChatState {
  initial,
  loading,
  loaded,
  error,
}

class ChatListNotifier extends StateNotifier<AsyncValue<List<Chat>>> {
  final ChatService _chatService = ChatService();
  final List<StreamSubscription> _subscriptions = [];

  ChatListNotifier() : super(const AsyncValue.loading()) {
    _initializeChats();
    _setupWebSocketListeners();
  }

  Future<void> _initializeChats() async {
    try {
      await _chatService.connectWebSocket();
      final chats = await _chatService.getChats();
      state = AsyncValue.data(chats);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _setupWebSocketListeners() {
    _subscriptions.add(
      _chatService.onNewChat.listen((chat) {
        state.whenData((chats) {
          final newChats = [chat, ...chats];
          state = AsyncValue.data(newChats);
        });
      }),
    );

    _subscriptions.add(
      _chatService.onMessageReceived.listen((message) {
        state.whenData((chats) {
          final updatedChats = chats.map((chat) {
            if (chat.chatId == message.chatId) {
              return chat.copyWith(
                lastMessage: message.content,
                lastMessageAt: message.sentAt,
                unreadCount: chat.unreadCount + 1,
              );
            }
            return chat;
          }).toList();
          final chatIndex = updatedChats.indexWhere((c) => c.chatId == message.chatId);
          if (chatIndex > 0) {
            final chat = updatedChats.removeAt(chatIndex);
            updatedChats.insert(0, chat);
          }
          state = AsyncValue.data(updatedChats);
        });
      }),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _initializeChats();
  }

  Future<Chat?> createDirectChat(int participantId) async {
    try {
      final chat = await _chatService.createDirectChat(participantId);
      state.whenData((chats) {
        final newChats = [chat, ...chats];
        state = AsyncValue.data(newChats);
      });
      return chat;
    } catch (e) {
      if (e.toString().contains('Chat criado com sucesso')) {
        await refresh();
        return Chat(
          chatId: -1, 
          isGroup: false, 
          participants: [], 
          createdAt: DateTime.now()
        );
      }
      return null;
    }
  }

  Future<Chat?> createGroup(String name, List<int> participantIds) async {
    try {
      final chat = await _chatService.createGroup(name, participantIds);
      state.whenData((chats) {
        final newChats = [chat, ...chats];
        state = AsyncValue.data(newChats);
      });
      return chat;
    } catch (e) {
      if (e.toString().contains('Grupo criado com sucesso')) {
        await refresh();
        return Chat(
          chatId: -1, 
          isGroup: true, 
          participants: [], 
          createdAt: DateTime.now()
        );
      }
      return null;
    }
  }

  void markChatAsRead(int chatId) {
    state.whenData((chats) {
      final updatedChats = chats.map((chat) {
        if (chat.chatId == chatId) {
          return chat.copyWith(unreadCount: 0);
        }
        return chat;
      }).toList();
      state = AsyncValue.data(updatedChats);
    });
  }

  Future<bool> addMemberToGroup(int chatId, int userId) async {
    try {
      await _chatService.addMemberToGroup(chatId, userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeMemberFromGroup(int chatId, int userId) async {
    try {
      await _chatService.removeMemberFromGroup(chatId, userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteChat(int chatId) async {
    try {
      await _chatService.deleteChat(chatId);
      state.whenData((chats) {
        final updatedChats = chats.where((chat) => chat.chatId != chatId).toList();
        state = AsyncValue.data(updatedChats);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> blockUser(int chatId, int targetUserId) async {
    try {
      await _chatService.blockUser(chatId, targetUserId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unblockUser(int chatId, int targetUserId) async {
    try {
      await _chatService.unblockUser(chatId, targetUserId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _chatService.dispose();
    super.dispose();
  }
}

class MessageListNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final int chatId;
  final ChatService _chatService = ChatService();
  final List<StreamSubscription> _subscriptions = [];
  String? _nextCursor;
  Timer? _reloadTimer;

  MessageListNotifier(this.chatId) : super(const AsyncValue.loading()) {
    _initializeMessages();
    _setupWebSocketListeners();
    _setupPeriodicReload();
  }

  Future<void> _initializeMessages() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      await _chatService.joinChat(chatId);
      await Future.delayed(const Duration(seconds: 2));
      await _chatService.joinChat(chatId);
      final messages = await _chatService.getMessages(chatId);
      state = AsyncValue.data(messages.reversed.toList());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _setupWebSocketListeners() {
    _subscriptions.add(
      _chatService.onMessageReceived.listen((message) {
        if (message.chatId == chatId) {
          state.whenData((messages) {
            try {
              final messageExists = messages.any((m) => 
                m.messageId == message.messageId || 
                (m.content == message.content && 
                 m.senderId == message.senderId &&
                 m.sentAt.difference(message.sentAt).abs().inSeconds < 5)
              );
              if (messageExists) {
                return;
              }
              final newMessages = [...messages, message];
              state = AsyncValue.data(newMessages);
            } catch (e) {
              debugPrint('WebSocket duplicate detection error: $e');
            }
          });
        }
      }),
    );
  }

  Future<bool> sendMessage(String content) async {
    try {
      final expectedContent = content;
      final expectedTime = DateTime.now();
      final currentMessages = state.value ?? [];
      if (currentMessages.isEmpty) {
        await _chatService.joinChat(chatId);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      final message = await _chatService.sendMessage(chatId, content);
      if (message.messageId > 1000000000000) {
        await Future.delayed(const Duration(seconds: 3));
        final currentMessages = state.value ?? [];
        final hasRealMessage = currentMessages.any((m) => 
          m.content == expectedContent && 
          m.senderId == message.senderId &&
          m.sentAt.difference(expectedTime).abs().inSeconds < 10 &&
          m.messageId != message.messageId
        );
        if (hasRealMessage) {
          return true;
        }
      }
      state.whenData((messages) {
        final newMessages = [...messages, message];
        state = AsyncValue.data(newMessages);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadMoreMessages() async {
    if (_nextCursor == null) return;
    try {
      final newMessages = await _chatService.getMessages(
        chatId,
        cursor: _nextCursor,
      );
      state.whenData((messages) {
        final allMessages = [...newMessages.reversed, ...messages];
        state = AsyncValue.data(allMessages);
      });
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    }
  }

  void startTyping() {
    _chatService.startTyping(chatId);
  }

  void stopTyping() {
    _chatService.stopTyping(chatId);
  }

  void _setupPeriodicReload() {
    _reloadTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (timer.tick > 4) {
        timer.cancel();
        return;
      }
      try {
        final newMessages = await _chatService.getMessages(chatId);
        state.whenData((currentMessages) {
          if (newMessages.length != currentMessages.length) {
            state = AsyncValue.data(newMessages.reversed.toList());
          }
        });
      } catch (e) {
        debugPrint('Error reloading messages after timeout: $e');
      }
    });
  }

  @override
  void dispose() {
    _chatService.leaveChat(chatId);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _reloadTimer?.cancel();
    super.dispose();
  }
}

final chatListProvider = StateNotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>((ref) {
  return ChatListNotifier();
});

final messageListProvider = StateNotifierProvider.family<MessageListNotifier, AsyncValue<List<Message>>, int>(
  (ref, chatId) {
    return MessageListNotifier(chatId);
  },
);

final userSearchProvider = FutureProvider.family<List<User>, String>((ref, phone) async {
  final chatService = ChatService();
  return await chatService.searchUsersByPhone(phone);
});

final webSocketConnectionProvider = StreamProvider<bool>((ref) {
  final chatService = ChatService();
  return chatService.onConnectionChange;
});

final webSocketErrorProvider = StreamProvider<String>((ref) {
  final chatService = ChatService();
  return chatService.onError;
});