import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

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

  AuthNotifier() : super(AuthState.initial) {
    _initializeAuth();
  }

  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => state == AuthState.authenticated && _currentUser != null;

  Future<void> _initializeAuth() async {
    state = AuthState.loading;
    
    try {
      await _authService.loadFromStorage();
      
      if (_authService.isAuthenticated) {
        _currentUser = _authService.currentUser;
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      _errorMessage = 'Erro ao inicializar autenticação: $e';
      state = AuthState.error;
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading;
    _errorMessage = null;

    try {
      final success = await _authService.login(email, password);
      
      if (success) {
        _currentUser = _authService.currentUser;
        _errorMessage = null;
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
      await _authService.logout();
      _currentUser = null;
      _errorMessage = null;
      state = AuthState.unauthenticated;
    } catch (e) {
      _errorMessage = 'Erro ao fazer logout: $e';
      state = AuthState.error;
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