import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class AuthService {
  static Database? _database;
  String? _token;
  User? _currentUser;

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConfig.databaseName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE auth_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            token TEXT NOT NULL,
            user_data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            expires_at TEXT
          )
        ''');
      },
    );
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
        default:
          throw Exception('Formato de base64 inválido');
      }
      final decodedBytes = base64.decode(payload);
      final decodedJson = utf8.decode(decodedBytes);
      return jsonDecode(decodedJson);
    } catch (e) {
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('${AppConfig.baseUrl}/login');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['token'] != null) {
            _token = data['token'];
            final jwtPayload = _decodeJwtPayload(_token!);
            
            if (jwtPayload != null && jwtPayload['id'] != null) {
              final userId = jwtPayload['id'];
              
              try {
                final userResponse = await http.get(
                  Uri.parse('${AppConfig.baseUrl}/api/users/$userId'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $_token',
                  },
                ).timeout(const Duration(seconds: 10));
                
                if (userResponse.statusCode == 200) {
                  final userData = jsonDecode(userResponse.body);
                  _currentUser = User.fromJson(userData);
                } else {
                  _currentUser = User(
                    userId: userId ?? 0,
                    name: email.split('@')[0],
                    email: jwtPayload['email'] ?? email,
                    phone: '',
                    avatarUrl: null,
                  );
                }
              } catch (userError) {
                _currentUser = User(
                  userId: userId ?? 0,
                  name: email.split('@')[0],
                  email: jwtPayload['email'] ?? email,
                  phone: '',
                  avatarUrl: null,
                );
              }
            } else {
              _currentUser = User(
                userId: 0,
                name: email.split('@')[0],
                email: email,
                phone: '',
                avatarUrl: null,
              );
            }
            
            await _saveTokenToStorage(_token!);
            await _saveUserToStorage(_currentUser!);
            return true;
          } else {
            throw Exception('Token não recebido do servidor');
          }
        } catch (jsonError) {
          throw Exception('Resposta inválida do servidor');
        }
      } else if (response.statusCode == 401) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Email ou senha incorretos';
          throw Exception('Credenciais inválidas: $errorMessage');
        } catch (e) {
          throw Exception('Email ou senha incorretos. Verifique suas credenciais e tente novamente.');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Dados de login inválidos';
          throw Exception('Erro nos dados: $errorMessage');
        } catch (e) {
          throw Exception('Dados de login inválidos. Verifique o formato do email.');
        }
      } else if (response.statusCode == 422) {
        throw Exception('Dados de login não atenden aos requisitos. Verifique o email e senha.');
      } else if (response.statusCode == 429) {
        throw Exception('Muitas tentativas de login. Aguarde alguns minutos antes de tentar novamente.');
      } else if (response.statusCode == 503) {
        throw Exception('Servidor em manutenção. Tente novamente em alguns minutos.');
      } else if (response.statusCode >= 500) {
        throw Exception('Servidor temporariamente indisponível (erro ${response.statusCode}). Tente novamente mais tarde.');
      } else {
        throw Exception('Erro inesperado do servidor (código ${response.statusCode}). Contate o suporte se o problema persistir.');
      }
    } on TimeoutException {
      throw Exception('Tempo limite esgotado. Verifique sua conexão com a internet e tente novamente.');
    } on SocketException {
      throw Exception('Sem conexão com a internet. Verifique sua rede e tente novamente.');
    } on FormatException {
      throw Exception('Resposta inválida do servidor. Tente novamente ou contate o suporte.');
    } on HttpException {
      throw Exception('Erro de comunicação com o servidor. Verifique sua conexão.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow; 
      }
      throw Exception('Erro inesperado durante o login: ${e.toString()}');
    }
  }

  Future<void> _saveTokenToStorage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
    final db = await database;
    await db.insert('auth_tokens', {
      'token': token,
      'user_data': _currentUser?.toJson().toString() ?? '',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConfig.tokenKey);
      final userData = prefs.getString(AppConfig.userKey);
      if (userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados de autenticação: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.tokenKey);
      await prefs.remove(AppConfig.userKey);
      final db = await database;
      await db.delete('auth_tokens');
    } catch (e) {
      debugPrint('Erro ao limpar dados de autenticação: $e');
    }
  }

  Map<String, String> getAuthHeaders() {
    if (_token == null) return {};
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }

  bool requiresLogin() {
    return !isAuthenticated;
  }

  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = getAuthHeaders();
    final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');
    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Método HTTP não suportado: $method');
    }
  }

  String getHomeRouteForUser() {
    if (_currentUser == null) return "/main";
    
    if (_currentUser!.isDriver == true && _currentUser!.isPassenger == true) {
      return "/driverHome";
    } else if (_currentUser!.isDriver == true) {
      return "/driverHome";
    } else if (_currentUser!.isPassenger == true) {
      return "/passengerHome";
    }
    
    return "/main";
  }

  String getUserTypeDescription() {
    if (_currentUser == null) return "indefinido";
    
    if (_currentUser!.isDriver == true && _currentUser!.isPassenger == true) {
      return "driver e passenger";
    } else if (_currentUser!.isDriver == true) {
      return "driver";
    } else if (_currentUser!.isPassenger == true) {
      return "passenger";
    }
    
    return "indefinido";
  }
}
