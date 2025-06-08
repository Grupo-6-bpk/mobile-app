import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class WebSocketService {
  io.Socket? _socket;
  final AuthService authService;
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
  bool get isConnected => _socket?.connected ?? false;
  bool _isConnecting = false;
  String? _lastToken;

  WebSocketService(this.authService);

  void _safeAddToMessageController(Message message) {
    if (!_messageController.isClosed) {
      _messageController.add(message);
    }
  }

  void _safeAddToMessageAckController(Map<String, dynamic> data) {
    if (!_messageAckController.isClosed) {
      _messageAckController.add(data);
    }
  }

  void _safeAddToErrorController(String error) {
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
  }

  void _safeAddToConnectionController(bool connected) {
    if (!_connectionController.isClosed) {
      _connectionController.add(connected);
    }
  }

  void _safeAddToNewChatController(Chat chat) {
    if (!_newChatController.isClosed) {
      _newChatController.add(chat);
    }
  }

  Future<void> connect([String? token]) async {
    if (_isConnecting) {
      debugPrint('WebSocketService: Já conectando, aguardando...');
      return;
    }

    final authToken = token ?? authService.token;
    if (authToken == null) {
      _safeAddToErrorController('Token de autenticação não encontrado');
      debugPrint('WebSocketService: ERRO - Token não encontrado');
      return;
    }

    debugPrint('WebSocketService: Token recebido: ${authToken.substring(0, 20)}...');
    debugPrint('WebSocketService: Usuário do AuthService: ${authService.currentUser?.userId}');
    debugPrint('WebSocketService: Email do usuário: ${authService.currentUser?.email}');

    if (_socket?.connected == true) {
      debugPrint('WebSocketService: Forçando reset de conexão existente');
      await reset();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    _isConnecting = true;
    _lastToken = authToken;
    
    debugPrint('WebSocketService: Iniciando nova conexão com token para usuário: ${authService.currentUser?.userId}');
    
    try {
      _socket = io.io(AppConfig.webSocketUrl, io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': authToken})
          .setExtraHeaders({'Authorization': 'Bearer $authToken'})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(AppConfig.maxRetryAttempts)
          .setReconnectionDelay(AppConfig.reconnectionDelay)
          .build());
      _setupEventListeners();
      _socket!.connect();
      debugPrint('WebSocketService: Conexão iniciada com sucesso para usuário: ${authService.currentUser?.userId}');
    } catch (e) {
      _safeAddToErrorController('Erro ao conectar WebSocket: $e');
      debugPrint('WebSocketService: ERRO na conexão: $e');
    } finally {
      _isConnecting = false;
    }
  }
  void _setupEventListeners() {
    if (_socket == null) return;
    _socket!.onConnect((_) {
      _safeAddToConnectionController(true);
    });
    _socket!.onDisconnect((_) {
      _safeAddToConnectionController(false);
    });
    _socket!.onError((error) {
      _safeAddToErrorController('Erro de conexão: $error');
    });
    _socket!.on('message_received', (data) {
      try {
        final message = Message.fromJson(
          data as Map<String, dynamic>,
          currentUserId: authService.currentUser?.userId,
        );
        
        debugPrint('   WebSocket Message created - isFromCurrentUser: ${message.isFromCurrentUser}');
        
        _safeAddToMessageController(message);
      } catch (e) {
        debugPrint('❌ DEBUG WebSocket error: $e');
      }
    });
    _socket!.on('message_ack', (data) {
      try {
        _safeAddToMessageAckController(data as Map<String, dynamic>);
      } catch (e) {
        debugPrint('WebSocket message_ack error: $e');
      }
    });
    _socket!.on('chat_created', (data) {
      try {
        final chat = Chat.fromJson(data as Map<String, dynamic>);
        _safeAddToNewChatController(chat);
      } catch (e) {
        debugPrint('WebSocket chat_created error: $e');
      }
    });
    _socket!.on('error', (data) {
      final message = data is Map ? data['message'] ?? 'Erro desconhecido' : data.toString();
      _safeAddToErrorController(message);
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
      _safeAddToErrorController('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('send_message', {
        'chatId': chatId,
        'content': content,
      });
    } catch (e) {
      _safeAddToErrorController('Erro ao enviar mensagem: $e');
    }
  }
  Future<void> createGroup(String name, List<int> participantIds) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _safeAddToErrorController('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('create_group', {
        'name': name,
        'participantIds': participantIds,
      });
    } catch (e) {
      _safeAddToErrorController('Erro ao criar grupo: $e');
    }
  }
  Future<void> joinChat(int chatId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _safeAddToErrorController('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('join_chat', {'chatId': chatId});
    } catch (e) {
      _safeAddToErrorController('Erro ao entrar no chat: $e');
    }
  }
  Future<void> leaveChat(int chatId) async {
    if (!isConnected) return;
    try {
      _socket!.emit('leave_chat', {'chatId': chatId});
    } catch (e) {
      _safeAddToErrorController('Erro ao sair do chat: $e');
    }
  }
  Future<void> blockUser(int chatId, int targetUserId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _safeAddToErrorController('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('block_user', {
        'chatId': chatId,
        'targetUserId': targetUserId,
      });
    } catch (e) {
      _safeAddToErrorController('Erro ao bloquear usuário: $e');
    }
  }
  Future<void> unblockUser(int chatId, int targetUserId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _safeAddToErrorController('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('unblock_user', {
        'chatId': chatId,
        'targetUserId': targetUserId,
      });
    } catch (e) {
      _safeAddToErrorController('Erro ao desbloquear usuário: $e');
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
      _safeAddToErrorController('Erro ao marcar como lido: $e');
    }
  }
  Future<void> startTyping(int chatId) async {
    if (!isConnected) return;
    try {
      _socket!.emit('start_typing', {'chatId': chatId});
    } catch (e) {
      debugPrint('WebSocket start typing error: $e');
    }
  }
  Future<void> stopTyping(int chatId) async {
    if (!isConnected) return;
    try {
      _socket!.emit('stop_typing', {'chatId': chatId});
    } catch (e) {
      debugPrint('WebSocket stop typing error: $e');
    }
  }
  Future<void> inviteUser(int chatId, int userId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _safeAddToErrorController('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('invite_user', {
        'chatId': chatId,
        'userId': userId,
      });
    } catch (e) {
      _safeAddToErrorController('Erro ao convidar usuário: $e');
    }
  }
  Future<void> removeUser(int chatId, int userId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _safeAddToErrorController('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('remove_user', {
        'chatId': chatId,
        'userId': userId,
      });
    } catch (e) {
      _safeAddToErrorController('Erro ao remover usuário: $e');
    }
  }
  Future<void> deleteChat(int chatId) async {
    if (!isConnected) {
      await connect();
    }
    if (!isConnected) {
      _safeAddToErrorController('Não conectado ao WebSocket');
      return;
    }
    try {
      _socket!.emit('delete_chat', {
        'chatId': chatId,
      });
    } catch (e) {
      _safeAddToErrorController('Erro ao excluir chat: $e');
    }
  }
  Future<void> disconnect() async {
    if (_socket?.connected == true) {
      _socket!.disconnect();
    }
    _safeAddToConnectionController(false);
  }
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }
  Future<void> reset() async {
    debugPrint('WebSocketService: Iniciando reset completo - Token anterior: ${_lastToken?.substring(0, 20)}...');
    
    await disconnect();
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (_socket != null) {
      try {
        _socket!.dispose();
      } catch (e) {
        debugPrint('WebSocketService: Erro ao dispor socket: $e');
      }
      _socket = null;
    }
    
    _isConnecting = false;
    _lastToken = null;
    
    debugPrint('WebSocketService: Reset concluído - Estado limpo');
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