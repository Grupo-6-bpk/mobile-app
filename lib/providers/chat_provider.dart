import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

enum ChatState {
  initial,
  loading,
  loaded,
  error,
}

class ChatListNotifier extends StateNotifier<AsyncValue<List<Chat>>> {
  final List<StreamSubscription> _subscriptions = [];
  ChatService? _chatService;

  ChatListNotifier() : super(const AsyncValue.loading());

  void setChatService(ChatService chatService) {
    _chatService = chatService;
    _initializeChats();
    _setupWebSocketListeners();
  }

  Future<void> _initializeChats() async {
    if (_chatService == null) return;
    
    try {
      final chats = await _chatService!.getChats();
      state = AsyncValue.data(chats);
      
      for (final chat in chats) {
        try {
          await _chatService!.joinChat(chat.chatId);
          debugPrint('ChatProvider: Entrou automaticamente no chat existente ${chat.chatId}');
        } catch (e) {
          debugPrint('ChatProvider: Erro ao entrar no chat ${chat.chatId}: $e');
        }
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _setupWebSocketListeners() {
    if (_chatService == null) return;
    
    _subscriptions.add(
      _chatService!.onNewChat.listen((chat) async {
        try {
          await _chatService!.joinChat(chat.chatId);
          debugPrint('ChatProvider: Entrou automaticamente no novo chat ${chat.chatId}');
        } catch (e) {
          debugPrint('ChatProvider: Erro ao entrar automaticamente no chat ${chat.chatId}: $e');
        }
        
        final currentState = state;
        if (currentState is AsyncData<List<Chat>>) {
          final chats = currentState.value;
          if (!chats.any((existingChat) => existingChat.chatId == chat.chatId)) {
            final newChats = [chat, ...chats];
            state = AsyncValue.data(newChats);
            debugPrint('ChatProvider: Novo chat ${chat.chatId} adicionado à lista');
          }
        }
      }),
    );

    _subscriptions.add(
      _chatService!.onMessageReceived.listen((message) {
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
    if (_chatService == null) return null;
    
    try {
      final chat = await _chatService!.createDirectChat(participantId);
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
    if (_chatService == null) return null;
    
    try {
      final chat = await _chatService!.createGroup(name, participantIds);
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
    if (_chatService == null) return false;
    
    try {
      await _chatService!.addMemberToGroup(chatId, userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeMemberFromGroup(int chatId, int userId) async {
    if (_chatService == null) return false;
    
    try {
      await _chatService!.removeMemberFromGroup(chatId, userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteChat(int chatId) async {
    if (_chatService == null) return false;
    
    try {
      await _chatService!.deleteChat(chatId);
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
    if (_chatService == null) return false;
    
    try {
      await _chatService!.blockUser(chatId, targetUserId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unblockUser(int chatId, int targetUserId) async {
    if (_chatService == null) return false;
    
    try {
      await _chatService!.unblockUser(chatId, targetUserId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> reset() async {
    if (_chatService == null) return;
    
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    await _chatService!.reset();
    
    state = const AsyncValue.loading();
    await _initializeChats();
    _setupWebSocketListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    if (_chatService != null) {
      _chatService!.dispose();
    }
    super.dispose();
  }
}

class MessageListNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final int chatId;
  ChatService? _chatService;
  final List<StreamSubscription> _subscriptions = [];
  String? _nextCursor;
  Timer? _reloadTimer;
  late final int _sessionId;

  MessageListNotifier(this.chatId) : super(const AsyncValue.loading()) {
    _sessionId = AuthService.sessionId;
  }

  void setChatService(ChatService chatService) {
    debugPrint('MessageListNotifier[$chatId]: Configurando novo ChatService');
    
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    _reloadTimer?.cancel();
    
    _chatService = chatService;
    ChatService.registerDisposable(() => dispose());
    
    _initializeMessages();
    _setupWebSocketListeners();
    _setupPeriodicReload();
  }

  Future<void> _initializeMessages() async {
    if (_chatService == null) return;
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      await _chatService!.joinChat(chatId);
      await Future.delayed(const Duration(seconds: 2));
      await _chatService!.joinChat(chatId);
      final messages = await _chatService!.getMessages(chatId);
      state = AsyncValue.data(messages.reversed.toList());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _setupWebSocketListeners() {
    if (_chatService == null) return;
    
    _subscriptions.add(
      _chatService!.onMessageReceived.listen((message) {
        if (message.chatId == chatId) {
          final currentState = state;
          if (currentState is AsyncData<List<Message>>) {
            final messages = currentState.value;
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
          }
        }
      }),
    );
  }

  Future<bool> sendMessage(String content) async {
    if (_chatService == null) {
      debugPrint('MessageListNotifier[$chatId]: ChatService não disponível para envio de mensagem');
      return false;
    }
    
    debugPrint('MessageListNotifier[$chatId]: Enviando mensagem: "$content"');
    
    try {
      final expectedContent = content;
      final expectedTime = DateTime.now();
      final initialState = state;
      final currentMessages = initialState is AsyncData<List<Message>> ? initialState.value : <Message>[];
      if (currentMessages.isEmpty) {
        await _chatService!.joinChat(chatId);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      final message = await _chatService!.sendMessage(chatId, content);
      
      debugPrint('MessageListNotifier[$chatId]: Mensagem enviada com sucesso - ID: ${message.messageId}');
      
      if (message.messageId > 1000000000000) {
        await Future.delayed(const Duration(seconds: 3));
        final checkState = state;
        final currentMessages = checkState is AsyncData<List<Message>> ? checkState.value : <Message>[];
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
      final currentState = state;
      if (currentState is AsyncData<List<Message>>) {
        final messages = currentState.value;
        final newMessages = [...messages, message];
        state = AsyncValue.data(newMessages);
      }
      return true;
    } catch (e) {
      debugPrint('MessageListNotifier[$chatId]: Erro ao enviar mensagem: $e');
      return false;
    }
  }

  Future<void> loadMoreMessages() async {
    if (_nextCursor == null || _chatService == null) return;
    try {
      final newMessages = await _chatService!.getMessages(
        chatId,
        cursor: _nextCursor,
      );
      final currentState = state;
      if (currentState is AsyncData<List<Message>>) {
        final messages = currentState.value;
        final allMessages = [...newMessages.reversed, ...messages];
        state = AsyncValue.data(allMessages);
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    }
  }

  void startTyping() {
    _chatService?.startTyping(chatId);
  }

  void stopTyping() {
    _chatService?.stopTyping(chatId);
  }

  void _setupPeriodicReload() {
    _reloadTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (timer.tick > 4) {
        timer.cancel();
        return;
      }
      
      if (_sessionId != AuthService.sessionId) {
        debugPrint('MessageListNotifier: Sessão inválida, cancelando timer');
        timer.cancel();
        dispose();
        return;
      }
      
      try {
        if (_chatService != null) {
          final newMessages = await _chatService!.getMessages(chatId);
          final currentState = state;
          if (currentState is AsyncData<List<Message>>) {
            final currentMessages = currentState.value;
            if (newMessages.length != currentMessages.length) {
              state = AsyncValue.data(newMessages.reversed.toList());
            }
          }
        }
      } catch (e) {
        debugPrint('Error reloading messages after timeout: $e');
        if (e.toString().contains('Sessão inválida')) {
          timer.cancel();
          dispose();
        }
      }
    });
  }

  @override
  void dispose() {
    ChatService.unregisterDisposable(() => dispose());
    if (_chatService != null) {
      _chatService!.leaveChat(chatId);
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _reloadTimer?.cancel();
    super.dispose();
  }
}

final chatListProvider = StateNotifierProvider.autoDispose<ChatListNotifier, AsyncValue<List<Chat>>>((ref) {
  final notifier = ChatListNotifier();
  final authNotifier = ref.watch(authProvider.notifier);
  
  ref.listen(authProvider, (previous, next) {
    if (next == AuthState.authenticated && authNotifier.chatService != null) {
      notifier.setChatService(authNotifier.chatService!);
    }
  });
  
  if (authNotifier.chatService != null) {
    notifier.setChatService(authNotifier.chatService!);
  }
  
  return notifier;
});

final messageListProvider = StateNotifierProvider.autoDispose.family<MessageListNotifier, AsyncValue<List<Message>>, int>(
  (ref, chatId) {
    final notifier = MessageListNotifier(chatId);
    final authNotifier = ref.watch(authProvider.notifier);
    
    debugPrint('MessageListProvider[$chatId]: Criando nova instância');
    
    ref.listen(authProvider, (previous, next) {
      debugPrint('MessageListProvider[$chatId]: Estado mudou de $previous para $next');
      if (next == AuthState.authenticated && authNotifier.chatService != null) {
        debugPrint('MessageListProvider[$chatId]: Configurando ChatService para usuário ${authNotifier.currentUser?.userId}');
        notifier.setChatService(authNotifier.chatService!);
      }
    });
    
    if (authNotifier.isAuthenticated && authNotifier.chatService != null) {
      debugPrint('MessageListProvider[$chatId]: Configuração inicial do ChatService para usuário ${authNotifier.currentUser?.userId}');
      notifier.setChatService(authNotifier.chatService!);
    }
    
    return notifier;
  },
);

final userSearchProvider = FutureProvider.autoDispose.family<List<User>, String>((ref, phone) async {
  final authNotifier = ref.read(authProvider.notifier);
  if (authNotifier.chatService == null) return [];
  return await authNotifier.chatService!.searchUsersByPhone(phone);
});

final webSocketConnectionProvider = StreamProvider.autoDispose<bool>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  if (authNotifier.chatService == null) return Stream.value(false);
  return authNotifier.chatService!.onConnectionChange;
});

final webSocketErrorProvider = StreamProvider.autoDispose<String>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  if (authNotifier.chatService == null) return Stream.value('');
  return authNotifier.chatService!.onError;
});