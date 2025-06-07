import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'websocket_service.dart';

class ChatCreatedSuccessfully implements Exception {
  final String message;
  ChatCreatedSuccessfully(this.message);
  
  @override
  String toString() => message;
}

class ChatService {
  final AuthService authService;
  final WebSocketService webSocketService;

  ChatService(this.authService, this.webSocketService);

  Future<List<Chat>> getChats() async {
    try {
      final response = await authService.authenticatedRequest(
        'GET',
        AppConfig.chatsEndpoint,
      );

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
      final response = await authService.authenticatedRequest(
        'POST',
        AppConfig.chatsEndpoint,
        body: {
          'isGroup': false,
          'participantIds': [participantId],
        },
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          final chatJson = jsonDecode(response.body);
          return Chat.fromJson(chatJson);
        } else {
          throw ChatCreatedSuccessfully('Chat criado com sucesso, atualizando lista...');
        }
      } else {
        throw Exception('Erro ao criar chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao criar chat: $e');
    }
  }

  Future<Chat> createGroup(String name, List<int> participantIds) async {
    try {
      final response = await authService.authenticatedRequest(
        'POST',
        AppConfig.chatsEndpoint,
        body: {'isGroup': true, 'name': name, 'participantIds': participantIds},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          final chatJson = jsonDecode(response.body);
          final chat = Chat.fromJson(chatJson);
          return chat;
        } else {
          throw ChatCreatedSuccessfully('Grupo criado com sucesso, atualizando lista...');
        }
      } else {
        throw Exception('Erro ao criar grupo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao criar grupo: $e');
    }
  }

  Future<Chat> getChatDetails(int chatId) async {
    try {
      final response = await authService.authenticatedRequest(
        'GET',
        '${AppConfig.chatsEndpoint}/$chatId',
      );

      if (response.statusCode == 200) {
        final chatJson = jsonDecode(response.body);
        return Chat.fromJson(chatJson);
      } else {
        throw Exception(
          'Erro ao carregar detalhes do chat: ${response.statusCode}',
        );
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
        final response = await authService.authenticatedRequest(
          'POST',
          '${AppConfig.chatsEndpoint}/$chatId/messages',
          body: {'content': content},
          expectedSessionId: AuthService.sessionId,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.statusCode == 201 && response.body.isEmpty) {
            final currentUser = authService.currentUser;
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
            throw Exception(
              'Backend retornou resposta vazia para envio de mensagem',
            );
          }

          final messageJson = jsonDecode(response.body);
          final message = Message.fromJson(
            messageJson,
            currentUserId: authService.currentUser?.userId,
          );

          return message;
        } else if (response.statusCode == 404) {
          throw Exception(
            'Chat não encontrado. Grupo pode ainda estar sendo criado no backend.',
          );
        } else {
          throw Exception('Erro ao enviar mensagem: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;

        if (retryCount < maxRetries &&
            (e is FormatException ||
                e.toString().contains('Chat não encontrado'))) {
          await Future.delayed(retryDelay);
          continue;
        }

        throw Exception(
          'Erro ao enviar mensagem após $maxRetries tentativas: $e',
        );
      }
    }

    throw Exception('Falha ao enviar mensagem após $maxRetries tentativas');
  }

  Future<List<Message>> getMessages(
    int chatId, {
    int? limit,
    String? cursor,
  }) async {
    try {
      final pageSize = limit ?? AppConfig.messagePageSize;
      String endpoint =
          '${AppConfig.chatsEndpoint}/$chatId/messages?limit=$pageSize';
      if (cursor != null) {
        endpoint += '&cursor=$cursor';
      }

      final response = await authService.authenticatedRequest(
        'GET', 
        endpoint,
        expectedSessionId: AuthService.sessionId,
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }

        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'] ?? data;

        final messages =
            messagesJson.map((json) {
              return Message.fromJson(
                json,
                currentUserId: authService.currentUser?.userId,
              );
            }).toList();

        return messages;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao carregar mensagens: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('FormatException') ||
          e.toString().contains('404')) {
        return [];
      }

      throw Exception('Erro ao carregar mensagens: $e');
    }
  }

  Future<void> addMemberToGroup(int chatId, int userId) async {
    try {
      final response = await authService.authenticatedRequest(
        'POST',
        '${AppConfig.chatsEndpoint}/$chatId/invite',
        body: {'userId': userId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          await webSocketService.inviteUser(chatId, userId);
        } catch (e) {
          debugPrint('WebSocket invite error: $e');
        }
      } else {
        throw Exception(
          'Erro ao adicionar membro: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao adicionar membro: $e');
    }
  }

  Future<void> removeMemberFromGroup(int chatId, int userId) async {
    try {
      final response = await authService.authenticatedRequest(
        'POST',
        '${AppConfig.chatsEndpoint}/$chatId/remove',
        body: {'userId': userId},
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        try {
          await webSocketService.removeUser(chatId, userId);
        } catch (e) {
          debugPrint('WebSocket remove user error: $e');
        }
      } else {
        throw Exception(
          'Erro ao remover membro: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao remover membro: $e');
    }
  }

  Future<void> deleteChat(int chatId) async {
    try {
      final response = await authService.authenticatedRequest(
        'DELETE',
        '${AppConfig.chatsEndpoint}/$chatId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          await webSocketService.deleteChat(chatId);
        } catch (e) {
          debugPrint('WebSocket delete chat error: $e');
        }
      } else {
        throw Exception(
          'Erro ao excluir chat: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao excluir chat: $e');
    }
  }

  Future<void> blockUser(int chatId, int targetUserId) async {
    try {
      final response = await authService.authenticatedRequest(
        'POST',
        '${AppConfig.chatsEndpoint}/$chatId/block',
        body: {'targetUserId': targetUserId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await webSocketService.blockUser(chatId, targetUserId);
      } else {
        throw Exception(
          'Erro ao bloquear usuário: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao bloquear usuário: $e');
    }
  }

  Future<void> unblockUser(int chatId, int targetUserId) async {
    try {
      final response = await authService.authenticatedRequest(
        'POST',
        '${AppConfig.chatsEndpoint}/$chatId/unblock',
        body: {'targetUserId': targetUserId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await webSocketService.unblockUser(chatId, targetUserId);
      } else {
        throw Exception(
          'Erro ao desbloquear usuário: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao desbloquear usuário: $e');
    }
  }

  Future<List<User>> searchUsersByPhone(String phone) async {
    try {
      final response = await authService.authenticatedRequest(
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
          return usersJson
              .map((json) {
                try {
                  return User.fromJson(json as Map<String, dynamic>);
                } catch (e) {
                  return null;
                }
              })
              .whereType<User>()
              .toList();
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
    final token = authService.token;
    final userId = authService.currentUser?.userId;
    debugPrint('ChatService: Conectando WebSocket com token para usuário ID: $userId');
    await webSocketService.connect(token);
  }

  Future<void> disconnectWebSocket() async {
    await webSocketService.disconnect();
  }

  Future<void> joinChat(int chatId) async {
    await webSocketService.joinChat(chatId);
  }

  Future<void> leaveChat(int chatId) async {
    await webSocketService.leaveChat(chatId);
  }

  Stream<Message> get onMessageReceived => webSocketService.onMessageReceived;
  Stream<Map<String, dynamic>> get onMessageAck =>
      webSocketService.onMessageAck;
  Stream<String> get onError => webSocketService.onError;
  Stream<bool> get onConnectionChange => webSocketService.onConnectionChange;
  Stream<Chat> get onNewChat => webSocketService.onNewChat;

  Future<void> markMessagesAsRead(int chatId, List<int> messageIds) async {
    await webSocketService.markAsRead(chatId, messageIds);
  }

  Future<void> startTyping(int chatId) async {
    await webSocketService.startTyping(chatId);
  }

  Future<void> stopTyping(int chatId) async {
    await webSocketService.stopTyping(chatId);
  }

  bool get isWebSocketConnected => webSocketService.isConnected;

  static final List<VoidCallback> _disposables = [];
  
  static void registerDisposable(VoidCallback dispose) {
    _disposables.add(dispose);
  }
  
  static void unregisterDisposable(VoidCallback dispose) {
    _disposables.remove(dispose);
  }
  
  static void disposeAll() {
    for (final dispose in List.from(_disposables)) {
      try {
        dispose();
      } catch (e) {
        debugPrint('Erro ao fazer dispose: $e');
      }
    }
    _disposables.clear();
  }

  Future<void> reset() async {
    disposeAll();
    await webSocketService.reset();
  }

  void dispose() {
    webSocketService.dispose();
  }
}
