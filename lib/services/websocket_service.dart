import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/message.dart';
import '../models/chat.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class WebSocketService {
  io.Socket? _socket;
  final AuthService _authService = AuthService();
  final StreamController<Message> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messageAckController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();
  final StreamController<bool> _connectionController = StreamController.broadcast();
  final StreamController<Chat> _newChatController = StreamController.broadcast();
  Stream<Message> get onMessageReceived => _messageController.stream;
  Stream<Map<String, dynamic>> get onMessageAck => _messageAckController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;
  Stream<Chat> get onNewChat => _newChatController.stream;
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();
  bool get isConnected => _socket?.connected ?? false;
  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = _authService.token;
    if (token == null) {
      _errorController.add('Token de autenticação não encontrado');
      return;
    }
    try {
      _socket = io.io(AppConfig.webSocketUrl, io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(AppConfig.maxRetryAttempts)
          .setReconnectionDelay(AppConfig.reconnectionDelay)
          .build());
      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      _errorController.add('Erro ao conectar WebSocket: $e');
    }
  }
  void _setupEventListeners() {
    if (_socket == null) return;
    _socket!.onConnect((_) {
      _connectionController.add(true);
    });
    _socket!.onDisconnect((_) {
      _connectionController.add(false);
    });
    _socket!.onError((error) {
      _errorController.add('Erro de conexão: $error');
    });
    _socket!.on('message_received', (data) {
      try {
        final message = Message.fromJson(
          data as Map<String, dynamic>,
          currentUserId: _authService.currentUser?.userId,
        );
        _messageController.add(message);
      } catch (e) {
      }
    });
    _socket!.on('message_ack', (data) {
      try {
        _messageAckController.add(data as Map<String, dynamic>);
      } catch (e) {
      }
    });
    _socket!.on('chat_created', (data) {
      try {
        final chat = Chat.fromJson(data as Map<String, dynamic>);
        _newChatController.add(chat);
      } catch (e) {
      }
    });
    _socket!.on('error', (data) {
      final message = data is Map ? data['message'] ?? 'Erro desconhecido' : data.toString();
      _errorController.add(message);
    });
    _socket!.on('user_joined_group', (data) {
    });
    _socket!.on('user_left_group', (data) {
    });
    _socket!.on('user_blocked', (data) {
    });
    _socket!.on('user_unblocked', (data) {
    });
  }
  Future<void> sendMessage(int chatId, String content) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _errorController.add('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('send_message', {
        'chatId': chatId,
        'content': content,
      });
    } catch (e) {
      _errorController.add('Erro ao enviar mensagem: $e');
    }
  }
  Future<void> createGroup(String name, List<int> participantIds) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _errorController.add('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('create_group', {
        'name': name,
        'participantIds': participantIds,
      });
    } catch (e) {
      _errorController.add('Erro ao criar grupo: $e');
    }
  }
  Future<void> joinChat(int chatId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _errorController.add('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('join_chat', {'chatId': chatId});
    } catch (e) {
      _errorController.add('Erro ao entrar no chat: $e');
    }
  }
  Future<void> leaveChat(int chatId) async {
    if (!isConnected) return;
    try {
      _socket!.emit('leave_chat', {'chatId': chatId});
    } catch (e) {
      _errorController.add('Erro ao sair do chat: $e');
    }
  }
  Future<void> blockUser(int chatId, int targetUserId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _errorController.add('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('block_user', {
        'chatId': chatId,
        'targetUserId': targetUserId,
      });
    } catch (e) {
      _errorController.add('Erro ao bloquear usuário: $e');
    }
  }
  Future<void> unblockUser(int chatId, int targetUserId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _errorController.add('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('unblock_user', {
        'chatId': chatId,
        'targetUserId': targetUserId,
      });
    } catch (e) {
      _errorController.add('Erro ao desbloquear usuário: $e');
    }
  }
  Future<void> markAsRead(int chatId, List<int> messageIds) async {
    if (!isConnected) return;
    try {
      _socket!.emit('mark_as_read', {
        'chatId': chatId,
        'messageIds': messageIds,
      });
    } catch (e) {
      _errorController.add('Erro ao marcar como lido: $e');
    }
  }
  Future<void> startTyping(int chatId) async {
    if (!isConnected) return;
    try {
      _socket!.emit('start_typing', {'chatId': chatId});
    } catch (e) {
    }
  }
  Future<void> stopTyping(int chatId) async {
    if (!isConnected) return;
    try {
      _socket!.emit('stop_typing', {'chatId': chatId});
    } catch (e) {
    }
  }
  Future<void> inviteUser(int chatId, int userId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _errorController.add('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('invite_user', {
        'chatId': chatId,
        'userId': userId,
      });
    } catch (e) {
      _errorController.add('Erro ao convidar usuário: $e');
    }
  }
  Future<void> removeUser(int chatId, int userId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _errorController.add('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('remove_user', {
        'chatId': chatId,
        'userId': userId,
      });
    } catch (e) {
      _errorController.add('Erro ao remover usuário: $e');
    }
  }
  Future<void> deleteChat(int chatId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _errorController.add('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('delete_chat', {
        'chatId': chatId,
      });
    } catch (e) {
      _errorController.add('Erro ao excluir chat: $e');
    }
  }
  Future<void> disconnect() async {
    if (_socket?.connected == true) {
      _socket!.disconnect();
    }
    _connectionController.add(false);
  }
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }
  void dispose() {
    _socket?.dispose();
    _messageController.close();
    _messageAckController.close();
    _errorController.close();
    _connectionController.close();
    _newChatController.close();
  }
}