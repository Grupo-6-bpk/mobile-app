import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../services/chat_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  String? _errorMessage;
  
  WebSocketService? _webSocketService;
  ChatService? _chatService;

  AuthNotifier() : super(AuthState.initial) {
    _initializeAuth();
  }

  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => state == AuthState.authenticated && _currentUser != null;
  
  WebSocketService? get webSocketService => _webSocketService;
  ChatService? get chatService => _chatService;

  Future<void> _initializeAuth() async {
    state = AuthState.loading;
    
    try {
      await _authService.loadFromStorage();
      
      if (_authService.isAuthenticated && _authService.currentUser != null) {
        _currentUser = _authService.currentUser;
        _createServices();
        state = AuthState.authenticated;
        debugPrint('AuthProvider: Usuário autenticado carregado: ${_currentUser?.email}');
      } else {
        _currentUser = null;
        state = AuthState.unauthenticated;
        debugPrint('AuthProvider: Nenhum usuário autenticado encontrado');
      }
    } catch (e) {
      debugPrint('AuthProvider: Erro ao inicializar autenticação: $e');
      _currentUser = null;
      _errorMessage = 'Erro ao inicializar autenticação: $e';
      state = AuthState.error;
    }
  }

  void _createServices() {
    _webSocketService = WebSocketService(_authService);
    _chatService = ChatService(_authService, _webSocketService!);
  }

  void _disposeServices() {
    debugPrint('AuthProvider: Iniciando dispose dos serviços');
    
    if (_chatService != null) {
      try {
        _chatService!.dispose();
      } catch (e) {
        debugPrint('AuthProvider: Erro ao dispor ChatService: $e');
      }
      _chatService = null;
    }
    
    if (_webSocketService != null) {
      try {
        _webSocketService!.dispose();
      } catch (e) {
        debugPrint('AuthProvider: Erro ao dispor WebSocketService: $e');
      }
      _webSocketService = null;
    }
    
    debugPrint('AuthProvider: Dispose dos serviços concluído');
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading;
    _errorMessage = null;

    try {
      final success = await _authService.login(email, password);
      
      if (success) {
        _currentUser = _authService.currentUser;
        _errorMessage = null;
        
        debugPrint('AuthProvider: Login bem-sucedido para usuário ${_currentUser?.userId}');
        debugPrint('AuthProvider: Token atual: ${_authService.token?.substring(0, 20)}...');
        
        _createServices();
        
        try {
          await Future.delayed(const Duration(milliseconds: 200));
          debugPrint('AuthProvider: Conectando WebSocket...');
          await _chatService!.connectWebSocket();
          debugPrint('AuthProvider: WebSocket conectado com sucesso');
        } catch (wsError) {
          debugPrint('AuthProvider: Erro ao conectar WebSocket: $wsError');
        }
        
        state = AuthState.authenticated;
        return true;
      } else {
        _errorMessage = 'Falha no login. Tente novamente.';
        state = AuthState.error;
        return false;
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      
      _errorMessage = errorMsg;
      state = AuthState.error;
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading;
    
    try {
      _currentUser = null;
      _errorMessage = null;
      
      _disposeServices();
      
      await _authService.logout();
      
      debugPrint('AuthProvider: Logout concluído, estado completamente resetado');
      
      state = AuthState.unauthenticated;
      
    } catch (e) {
      debugPrint('AuthProvider: Erro no logout: $e');
      
      _currentUser = null;
      _errorMessage = 'Erro ao fazer logout: $e';
      state = AuthState.unauthenticated;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (state == AuthState.error) {
      state = _authService.isAuthenticated 
          ? AuthState.authenticated 
          : AuthState.unauthenticated;
    }
  }

  String getHomeRouteForUser() {
    return _authService.getHomeRouteForUser();
  }

  String getUserTypeDescription() {
    return _authService.getUserTypeDescription();
  }

  Future<void> forceReinitialize() async {
    debugPrint('AuthProvider: Forçando reinicialização completa...');
    _currentUser = null;
    _errorMessage = null;
    state = AuthState.initial;
    await _initializeAuth();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  return ref.read(authProvider.notifier);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return authState == AuthState.authenticated && authNotifier.currentUser != null;
});

final currentUserProvider = Provider<User?>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return authNotifier.currentUser;
});

final authErrorProvider = Provider<String?>((ref) {
  ref.watch(authProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return authNotifier.errorMessage;
}); 