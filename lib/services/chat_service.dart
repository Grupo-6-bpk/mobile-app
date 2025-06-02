import 'dart:convert';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'websocket_service.dart';

class ChatService {
  final AuthService _authService = AuthService();
  final WebSocketService _webSocketService = WebSocketService();

  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Future<List<Chat>> getChats() async {
    try {
      final response = await _authService.authenticatedRequest('GET', AppConfig.chatsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> chatsJson = jsonDecode(response.body);
        return chatsJson.map((json) => Chat.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar chats: $e');
    }
  }

  Future<Chat> createDirectChat(int participantId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        AppConfig.chatsEndpoint,
        body: {
          'isGroup': false,
          'participantIds': [participantId],
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatJson = jsonDecode(response.body);
        return Chat.fromJson(chatJson);
      } else {
        throw Exception('Erro ao criar chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao criar chat: $e');
    }
  }

  Future<Chat> createGroup(String name, List<int> participantIds) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        AppConfig.chatsEndpoint,
        body: {
          'isGroup': true,
          'name': name,
          'participantIds': participantIds,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatJson = jsonDecode(response.body);
        final chat = Chat.fromJson(chatJson);
        return chat;
      } else {
        throw Exception('Erro ao criar grupo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao criar grupo: $e');
    }
  }

  Future<Chat> getChatDetails(int chatId) async {
    try {
      final response = await _authService.authenticatedRequest('GET', '${AppConfig.chatsEndpoint}/$chatId');

      if (response.statusCode == 200) {
        final chatJson = jsonDecode(response.body);
        return Chat.fromJson(chatJson);
      } else {
        throw Exception('Erro ao carregar detalhes do chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar detalhes do chat: $e');
    }
  }

  Future<Message> sendMessage(int chatId, String content) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        final response = await _authService.authenticatedRequest(
          'POST',
          '${AppConfig.chatsEndpoint}/$chatId/messages',
          body: {'content': content},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.statusCode == 201 && response.body.isEmpty) {
            final currentUser = _authService.currentUser;
            final tempMessage = Message(
              messageId: DateTime.now().millisecondsSinceEpoch,
              chatId: chatId,
              senderId: currentUser?.userId ?? 0,
              senderName: currentUser?.name ?? 'Você',
              senderAvatar: currentUser?.avatarUrl,
              content: content,
              sentAt: DateTime.now(),
              isFromCurrentUser: true,
            );

            return tempMessage;
          }

          if (response.body.isEmpty) {
            throw Exception('Backend retornou resposta vazia para envio de mensagem');
          }

          final messageJson = jsonDecode(response.body);
          final message = Message.fromJson(
            messageJson,
            currentUserId: _authService.currentUser?.userId,
          );

          return message;
        } else if (response.statusCode == 404) {
          throw Exception('Chat não encontrado. Grupo pode ainda estar sendo criado no backend.');
        } else {
          throw Exception('Erro ao enviar mensagem: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;

        if (retryCount < maxRetries && (e is FormatException || e.toString().contains('Chat não encontrado'))) {
          await Future.delayed(retryDelay);
          continue;
        }

        throw Exception('Erro ao enviar mensagem após $maxRetries tentativas: $e');
      }
    }

    throw Exception('Falha ao enviar mensagem após $maxRetries tentativas');
  }

  Future<List<Message>> getMessages(int chatId, {int? limit, String? cursor}) async {
    try {
      final pageSize = limit ?? AppConfig.messagePageSize;
      String endpoint = '${AppConfig.chatsEndpoint}/$chatId/messages?limit=$pageSize';
      if (cursor != null) {
        endpoint += '&cursor=$cursor';
      }

      final response = await _authService.authenticatedRequest('GET', endpoint);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }

        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'] ?? data;

        final messages = messagesJson.map((json) {
          final message = Message.fromJson(
            json,
            currentUserId: _authService.currentUser?.userId,
          );
          return message;
        }).toList();

        return messages;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao carregar mensagens: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('FormatException') || e.toString().contains('404')) {
        return [];
      }

      throw Exception('Erro ao carregar mensagens: $e');
    }
  }

  Future<void> addMemberToGroup(int chatId, int userId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '${AppConfig.chatsEndpoint}/$chatId/invite',
        body: {'userId': userId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          await _webSocketService.inviteUser(chatId, userId);
        } catch (e) {
        }
      } else {
        throw Exception('Erro ao adicionar membro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao adicionar membro: $e');
    }
  }

  Future<void> removeMemberFromGroup(int chatId, int userId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '${AppConfig.chatsEndpoint}/$chatId/remove',
        body: {'userId': userId},
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        try {
          await _webSocketService.removeUser(chatId, userId);
        } catch (e) {
        }
      } else {
        throw Exception('Erro ao remover membro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao remover membro: $e');
    }
  }

  Future<void> deleteChat(int chatId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'DELETE',
        '${AppConfig.chatsEndpoint}/$chatId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          await _webSocketService.deleteChat(chatId);
        } catch (e) {
        }
      } else {
        throw Exception('Erro ao excluir chat: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao excluir chat: $e');
    }
  }

  Future<void> blockUser(int chatId, int targetUserId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '${AppConfig.chatsEndpoint}/$chatId/block',
        body: {'targetUserId': targetUserId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _webSocketService.blockUser(chatId, targetUserId);
      } else {
        throw Exception('Erro ao bloquear usuário: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao bloquear usuário: $e');
    }
  }

  Future<void> unblockUser(int chatId, int targetUserId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '${AppConfig.chatsEndpoint}/$chatId/unblock',
        body: {'targetUserId': targetUserId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _webSocketService.unblockUser(chatId, targetUserId);
      } else {
        throw Exception('Erro ao desbloquear usuário: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao desbloquear usuário: $e');
    }
  }

  Future<List<User>> searchUsersByPhone(String phone) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '${AppConfig.usersSearchEndpoint}?phone=$phone',
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }

        final responseData = jsonDecode(response.body);
        
        if (responseData is List) {
          final List<dynamic> usersJson = responseData;
          return usersJson.map((json) {
            try {
              return User.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          }).whereType<User>().toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Erro ao buscar usuários: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  Future<void> connectWebSocket() async {
    await _webSocketService.connect();
  }

  Future<void> disconnectWebSocket() async {
    await _webSocketService.disconnect();
  }

  Future<void> joinChat(int chatId) async {
    await _webSocketService.joinChat(chatId);
  }

  Future<void> leaveChat(int chatId) async {
    await _webSocketService.leaveChat(chatId);
  }

  Stream<Message> get onMessageReceived => _webSocketService.onMessageReceived;
  Stream<Map<String, dynamic>> get onMessageAck => _webSocketService.onMessageAck;
  Stream<String> get onError => _webSocketService.onError;
  Stream<bool> get onConnectionChange => _webSocketService.onConnectionChange;
  Stream<Chat> get onNewChat => _webSocketService.onNewChat;

  Future<void> markMessagesAsRead(int chatId, List<int> messageIds) async {
    await _webSocketService.markAsRead(chatId, messageIds);
  }

  Future<void> startTyping(int chatId) async {
    await _webSocketService.startTyping(chatId);
  }

  Future<void> stopTyping(int chatId) async {
    await _webSocketService.stopTyping(chatId);
  }

  bool get isWebSocketConnected => _webSocketService.isConnected;

  void dispose() {
    _webSocketService.dispose();
  }
}